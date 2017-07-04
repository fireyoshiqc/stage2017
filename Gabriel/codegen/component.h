#pragma once

#include <vector>
#include <string>
#include <stdexcept>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <memory>
#include <cmath>

namespace gen
{
using namespace std;

inline size_t global_counter()
{
    static size_t val = 0;
    return val++;
};

size_t bits_needed(size_t maxval) { return ceil(log2(maxval + 0.5)); }
size_t bits_needed_for_max_int_part_signed(const vector<double>& v)
{
    if (v.empty())
        return 1;
    double absmax = abs(*max_element(v.begin(), v.end(), [](double a, double b){ return abs(a) < abs(b); }));
    if (absmax == 0)
        absmax = 1;
    return 2 + floor(log2(absmax));
}

enum class Sem { clock, reset, main_input, main_output, sig_in_back, sig_in_front, sig_out_back, sig_out_front,
                 side_input, side_output, sig_in_side, sig_out_side, offset_intake, offset_outtake,
                 input_spec, output_spec, data_spec, input_width, output_width, data, file, param };

struct polyvalue
{
    polyvalue() {}
    polyvalue(vector<double> num)
        : num(move(num)) {}
    polyvalue(initializer_list<double> num)
        : num(num) {}
    polyvalue(string str)
        : str(move(str)) {}
    polyvalue(const char* str)
        : str(str) {}
    double& operator[](size_t n) { return num[n]; }
    double operator[](size_t n) const { return num[n]; }
    vector<double> num;
    string str;
};

struct data_type
{
    data_type() : name("INVALID") {}
    data_type(string name, bool ranged, string (*val_format)(const polyvalue&) = +[](const polyvalue&){ return string(); })
        : val_format(val_format), name(move(name)), ranged(ranged) {}
    string full_name() { return name + (ranged ? "(" + to_string(range_high) + " downto " + to_string(range_low) + ")": ""); }
    data_type with_range(int high, int low)
    {
        if (!ranged)
            throw runtime_error("data_type.with_range: Trying to give range (" + to_string(high) + ", " + to_string(low) + ") to " + name + ", which doesn't have a range");
        data_type ret(name, ranged, val_format);
        tie(ret.range_high, ret.range_low) = make_tuple(high, low);
        return move(ret);
    }
    void set_range(int high, int low)
    {
        if (!ranged)
            throw runtime_error("data_type.set_range: Trying to give range (" + to_string(high) + ", " + to_string(low) + ") to " + name + ", which doesn't have a range");
        tie(range_high, range_low) = make_tuple(high, low);
    }
    pair<int, int> get_range() { return make_pair(range_high, range_low); }
    string (*val_format)(const polyvalue&);
    string name;
    int range_high, range_low;
    bool ranged;
};
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
data_type std_logic_vector_type("std_logic_vector", true);
data_type unsigned_type("unsigned", true);
data_type sfixed_type("sfixed", true);

struct datum
{
    datum(string name) : name(move(name)) {}
    datum(string name, data_type type, Sem sem) : name(move(name)), type(move(type)), sem(sem) {}
    datum(string name, data_type type, Sem sem, initializer_list<double> value) : name(move(name)), value(move(value)), type(move(type)), sem(sem) {}
    datum(string name, data_type type, Sem sem, vector<double> value) : name(move(name)), value(move(value)), type(move(type)), sem(sem) {}
    datum(string name, data_type type, Sem sem, string value) : name(move(name)), value(move(value)), type(move(type)), sem(sem) {}
    string generic_decl() { return name + " : " + type.full_name(); }
    string port_decl() { return name + " : " + (is_in ? "in " : "out ") + type.name; }
    string generic_inst() { return name + " => " + formatted_value(); }
    string port_inst() { return name + " => " + plugged_signal_name; }
    string signal() { return sem != Sem::clock && sem != Sem::reset ? "signal " + plugged_signal_name + " : " + type.full_name() + ";" : ""; }
    string formatted_value() { return value.str.empty() ? type.val_format(value) : value.str; }
    bool is_invalid() { return name == "INVALID"; }
    datum& in() && { is_in = true; return *this; }
    datum& out() && { is_in = false; return *this; }
    string name;
    string plugged_signal_name;
    polyvalue value;
    data_type type;
    Sem sem;
    bool is_in;
};
datum invalid_datum("INVALID");

template<typename Container>
datum& find_by(Container&& cont, Sem sem)
{
    auto it = find_if(cont.begin(), cont.end(), [sem](const datum& d){ return d.sem == sem; });
    return it != cont.end() ? *it : invalid_datum;
}
template<typename Container>
datum& find_by(Container&& cont, Sem sem, const string& name)
{
    auto it = find_if(cont.begin(), cont.end(), [sem, &name](const datum& d){ return d.sem == sem && d.name == name; });
    return it != cont.end() ? *it : invalid_datum;
}

struct component;

struct system
{
    void propagate();
    string chain_main();
    string chain_side();
    component* start() { return components.empty() ? nullptr : components.front().get(); }
    component* last() { return components.empty() ? nullptr : components.back().get(); }
    void push_front(unique_ptr<component> c) { components.insert(components.begin(), move(c)); }
    void pop_front() { components.erase(components.begin()); }
    void push_back(unique_ptr<component> c) { components.push_back(move(c)); }
    void pop_back() { components.pop_back(); }
    vector<unique_ptr<component>> components;
};

struct component
{
    component(string name, string instance_name, vector<datum> generic, vector<datum> port)
        : name(move(name)), instance_name(move(instance_name)), generic(move(generic)), port(move(port))
    {
        for (datum& p : this->port)
            p.plugged_signal_name = p.sem == Sem::clock ? "clk" :
                                    p.sem == Sem::reset ? "rst" :
                                                          p.name + "_s" + to_string(global_counter());
    }
    virtual ~component() {}
    virtual void propagate(component& prev) {};
    virtual string demand_signal(Sem sem) { return ""; };
    virtual string chain_internal() { return ""; };
    string component_decl()
    {
        stringstream ss;
        ss << "component " << name << R"( is
generic(
)";
        for (size_t i = 0, sz = generic.size(); i < sz; ++i)
            ss << "    " << generic[i].generic_decl() << (i < sz - 1 ? ";\n" : "\n");
        ss << R"();
port(
)";
        for (size_t i = 0, sz = port.size(); i < sz; ++i)
            ss << "    " << port[i].port_decl() << (i < sz - 1 ? ";\n" : "\n");
        ss << R"();
end component;
)";
        return ss.str();
    }
    string instance()
    {
        stringstream ss;
        ss << instance_name << " : " << name << " generic map(\n";
        for (size_t i = 0, sz = generic.size(); i < sz; ++i)
            ss << "    " << generic[i].generic_inst() << (i < sz - 1 ? ",\n" : "\n");
        ss << ") port map(\n";
        for (size_t i = 0, sz = port.size(); i < sz; ++i)
            ss << "    " << port[i].port_inst() << (i < sz - 1 ? ",\n" : "\n");
        ss << ");";
        return ss.str();
    }
    string signals()
    {
        stringstream ss;
        for (datum& p : port)
            ss << p.signal() << '\n';
        return ss.str();
    }
    unique_ptr<system> subsystem;
    string name, instance_name;
    vector<datum> generic, port;
    unique_ptr<component> prepended;
};

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
