#pragma once

#include "interlayer.h"

namespace gen
{
using namespace std;

struct fcbin_to_fc_interlayer : public interlayer
{
    fcbin_to_fc_interlayer(unsigned int width, pair<int, int> spec)
        : interlayer("fcbin_to_fc_interlayer", "fcbin_to_fc_interlayer_u" + to_string(global_counter()),
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
            datum("previous_a", std_logic_vector_type.with_range(width - 1, 0),                              Sem::main_input)   .in(),
            datum("next_a",     std_logic_vector_type.with_range(width * (spec.first + spec.second) - 1, 0), Sem::main_output)  .out(),
        }) {}
    virtual string demand_signal(Sem sem) { return demand_signal_basic(sem); }
};

} //namespace gen
