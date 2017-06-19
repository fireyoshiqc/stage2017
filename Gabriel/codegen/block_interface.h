#pragma once

#include <sstream>

#include "interface.h"

namespace gen
{
using namespace std;

struct block_interface : public system_interface
{
    block_interface() {}
    virtual string entity(system& s)
    {
        stringstream ss;
        ss <<
R"(    clk : in std_logic;
    rst : in std_logic;
    start : in std_logic;
    ready : out std_logic;
    ack : in std_logic;
    done : out std_logic;
    in_a : in )" << find_by(s.start()->port, Sem::main_input).type.full_name() << R"(;
    out_a : out )" << find_by(s.last()->port, Sem::main_output).type.full_name();
        return ss.str();
    }
    virtual string architecture_preface(system& s) { return ""; }
    virtual string architecture_body(system& s)
    {
        stringstream ss;
        ss << s.start()->demand_signal(Sem::sig_in_back) << " <= start;\n"
           << "ready <= " << s.start()->demand_signal(Sem::sig_out_back) << ";\n"
           << s.last()->demand_signal(Sem::sig_in_front) << " <= ack;\n"
           << "done <= " << s.last()->demand_signal(Sem::sig_out_front) << ";\n"
           << s.start()->demand_signal(Sem::main_input) << " <= in_a;\n"
           << "out_a <= " << s.last()->demand_signal(Sem::main_output) << ";";
        return ss.str();
    }
};
auto block_int_gen = define_interface_generator("block", +[](const sexpr& s)
{
    return unique_ptr<system_interface>(new block_interface());
});

} //namespace gen
