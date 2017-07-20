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

struct pool_layer_component : public conv2d_family_layer_component
{
    pool_layer_component(size_t pool_size, size_t stride, const string& padding_previous);
};

//layer_specification conv2d(Output o, Weights w, Simd s, system_specification side_path);

} //namespace gen
