#pragma once

#include <sstream>
#include <iomanip>
#include <vector>

#include "interface.h"

namespace gen
{
using namespace std;

struct test_interface : public system_interface
{
    test_interface(const vector<double>& test_input)
        : test_input(test_input) {}
    virtual string entity(system& s)
    {
        stringstream ss;
        ss <<
R"(    start : in std_logic;
    test_out : out std_logic_vector(8 - 1 downto 0);
    sel : in unsigned(8 - 1 downto 0))";
        return ss.str();
    }
    virtual string architecture_preface(system& s)
    {
        stringstream ss;
        ss <<
R"(component ps_clk is
port(
    clk, rst : out std_logic
);
end component;

signal clk, rst_sink : std_logic;
constant rst : std_logic := '0';

)" << (!find_by(s.start()->generic, Sem::input_spec).is_invalid() ? to_vec_function_def(s) : "\n");//to_vec_function_def(s);
        return ss.str();
    }
    virtual string architecture_body(system& s)
    {
        stringstream ss;
        ss <<
R"(uPS : ps_clk port map(
    clk => clk,
    rst => rst_sink
);
)";
        if (find_by(s.start()->generic, Sem::input_spec).is_invalid()){
            ss << s.start()->demand_signal(Sem::main_input) << " <= \"";
            for (size_t i = test_input.size(); i --> 0;)
                ss << (test_input[i] < 0.5 ? '0' : '1');
            ss << "\";\n"
               << s.start()->demand_signal(Sem::sig_in_back) << " <= start;\n"
                  "test_out <= \"10101010\" when to_integer(sel) >= " << size_t(find_by(s.last()->generic, Sem::output_width).value[0]) << " else \"00000000\" when " << s.last()->demand_signal(Sem::main_output) << "(to_integer(sel)) = '0' else \"11111111\";\n";
        } else {
            ss << s.start()->demand_signal(Sem::main_input) << " <= to_vec(reals'(";
            for (size_t i = 0, sz = test_input.size(); i < sz; ++i)
                ss << fixed << setprecision(7) << test_input[i] << (i < sz - 1 ? ", " : "");
            datum& output_spec = find_by(s.last()->generic, Sem::output_spec);
            datum& output_width = find_by(s.last()->generic, Sem::output_width);
            ss << "));\n"
               << s.start()->demand_signal(Sem::sig_in_back) << " <= start;\n"
                  "test_out <= shift_range(std_logic_vector(get(" << s.last()->demand_signal(Sem::main_output) << ", to_integer(sel), mk(" << output_spec.formatted_value() << "))), " << int(output_spec.value[1]) << ")(test_out'range) when to_integer(sel) < " << size_t(output_width.value[0]) << R"( else "00000000";)";
        }
        return ss.str();
    }
    vector<double> test_input;
};
auto test_int_gen = define_interface_generator("test", +[](const sexpr& s)
{
    if (s.size() < 3)
        throw runtime_error("test interface generator: Third argument missing.");
    return unique_ptr<system_interface>(new test_interface(parse_data(s[2], "test interface generator")));
});

} //namespace gen
