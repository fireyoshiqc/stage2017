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

struct interlayer : public component
{
    interlayer(unsigned int width, pair<int, int> spec)
        : component("interlayer", "interlayer_u" + to_string(global_counter()),
        {
            datum("width",     integer_type, Sem::input_width, { double(width) }),
            datum("word_size", integer_type, Sem::input_spec,  { double(spec.first + spec.second) }),
        }, {
            datum("clk",        std_logic_type,                                                              Sem::clock)        .in(),
            datum("rst",        std_logic_type,                                                              Sem::reset)        .in(),
            datum("ready",      std_logic_type,                                                              Sem::sig_in_front) .in(),
            datum("done",       std_logic_type,                                                              Sem::sig_in_back)  .in(),
            datum("start",      std_logic_type,                                                              Sem::sig_out_front).out(),
            datum("ack",        std_logic_type,                                                              Sem::sig_out_back) .out(),
            datum("previous_a", std_logic_vector_type.with_range(width * (spec.first + spec.second) - 1, 0), Sem::main_input)   .in(),
            datum("next_a",     std_logic_vector_type.with_range(width * (spec.first + spec.second) - 1, 0), Sem::main_output)  .out(),
        }) {}
    virtual string demand_signal(Sem sem)
    {
        switch (sem){
        case Sem::main_input:
            return find_by(port, Sem::main_input).plugged_signal_name;
        case Sem::main_output:
            return find_by(port, Sem::main_output).plugged_signal_name;
        case Sem::sig_out_back:
            return find_by(port, Sem::sig_out_back).plugged_signal_name;
        case Sem::sig_out_front:
            return find_by(port, Sem::sig_out_front).plugged_signal_name;
        case Sem::sig_in_back:
            return find_by(port, Sem::sig_in_back).plugged_signal_name;
        case Sem::sig_in_front:
            return find_by(port, Sem::sig_in_front).plugged_signal_name;
        default:
            throw runtime_error("fc_layer_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
        }
    };
};

struct fc_layer_component : public component
{
    fc_layer_component(unsigned int output_width, pair<int, int> output_spec, const vector<double>& weights, pair<int, int> weight_spec, unsigned int simd_width)
        : component("fc_layer", "fc_layer_u" + to_string(global_counter()),
        {
            datum("input_width",      integer_type,    Sem::input_width),
            datum("output_width",     integer_type,    Sem::output_width, { double(output_width) }),
            datum("simd_width",       integer_type,    Sem::param,        { double(simd_width) }),
            datum("input_spec",       fixed_spec_type, Sem::input_spec),
            datum("weight_spec",      fixed_spec_type, Sem::data_spec,    { double(weight_spec.first), double(weight_spec.second) }),
            datum("op_arg_spec",      fixed_spec_type, Sem::param),
            datum("output_spec",      fixed_spec_type, Sem::output_spec,  { double(output_spec.first), double(output_spec.second) }),
            datum("n_weights",        integer_type,    Sem::param,        { double(weights.size()) }),
            datum("weights_filename", string_type,    Sem::file,         "\"whatever\""),
            datum("weight_values",    reals_type,      Sem::output_width, weights),
        },{
            datum("clk",         std_logic_type,                                                                                   Sem::clock)         .in(),
            datum("rst",         std_logic_type,                                                                                   Sem::reset)         .in(),
            datum("ready",       std_logic_type,                                                                                   Sem::sig_out_back)  .out(),
            datum("done",        std_logic_type,                                                                                   Sem::sig_out_front) .out(),
            datum("start",       std_logic_type,                                                                                   Sem::sig_in_back)   .in(),
            datum("ack",         std_logic_type,                                                                                   Sem::sig_in_front)  .in(),
            datum("in_a",        std_logic_vector_type,                                                                            Sem::main_input)    .in(),
            datum("out_a",       std_logic_vector_type.with_range(output_width * (output_spec.first + output_spec.second) - 1, 0), Sem::main_output)   .out(),
            datum("out_offset",  unsigned_type.with_range(bits_needed(output_width) - 1, 0),                                       Sem::offset_outtake).out(),
            datum("op_argument", sfixed_type,                                                                                      Sem::side_output)   .out(),
            datum("op_result",   sfixed_type.with_range(output_spec.first - 1, -output_spec.second),                               Sem::side_input)    .in(),
            datum("op_send",     std_logic_type,                                                                                   Sem::sig_out_side)  .out(),
            datum("op_receive",  std_logic_type,                                                                                   Sem::sig_in_side)   .in(),
        }) {}
    virtual void propagate(component& prev)
    {
        auto prevspec = find_by(prev.generic, Sem::output_spec).value.num;
        size_t prevwidth = find_by(prev.generic, Sem::output_width).value[0];
        find_by(generic, Sem::input_spec).value = prevspec;
        find_by(generic, Sem::input_width).value.num = { double(prevwidth) };
        datum& op_arg_spec = find_by(generic, Sem::param, "op_arg_spec");
        datum& weight_spec = find_by(generic, Sem::data_spec);
        datum& simd_width = find_by(generic, Sem::param, "simd_width");
        size_t mul_int_part = prevspec[0] + weight_spec.value[0] + 1,
               n_accumulated = prevwidth / size_t(simd_width.value[0]);
        double mulacc_int_part = ceil(log2(n_accumulated * pow(2.0, mul_int_part) + 1)),
               add_tree_contribution = ceil(log2(simd_width.value[0]));
        op_arg_spec.value = { mulacc_int_part + add_tree_contribution,//prevspec[0] + weight_spec.value[0] + prevwidth / size_t(simd_width.value[0]) + ,
                              prevspec[1] + weight_spec.value[1] };
        find_by(port, Sem::main_input).type.set_range(prevwidth * (prevspec[0] + prevspec[1]) - 1, 0);
        datum& side_output = find_by(port, Sem::side_output);
        side_output.type.set_range(op_arg_spec.value[0] - 1, -op_arg_spec.value[1]);
        prepended = make_unique<interlayer>(prevwidth, make_pair(int(prevspec[0]), int(prevspec[1])));
        if (subsystem){
            find_by(subsystem->start()->port, Sem::input_spec).value.num = op_arg_spec.value.num;
            subsystem->push_front(make_unique<component>("DUMMY", "DUMMY", vector<datum>{
                datum("output_spec", fixed_spec_type, Sem::output_spec, op_arg_spec.value.num),
            }, vector<datum>{
                datum("output", sfixed_type.with_range(side_output.type.range_high, side_output.type.range_low), Sem::main_output),
            }));
            subsystem->propagate();
            subsystem->pop_front();
        }
    }
    virtual string demand_signal(Sem sem)
    {
        switch (sem){
        case Sem::main_input:
            return prepended->demand_signal(Sem::main_input);
        case Sem::main_output:
            return find_by(port, Sem::main_output).plugged_signal_name;
        case Sem::sig_out_back:
            return prepended->demand_signal(Sem::sig_out_back);
        case Sem::sig_out_front:
            return find_by(port, Sem::sig_out_front).plugged_signal_name;
        case Sem::sig_in_back:
            return prepended->demand_signal(Sem::sig_in_back);
        case Sem::sig_in_front:
            return find_by(port, Sem::sig_in_front).plugged_signal_name;
        case Sem::side_input:
            return find_by(port, Sem::side_input).plugged_signal_name;
        case Sem::side_output:
            return find_by(port, Sem::side_output).plugged_signal_name;
        case Sem::offset_outtake:
            return find_by(port, Sem::offset_outtake).plugged_signal_name;
        case Sem::sig_in_side:
            return find_by(port, Sem::sig_in_side).plugged_signal_name;
        case Sem::sig_out_side:
            return find_by(port, Sem::sig_out_side).plugged_signal_name;
        default:
            throw runtime_error("fc_layer_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
        }
    };
    virtual string chain_internal()
    {
        stringstream ss;
        ss << find_by(port, Sem::main_input).plugged_signal_name << " <= " << prepended->demand_signal(Sem::main_output) << ";\n"
           << find_by(port, Sem::sig_in_back).plugged_signal_name << " <= " << prepended->demand_signal(Sem::sig_out_front) << ";\n"
           << prepended->demand_signal(Sem::sig_in_front) << " <= " << find_by(port, Sem::sig_out_back).plugged_signal_name << ";\n";
        if (subsystem){
            component* start = subsystem->start(), * last = subsystem->last();
            ss << start->demand_signal(Sem::main_input) << " <= " << demand_signal(Sem::side_output) << ";\n"
               << start->demand_signal(Sem::sig_in_back) << " <= " << demand_signal(Sem::sig_out_side) << ";\n"
               << demand_signal(Sem::sig_in_side) << " <= " << last->demand_signal(Sem::sig_out_front) << ";\n"
               << subsystem->chain_side();
            for (auto&& cur : subsystem->components)
                if (!find_by(cur->port, Sem::offset_intake).is_invalid())
                    ss << cur->demand_signal(Sem::offset_intake) << " <= " << demand_signal(Sem::offset_outtake) << ";\n";
            ss << demand_signal(Sem::side_input) << " <= resize(" << last->demand_signal(Sem::main_output) << ", mk(" << find_by(generic, Sem::output_spec).formatted_value() << "));\n";
        } else {
            ss << demand_signal(Sem::side_input) << " <= resize(" << demand_signal(Sem::side_output) << ", mk(" << find_by(generic, Sem::output_spec).formatted_value() << "));\n";
            ss << demand_signal(Sem::sig_in_side) << " <= " << demand_signal(Sem::sig_out_side) << ";\n";
        }
        return ss.str();
    };
};

auto fc_gen = define_component_generator("fc", +[](const unordered_map<string, specification_variant>& params)
{
    auto get = checked_get("component generator")("fc", params);
    unique_ptr<component> ret(new fc_layer_component(
        get("output_width"),
        int_pair(get("output_spec_int"), get("output_spec_frac")),
        get("weights"),
        pair<int, int>(get("weight_spec_int"), get("weight_spec_frac")),
        get("simd_width")
    ));
    const system_specification& side_path = get("side_path");
    if (!side_path.parts.empty()){
        ret->subsystem = make_unique<system>();
        for (const layer_specification& part : side_path.parts)
            ret->subsystem->push_back(component_from_specification(part));
    }
    return move(ret);
});

auto fc_ff = define_feedforward_behavior_generator("fc", +[](const unordered_map<string, specification_variant>& params) -> feedforward_behavior
{
    auto get = checked_get("feedforward behavior generator")("fc", params);
    size_t output_width = get("output_width");
    vector<double> weights = get("weights");
    const system_specification& side_path = get("side_path");
    vector<activation_behavior> activation;
    for (const layer_specification& part : side_path.parts)
        activation.push_back(activation_behavior_from_specification(part));
    return [output_width, input_width = size_t(weights.size() / output_width), weights = move(weights), activation = move(activation)](vector<double> input){
        vector<double> output(output_width, 0.0);
        for (size_t i = 0, ij = 0; i < output_width; ++i){
            for (size_t j = 0; j < input_width; ++j, ++ij)
                output[i] += weights[ij] * input[j];
            for (const activation_behavior& f : activation)
                output[i] = f(output[i], i);
        }
        return move(output);
    };
});

auto fc_av = define_validity_assertion_generator("fc", +[](const unordered_map<string, specification_variant>& params) -> validity_assertion
{
    auto get = checked_get("validity assertion generator")("fc", params);
    size_t output_width = get("output_width");
    const vector<double>& weights = get("weights");
    const system_specification& side_path = get("side_path");
    vector<validity_assertion> side_val_asserts;
    for (const layer_specification& part : side_path.parts)
        side_val_asserts.push_back(validity_assertion_from_specification(part));
    return [output_width, weights_size = weights.size(), side_val_asserts = move(side_val_asserts)](size_t prev_width){
        if (weights_size != output_width * prev_width)
            throw runtime_error("fc layer has " + to_string(prev_width) + " inputs and " + to_string(output_width) + " outputs, and should therefore have " +
                                to_string(prev_width * output_width) + " weights. However, the actual number of weights given is " + to_string(weights_size) + ".");
        for (auto&& sva : side_val_asserts)
            sva(output_width);
        return output_width;
    };
});

layer_specification fc(Output o, Weights w, Simd s, system_specification side_path)
{
    return layer_specification{
        "fc", {
            dyn_param("output_width", o.output_width),
            dyn_param("output_spec_int", o.output_spec.first),
            dyn_param("output_spec_frac", o.output_spec.second),
            dyn_param("weights", move(w.w)),
            dyn_param("weight_spec_int", w.w_spec.first),
            dyn_param("weight_spec_frac", w.w_spec.second),
            dyn_param("simd_width", s.simd_width),
            dyn_param("side_path", move(side_path)),
        }
    };
}

auto fc_parse = define_layer_spec_parser("fc", +[](const sexpr_field& s, const string& pos_info)
{
    if (s.size() != 5)
        throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Clause expects 4 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "fc", {} };
    unordered_map<string, const sexpr_field*> fields;
    for (const string& name : { "output", "weights", "simd", "neuron" }){
        auto it = find_if(s.sexpr().fields.begin() + 1, s.sexpr().fields.end(),
                          [&](const sexpr_field& sf){ return sf.is_tree() && !sf.empty() && sf[0].is_leaf() && sf[0].string() == name; });
        if (it == s.sexpr().fields.end())
            throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Couldn't find \"" + name + "\" field.");
        fields.emplace(name, &(*it));
    }
    const sexpr_field& outputf = *fields["output"];
    if (outputf.size() != 3)
        throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Output field takes 2 arguments, not " + to_string(outputf.size() - 1) + ".");
    layer.parameters.emplace("output_width", parse_positive_integer(outputf[1], pos_info + ", first argument of output clause"));
    pair<int, int> outspec = parse_fixed_pair(outputf[2], pos_info + ", second argument of output clause");
    layer.parameters.emplace("output_spec_int", outspec.first);
    layer.parameters.emplace("output_spec_frac", outspec.second);
    const sexpr_field& weightsf = *fields["weights"];
    if (weightsf.size() != 3)
        throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Weights field takes 2 arguments, not " + to_string(weightsf.size() - 1) + ".");
    layer.parameters.emplace("weights", parse_data(weightsf[1], pos_info + ", first argument of weights clause"));
    pair<int, int> wspec = parse_fixed_pair(weightsf[2], pos_info + ", second argument of weights clause");
    layer.parameters.emplace("weight_spec_int", wspec.first);
    layer.parameters.emplace("weight_spec_frac", wspec.second);
    const sexpr_field& simdf = *fields["simd"];
    if (simdf.size() != 2)
        throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Simd field takes 1 argument, not " + to_string(simdf.size() - 1) + ".");
    layer.parameters.emplace("simd_width", parse_positive_integer(simdf[1], pos_info + ", first argument of simd clause"));
    const sexpr_field& neuronf = *fields["neuron"];
    system_specification side_path;
    for (size_t i = 1; i < neuronf.sexpr().fields.size(); ++i){
        if (neuronf.sexpr().fields[i].is_leaf() || neuronf.sexpr().fields[i].empty() || neuronf.sexpr().fields[i][0].is_tree())
            throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Neuron op field " + to_string(i) + " is invalid.");
        string pos_info_sub = pos_info + ", neuron op " + to_string(i);
        side_path.parts.push_back(layer_spec_parser_from_name(neuronf.sexpr().fields[i][0].string(), pos_info_sub)(neuronf.sexpr().fields[i], pos_info_sub));
    }
    layer.parameters.emplace("side_path", move(side_path));
    return move(layer);
});

} //namespace gen