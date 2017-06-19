#pragma once

#include <string>
#include <functional>
#include <stdexcept>
#include <memory>
#include <unordered_map>

#include "util.h"

namespace gen
{
using namespace std;
using namespace util;

struct system_interface
{
    virtual string entity(system& s) = 0;
    virtual string architecture_preface(system& s) = 0;
    virtual string architecture_body(system& s) = 0;
};

inline string to_vec_function_def(system& s)
{
    stringstream ss;
    ss <<
R"(function to_vec(r : reals) return std_logic_vector is
    constant input_spec : fixed_spec := )" << find_by(s.start()->generic, Sem::input_spec).formatted_value() << R"(;
    variable ret : std_logic_vector()" << find_by(s.start()->generic, Sem::input_width).value[0] << R"( * size(input_spec) - 1 downto 0);
begin
    for i in r'range loop
        ret((1 + i) * size(input_spec) - 1 downto i * size(input_spec)) :=
            std_logic_vector(to_sfixed(r(i), mk(input_spec)));
    end loop;
    return ret;
end to_vec;
)";
    return ss.str();
}

using interface_generator = function<unique_ptr<system_interface>(const sexpr&)>;
unordered_map<string, interface_generator> interface_generators;
inline int define_interface_generator(const string& name, interface_generator igen)
{
    interface_generators.emplace(name, move(igen));
    return 0;
}
inline unique_ptr<system_interface> generate_interface(const sexpr& s)
{
    if (s.size() < 2 || !s[1].is_leaf())
        throw runtime_error("Interface s-expr is unnamed.");
    auto it = interface_generators.find(s[1].string());
    if (it != interface_generators.end())
        return (it->second)(s);
    else
        throw runtime_error("Could not find an interface with the name \"" + s[1].string() + "\".");
};

} //namespace gen
