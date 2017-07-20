#include "conv2d_layer.h"

namespace gen
{
using namespace std;
using namespace util;

conv2d_layer_component::conv2d_layer_component(size_t n_filters_output, pair<int, int> output_spec, const vector<double>& weights, pair<int, int> weight_spec, size_t simd_width_dsp_alloc, const string& padding_previous, size_t stride, size_t kernel_side, const vector<double>& biases, pair<int, int> bias_spec)
    : conv2d_family_layer_component("conv_layer_mc", "conv_layer_mc_u" + to_string(global_counter()),
    {
        datum("stride",           integer_type, Sem::param,            { double(stride) }),
        datum("filter_size",      integer_type, Sem::param,            { double(kernel_side) }),
        datum("filter_nb",        integer_type, Sem::param,            { double(n_filters_output) }),
        datum("input_size",       integer_type, Sem::input_width),     //size of image side (+ 2 (padding))
        datum("channels",         integer_type, Sem::input_width),     //number of input channels?
        datum("dsp_alloc",        integer_type, Sem::param,            { double(simd_width_dsp_alloc) }),
        datum("weights",          reals_type,   Sem::data,             weights),
        datum("biases",           reals_type,   Sem::data,             biases),
        datum("input_int_part",   integer_type, Sem::input_spec_int),
        datum("input_frac_part",  integer_type, Sem::input_spec_frac),
        datum("weight_int_part",  integer_type, Sem::data_spec,        { double(weight_spec.first) }),
        datum("weight_frac_part", integer_type, Sem::data_spec,        { double(weight_spec.second) }),
        datum("bias_int_part",    integer_type, Sem::data_spec,        { double(bias_spec.first) }),
        datum("bias_frac_part",   integer_type, Sem::data_spec,        { double(bias_spec.second) }),
        datum("out_int_part",     integer_type, Sem::output_spec_int,  { double(output_spec.first) }),
        datum("out_frac_part",    integer_type, Sem::output_spec_frac, { double(output_spec.second) }),

        datum("output_size",      integer_type, Sem::output_width).hide(),
    },{
        datum("clk",       std_logic_type,                                                                                       Sem::clock)                   .in(),
        datum("ready",     std_logic_type,                                                                                       Sem::sig_out_back)            .out(),
        datum("done",      std_logic_type,                                                                                       Sem::sig_out_front)           .out(),
        datum("start",     std_logic_type,                                                                                       Sem::sig_in_back)             .in(),
        datum("ack",       std_logic_type,                                                                                       Sem::sig_in_front)            .in(),
        datum("load_done", std_logic_type,                                                                                       Sem::sig_out_back)            .out(), //2 sig_out_back signals
        datum("din",       std_logic_vector_type,                                                                                Sem::main_input)              .in(),
        datum("dout",      std_logic_vector_type.with_range(n_filters_output * (output_spec.first + output_spec.second) - 1, 0), Sem::main_output)             .out(),
        datum("addr",      std_logic_vector_type,                                                                                Sem::back_offset_outtake)     .out(),
        datum("out_addr",  std_logic_vector_type,                                                                                Sem::front_offset_outtake)    .out(),
        datum("row",       std_logic_vector_type,                                                                                Sem::special_output_conv_row) .out(),
        datum("wren",      std_logic_vector_type.with_range(n_filters_output - 1, 0),                                            Sem::special_output_conv_wren).out(),
    }, padding_previous) {}

auto conv2d_gen = define_component_generator("conv2d", +[](const unordered_map<string, specification_variant>& params)
{
    auto get = checked_get("component generator")("conv2d", params);
    unique_ptr<component> ret(new conv2d_layer_component(
        get("n_filters_output"),
        int_pair(get("output_spec_int"), get("output_spec_frac")),
        get("weights"),
        pair<int, int>(get("weight_spec_int"), get("weight_spec_frac")),
        get("simd_width_dsp_alloc"),
        get("padding_previous"),
        get("stride"),
        get("kernel_side"),
        get("biases"),
        pair<int, int>(get("bias_spec_int"), get("bias_spec_frac"))
    ));
    return move(ret);
});

auto conv2d_parse = define_layer_spec_parser("conv2d", +[](const sexpr_field& s, const string& pos_info)
{
    if (s.size() != 8)
        throw runtime_error("layer_spec_parser for conv2d: At " + pos_info + ": Clause expects 7 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "conv2d", {} };
    unordered_map<string, const sexpr_field*> fields;
    for (const string& name : { "output", "weights", "simd", "padding", "stride", "kernel", "neuron" }){
        auto it = find_if(s.sexpr().fields.begin() + 1, s.sexpr().fields.end(),
                          [&](const sexpr_field& sf){ return sf.is_tree() && !sf.empty() && sf[0].is_leaf() && sf[0].string() == name; });
        if (it == s.sexpr().fields.end())
            throw runtime_error("layer_spec_parser for conv2d: At " + pos_info + ": Couldn't find \"" + name + "\" field.");
        fields.emplace(name, &(*it));
    }

    const sexpr_field& outputf = *fields["output"];
    if (outputf.size() != 3)
        throw runtime_error("layer_spec_parser for conv2d: At " + pos_info + ": Output field takes 2 arguments, not " + to_string(outputf.size() - 1) + ".");
    layer.parameters.emplace("n_filters_output", parse_positive_integer(outputf[1], pos_info + ", first argument of output clause"));
    pair<int, int> outspec = parse_fixed_pair(outputf[2], pos_info + ", second argument of output clause");
    layer.parameters.emplace("output_spec_int", outspec.first);
    layer.parameters.emplace("output_spec_frac", outspec.second);

    const sexpr_field& weightsf = *fields["weights"];
    if (weightsf.size() != 3)
        throw runtime_error("layer_spec_parser for conv2d: At " + pos_info + ": Weights field takes 2 arguments, not " + to_string(weightsf.size() - 1) + ".");
    vector<double> w_data = parse_data(weightsf[1], pos_info + ", first argument of weights clause");
    pair<int, int> wspec = parse_fixed_pair(weightsf[2], pos_info + ", second argument of output clause");
    layer.parameters.emplace("weight_spec_int", wspec.first);
    layer.parameters.emplace("weight_spec_frac", wspec.second);
    layer.parameters.emplace("weights", w_data);

    const auto one_arg = [&](auto&& parser, const string& name, const string& param_name){
        const sexpr_field& f = *fields[name];
        if (f.size() != 2)
            throw runtime_error("layer_spec_parser for conv2d: At " + pos_info + ": " + char(toupper(name[0])) + name.substr(1) + " field takes 1 argument, not " + to_string(f.size() - 1) + ".");
        layer.parameters.emplace(param_name, parser(f[1], pos_info + ", first argument of " + name + " clause"));
    };
    one_arg(parse_positive_integer, "simd", "simd_width_dsp_alloc");
    one_arg(parse_string, "padding", "padding_previous");
    one_arg(parse_positive_integer, "stride", "stride");
    one_arg(parse_positive_integer, "kernel", "kernel_side");

    const sexpr_field& neuronf = *fields["neuron"];
    if (!(neuronf.size() == 3 && neuronf[1].is_tree() && neuronf[1].size() == 3 && neuronf[1][0].is_leaf() && neuronf[1][0].string() == "bias" &&
                                 neuronf[2].is_tree() && neuronf[2].size() == 1 && neuronf[2][0].is_leaf() && neuronf[2][0].string() == "relu"))
        throw runtime_error("layer_spec_parser for conv2d: At " + pos_info + ": Incorrect format for neuron field (expecting form (neuron (bias *data* *fixed*) (relu))).");
    vector<double> b_data = parse_data(neuronf[1][1], pos_info + ", first argument of bias clause");
    pair<int, int> bspec = parse_fixed_pair(neuronf[1][2], pos_info + ", second argument of bias clause");
    layer.parameters.emplace("bias_spec_int", bspec.first);
    layer.parameters.emplace("bias_spec_frac", bspec.second);
    layer.parameters.emplace("biases", b_data);

    return move(layer);
});

} //namespace gen
