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

struct sigmoid_op_component : public component
{
    sigmoid_op_component(pair<int, int> ospec, int step_prec, int bit_prec);
    virtual void propagate(component& prev);
    virtual string demand_signal(Sem sem);
};

layer_specification sigmoid(pair<int, int> ospec, int step_prec, int bit_prec);

} //namespace gen;
