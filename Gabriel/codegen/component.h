#pragma once

#include <vector>
#include <string>
#include <stdexcept>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <memory>
#include <cmath>
#include <typeindex>
#include <unordered_map>
#include <iostream>

namespace gen
{
using namespace std;

inline size_t global_counter()
{
    static size_t val = 0;
    return val++;
};

inline size_t bits_needed(size_t maxval) { return ceil(log2(maxval + 0.5)); }
size_t bits_needed_for_max_int_part_signed(const vector<double>& v);

inline int round_to_next_two(int x)
{
    if (x-- < 2)
        return 2;
    for (uint8_t off : { 1, 2, 4, 8, 16 })
        x |= x >> off;
    return ++x;
}
inline int clogb2(const int x)
{
    int res = 0;
    for (size_t i = 0; pow(2, i) < x; ++i)
        res = i + 1;
    return res;
}

enum class Sem { INVALID, clock, reset, main_input, main_output,
                 sig_in_back, sig_in_front, sig_out_back, sig_out_front,
                 side_input, side_output, sig_in_side, sig_out_side,
                 offset_outtake, offset_intake, side_offset_outtake, front_offset_intake, back_offset_outtake, front_offset_outtake, back_offset_intake,
                 special_input_conv_row, special_input_conv_wren, special_output_conv_row, special_output_conv_wren,
                 input_spec, output_spec, data_spec, input_width, output_width,
                 input_spec_int, input_spec_frac, output_spec_int, output_spec_frac,
                 data, file, param };

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
        ret.range_specified = true;
        return move(ret);
    }
    void set_range(int high, int low)
    {
        if (!ranged)
            throw runtime_error("data_type.set_range: Trying to give range (" + to_string(high) + ", " + to_string(low) + ") to " + name + ", which doesn't have a range");
        tie(range_high, range_low) = make_tuple(high, low);
        range_specified = true;
    }
    pair<int, int> get_range() { return make_pair(range_high, range_low); }
    string (*val_format)(const polyvalue&);
    string name;
    int range_high, range_low;
    bool ranged;
    bool range_specified = false;
};
extern data_type std_logic_type;
extern data_type integer_type;
extern data_type boolean_type;
extern data_type string_type;
extern data_type fixed_spec_type;
extern data_type reals_type;
extern data_type std_logic_vector_type;
extern data_type unsigned_type;
extern data_type sfixed_type;
extern data_type integers_type;

struct datum
{
    datum(string name) : name(move(name)), sem(Sem::INVALID) {}
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
    bool is_invalid() const { return name == "INVALID"; }
    operator bool() const { return !is_invalid(); }
    bool operator!() const { return is_invalid(); }
    datum& in() && { is_in = true; return *this; }
    datum& out() && { is_in = false; return *this; }
    datum& hide() { hidden = true; return *this; }
    bool is_hidden() const { return hidden; }
    string name;
    string plugged_signal_name;
    polyvalue value;
    data_type type;
    Sem sem;
    bool is_in;
    bool hidden = false;
};

extern datum invalid_datum;

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
        vector<string> generic_decls; generic_decls.reserve(generic.size());
        for (datum& g : generic)
            if (!g.is_hidden())
                generic_decls.push_back(g.generic_decl());
        for (size_t i = 0, sz = generic_decls.size(); i < sz; ++i)
            ss << "    " << generic_decls[i] << (i < sz - 1 ? ";\n" : "\n");
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
        vector<string> generic_insts; generic_insts.reserve(generic.size());
        for (datum& g : generic)
            if (!g.is_hidden())
                generic_insts.push_back(g.generic_inst());
        for (size_t i = 0, sz = generic_insts.size(); i < sz; ++i)
            ss << "    " << generic_insts[i] << (i < sz - 1 ? ",\n" : "\n");
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

struct layer_component : public component
{
    layer_component(type_index type, string name, string instance_name, vector<datum> generic, vector<datum> port)
        : component(move(name), move(instance_name), move(generic), move(port)), id(id_of(type)) {}
    uint8_t get_id() const { return id; }
    static uint8_t id_of(type_index type)
    {
        static uint8_t counter = 0;
        static unordered_map<type_index, uint8_t> type_to_id_map;
        auto it = type_to_id_map.find(type);
        if (it == type_to_id_map.end()){
            type_to_id_map.emplace(type, counter++);
            return counter - 1;
        }
        return it->second;
    }
    uint8_t id;
};

} //namespace gen
