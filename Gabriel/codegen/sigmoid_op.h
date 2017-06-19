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

struct sigmoid_op_component : public component
{
    sigmoid_op_component(pair<int, int> ospec, int step_prec, int bit_prec)
        : component("sigmoid_op", "sigmoid_op_u" + to_string(global_counter()),
        {
            datum("input_spec",     fixed_spec_type, Sem::input_spec),
            datum("output_spec",    fixed_spec_type, Sem::output_spec, { double(ospec.first), double(ospec.second) }),
            datum("step_precision", integer_type,    Sem::param,       { double(step_prec) }),
            datum("bit_precision",  integer_type,    Sem::param,       { double(bit_prec) }),
        }, {
            datum("clk",        std_logic_type,                                         Sem::clock)        .in(),
            datum("input",      sfixed_type,                                            Sem::main_input)   .in(),
            datum("output",     sfixed_type.with_range(ospec.first - 1, -ospec.second), Sem::main_output)  .out(),
            datum("op_send",    std_logic_type,                                         Sem::sig_out_front)  .out(),
            datum("op_receive", std_logic_type,                                         Sem::sig_in_back).in(),
        }) {}
    virtual void propagate(component& prev)
    {
        datum& input_spec = find_by(generic, Sem::input_spec);
        datum& prev_out = find_by(prev.port, Sem::main_output);
        input_spec.value = { double(prev_out.type.range_high + 1), double(-prev_out.type.range_low) };
        find_by(port, Sem::main_input).type.set_range(prev_out.type.range_high, prev_out.type.range_low);
    }
    virtual string demand_signal(Sem sem)
    {
        datum& d = find_by(port, sem);
        if (d.is_invalid())
            throw runtime_error("sigmoid_op_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
        return d.plugged_signal_name;
    };
};

auto sigmoid_gen = define_component_generator("sigmoid", +[](const unordered_map<string, specification_variant>& params)
{
    auto get = checked_get("component generator")("sigmoid", params);
    return unique_ptr<component>(new sigmoid_op_component(
        pair<int, int>(get("ospec_int"), get("ospec_frac")),
        get("step_prec"),
        get("bit_prec")
    ));
});

auto sigmoid_ac = define_activation_behavior_generator("sigmoid", +[](const unordered_map<string, specification_variant>& params) -> activation_behavior
{
    return [](double input, size_t offset){
        return 1.0 / (1.0 + exp(-input));
    };
});

auto sigmoid_av = define_validity_assertion_generator("sigmoid", +[](const unordered_map<string, specification_variant>& params) -> validity_assertion
{
    return [](size_t offset_width){
        return offset_width;
    };
});

layer_specification sigmoid(pair<int, int> ospec, int step_prec, int bit_prec)
{
    return layer_specification{
        "sigmoid", {
            dyn_param("ospec_int", ospec.first),
            dyn_param("ospec_frac", ospec.second),
            dyn_param("step_prec", step_prec),
            dyn_param("bit_prec", bit_prec),
        }
    };
}

auto sigmoid_parse = define_layer_spec_parser("sigmoid", +[](const sexpr_field& s, const string& pos_info)
{
    if (s.size() != 4)
        throw runtime_error("layer_spec_parser for sigmoid: At " + pos_info + ": Clause expects 3 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "sigmoid", {} };
    pair<int, int> ospec = parse_fixed_pair(s[1], pos_info + ", first argument");
    layer.parameters.emplace("ospec_int", ospec.first);
    layer.parameters.emplace("ospec_frac", ospec.second);
    layer.parameters.emplace("step_prec", parse_integer(s[2], pos_info + ", second argument"));
    layer.parameters.emplace("bit_prec", parse_integer(s[3], pos_info + ", third argument"));
    return move(layer);
});

} //namespace gen;
