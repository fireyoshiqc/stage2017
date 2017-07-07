#pragma once

#include "interlayer.h"

namespace gen
{
using namespace std;

struct fcbin_to_fcbin_interlayer : public interlayer
{
    fcbin_to_fcbin_interlayer(unsigned int width)
        : interlayer("fcbin_to_fcbin_interlayer", "fcbin_to_fcbin_interlayer_u" + to_string(global_counter()),
        {
            datum("width",     integer_type, Sem::input_width, { double(width) }),
        }, {
            datum("clk",        std_logic_type,                                 Sem::clock)        .in(),
            datum("ready",      std_logic_type,                                 Sem::sig_in_front) .in(),
            datum("done",       std_logic_type,                                 Sem::sig_in_back)  .in(),
            datum("start",      std_logic_type,                                 Sem::sig_out_front).out(),
            datum("ack",        std_logic_type,                                 Sem::sig_out_back) .out(),
            datum("previous_a", std_logic_vector_type.with_range(width - 1, 0), Sem::main_input)   .in(),
            datum("next_a",     std_logic_vector_type.with_range(width - 1, 0), Sem::main_output)  .out(),
        }) {}
    virtual string demand_signal(Sem sem) { return demand_signal_basic(sem); }
};

} //namespace gen
