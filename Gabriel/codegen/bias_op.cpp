#include "bias_op.h"

#include <iostream>

namespace gen
{
using namespace std;
using namespace util;

bias_op_component::bias_op_component(const vector<double>& biases, pair<int, int> bspec)
    : component("bias_op", "bias_op_u" + to_string(global_counter()),
    {
        datum("input_spec", fixed_spec_type, Sem::input_spec),
        datum("bias_spec",  fixed_spec_type, Sem::data_spec,  { double(bspec.first), double(bspec.second) }),
        datum("biases",     reals_type,      Sem::data,       biases),
    }, {
        datum("input",      sfixed_type,                                                 Sem::main_input)   .in(),
        datum("offset",     unsigned_type.with_range(bits_needed(biases.size()) - 1, 0), Sem::offset_intake).in(),
        datum("output",     sfixed_type,                                                 Sem::main_output)  .out(),
        datum("op_send",    std_logic_type,                                              Sem::sig_out_front)  .out(),
        datum("op_receive", std_logic_type,                                              Sem::sig_in_back).in(),
    })
{
    int nbits_int = bits_needed_for_max_int_part_signed(biases);
    if (nbits_int > bspec.first)
        cerr << "Warning: Bias value " << *max_element(biases.begin(), biases.end()) << " requires at least " << nbits_int
             << " bits to represent its (signed) integer part, but only gets " << bspec.first << ".\n";
}
void bias_op_component::propagate(component& prev)
{
    datum& spec = find_by(generic, Sem::input_spec);
    datum& prev_out = find_by(prev.port, Sem::main_output);
    spec.value = { double(prev_out.type.range_high + 1), double(-prev_out.type.range_low) };
    find_by(port, Sem::main_input).type.set_range(prev_out.type.range_high, prev_out.type.range_low);
    datum& bspec = find_by(generic, Sem::data_spec);
    find_by(port, Sem::main_output).type.set_range(max(spec.value[0], bspec.value[0]), -max(spec.value[1], bspec.value[1]));
}
string bias_op_component::demand_signal(Sem sem)
{
    datum& d = find_by(port, sem);
    if (d.is_invalid())
        throw runtime_error("bias_op_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
    return d.plugged_signal_name;
}

auto bias_gen = define_component_generator("bias", +[](const unordered_map<string, specification_variant>& params)
{
    auto get = checked_get("component generator")("bias", params);
    return unique_ptr<component>(new bias_op_component(
        get("biases"),
        pair<int, int>(get("bspec_int"), get("bspec_frac"))
    ));
});

auto bias_ac = define_activation_behavior_generator("bias", +[](const unordered_map<string, specification_variant>& params) -> activation_behavior
{
    auto get = checked_get("activation behavior generator")("bias", params);
    vector<double> biases = get("biases");
    return [biases = move(biases)](double input, size_t offset){
        return input + biases[offset];
    };
});

auto bias_av = define_validity_assertion_generator("bias", +[](const unordered_map<string, specification_variant>& params) -> validity_assertion
{
    auto get = checked_get("validity assertion generator")("bias", params);
    const vector<double>& biases = get("biases");
    return [biases_size = biases.size()](size_t offset_width){
        if (biases_size != offset_width)
            throw runtime_error("Layer with bias op has " + to_string(offset_width) + " outputs, and therefore bias op should have " +
                                to_string(offset_width) + " biases. However, the actual number of biases given is " + to_string(biases_size) + ".");
        return offset_width;
    };
});

layer_specification bias(const vector<double>& b, pair<int, int> b_spec)
{
    return layer_specification{
        "bias", {
            dyn_param("biases", b),
            dyn_param("bspec_int", b_spec.first),
            dyn_param("bspec_frac", b_spec.second),
        }
    };
}

auto bias_parse = define_layer_spec_parser("bias", +[](const sexpr_field& s, const string& pos_info)
{
    if (s.size() != 2 && s.size() != 3)
        throw runtime_error("layer_spec_parser for bias: At " + pos_info + ": Clause expects 2 or 3 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "bias", {} };
    vector<double> biases = parse_data(s[1], pos_info + ", first argument");
    static constexpr int default_n_bits = 12;
    const auto deduce_spec = [&](int n_bits){
        int n_bits_int = bits_needed_for_max_int_part_signed(biases);
        layer.parameters.emplace("bspec_int", n_bits_int);
        layer.parameters.emplace("bspec_frac", n_bits - n_bits_int);
    };
    layer.parameters.emplace("biases", biases);
    if (s.size() == 3){
        if (s[2].is_tree() && !s[2].empty() && s[2][0].string() == "fixed"){
            pair<int, int> bspec = parse_fixed_pair(s[2], pos_info + ", second argument");
            layer.parameters.emplace("bspec_int", bspec.first);
            layer.parameters.emplace("bspec_frac", bspec.second);
        } else
            deduce_spec(parse_bits(s[2], pos_info + ", second argument"));
    } else
        deduce_spec(default_n_bits);
    return move(layer);
});

} //namespace gen
