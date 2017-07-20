#include "pool_layer.h"

namespace gen
{
using namespace std;
using namespace util;

pool_layer_component::pool_layer_component(size_t pool_size, size_t stride, const string& padding_previous)
    : conv2d_family_layer_component("maxpool_layer_mc", "maxpool_layer_mc_u" + to_string(global_counter()),
    {
        datum("pool_size",        integer_type, Sem::param,            { double(pool_size) }),
        datum("stride",           integer_type, Sem::param,            { double(stride) }),
        datum("input_size",       integer_type, Sem::input_width),     //size of image side (+ 2 (padding))
        datum("channels",         integer_type, Sem::input_width),     //number of input channels?

        datum("output_size",      integer_type, Sem::output_width)                            .hide(),
        datum("filter_size",      integer_type, Sem::param,             { double(pool_size) }).hide(),
//        datum("output_int_part",  integer_type, Sem::output_spec_int)                         .hide(),
//        datum("output_frac_part", integer_type, Sem::output_spec_frac)                        .hide(),
    },{
        datum("clk",       std_logic_type,        Sem::clock)                   .in(),
        datum("ready",     std_logic_type,        Sem::sig_out_back)            .out(),
        datum("done",      std_logic_type,        Sem::sig_out_front)           .out(),
        datum("start",     std_logic_type,        Sem::sig_in_back)             .in(),
        datum("ack",       std_logic_type,        Sem::sig_in_front)            .in(),
        datum("load_done", std_logic_type,        Sem::sig_out_back)            .out(), //2 sig_out_back signals
        datum("din",       std_logic_vector_type, Sem::main_input)              .in(),
        datum("dout",      std_logic_vector_type, Sem::main_output)             .out(),
        datum("addr",      std_logic_vector_type, Sem::back_offset_outtake)     .out(),
        datum("out_addr",  std_logic_vector_type, Sem::front_offset_outtake)    .out(),
        datum("row",       std_logic_vector_type, Sem::special_output_conv_row) .out(),
        datum("wren",      std_logic_vector_type, Sem::special_output_conv_wren).out(),
    }, padding_previous) {}

auto pool_gen = define_component_generator("pool", +[](const unordered_map<string, specification_variant>& params)
{
    auto get = checked_get("component generator")("pool", params);
    unique_ptr<component> ret(new pool_layer_component(
        get("pool_size"),
        get("stride"),
        get("padding_previous")
    ));
    return move(ret);
});

auto pool_parse = define_layer_spec_parser("pool", +[](const sexpr_field& s, const string& pos_info)
{
    if (s.size() != 4)
        throw runtime_error("layer_spec_parser for pool: At " + pos_info + ": Clause expects 3 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "pool", {} };
    unordered_map<string, const sexpr_field*> fields;
    for (const string& name : { "max", "stride", "padding" }){
        auto it = find_if(s.sexpr().fields.begin() + 1, s.sexpr().fields.end(),
                          [&](const sexpr_field& sf){ return sf.is_tree() && !sf.empty() && sf[0].is_leaf() && sf[0].string() == name; });
        if (it == s.sexpr().fields.end())
            throw runtime_error("layer_spec_parser for pool: At " + pos_info + ": Couldn't find \"" + name + "\" field.");
        fields.emplace(name, &(*it));
    }

    const auto one_arg = [&](auto&& parser, const string& name, const string& param_name){
        const sexpr_field& f = *fields[name];
        if (f.size() != 2)
            throw runtime_error("layer_spec_parser for conv2d: At " + pos_info + ": " + char(toupper(name[0])) + name.substr(1) + " field takes 1 argument, not " + to_string(f.size() - 1) + ".");
        layer.parameters.emplace(param_name, parser(f[1], pos_info + ", first argument of " + name + " clause"));
    };
    one_arg(parse_positive_integer, "max", "pool_size");
    one_arg(parse_positive_integer, "stride", "stride");
    one_arg(parse_string, "padding", "padding_previous");

    return move(layer);
});

} //namespace gen
