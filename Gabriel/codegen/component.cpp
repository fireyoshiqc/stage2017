#include "component.h"

namespace gen
{
using namespace std;

size_t bits_needed_for_max_int_part_signed(const vector<double>& v)
{
    if (v.empty())
        return 1;
    double absmax = abs(*max_element(v.begin(), v.end(), [](double a, double b){ return abs(a) < abs(b); }));
    if (absmax == 0)
        absmax = 1;
    return 2 + floor(log2(absmax));
}

data_type std_logic_type("std_logic", false);
data_type integer_type("integer", false, +[](const polyvalue& v){
    return to_string(int(v[0]));
});
data_type string_type("string", false, +[](const polyvalue& v){
    return v.str;
});
data_type fixed_spec_type("fixed_spec", false, +[](const polyvalue& v){
    return "fixed_spec(fixed_spec'(int => " + to_string(int(v[0])) + ", frac => " + to_string(int(v[1])) + "))";
});
data_type reals_type("reals", false, +[](const polyvalue& v){
    stringstream ss;
    ss << "reals(reals'( ";
    for (size_t i = 0, sz = v.num.size(); i < sz; ++i)
        ss << fixed << setprecision(7) << v[i] << (i < sz - 1 ? ", " : "");
    ss << "))";
    return ss.str();
});
data_type integers_type("integers", false, +[](const polyvalue& v){
    stringstream ss;
    ss << "integers(integers'( ";
    if (v.num.size() == 0)
        ss << "1 to 0 => 0";
    else if (v.num.size() == 1)
        ss << "0 to 0 => " << v.num[0];
    else for (size_t i = 0, sz = v.num.size(); i < sz; ++i)
        ss << int(round(v[i])) << (i < sz - 1 ? ", " : "");
    ss << "))";
    return ss.str();
});
data_type std_logic_vector_type("std_logic_vector", true, +[](const polyvalue& v){
    stringstream ss;
    ss << "\"";
    //for (double d : v.num)
    //    ss << (d < 0.5 ? '0' : '1');
    for (size_t i = v.num.size(); i --> 0;)
        ss << (v[i] < 0.5 ? '0' : '1');
    ss << "\"";
    return ss.str();
});
data_type unsigned_type("unsigned", true);
data_type sfixed_type("sfixed", true);

datum invalid_datum("INVALID");

void system::propagate()
{
    for (size_t i = 0; i < components.size() - 1; ++i)
        components[i + 1]->propagate(*components[i]);
}

string system::chain_main()
{
    stringstream ss;
    for (size_t i = 0; i < components.size() - 1; ++i){
        ss << components[i + 1]->demand_signal(Sem::main_input) << " <= " << components[i]->demand_signal(Sem::main_output) << ";\n"
           << components[i]->demand_signal(Sem::sig_in_front) << " <= " << components[i + 1]->demand_signal(Sem::sig_out_back) << ";\n"
           << components[i + 1]->demand_signal(Sem::sig_in_back) << " <= " << components[i]->demand_signal(Sem::sig_out_front) << ";\n"
           << components[i]->chain_internal();
    }
    ss << components[components.size() - 1]->chain_internal();
    return ss.str();
}

string system::chain_side()
{
    stringstream ss;
    for (size_t i = 0; i < components.size() - 1; ++i){
        ss << components[i + 1]->demand_signal(Sem::main_input) << " <= " << components[i]->demand_signal(Sem::main_output) << ";\n"
           << components[i + 1]->demand_signal(Sem::sig_in_back) << " <= " << components[i]->demand_signal(Sem::sig_out_front) << ";\n"
           << components[i]->chain_internal();
    }
    ss << components[components.size() - 1]->chain_internal();
    return ss.str();
}

} //namespace gen
