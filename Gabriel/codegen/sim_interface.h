#pragma once

#include <sstream>
#include <iomanip>
#include <vector>

#include "interface.h"

namespace gen
{
using namespace std;

struct sim_interface : public system_interface
{
    sim_interface(const vector<double>& test_input)
        : test_input(test_input) {}
    virtual string entity(system& s)
    {
        stringstream ss;
        ss <<
R"(    clk : in std_logic;
    rst : in std_logic;
    start : in std_logic;
    out_a : out )" << find_by(s.last()->port, Sem::main_output).type.full_name();
        return ss.str();
    }
    virtual string architecture_preface(system& s)
    {
        return to_vec_function_def(s);
    }
    virtual string architecture_body(system& s)
    {
        stringstream ss;
        ss << s.start()->demand_signal(Sem::main_input) << " <= to_vec(reals'(";
        for (size_t i = 0, sz = test_input.size(); i < sz; ++i)
            ss << fixed << setprecision(7) << test_input[i] << (i < sz - 1 ? ", " : "");
        ss << "));\n"
           << s.start()->demand_signal(Sem::sig_in_back) << " <= start;\n"
              "out_a <= " << s.last()->demand_signal(Sem::main_output) << ";";
        return ss.str();
    }
    vector<double> test_input;
};
auto sim_int_gen = define_interface_generator("sim", +[](const sexpr& s)
{
    if (s.size() < 3)
        throw runtime_error("sim interface generator: Third argument missing.");
    return unique_ptr<system_interface>(new sim_interface(parse_data(s[2], "sim interface generator")));
});

} //namespace gen
