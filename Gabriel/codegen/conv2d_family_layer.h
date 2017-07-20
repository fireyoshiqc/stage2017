#pragma once

#include <iostream>

#include "util.h"
#include "parse.h"
#include "dynamic.h"
#include "component.h"
#include "specification.h"
#include "interlayer.h"

namespace gen
{
using namespace std;
using namespace util;

struct conv2d_family_layer_component : public layer_component
{
    conv2d_family_layer_component(string name, string instance_name, vector<datum> generic, vector<datum> port, const string& padding_previous);
    virtual void propagate(component& prev);
    virtual string demand_signal(Sem sem);
    virtual string chain_internal();
    string padding_previous;
    size_t zero_padding;
    size_t input_size_before_padding;
};

//layer_specification conv2d(Output o, Weights w, Simd s, system_specification side_path);

} //namespace gen

