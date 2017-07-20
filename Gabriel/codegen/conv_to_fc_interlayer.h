#pragma once

#include "interlayer.h"
#include "util.h"

namespace gen
{
using namespace std;
using namespace util;

struct conv_to_fc_interlayer : public interlayer
{
    conv_to_fc_interlayer(size_t n_channels, size_t channel_width, bool signbit, size_t layer_size, size_t fc_simd)
        : interlayer("conv_to_fc_interlayer", "conv_to_fc_interlayer_u" + to_string(global_counter()),
        {
            datum("channels",      integer_type, Sem::param, { double(n_channels) }),
            datum("channel_width", integer_type, Sem::param, { double(channel_width) }),
            datum("layer_size",    integer_type, Sem::param, { double(layer_size) }),
            datum("fc_simd",       integer_type, Sem::param, { double(fc_simd) }),
        }, {
            datum("clk",     std_logic_type,                                                                                            Sem::clock)                  .in(),
            datum("ready",   std_logic_type,                                                                                            Sem::sig_in_front)           .in(),
            datum("done",    std_logic_type,                                                                                            Sem::sig_in_back)            .in(),
            datum("start",   std_logic_type,                                                                                            Sem::sig_out_front)          .out(),
            datum("ack",     std_logic_type,                                                                                            Sem::sig_out_back)           .out(),
            datum("din",     std_logic_vector_type.with_range(n_channels * channel_width - 1, 0),                                       Sem::main_input)             .in(),
            datum("dout",    std_logic_vector_type.with_range(lcm(n_channels, fc_simd) * (int(signbit) + channel_width) - 1, 0),        Sem::main_output)            .out(),
            datum("wr_addr", std_logic_vector_type.with_range(clogb2(round_to_next_two(pow(layer_size, 2))) - 1, 0),                    Sem::back_offset_intake)     .in(),
            datum("rd_addr", std_logic_vector_type.with_range(clogb2(round_to_next_two(lcm(n_channels, fc_simd) / n_channels)) - 1, 0), Sem::front_offset_intake)    .in(),
            datum("wren_in", std_logic_vector_type.with_range(n_channels - 1, 0),                                                       Sem::special_input_conv_wren).in(),
        }) {}
    virtual string demand_signal(Sem sem)
    {
        switch (sem){
        case Sem::back_offset_intake:
            return find_by(port, Sem::back_offset_intake).plugged_signal_name;
        case Sem::front_offset_intake:
            return find_by(port, Sem::front_offset_intake).plugged_signal_name;
        case Sem::special_input_conv_row:
            throw runtime_error("conv_to_fc_interlayer doesn't have a special_input_conv_row.");
        case Sem::special_input_conv_wren:
            return find_by(port, Sem::special_input_conv_wren).plugged_signal_name;
        //case Sem::sig_out_back:
        //    throw runtime_error("conv_to_fc_interlayer doesn't have a sig_out_back (ack).");
        default:
            return demand_signal_basic(sem);
        }
    }
};

} //namespace gen

