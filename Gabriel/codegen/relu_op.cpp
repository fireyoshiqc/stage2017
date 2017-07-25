#include "relu_op.h"

namespace gen
{
using namespace std;
using namespace util;

relu_op_component::relu_op_component()
    : component("relu_op", "relu_op_u" + to_string(global_counter()),
    {
        datum("spec", fixed_spec_type, Sem::input_spec),
    }, {
        datum("input",      sfixed_type,    Sem::main_input)   .in(),
        datum("output",     sfixed_type,    Sem::main_output)  .out(),
        datum("op_send",    std_logic_type, Sem::sig_out_front).out(),
        datum("op_receive", std_logic_type, Sem::sig_in_back)  .in(),
    }) {}
void relu_op_component::propagate(component& prev)
{
    datum& input_spec = find_by(generic, Sem::input_spec);
    datum& prev_out = find_by(prev.port, Sem::main_output);
    input_spec.value = { double(prev_out.type.range_high + 1), double(-prev_out.type.range_low) };
    find_by(port, Sem::main_input).type.set_range(prev_out.type.range_high, prev_out.type.range_low);
    find_by(port, Sem::main_output).type.set_range(prev_out.type.range_high, prev_out.type.range_low);
}
string relu_op_component::demand_signal(Sem sem)
{
    datum& d = find_by(port, sem);
    if (d.is_invalid())
        throw runtime_error("relu_op_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
    return d.plugged_signal_name;
}

auto relu_gen = define_component_generator("relu", +[](const unordered_map<string, specification_variant>& params)
{
    auto get = checked_get("component generator")("relu", params);
    return unique_ptr<component>(new relu_op_component());
});

auto relu_ac = define_activation_behavior_generator("relu", +[](const unordered_map<string, specification_variant>& params) -> activation_behavior
{
    return [](double input, size_t offset){
        return input < 0.0 ? 0.0 : input;
    };
});

auto relu_av = define_validity_assertion_generator("relu", +[](const unordered_map<string, specification_variant>& params) -> validity_assertion
{
    return [](size_t offset_width){
        return offset_width;
    };
});

//layer_specification sigmoid(pair<int, int> ospec, int step_prec, int bit_prec)
//{
//    return layer_specification{
//        "sigmoid", {
//            dyn_param("ospec_int", ospec.first),
//            dyn_param("ospec_frac", ospec.second),
//            dyn_param("step_prec", step_prec),
//            dyn_param("bit_prec", bit_prec),
//        }
//    };
//}

auto relu_parse = define_layer_spec_parser("relu", +[](const sexpr_field& s, const string& pos_info)
{
    if (s.size() != 1)
        throw runtime_error("layer_spec_parser for relu: At " + pos_info + ": Clause expects 0 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "relu", {} };
    return move(layer);
});

} //namespace gen;
