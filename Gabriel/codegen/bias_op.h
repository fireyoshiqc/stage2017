#pragma once

#include "util.h"
#include "parse.h"
#include "dynamic.h"
#include "component.h"
#include "specification.h"

namespace gen
{
using namespace std;
using namespace util;

struct bias_op_component : public component
{
    bias_op_component(const vector<double>& biases, pair<int, int> bspec)
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
        }) {}
    virtual void propagate(component& prev)
    {
        datum& spec = find_by(generic, Sem::input_spec);
        datum& prev_out = find_by(prev.port, Sem::main_output);
        spec.value = { double(prev_out.type.range_high + 1), double(-prev_out.type.range_low) };
        find_by(port, Sem::main_input).type.set_range(prev_out.type.range_high, prev_out.type.range_low);
        datum& bspec = find_by(generic, Sem::data_spec);
        find_by(port, Sem::main_output).type.set_range(max(spec.value[0], bspec.value[0]), -max(spec.value[1], bspec.value[1]));
    }
    virtual string demand_signal(Sem sem)
    {
        datum& d = find_by(port, sem);
        if (d.is_invalid())
            throw runtime_error("bias_op_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
        return d.plugged_signal_name;
    };
};

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
    if (s.size() != 3)
        throw runtime_error("layer_spec_parser for bias: At " + pos_info + ": Clause expects 2 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "bias", {} };
    layer.parameters.emplace("biases", parse_data(s[1], pos_info + ", first argument"));
    pair<int, int> bspec = parse_fixed_pair(s[2], pos_info + ", second argument");
    layer.parameters.emplace("bspec_int", bspec.first);
    layer.parameters.emplace("bspec_frac", bspec.second);
    return move(layer);
});

} //namespace gen
