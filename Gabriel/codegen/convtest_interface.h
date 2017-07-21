#pragma once

#include <sstream>
#include <iomanip>
#include <vector>

#include "interface.h"

namespace gen
{
using namespace std;

struct convtest_interface : public system_interface
{
    convtest_interface(const string& test_input_file)
        : test_input_file(test_input_file) {}
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

)";
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
            datum& output_spec = find_by(s.last()->generic, Sem::output_spec);
            datum& output_width = find_by(s.last()->generic, Sem::output_width);
            ss << s.start()->demand_signal(Sem::sig_in_back) << " <= start;\n"
                  "test_out <= shift_range(std_logic_vector(get(" << s.last()->demand_signal(Sem::main_output) << ", to_integer(sel), mk(" << output_spec.formatted_value() << "))), " << int(output_spec.value[1]) << ")(test_out'range) when to_integer(sel) < " << size_t(output_width.value[0]) << R"( else "00000000";)";
        return ss.str();
    }
    virtual void alter(system& s)
    {
        auto fail = []{ throw runtime_error("convtest_interface::alter: First layer doesn't have a prepended interlayer with a file parameter."); };
        if (!s.start() || !s.start()->prepended)
            fail();
        datum& front_data = find_by(s.start()->prepended->generic, Sem::file);
        if (!front_data)
            fail();
        front_data.value.str = test_input_file;
    }
    string test_input_file;
};
auto convtest_int_gen = define_interface_generator("convtest", +[](const sexpr& s)
{
    if (s.size() < 3)
        throw runtime_error("convtest interface generator: Third argument missing.");
    return unique_ptr<system_interface>(new convtest_interface(parse_file(s[2], "convtest interface generator")));
});

} //namespace gen

