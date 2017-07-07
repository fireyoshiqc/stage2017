#pragma once

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

struct fcbin_layer_component : public layer_component
{
    fcbin_layer_component(unsigned int output_width, const vector<double>& weights, unsigned int simd_width, const vector<double>& biases);
    virtual void propagate(component& prev);
    virtual string demand_signal(Sem sem);
    virtual string chain_internal();
};

layer_specification fcbin(BinOutput o, BinWeights w, Simd s, Biases b);

} //namespace gen
