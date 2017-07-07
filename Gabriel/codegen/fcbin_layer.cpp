#include "fcbin_layer.h"

namespace gen
{
using namespace std;
using namespace util;

fcbin_layer_component::fcbin_layer_component(unsigned int output_width, const vector<double>& weights, unsigned int simd_width, const vector<double>& biases)
    : layer_component(typeid(fcbin_layer_component), "fcbin_layer", "fcbin_layer_u" + to_string(global_counter()),
    {
        datum("n_inputs",   integer_type,  Sem::input_width),
        datum("n_outputs",  integer_type,  Sem::output_width, { double(output_width) }),
        datum("simd_width", integer_type,  Sem::param,        { double(simd_width) }),
        datum("weights",    integers_type, Sem::data, weights),
        datum("biases",     integers_type, Sem::data, biases),
    },{
        datum("clk",         std_logic_type,                                        Sem::clock)         .in(),
        datum("ready",       std_logic_type,                                        Sem::sig_out_back)  .out(),
        datum("done",        std_logic_type,                                        Sem::sig_out_front) .out(),
        datum("start",       std_logic_type,                                        Sem::sig_in_back)   .in(),
        datum("ack",         std_logic_type,                                        Sem::sig_in_front)  .in(),
        datum("in_a",        std_logic_vector_type,                                 Sem::main_input)    .in(),
        datum("out_a",       std_logic_vector_type.with_range(output_width - 1, 0), Sem::main_output)   .out(),
    }) {}
void fcbin_layer_component::propagate(component& prev)
{
    size_t prevwidth = find_by(prev.generic, Sem::output_width).value[0];
    find_by(generic, Sem::input_width).value.num = { double(prevwidth) };
    find_by(port, Sem::main_input).type.set_range(prevwidth - 1, 0);
    prepended = interlayer_between(static_cast<layer_component*>(&prev), this);
}
string fcbin_layer_component::demand_signal(Sem sem)
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
    default:
        throw runtime_error("fcbin_layer_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
    }
};
string fcbin_layer_component::chain_internal()
{
    stringstream ss;
    ss << find_by(port, Sem::main_input).plugged_signal_name << " <= " << prepended->demand_signal(Sem::main_output) << ";\n"
       << find_by(port, Sem::sig_in_back).plugged_signal_name << " <= " << prepended->demand_signal(Sem::sig_out_front) << ";\n"
       << prepended->demand_signal(Sem::sig_in_front) << " <= " << find_by(port, Sem::sig_out_back).plugged_signal_name << ";\n";
    return ss.str();
};


auto fcbin_gen = define_component_generator("fcbin", +[](const unordered_map<string, specification_variant>& params)
{
    auto get = checked_get("component generator")("fcbin", params);
    unique_ptr<component> ret(new fcbin_layer_component(
        get("output_width"),
        get("weights"),
        get("simd_width"),
        get("biases")
    ));
    return move(ret);
});

auto fcbin_ff = define_feedforward_behavior_generator("fcbin", +[](const unordered_map<string, specification_variant>& params) -> feedforward_behavior
{
    auto get = checked_get("feedforward behavior generator")("fcbin", params);
    size_t output_width = get("output_width");
    vector<double> weights = get("weights"), biases = get("biases");
    return [output_width, input_width = size_t(weights.size() / output_width), weights = move(weights), biases = move(biases)](vector<double> input){
        vector<double> output(output_width, 0.0);
        for (size_t i = 0, ij = 0; i < output_width; ++i){
            for (size_t j = 0; j < input_width; ++j, ++ij)
                output[i] += weights[ij] == (input[j] >= 0.5);
            output[i] = (output[i] + (biases.empty() ? 0 : biases[i])) >= input.size() / 2;
        }
        return move(output);
    };
});

auto fcbin_av = define_validity_assertion_generator("fcbin", +[](const unordered_map<string, specification_variant>& params) -> validity_assertion
{
    auto get = checked_get("validity assertion generator")("fcbin", params);
    size_t output_width = get("output_width");
    const vector<double>& weights = get("weights"), & biases = get("biases");
    return [output_width, weights_size = weights.size(), biases_size = biases.size()](size_t prev_width){
        if (weights_size != output_width * prev_width)
            throw runtime_error("fcbin layer has " + to_string(prev_width) + " inputs and " + to_string(output_width) + " outputs, and should therefore have " +
                                to_string(prev_width * output_width) + " weights. However, the actual number of weights given is " + to_string(weights_size) + ".");
        if (biases_size != 0 && biases_size != output_width)
            throw runtime_error("fcbin layer has " + to_string(output_width) + " outputs, and should therefore have " +
                                to_string(output_width) + " or 0 biases. However, the actual number of biases given is " + to_string(biases_size) + ".");
        return output_width;
    };
});

layer_specification fcbin(BinOutput o, BinWeights w, Simd s, Biases b)
{
    vector<double> w_double; w_double.reserve(w.w.size());
    for (bool b : w.w)
        w_double.push_back(b);
    vector<double> b_double; b_double.reserve(b.b.size());
    for (int i : b.b)
        b_double.push_back(i);
    return layer_specification{
        "fcbin", {
            dyn_param("output_width", o.output_width),
            dyn_param("weights", move(w_double)),
            dyn_param("simd_width", s.simd_width),
            dyn_param("biases", move(b_double)),
        }
    };
}

auto fcbin_parse = define_layer_spec_parser("fcbin", +[](const sexpr_field& s, const string& pos_info)
{
    if (s.size() != 4 && s.size() != 5)
        throw runtime_error("layer_spec_parser for fcbin: At " + pos_info + ": Clause expects 3 or 4 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "fcbin", {} };
    unordered_map<string, const sexpr_field*> fields;
    for (const string& name : { "output", "weights", "simd", "biases" }){
        auto it = find_if(s.sexpr().fields.begin() + 1, s.sexpr().fields.end(),
                          [&](const sexpr_field& sf){ return sf.is_tree() && !sf.empty() && sf[0].is_leaf() && sf[0].string() == name; });
        if (it != s.sexpr().fields.end())
            fields.emplace(name, &(*it));
        else if (name != "biases")
            throw runtime_error("layer_spec_parser for fcbin: At " + pos_info + ": Couldn't find \"" + name + "\" field.");
    }

    const sexpr_field& outputf = *fields["output"];
    if (outputf.size() != 2)
        throw runtime_error("layer_spec_parser for fcbin: At " + pos_info + ": Output field takes 1 argument, not " + to_string(outputf.size() - 1) + ".");
    layer.parameters.emplace("output_width", parse_positive_integer(outputf[1], pos_info + ", first argument of output clause"));

    const sexpr_field& weightsf = *fields["weights"];
    if (weightsf.size() != 2)
        throw runtime_error("layer_spec_parser for fcbin: At " + pos_info + ": Weights field takes 1 argument, not " + to_string(weightsf.size() - 1) + ".");
    layer.parameters.emplace("weights", parse_data(weightsf[1], pos_info + ", first argument of weights clause"));

    const sexpr_field& simdf = *fields["simd"];
    if (simdf.size() != 2)
        throw runtime_error("layer_spec_parser for fcbin: At " + pos_info + ": Simd field takes 1 argument, not " + to_string(simdf.size() - 1) + ".");
    layer.parameters.emplace("simd_width", parse_positive_integer(simdf[1], pos_info + ", first argument of simd clause"));

    auto it = fields.find("biases");
    if (it != fields.end()){
        const sexpr_field& biasesf = *(it->second);
        if (biasesf.size() != 2)
            throw runtime_error("layer_spec_parser for fcbin: At " + pos_info + ": Biases field takes 1 argument, not " + to_string(biasesf.size() - 1) + ".");
        layer.parameters.emplace("biases", parse_data(biasesf[1], pos_info + ", first argument of biases clause"));
    } else
        layer.parameters.emplace("biases", vector<double>());

    return move(layer);
});

} //namespace gen
