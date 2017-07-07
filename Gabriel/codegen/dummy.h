#pragma once

#include "component.h"

namespace gen
{
using namespace std;

struct dummy_layer : public layer_component
{
    dummy_layer(vector<datum> generic, vector<datum> port)
        : layer_component(typeid(dummy_layer), "DUMMY", "DUMMY", move(generic), move(port)) {}
};

struct dummy_op : public component
{
    dummy_op(vector<datum> generic, vector<datum> port)
        : component("DUMMY", "DUMMY", move(generic), move(port)) {}
};

} //namespace gen
