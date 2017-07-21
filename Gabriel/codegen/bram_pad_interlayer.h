#pragma once

#include "interlayer.h"

namespace gen
{
using namespace std;

struct bram_pad_interlayer : public interlayer
{
    bram_pad_interlayer(size_t n_channels, size_t channel_width, size_t zero_padding, size_t layer_size)
        : interlayer("bram_pad_interlayer", "bram_pad_interlayer_u" + to_string(global_counter()),
        {
            datum("init_file",     string_type,  Sem::file,  ""s),
            datum("channels",      integer_type, Sem::param, { double(n_channels) }),
            datum("channel_width", integer_type, Sem::param, { double(channel_width) }),
            datum("zero_padding",  integer_type, Sem::param, { double(zero_padding) }),
            datum("layer_size",    integer_type, Sem::param, { double(layer_size) }),
        }, {
            datum("clk",     std_logic_type,                                                                                            Sem::clock)                  .in(),
            datum("ready",   std_logic_type,                                                                                            Sem::sig_in_front)           .in(),
            datum("done",    std_logic_type,                                                                                            Sem::sig_in_back)            .in(),
            datum("start",   std_logic_type,                                                                                            Sem::sig_out_front)          .out(),
            datum("din",     std_logic_vector_type.with_range(n_channels * channel_width - 1, 0),                                       Sem::main_input)             .in(),
            datum("dout",    std_logic_vector_type.with_range(n_channels * channel_width - 1, 0),                                       Sem::main_output)            .out(),
            datum("wr_addr", std_logic_vector_type.with_range(clogb2(pow(layer_size, 2)) - 1, 0),                                       Sem::back_offset_intake)     .in(),
            datum("rd_addr", std_logic_vector_type.with_range(clogb2(round_to_next_two(pow(layer_size + 2 * zero_padding, 2))) - 1, 0), Sem::front_offset_intake)    .in(),
            datum("row",     std_logic_vector_type.with_range(clogb2(round_to_next_two(layer_size)) - 1, 0),                            Sem::special_input_conv_row) .in(),
            datum("wren",    std_logic_vector_type.with_range(n_channels - 1, 0),                                                       Sem::special_input_conv_wren).in(),
        }) {}
    virtual string demand_signal(Sem sem)
    {
        switch (sem){
        case Sem::back_offset_intake:
            return find_by(port, Sem::back_offset_intake).plugged_signal_name;
        case Sem::front_offset_intake:
            return find_by(port, Sem::front_offset_intake).plugged_signal_name;
        case Sem::special_input_conv_row:
            return find_by(port, Sem::special_input_conv_row).plugged_signal_name;
        case Sem::special_input_conv_wren:
            return find_by(port, Sem::special_input_conv_wren).plugged_signal_name;
        case Sem::sig_out_back:
            throw runtime_error("bram_pad_interlayer doesn't have a sig_out_back (ack).");
        default:
            return demand_signal_basic(sem);
        }
    }
};

} //namespace gen
