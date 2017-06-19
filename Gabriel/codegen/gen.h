/// Author: Gabriel Demers
/// Generates a VHDL file from a specification of a fixed-point neural network.

#pragma once

#include <string>
#include <vector>
#include <functional>
#include <sstream>
#include <unordered_set>
#include <stdexcept>

#include "util.h"
#include "component.h"
#include "interface.h"
#include "specification.h"
#include "dynamic.h"

namespace gen
{
using namespace std;
using namespace util;

struct system_str_parts
{
    system_str_parts& operator<<(system& s)
    {
        for (auto&& cur : s.components)
            add_from(cur.get());
        return *this;
    }
private:
    void add_from(component* c)
    {
        if (seen.count(c->name) == 0){
            seen.insert(c->name);
            components += c->component_decl() + '\n';
        }
        signals += c->signals() + '\n';
        instances += c->instance() + '\n';
        if (c->prepended)
            add_from(c->prepended.get());
        if (c->subsystem)
            *this << *c->subsystem.get();
    };
public:
    unordered_set<string> seen;
    string components, signals, instances;
};


system_str_parts process(system& sys, size_t input_width, pair<int, int> input_spec)
{
    sys.push_front(make_unique<component>("DUMMY", "DUMMY", vector<datum>{
        datum("output_width", integer_type,    Sem::output_width, { double(input_width) }),
        datum("output_spec",  fixed_spec_type, Sem::output_spec,  { double(input_spec.first), double(input_spec.second) }),
    }, vector<datum>{
        datum("output", sfixed_type.with_range(input_width * (input_spec.first + input_spec.second), 0), Sem::main_output),
    }));
    sys.propagate();
    sys.pop_front();
    sys.propagate();
    system_str_parts res;
    res << sys;
    return move(res);
}

string generate_code_from(system& sys, system_str_parts parts, system_interface& interface)
{
    stringstream ss;
    ss << R"(use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity system is
port(
)" << interface.entity(sys) << R"(
);
end system;

architecture system of system is

)" << parts.components << '\n' << parts.signals << '\n' << interface.architecture_preface(sys) << R"(
begin

)" << parts.instances << '\n' << sys.chain_main() << '\n' << interface.architecture_body(sys) << R"(
end system;
)";
    return ss.str();
}


string gen_code(const system_specification& ssp, system_interface& interf)
{
    if (ssp.parts.empty())
        throw runtime_error("gen_code: System specification is empty.");
    system built;
    for (const layer_specification& layer : ssp.parts)
        built.push_back(component_from_specification(layer));
    return generate_code_from(built, process(built, ssp.input_width, ssp.input_spec), interf);
}

function<vector<double>(vector<double>)> gen_feedforward(const system_specification& ssp)
{
    if (ssp.parts.empty())
        throw runtime_error("gen_feedforward: System specification is empty.");
    vector<function<vector<double>(vector<double>)>> net;
    for (const layer_specification& layer : ssp.parts)
        net.push_back(feedforward_behavior_from_specification(layer));
    return [net = move(net), insz = ssp.input_width](vector<double> vec){
        if (vec.size() != insz)
            throw runtime_error("Trying to feedforward wrong number of inputs (" + to_string(insz) + " expected, " + to_string(vec.size()) + " given).");
        for (auto&& layer : net)
            vec = layer(move(vec));
        return move(vec);
    };
}

size_t assert_valid(const system_specification& ssp)
{
    size_t prev_width = ssp.input_width;
    for (const layer_specification& layer : ssp.parts)
        prev_width = validity_assertion_from_specification(layer)(prev_width);
    return prev_width;
}

} //namespace gen
