#pragma once

#include "util.h"
#include "parse.h"
#include "dynamic.h"
#include "component.h"
#include "specification.h"

namespace gen
{
using namespace std;
using namespace util;

struct bias_op_component : public component
{
    bias_op_component(const vector<double>& biases, pair<int, int> bspec);
    virtual void propagate(component& prev);
    virtual string demand_signal(Sem sem);
};

layer_specification bias(const vector<double>& b, pair<int, int> b_spec);

} //namespace gen
