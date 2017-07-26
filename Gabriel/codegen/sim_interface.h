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
        : test_input(test_input), is_data(true) {}
    sim_interface(const string& test_file)
        : test_file(test_file), is_data(false) {}
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
        return is_data && !find_by(s.start()->generic, Sem::input_spec).is_invalid() ? to_vec_function_def(s) : "\n";
    }
    virtual string architecture_body(system& s)
    {
        stringstream ss;
        if (is_data){
            ss << s.start()->demand_signal(Sem::main_input);
            if (find_by(s.start()->generic, Sem::input_spec).is_invalid()){
                ss << " <= \"";
                //for (double d : test_input)
                //    ss << (d < 0.5 ? '0' : '1');
                for (size_t i = test_input.size(); i --> 0;)
                    ss << (test_input[i] < 0.5 ? '0' : '1');
                ss << "\";\n";
            } else {
                ss << " <= to_vec(reals'(";
                for (size_t i = 0, sz = test_input.size(); i < sz; ++i)
                    ss << fixed << setprecision(7) << test_input[i] << (i < sz - 1 ? ", " : "");
                ss << "));\n";
            }
        }
        ss << s.start()->demand_signal(Sem::sig_in_back) << " <= start;\n"
              "out_a <= " << s.last()->demand_signal(Sem::main_output) << ";";
        return ss.str();
    }
    virtual void alter(system& s)
    {
        if (is_data)
            return;
        auto fail = []{ throw runtime_error("sim_interface::alter: First layer doesn't have a prepended interlayer with a file parameter."); };
        if (!s.start() || !s.start()->prepended)
            fail();
        datum& front_data = find_by(s.start()->prepended->generic, Sem::file);
        if (!front_data)
            fail();
        front_data.value.str = test_file;
    }
    vector<double> test_input;
    string test_file;
    bool is_data;
};
auto sim_int_gen = define_interface_generator("sim", +[](const sexpr& s)
{
    if (s.size() < 3)
        throw runtime_error("sim interface generator: Third argument missing.");
    if (s[2].is_tree() && !s[2].empty() && s[2][0].is_leaf() && s[2][0].string() == "data")
        return unique_ptr<system_interface>(new sim_interface(parse_data(s[2], "sim interface generator")));
    else
        return unique_ptr<system_interface>(new sim_interface(parse_file(s[2], "sim interface generator")));
});

} //namespace gen
