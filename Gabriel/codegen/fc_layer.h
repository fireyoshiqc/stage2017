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

class conv2d_family_layer_component;

struct fc_layer_component : public layer_component
{
    fc_layer_component(unsigned int output_width, pair<int, int> output_spec, const vector<double>& weights, pair<int, int> weight_spec, unsigned int simd_width);
    virtual void propagate(component& prev);
    virtual string demand_signal(Sem sem);
    virtual string chain_internal();
private:
    void side_propagate(size_t total_input_width);
    void propagate_conv(conv2d_family_layer_component& prev);
};

layer_specification fc(Output o, Weights w, Simd s, system_specification side_path);

} //namespace gen
