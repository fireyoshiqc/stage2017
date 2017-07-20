#pragma once

#include <iostream>

#include "util.h"
#include "parse.h"
#include "dynamic.h"
#include "conv2d_family_layer.h"
#include "specification.h"
#include "interlayer.h"

namespace gen
{
using namespace std;
using namespace util;

struct conv2d_layer_component : public conv2d_family_layer_component
{
    conv2d_layer_component(size_t n_filters_output, pair<int, int> output_spec, const vector<double>& weights, pair<int, int> weight_spec, size_t simd_width_dsp_alloc, const string& padding_previous, size_t stride, size_t kernel_side, const vector<double>& biases, pair<int, int> bias_spec);
};

//layer_specification conv2d(Output o, Weights w, Simd s, system_specification side_path);



} //namespace gen
