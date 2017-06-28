#pragma once

#include <sstream>
#include <iomanip>
#include <vector>

#include "interface.h"

namespace gen
{
using namespace std;

struct feed_interface : public system_interface
{
    feed_interface() {}
    virtual string entity(system& s)
    {
        stringstream ss;
        ss <<
R"(    debug : out std_logic_vector(7 downto 0))";
        return ss.str();
    }
    virtual string architecture_preface(system& s)
    {
        stringstream ss;
        ss <<
R"(component gpio_portal is
generic(
    n_from : integer;
    word_size_from : integer;
    word_offset_from : integer;
    n_to : integer;
    word_size_to : integer;
    word_offset_to : integer
);
port(
    clk, rst : out std_logic;
    from_done, to_ack : out std_logic;
    from_ack, to_done : in std_logic;
    from_ps : out std_logic_vector;
    to_ps : in std_logic_vector;
    debug : out std_logic_vector
);
end component gpio_portal;

signal clk, rst_sink : std_logic;
constant rst : std_logic := '0';

)";// << to_vec_function_def(s);
        return ss.str();
    }
    virtual string architecture_body(system& s)
    {
        stringstream ss;
        const vector<double>& inspec = find_by(s.start()->generic, Sem::input_spec).value.num;
        const vector<double>& outspec = find_by(s.last()->generic, Sem::output_spec).value.num;
        ss <<
R"(u_gpio_portal: gpio_portal generic map(
    n_from => )" << find_by(s.start()->generic, Sem::input_width).formatted_value() << R"(,
    word_size_from => )" << inspec[0] + inspec[1] << R"(,
    word_offset_from => 0,
    n_to => )" << find_by(s.last()->generic, Sem::output_width).formatted_value() << R"(,
    word_size_to => )" << outspec[0] + outspec[1] << R"(,
    word_offset_to => 0
) port map(
    clk => clk,
    rst => rst_sink,
    from_done => )" << s.start()->demand_signal(Sem::sig_in_back) << R"(,
    to_ack => )" << s.last()->demand_signal(Sem::sig_in_front) << R"(,
    from_ack => )" << s.start()->demand_signal(Sem::sig_out_back) << R"(,
    to_done => )" << s.last()->demand_signal(Sem::sig_out_front) << R"(,
    from_ps => )" << s.start()->demand_signal(Sem::main_input) << R"(,
    to_ps => )" << s.last()->demand_signal(Sem::main_output) << R"(,
    debug => debug
);
)";
        return ss.str();
    }
};
auto feed_int_gen = define_interface_generator("feed", +[](const sexpr& s)
{
    return unique_ptr<system_interface>(new feed_interface());
});

} //namespace gen

