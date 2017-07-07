#pragma once

#include <memory>

#include "component.h"

namespace gen
{
using namespace std;

struct interlayer : public component
{
    interlayer(string name, string instance_name, vector<datum> generic, vector<datum> port)
        : component(move(name), move(instance_name), move(generic), move(port)) {}
    string demand_signal_basic(Sem sem)
    {
        switch (sem){
        case Sem::main_input:
            return find_by(port, Sem::main_input).plugged_signal_name;
        case Sem::main_output:
            return find_by(port, Sem::main_output).plugged_signal_name;
        case Sem::sig_out_back:
            return find_by(port, Sem::sig_out_back).plugged_signal_name;
        case Sem::sig_out_front:
            return find_by(port, Sem::sig_out_front).plugged_signal_name;
        case Sem::sig_in_back:
            return find_by(port, Sem::sig_in_back).plugged_signal_name;
        case Sem::sig_in_front:
            return find_by(port, Sem::sig_in_front).plugged_signal_name;
        default:
            throw runtime_error("interlayer can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
        }
    };
};

unique_ptr<component> interlayer_between(layer_component* a, layer_component* b);

} //namespace gen
