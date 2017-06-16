/// Author: Gabriel Demers
/// Generates a VHDL file from a specification of a fixed-point neural network.

#pragma once

#include <string>
#include <vector>
#include <functional>
#include <sstream>
#include <cmath>
#include <unordered_set>
#include <unordered_map>
#include <algorithm>
#include <iomanip>
#include <type_traits>
#include <iostream>
#include <functional>

#include "util.h"

namespace gen
{
using namespace std;
using namespace util;


pair<int, int> parse_fixed_pair(const sexpr_field& s, const string& pos_info)
{
    if (s.is_leaf() || s.size() != 3 || s[0].is_tree() || s[0].string() != "fixed" || s[1].is_tree() || s[2].is_tree())
        throw runtime_error("parse_fixed_pair: At " + pos_info + ": Wrong format for \"fixed\" pair (Name \"fixed\" + 2 integer arguments expected).");
    pair<int, int> res;
    for (auto&& val : { make_tuple(&res.first, 1, "First"), make_tuple(&res.second, 2, "Second") }){
        try {
            *get<0>(val) = stoi(s[get<1>(val)].string());
            if (*get<0>(val) <= 0)
                throw runtime_error("parse_fixed_pair: At " + pos_info + ": " + string(get<2>(val)) + " value should be positive.");
        } catch (exception&){
            throw runtime_error("parse_fixed_pair: At " + pos_info + ": " + string(get<2>(val)) + " value has invalid format.");
        }
    }
    return res;
}
size_t parse_positive_integer(const sexpr_field& s, const string& pos_info)
{
    if (s.is_tree())
        throw runtime_error("parse_positive_integer: At " + pos_info + ": Expecting a value.");
    size_t res;
    try {
        int val = stoi(s.string());
        if (val <= 0)
            throw runtime_error("parse_positive_integer: At " + pos_info + ": Value should be positive.");
        res = val;
    } catch (exception&){
        throw runtime_error("parse_positive_integer: At " + pos_info + ": Value has invalid format.");
    }
    return res;
}
int parse_integer(const sexpr_field& s, const string& pos_info)
{
    if (s.is_tree())
        throw runtime_error("parse_integer: At " + pos_info + ": Expecting a value.");
    int res;
    try {
        res = stoi(s.string());
    } catch (exception&){
        throw runtime_error("parse_integer: At " + pos_info + ": Value has invalid format.");
    }
    return res;
}
double parse_double(const sexpr_field& s, const string& pos_info)
{
    if (s.is_tree())
        throw runtime_error("parse_double: At " + pos_info + ": Expecting a value.");
    double res;
    try {
        res = stod(s.string());
    } catch (exception&){
        throw runtime_error("parse_double: At " + pos_info + ": Value has invalid format.");
    }
    return res;
}
vector<double> parse_data(const sexpr_field& s, const string& pos_info)
{
    if (s.is_leaf() || s.empty() || s[0].is_tree() || s[0].string() != "data")
        throw runtime_error("parse_data: At " + pos_info + ": Wrong format for data list (expecting \"data\" followed by a list of doubles).");
    vector<double> res;
    for (size_t i = 1; i < s.size(); ++i)
        res.push_back(parse_double(s[i], pos_info + ", field " + to_string(i)));
    return move(res);
}

struct system_specification;
system_specification* clone_system_specification(const system_specification&);
void delete_system_specification(system_specification*);

struct specification_variant
{
    enum type_t { empty, num, vec, str, sys_spec };
    template<typename T>
    specification_variant(T&& t)
        : u(forward<T>(t), this) {}
    static runtime_error unhandled_err(const string& caller, type_t type)
    {
        return runtime_error(caller + ": Unhandled data type with code " + to_string(static_cast<int>(type)) + ".");
    }
    void discard()
    {
        switch (type){
        case empty: case num: return;
        case vec: return u.v.vector<double>::~vector<double>();
        case str: return u.s.string::~string();
        case sys_spec: return delete_system_specification(u.sys);
        default: throw unhandled_err("specification_variant::discard", type);
        }
    }
    ~specification_variant() { discard(); }
    void copy(const specification_variant& other)
    {
        switch (other.type){
        case empty: break;
        case num: u.d = other.u.d; break;
        case vec: ::new(&u.v) vector<double>(other.u.v); break;
        case str: ::new(&u.s) string(other.u.s); break;
        case sys_spec: u.sys = clone_system_specification(*other.u.sys); break;
        default: throw unhandled_err("specification_variant::copy", other.type);
        }
        type = other.type;
    }
    specification_variant(const specification_variant& other) : u(0.0) { copy(other); }
    specification_variant& operator=(const specification_variant& other) { discard(); copy(other); return *this; }
    void move(specification_variant&& other)
    {
        switch (other.type){
        case empty: break;
        case num: u.d = other.u.d; break;
        case vec: ::new(&u.v) vector<double>(std::move(other.u.v)); break;
        case str: ::new(&u.s) string(std::move(other.u.s)); break;
        case sys_spec: u.sys = other.u.sys; other.u.sys = nullptr; break;
        default: throw unhandled_err("specification_variant::move", other.type);
        }
        type = other.type;
        other.discard();
    }
    specification_variant(specification_variant&& other) : u(0.0) { move(std::move(other)); }
    specification_variant& operator=(specification_variant&& other) { discard(); move(std::move(other)); return *this; }
    union data_t
    {
        data_t(double d, specification_variant* obj = nullptr)
            : d(d) { if (obj) obj->type = num; }
        data_t(vector<double> v, specification_variant* obj = nullptr)
            : v(std::move(v)) { if (obj) obj->type = vec; }
        data_t(string s, specification_variant* obj = nullptr)
            : s(std::move(s)) { if (obj) obj->type = str; }
        data_t(unique_ptr<system_specification> s, specification_variant* obj = nullptr)
            : sys(s.release()) { if (obj) obj->type = sys_spec; }
        data_t(const system_specification& s, specification_variant* obj = nullptr)
            : sys(clone_system_specification(s)) { if (obj) obj->type = sys_spec; }
        ~data_t() {}
        double d;
        vector<double> v;
        string s;
        system_specification* sys;
    } u;
    type_t type;
    static string type_str(type_t t)
    {
        switch (t){
        case empty: return "EMPTY";
        case num: return "number";
        case vec: return "vector of numbers";
        case str: return "string";
        case sys_spec: return "system specification";
        default: return "???";
        }
    }
    runtime_error err(type_t wanted) const
    {
        return runtime_error("Trying to extract a " + type_str(wanted) + " from specification_variant even though it contains a " + type_str(type) + ".");
    }
    template<typename T, enable_if_t<is_convertible<T, double>::value>* = nullptr>
    operator T() const { if (type == num) return T(u.d); else throw err(num); }
    operator vector<double>&() & { if (type == vec) return u.v; else throw err(vec); }
    operator const vector<double>&() const & { if (type == vec) return u.v; else throw err(vec); }
    template<typename T, enable_if_t<is_convertible<T, string>::value>* = nullptr>
    operator T() const { if (type == str) return T(u.s); else throw err(str); }
    //operator unique_ptr<system_specification>() && { if (type == sys_spec) return unique_ptr<system_specification>(u.sys); else throw err(sys_spec); }
    operator system_specification&() & { if (type == sys_spec) return *u.sys; else throw err(sys_spec); }
    operator const system_specification&() const & { if (type == sys_spec) return *u.sys; else throw err(sys_spec); }
};

template<typename T>
auto dyn_param(const string& key, T&& val)
{
    return make_pair(key, specification_variant(forward<T>(val)));
}

struct layer_specification
{
    string name;
    unordered_map<string, specification_variant> parameters;
};

struct system_specification
{
    vector<layer_specification> parts;
    size_t input_width;
    pair<int, int> input_spec;
};
system_specification* clone_system_specification(const system_specification& other)
{
    return new system_specification(other);
}
void delete_system_specification(system_specification* s)
{
    delete s;
}

system_specification input(size_t input_width, pair<int, int> input_spec)
{
    return system_specification{ vector<layer_specification>{}, input_width, input_spec };
}

system_specification neuron()
{
    return system_specification{};
}

auto spec(int int_part, int frac_part)
{
    return make_pair(int_part, frac_part);
}
auto int_pair(int a, int b)
{
    return make_pair(a, b);
}

struct Output { size_t output_width; pair<int, int> output_spec; };
auto output(size_t output_width, pair<int, int> output_spec)
{
    return Output{ output_width, output_spec };
}

struct Weights { vector<double> w; pair<int, int> w_spec; };
auto weights(const vector<double>& w, pair<int, int> w_spec)
{
    return Weights{ w, w_spec };
}
auto weights(const vector<vector<double>>& w2d, pair<int, int> w_spec)
{
    vector<double> w;
    size_t expected_row_size = size_t(-1);
    for (const vector<double>& row : w2d){
        if (expected_row_size == size_t(-1))
            expected_row_size = row.size();
        else if (row.size() != expected_row_size)
            throw runtime_error("weights: Inconsistent row sizes (" + to_string(expected_row_size) + " and " + to_string(row.size()) + ").");
        copy(row.begin(), row.end(), back_inserter(w));
    }
    return Weights{ w, w_spec };
}

struct Simd { size_t simd_width; };
auto simd(size_t simd_width)
{
    return Simd{ simd_width };
}

system_specification operator|(system_specification sys, layer_specification&& ls)
{
    sys.parts.push_back(move(ls));
    return move(sys);
}
system_specification operator|(system_specification sys, const layer_specification& ls)
{
    sys.parts.push_back(ls);
    return move(sys);
}


size_t global_counter()
{
    static size_t val = 0;
    return val++;
};

size_t bits_needed(size_t maxval) { return ceil(log2(maxval + 0.5)); }

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


auto checked_get(const string& caller_type)
{
    return [caller_type](const string& caller, const unordered_map<string, specification_variant>& cgen){
        return [caller_type, caller, &cgen](const string& param) -> const specification_variant& {
            auto it = cgen.find(param);
            if (it != cgen.end())
                return it->second;
            else
                throw runtime_error("Trying to access invalid or inexistant parameter \"" + param + "\" from " + caller_type + " \"" + caller + "\".");
        };
    };
}
template<typename Contained>
auto generator_definer(unordered_map<string, Contained>& cont)
{
    return [&](const string& name, Contained cgen){
        cont.emplace(name, cgen);
        return 0;
    };
}
template<typename Contained>
auto from_specification(unordered_map<string, Contained>& cont, const string& subject)
{
    return [&cont, subject](const layer_specification& ls){
        auto it = cont.find(ls.name);
        if (it != cont.end())
            return (it->second)(ls.parameters);
        else
            throw runtime_error("\"" + ls.name + "\" has no corresponding " + subject + ".");
    };
}

using component_generator = unique_ptr<component>(*)(const unordered_map<string, specification_variant>&);
unordered_map<string, component_generator> component_generators;
auto define_component_generator = generator_definer(component_generators);
auto component_from_specification = from_specification(component_generators, "component");


using feedforward_behavior = function<vector<double>(vector<double>)>;
using feedforward_behavior_generator = feedforward_behavior(*)(const unordered_map<string, specification_variant>&);
unordered_map<string, feedforward_behavior_generator> feedforward_behavior_generators;
auto define_feedforward_behavior_generator = generator_definer(feedforward_behavior_generators);
auto feedforward_behavior_from_specification = from_specification(feedforward_behavior_generators, "feedforward behavior");


using activation_behavior = function<double(double, size_t)>;
using activation_behavior_generator = activation_behavior(*)(const unordered_map<string, specification_variant>&);
unordered_map<string, activation_behavior_generator> activation_behavior_generators;
auto define_activation_behavior_generator = generator_definer(activation_behavior_generators);
auto activation_behavior_from_specification = from_specification(activation_behavior_generators, "activation behavior");


using validity_assertion = function<size_t(size_t)>;
using validity_assertion_generator = validity_assertion(*)(const unordered_map<string, specification_variant>&);
unordered_map<string, validity_assertion_generator> validity_assertion_generators;
auto define_validity_assertion_generator = generator_definer(validity_assertion_generators);
auto validity_assertion_from_specification = from_specification(validity_assertion_generators, "validity assertion");


using layer_spec_parser = function<layer_specification(const sexpr_field&, const string&)>;
unordered_map<string, layer_spec_parser> layer_spec_parsers;
auto define_layer_spec_parser = generator_definer(layer_spec_parsers);
layer_spec_parser layer_spec_parser_from_name(const string& name, const string& pos_info)
{
    auto it = layer_spec_parsers.find(name);
    if (it != layer_spec_parsers.end())
        return it->second;
    else
        throw runtime_error("layer_spec_parser_from_name: At " + pos_info + ": Can't find parser for layer type \"" + name + "\".");
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

struct interlayer : public component
{
    interlayer(unsigned int width, pair<int, int> spec)
        : component("interlayer", "interlayer_u" + to_string(global_counter()),
        {
            datum("width",     integer_type, Sem::input_width, { double(width) }),
            datum("word_size", integer_type, Sem::input_spec,  { double(spec.first + spec.second) }),
        }, {
            datum("clk",        std_logic_type,                                                              Sem::clock)        .in(),
            datum("rst",        std_logic_type,                                                              Sem::reset)        .in(),
            datum("ready",      std_logic_type,                                                              Sem::sig_in_front) .in(),
            datum("done",       std_logic_type,                                                              Sem::sig_in_back)  .in(),
            datum("start",      std_logic_type,                                                              Sem::sig_out_front).out(),
            datum("ack",        std_logic_type,                                                              Sem::sig_out_back) .out(),
            datum("previous_a", std_logic_vector_type.with_range(width * (spec.first + spec.second) - 1, 0), Sem::main_input)   .in(),
            datum("next_a",     std_logic_vector_type.with_range(width * (spec.first + spec.second) - 1, 0), Sem::main_output)  .out(),
        }) {}
    virtual string demand_signal(Sem sem)
    {
        switch (sem){
        case Sem::main_input:
            return find_by(port, Sem::main_input).plugged_signal_name;
        case Sem::main_output:
            return find_by(port, Sem::main_output).plugged_signal_name;
        case Sem::sig_out_back:
            return find_by(port, Sem::sig_out_back).plugged_signal_name;
        case Sem::sig_out_front:
            return find_by(port, Sem::sig_out_front).plugged_signal_name;
        case Sem::sig_in_back:
            return find_by(port, Sem::sig_in_back).plugged_signal_name;
        case Sem::sig_in_front:
            return find_by(port, Sem::sig_in_front).plugged_signal_name;
        default:
            throw runtime_error("fc_layer_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
        }
    };
};

struct fc_layer_component : public component
{
    fc_layer_component(unsigned int output_width, pair<int, int> output_spec, const vector<double>& weights, pair<int, int> weight_spec, unsigned int simd_width)
        : component("fc_layer", "fc_layer_u" + to_string(global_counter()),
        {
            datum("input_width",      integer_type,    Sem::input_width),
            datum("output_width",     integer_type,    Sem::output_width, { double(output_width) }),
            datum("simd_width",       integer_type,    Sem::param,        { double(simd_width) }),
            datum("input_spec",       fixed_spec_type, Sem::input_spec),
            datum("weight_spec",      fixed_spec_type, Sem::data_spec,    { double(weight_spec.first), double(weight_spec.second) }),
            datum("op_arg_spec",      fixed_spec_type, Sem::param),
            datum("output_spec",      fixed_spec_type, Sem::output_spec,  { double(output_spec.first), double(output_spec.second) }),
            datum("n_weights",        integer_type,    Sem::param,        { double(weights.size()) }),
            datum("weights_filename", string_type,    Sem::file,         "\"whatever\""),
            datum("weight_values",    reals_type,      Sem::output_width, weights),
        },{
            datum("clk",         std_logic_type,                                                                                   Sem::clock)         .in(),
            datum("rst",         std_logic_type,                                                                                   Sem::reset)         .in(),
            datum("ready",       std_logic_type,                                                                                   Sem::sig_out_back)  .out(),
            datum("done",        std_logic_type,                                                                                   Sem::sig_out_front) .out(),
            datum("start",       std_logic_type,                                                                                   Sem::sig_in_back)   .in(),
            datum("ack",         std_logic_type,                                                                                   Sem::sig_in_front)  .in(),
            datum("in_a",        std_logic_vector_type,                                                                            Sem::main_input)    .in(),
            datum("out_a",       std_logic_vector_type.with_range(output_width * (output_spec.first + output_spec.second) - 1, 0), Sem::main_output)   .out(),
            datum("out_offset",  unsigned_type.with_range(bits_needed(output_width) - 1, 0),                                       Sem::offset_outtake).out(),
            datum("op_argument", sfixed_type,                                                                                      Sem::side_output)   .out(),
            datum("op_result",   sfixed_type.with_range(output_spec.first - 1, -output_spec.second),                               Sem::side_input)    .in(),
            datum("op_send",     std_logic_type,                                                                                   Sem::sig_out_side)  .out(),
            datum("op_receive",  std_logic_type,                                                                                   Sem::sig_in_side)   .in(),
        }) {}
    virtual void propagate(component& prev)
    {
        auto prevspec = find_by(prev.generic, Sem::output_spec).value.num;
        size_t prevwidth = find_by(prev.generic, Sem::output_width).value[0];
        find_by(generic, Sem::input_spec).value = prevspec;
        find_by(generic, Sem::input_width).value.num = { double(prevwidth) };
        datum& op_arg_spec = find_by(generic, Sem::param, "op_arg_spec");
        datum& weight_spec = find_by(generic, Sem::data_spec);
        datum& simd_width = find_by(generic, Sem::param, "simd_width");
        size_t mul_int_part = prevspec[0] + weight_spec.value[0] + 1,
               n_accumulated = prevwidth / size_t(simd_width.value[0]);
        double mulacc_int_part = ceil(log2(n_accumulated * pow(2.0, mul_int_part) + 1)),
               add_tree_contribution = ceil(log2(simd_width.value[0]));
        op_arg_spec.value = { mulacc_int_part + add_tree_contribution,//prevspec[0] + weight_spec.value[0] + prevwidth / size_t(simd_width.value[0]) + ,
                              prevspec[1] + weight_spec.value[1] };
        find_by(port, Sem::main_input).type.set_range(prevwidth * (prevspec[0] + prevspec[1]) - 1, 0);
        datum& side_output = find_by(port, Sem::side_output);
        side_output.type.set_range(op_arg_spec.value[0] - 1, -op_arg_spec.value[1]);
        prepended = make_unique<interlayer>(prevwidth, make_pair(int(prevspec[0]), int(prevspec[1])));
        if (subsystem){
            find_by(subsystem->start()->port, Sem::input_spec).value.num = op_arg_spec.value.num;
            subsystem->push_front(make_unique<component>("DUMMY", "DUMMY", vector<datum>{
                datum("output_spec", fixed_spec_type, Sem::output_spec, op_arg_spec.value.num),
            }, vector<datum>{
                datum("output", sfixed_type.with_range(side_output.type.range_high, side_output.type.range_low), Sem::main_output),
            }));
            subsystem->propagate();
            subsystem->pop_front();
        }
    }
    virtual string demand_signal(Sem sem)
    {
        switch (sem){
        case Sem::main_input:
            return prepended->demand_signal(Sem::main_input);
        case Sem::main_output:
            return find_by(port, Sem::main_output).plugged_signal_name;
        case Sem::sig_out_back:
            return prepended->demand_signal(Sem::sig_out_back);
        case Sem::sig_out_front:
            return find_by(port, Sem::sig_out_front).plugged_signal_name;
        case Sem::sig_in_back:
            return prepended->demand_signal(Sem::sig_in_back);
        case Sem::sig_in_front:
            return find_by(port, Sem::sig_in_front).plugged_signal_name;
        case Sem::side_input:
            return find_by(port, Sem::side_input).plugged_signal_name;
        case Sem::side_output:
            return find_by(port, Sem::side_output).plugged_signal_name;
        case Sem::offset_outtake:
            return find_by(port, Sem::offset_outtake).plugged_signal_name;
        case Sem::sig_in_side:
            return find_by(port, Sem::sig_in_side).plugged_signal_name;
        case Sem::sig_out_side:
            return find_by(port, Sem::sig_out_side).plugged_signal_name;
        default:
            throw runtime_error("fc_layer_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
        }
    };
    virtual string chain_internal()
    {
        stringstream ss;
        ss << find_by(port, Sem::main_input).plugged_signal_name << " <= " << prepended->demand_signal(Sem::main_output) << ";\n"
           << find_by(port, Sem::sig_in_back).plugged_signal_name << " <= " << prepended->demand_signal(Sem::sig_out_front) << ";\n"
           << prepended->demand_signal(Sem::sig_in_front) << " <= " << find_by(port, Sem::sig_out_back).plugged_signal_name << ";\n";
        if (subsystem){
            component* start = subsystem->start(), * last = subsystem->last();
            ss << start->demand_signal(Sem::main_input) << " <= " << demand_signal(Sem::side_output) << ";\n"
               << start->demand_signal(Sem::sig_in_back) << " <= " << demand_signal(Sem::sig_out_side) << ";\n"
               << demand_signal(Sem::sig_in_side) << " <= " << last->demand_signal(Sem::sig_out_front) << ";\n"
               << subsystem->chain_side();
            for (auto&& cur : subsystem->components)
                if (!find_by(cur->port, Sem::offset_intake).is_invalid())
                    ss << cur->demand_signal(Sem::offset_intake) << " <= " << demand_signal(Sem::offset_outtake) << ";\n";
            ss << demand_signal(Sem::side_input) << " <= resize(" << last->demand_signal(Sem::main_output) << ", mk(" << find_by(generic, Sem::output_spec).formatted_value() << "));\n";
        } else
            ss << demand_signal(Sem::side_input) << " <= resize(" << demand_signal(Sem::side_output) << ", mk(" << find_by(generic, Sem::output_spec).formatted_value() << "));\n";
        return ss.str();
    };
};

auto fc_gen = define_component_generator("fc", +[](const unordered_map<string, specification_variant>& params)
{
    auto get = checked_get("component generator")("fc", params);
    unique_ptr<component> ret(new fc_layer_component(
        get("output_width"),
        int_pair(get("output_spec_int"), get("output_spec_frac")),
        get("weights"),
        pair<int, int>(get("weight_spec_int"), get("weight_spec_frac")),
        get("simd_width")
    ));
    const system_specification& side_path = get("side_path");
    if (!side_path.parts.empty()){
        ret->subsystem = make_unique<system>();
        for (const layer_specification& part : side_path.parts)
            ret->subsystem->push_back(component_from_specification(part));
    }
    return move(ret);
});

auto fc_ff = define_feedforward_behavior_generator("fc", +[](const unordered_map<string, specification_variant>& params) -> feedforward_behavior
{
    auto get = checked_get("feedforward behavior generator")("fc", params);
    size_t output_width = get("output_width");
    vector<double> weights = get("weights");
    const system_specification& side_path = get("side_path");
    vector<activation_behavior> activation;
    for (const layer_specification& part : side_path.parts)
        activation.push_back(activation_behavior_from_specification(part));
    return [output_width, input_width = size_t(weights.size() / output_width), weights = move(weights), activation = move(activation)](vector<double> input){
        vector<double> output(output_width, 0.0);
        for (size_t i = 0, ij = 0; i < output_width; ++i){
            for (size_t j = 0; j < input_width; ++j, ++ij)
                output[i] += weights[ij] * input[j];
            for (const activation_behavior& f : activation)
                output[i] = f(output[i], i);
        }
        return move(output);
    };
});

auto fc_av = define_validity_assertion_generator("fc", +[](const unordered_map<string, specification_variant>& params) -> validity_assertion
{
    auto get = checked_get("validity assertion generator")("fc", params);
    size_t output_width = get("output_width");
    const vector<double>& weights = get("weights");
    const system_specification& side_path = get("side_path");
    vector<validity_assertion> side_val_asserts;
    for (const layer_specification& part : side_path.parts)
        side_val_asserts.push_back(validity_assertion_from_specification(part));
    return [output_width, weights_size = weights.size(), side_val_asserts = move(side_val_asserts)](size_t prev_width){
        if (weights_size != output_width * prev_width)
            throw runtime_error("fc layer has " + to_string(prev_width) + " inputs and " + to_string(output_width) + " outputs, and should therefore have " +
                                to_string(prev_width * output_width) + " weights. However, the actual number of weights given is " + to_string(weights_size) + ".");
        for (auto&& sva : side_val_asserts)
            sva(output_width);
        return output_width;
    };
});

layer_specification fc(Output o, Weights w, Simd s, system_specification side_path)
{
    return layer_specification{
        "fc", {
            dyn_param("output_width", o.output_width),
            dyn_param("output_spec_int", o.output_spec.first),
            dyn_param("output_spec_frac", o.output_spec.second),
            dyn_param("weights", move(w.w)),
            dyn_param("weight_spec_int", w.w_spec.first),
            dyn_param("weight_spec_frac", w.w_spec.second),
            dyn_param("simd_width", s.simd_width),
            dyn_param("side_path", move(side_path)),
        }
    };
}

auto fc_parse = define_layer_spec_parser("fc", +[](const sexpr_field& s, const string& pos_info)
{
    if (s.size() != 5)
        throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Clause expects 4 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "fc", {} };
    unordered_map<string, const sexpr_field*> fields;
    for (const string& name : { "output", "weights", "simd", "neuron" }){
        auto it = find_if(s.sexpr().fields.begin() + 1, s.sexpr().fields.end(),
                          [&](const sexpr_field& sf){ return sf.is_tree() && !sf.empty() && sf[0].is_leaf() && sf[0].string() == name; });
        if (it == s.sexpr().fields.end())
            throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Couldn't find \"" + name + "\" field.");
        fields.emplace(name, &(*it));
    }
    const sexpr_field& outputf = *fields["output"];
    if (outputf.size() != 3)
        throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Output field takes 2 arguments, not " + to_string(outputf.size() - 1) + ".");
    layer.parameters.emplace("output_width", parse_positive_integer(outputf[1], pos_info + ", first argument of output clause"));
    pair<int, int> outspec = parse_fixed_pair(outputf[2], pos_info + ", second argument of output clause");
    layer.parameters.emplace("output_spec_int", outspec.first);
    layer.parameters.emplace("output_spec_frac", outspec.second);
    const sexpr_field& weightsf = *fields["weights"];
    if (weightsf.size() != 3)
        throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Weights field takes 2 arguments, not " + to_string(weightsf.size() - 1) + ".");
    layer.parameters.emplace("weights", parse_data(weightsf[1], pos_info + ", first argument of weights clause"));
    pair<int, int> wspec = parse_fixed_pair(weightsf[2], pos_info + ", second argument of weights clause");
    layer.parameters.emplace("weight_spec_int", wspec.first);
    layer.parameters.emplace("weight_spec_frac", wspec.second);
    const sexpr_field& simdf = *fields["simd"];
    if (simdf.size() != 2)
        throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Simd field takes 1 argument, not " + to_string(simdf.size() - 1) + ".");
    layer.parameters.emplace("simd_width", parse_positive_integer(simdf[1], pos_info + ", first argument of simd clause"));
    const sexpr_field& neuronf = *fields["neuron"];
    system_specification side_path;
    for (size_t i = 1; i < neuronf.sexpr().fields.size(); ++i){
        if (neuronf.sexpr().fields[i].is_leaf() || neuronf.sexpr().fields[i].empty() || neuronf.sexpr().fields[i][0].is_tree())
            throw runtime_error("layer_spec_parser for fc: At " + pos_info + ": Neuron op field " + to_string(i) + " is invalid.");
        string pos_info_sub = pos_info + ", neuron op " + to_string(i);
        side_path.parts.push_back(layer_spec_parser_from_name(neuronf.sexpr().fields[i][0].string(), pos_info_sub)(neuronf.sexpr().fields[i], pos_info_sub));
    }
    layer.parameters.emplace("side_path", move(side_path));
    return move(layer);
});



struct bias_op_component : public component
{
    bias_op_component(const vector<double>& biases, pair<int, int> bspec)
        : component("bias_op", "bias_op_u" + to_string(global_counter()),
        {
            datum("input_spec", fixed_spec_type, Sem::input_spec),
            datum("bias_spec",  fixed_spec_type, Sem::data_spec,  { double(bspec.first), double(bspec.second) }),
            datum("biases",     reals_type,      Sem::data,       biases),
        }, {
            datum("input",      sfixed_type,                                                 Sem::main_input)   .in(),
            datum("offset",     unsigned_type.with_range(bits_needed(biases.size()) - 1, 0), Sem::offset_intake).in(),
            datum("output",     sfixed_type,                                                 Sem::main_output)  .out(),
            datum("op_send",    std_logic_type,                                              Sem::sig_out_front)  .out(),
            datum("op_receive", std_logic_type,                                              Sem::sig_in_back).in(),
        }) {}
    virtual void propagate(component& prev)
    {
        datum& spec = find_by(generic, Sem::input_spec);
        datum& prev_out = find_by(prev.port, Sem::main_output);
        spec.value = { double(prev_out.type.range_high + 1), double(-prev_out.type.range_low) };
        find_by(port, Sem::main_input).type.set_range(prev_out.type.range_high, prev_out.type.range_low);
        datum& bspec = find_by(generic, Sem::data_spec);
        find_by(port, Sem::main_output).type.set_range(max(spec.value[0], bspec.value[0]), -max(spec.value[1], bspec.value[1]));
    }
    virtual string demand_signal(Sem sem)
    {
        datum& d = find_by(port, sem);
        if (d.is_invalid())
            throw runtime_error("bias_op_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
        return d.plugged_signal_name;
    };
};

auto bias_gen = define_component_generator("bias", +[](const unordered_map<string, specification_variant>& params)
{
    auto get = checked_get("component generator")("bias", params);
    return unique_ptr<component>(new bias_op_component(
        get("biases"),
        pair<int, int>(get("bspec_int"), get("bspec_frac"))
    ));
});

auto bias_ac = define_activation_behavior_generator("bias", +[](const unordered_map<string, specification_variant>& params) -> activation_behavior
{
    auto get = checked_get("activation behavior generator")("bias", params);
    vector<double> biases = get("biases");
    return [biases = move(biases)](double input, size_t offset){
        return input + biases[offset];
    };
});

auto bias_av = define_validity_assertion_generator("bias", +[](const unordered_map<string, specification_variant>& params) -> validity_assertion
{
    auto get = checked_get("validity assertion generator")("bias", params);
    const vector<double>& biases = get("biases");
    return [biases_size = biases.size()](size_t offset_width){
        if (biases_size != offset_width)
            throw runtime_error("Layer with bias op has " + to_string(offset_width) + " outputs, and therefore bias op should have " +
                                to_string(offset_width) + " biases. However, the actual number of biases given is " + to_string(biases_size) + ".");
        return offset_width;
    };
});

layer_specification bias(const vector<double>& b, pair<int, int> b_spec)
{
    return layer_specification{
        "bias", {
            dyn_param("biases", b),
            dyn_param("bspec_int", b_spec.first),
            dyn_param("bspec_frac", b_spec.second),
        }
    };
}

auto bias_parse = define_layer_spec_parser("bias", +[](const sexpr_field& s, const string& pos_info)
{
    if (s.size() != 3)
        throw runtime_error("layer_spec_parser for bias: At " + pos_info + ": Clause expects 2 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "bias", {} };
    layer.parameters.emplace("biases", parse_data(s[1], pos_info + ", first argument"));
    pair<int, int> bspec = parse_fixed_pair(s[2], pos_info + ", second argument");
    layer.parameters.emplace("bspec_int", bspec.first);
    layer.parameters.emplace("bspec_frac", bspec.second);
    return move(layer);
});


struct sigmoid_op_component : public component
{
    sigmoid_op_component(pair<int, int> ospec, int step_prec, int bit_prec)
        : component("sigmoid_op", "sigmoid_op_u" + to_string(global_counter()),
        {
            datum("input_spec",     fixed_spec_type, Sem::input_spec),
            datum("output_spec",    fixed_spec_type, Sem::output_spec, { double(ospec.first), double(ospec.second) }),
            datum("step_precision", integer_type,    Sem::param,       { double(step_prec) }),
            datum("bit_precision",  integer_type,    Sem::param,       { double(bit_prec) }),
        }, {
            datum("clk",        std_logic_type,                                         Sem::clock)        .in(),
            datum("input",      sfixed_type,                                            Sem::main_input)   .in(),
            datum("output",     sfixed_type.with_range(ospec.first - 1, -ospec.second), Sem::main_output)  .out(),
            datum("op_send",    std_logic_type,                                         Sem::sig_out_front)  .out(),
            datum("op_receive", std_logic_type,                                         Sem::sig_in_back).in(),
        }) {}
    virtual void propagate(component& prev)
    {
        datum& input_spec = find_by(generic, Sem::input_spec);
        datum& prev_out = find_by(prev.port, Sem::main_output);
        input_spec.value = { double(prev_out.type.range_high + 1), double(-prev_out.type.range_low) };
        find_by(port, Sem::main_input).type.set_range(prev_out.type.range_high, prev_out.type.range_low);
    }
    virtual string demand_signal(Sem sem)
    {
        datum& d = find_by(port, sem);
        if (d.is_invalid())
            throw runtime_error("sigmoid_op_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
        return d.plugged_signal_name;
    };
};

auto sigmoid_gen = define_component_generator("sigmoid", +[](const unordered_map<string, specification_variant>& params)
{
    auto get = checked_get("component generator")("sigmoid", params);
    return unique_ptr<component>(new sigmoid_op_component(
        pair<int, int>(get("ospec_int"), get("ospec_frac")),
        get("step_prec"),
        get("bit_prec")
    ));
});

auto sigmoid_ac = define_activation_behavior_generator("sigmoid", +[](const unordered_map<string, specification_variant>& params) -> activation_behavior
{
    return [](double input, size_t offset){
        return 1.0 / (1.0 + exp(-input));
    };
});

auto sigmoid_av = define_validity_assertion_generator("sigmoid", +[](const unordered_map<string, specification_variant>& params) -> validity_assertion
{
    return [](size_t offset_width){
        return offset_width;
    };
});

layer_specification sigmoid(pair<int, int> ospec, int step_prec, int bit_prec)
{
    return layer_specification{
        "sigmoid", {
            dyn_param("ospec_int", ospec.first),
            dyn_param("ospec_frac", ospec.second),
            dyn_param("step_prec", step_prec),
            dyn_param("bit_prec", bit_prec),
        }
    };
}

auto sigmoid_parse = define_layer_spec_parser("sigmoid", +[](const sexpr_field& s, const string& pos_info)
{
    if (s.size() != 4)
        throw runtime_error("layer_spec_parser for sigmoid: At " + pos_info + ": Clause expects 3 arguments, not " + to_string(s.size() - 1) + ".");
    layer_specification layer{ "sigmoid", {} };
    pair<int, int> ospec = parse_fixed_pair(s[1], pos_info + ", first argument");
    layer.parameters.emplace("ospec_int", ospec.first);
    layer.parameters.emplace("ospec_frac", ospec.second);
    layer.parameters.emplace("step_prec", parse_integer(s[2], pos_info + ", second argument"));
    layer.parameters.emplace("bit_prec", parse_integer(s[3], pos_info + ", third argument"));
    return move(layer);
});

struct system_str_parts
{
    system_str_parts& operator<<(system& s)
    {
        for (auto&& cur : s.components)
            add_from(cur.get());
        return *this;
    }
private:
    void add_from(component* c)
    {
        if (seen.count(c->name) == 0){
            seen.insert(c->name);
            components += c->component_decl() + '\n';
        }
        signals += c->signals() + '\n';
        instances += c->instance() + '\n';
        if (c->prepended)
            add_from(c->prepended.get());
        if (c->subsystem)
            *this << *c->subsystem.get();
    };
public:
    unordered_set<string> seen;
    string components, signals, instances;
};


struct system_interface
{
    virtual string entity(system& s) = 0;
    virtual string architecture_preface(system& s) = 0;
    virtual string architecture_body(system& s) = 0;
};

using interface_generator = function<unique_ptr<system_interface>(const sexpr&)>;
unordered_map<string, interface_generator> interface_generators;
int define_interface_generator(const string& name, interface_generator igen)
{
    interface_generators.emplace(name, move(igen));
    return 0;
}
unique_ptr<system_interface> generate_interface(const sexpr& s)
{
    if (s.size() < 2 || !s[1].is_leaf())
        throw runtime_error("Interface s-expr is unnamed.");
    auto it = interface_generators.find(s[1].string());
    if (it != interface_generators.end())
        return (it->second)(s);
    else
        throw runtime_error("Could not find an interface with the name \"" + s[1].string() + "\".");
};

struct block_interface : public system_interface
{
    block_interface() {}
    virtual string entity(system& s)
    {
        stringstream ss;
        ss <<
R"(    clk : in std_logic;
    rst : in std_logic;
    start : in std_logic;
    ready : out std_logic;
    ack : in std_logic;
    done : out std_logic;
    in_a : in )" << find_by(s.start()->port, Sem::main_input).type.full_name() << R"(;
    out_a : out )" << find_by(s.last()->port, Sem::main_output).type.full_name();
        return ss.str();
    }
    virtual string architecture_preface(system& s) { return ""; }
    virtual string architecture_body(system& s)
    {
        stringstream ss;
        ss << s.start()->demand_signal(Sem::sig_in_back) << " <= start;\n"
           << "ready <= " << s.start()->demand_signal(Sem::sig_out_back) << ";\n"
           << s.last()->demand_signal(Sem::sig_in_front) << " <= ack;\n"
           << "done <= " << s.last()->demand_signal(Sem::sig_out_front) << ";\n"
           << s.start()->demand_signal(Sem::main_input) << " <= in_a;\n"
           << "out_a <= " << s.last()->demand_signal(Sem::main_output) << ";";
        return ss.str();
    }
};
auto block_int_gen = define_interface_generator("block", +[](const sexpr& s)
{
    return unique_ptr<system_interface>(new block_interface());
});

string to_vec_function_def(system& s)
{
    stringstream ss;
    ss <<
R"(function to_vec(r : reals) return std_logic_vector is
    constant input_spec : fixed_spec := )" << find_by(s.start()->generic, Sem::input_spec).formatted_value() << R"(;
    variable ret : std_logic_vector()" << find_by(s.start()->generic, Sem::input_width).value[0] << R"( * size(input_spec) - 1 downto 0);
begin
    for i in r'range loop
        ret((1 + i) * size(input_spec) - 1 downto i * size(input_spec)) :=
            std_logic_vector(to_sfixed(r(i), mk(input_spec)));
    end loop;
    return ret;
end to_vec;
)";
    return ss.str();
}

struct sim_interface : public system_interface
{
    sim_interface(const vector<double>& test_input)
        : test_input(test_input) {}
    virtual string entity(system& s)
    {
        stringstream ss;
        ss <<
R"(    clk : in std_logic;
    rst : in std_logic;
    start : in std_logic;
    out_a : out )" << find_by(s.last()->port, Sem::main_output).type.full_name();
        return ss.str();
    }
    virtual string architecture_preface(system& s)
    {
        return to_vec_function_def(s);
    }
    virtual string architecture_body(system& s)
    {
        stringstream ss;
        ss << s.start()->demand_signal(Sem::main_input) << " <= to_vec(reals'(";
        for (size_t i = 0, sz = test_input.size(); i < sz; ++i)
            ss << fixed << setprecision(7) << test_input[i] << (i < sz - 1 ? ", " : "");
        ss << "));\n"
           << s.start()->demand_signal(Sem::sig_in_back) << " <= start;\n"
              "out_a <= " << s.last()->demand_signal(Sem::main_output) << ";";
        return ss.str();
    }
    vector<double> test_input;
};
auto sim_int_gen = define_interface_generator("sim", +[](const sexpr& s)
{
    if (s.size() < 3)
        throw runtime_error("sim interface generator: Third argument missing.");
    return unique_ptr<system_interface>(new sim_interface(parse_data(s[2], "sim interface generator")));
});

struct test_interface : public system_interface
{
    test_interface(const vector<double>& test_input)
        : test_input(test_input) {}
    virtual string entity(system& s)
    {
        stringstream ss;
        ss <<
R"(    start : in std_logic;
    test_out : out std_logic_vector(8 - 1 downto 0);
    sel : in unsigned(8 - 1 downto 0))";
        return ss.str();
    }
    virtual string architecture_preface(system& s)
    {
        stringstream ss;
        ss <<
R"(component ps is
port(
    clk, rst : out std_logic
);
end component;

signal clk, rst_sink : std_logic;
constant rst : std_logic := '0';

)" << to_vec_function_def(s);
        return ss.str();
    }
    virtual string architecture_body(system& s)
    {
        stringstream ss;
        ss <<
R"(uPS : ps port map(
    clk => clk,
    rst => rst_sink
);
)";
        ss << s.start()->demand_signal(Sem::main_input) << " <= to_vec(reals'(";
        for (size_t i = 0, sz = test_input.size(); i < sz; ++i)
            ss << fixed << setprecision(7) << test_input[i] << (i < sz - 1 ? ", " : "");
        datum& output_spec = find_by(s.last()->generic, Sem::output_spec);
        datum& output_width = find_by(s.last()->generic, Sem::output_width);
        ss << "));\n"
           << s.start()->demand_signal(Sem::sig_in_back) << " <= start;\n"
              "test_out <= shift_range(std_logic_vector(get(" << s.last()->demand_signal(Sem::main_output) << ", to_integer(sel), mk(" << output_spec.formatted_value() << "))), " << int(output_spec.value[1]) << ")(test_out'range) when to_integer(sel) < " << size_t(output_width.value[0]) << R"( else "00000000";)";
        return ss.str();
    }
    vector<double> test_input;
};
auto test_int_gen = define_interface_generator("test", +[](const sexpr& s)
{
    if (s.size() < 3)
        throw runtime_error("test interface generator: Third argument missing.");
    return unique_ptr<system_interface>(new test_interface(parse_data(s[2], "test interface generator")));
});

system_str_parts process(system& sys, size_t input_width, pair<int, int> input_spec)
{
    sys.push_front(make_unique<component>("DUMMY", "DUMMY", vector<datum>{
        datum("output_width", integer_type,    Sem::output_width, { double(input_width) }),
        datum("output_spec",  fixed_spec_type, Sem::output_spec,  { double(input_spec.first), double(input_spec.second) }),
    }, vector<datum>{
        datum("output", sfixed_type.with_range(input_width * (input_spec.first + input_spec.second), 0), Sem::main_output),
    }));
    sys.propagate();
    sys.pop_front();
    sys.propagate();
    system_str_parts res;
    res << sys;
    return move(res);
}

string generate_code_from(system& sys, system_str_parts parts, system_interface& interface)
{
    stringstream ss;
    ss << R"(use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity system is
port(
)" << interface.entity(sys) << R"(
);
end system;

architecture system of system is

)" << parts.components << '\n' << parts.signals << '\n' << interface.architecture_preface(sys) << R"(
begin

)" << parts.instances << '\n' << sys.chain_main() << '\n' << interface.architecture_body(sys) << R"(
end system;
)";
    return ss.str();
}


string gen_code(const system_specification& ssp, system_interface& interf)
{
    if (ssp.parts.empty())
        throw runtime_error("gen_code: System specification is empty.");
    system built;
    for (const layer_specification& layer : ssp.parts)
        built.push_back(component_from_specification(layer));
    return generate_code_from(built, process(built, ssp.input_width, ssp.input_spec), interf);
}

function<vector<double>(vector<double>)> gen_feedforward(const system_specification& ssp)
{
    if (ssp.parts.empty())
        throw runtime_error("gen_feedforward: System specification is empty.");
    vector<function<vector<double>(vector<double>)>> net;
    for (const layer_specification& layer : ssp.parts)
        net.push_back(feedforward_behavior_from_specification(layer));
    return [net = move(net), insz = ssp.input_width](vector<double> vec){
        if (vec.size() != insz)
            throw runtime_error("Trying to feedforward wrong number of inputs (" + to_string(insz) + " expected, " + to_string(vec.size()) + " given).");
        for (auto&& layer : net)
            vec = layer(move(vec));
        return move(vec);
    };
}

size_t assert_valid(const system_specification& ssp)
{
    size_t prev_width = ssp.input_width;
    for (const layer_specification& layer : ssp.parts)
        prev_width = validity_assertion_from_specification(layer)(prev_width);
    return prev_width;
}

size_t substitute_macro(sexpr_field& target, sexpr& target_parent, size_t target_index, const string& label, const sexpr_field& body)
{
    if (target.is_leaf()){
        if (target.string() == '$' + label)
            target = body;
        else if (target.string() == '@' + label){
            target_parent.fields.erase(target_parent.fields.begin() + target_index);
            if (body.is_leaf())
                target_parent.fields.insert(target_parent.fields.begin() + target_index, body);
            else
                target_parent.fields.insert(target_parent.fields.begin() + target_index, body.sexpr().fields.begin(), body.sexpr().fields.end());
            return body.is_tree() ? body.size() : 1;
        }
    } else {
        sexpr& s = target.sexpr();
        for (size_t i = 0, stride; i < s.size(); i += stride)
            stride = substitute_macro(s[i], s, i, label, body);
    }
    return 1;
}

bool parse_macro(sexpr& s, size_t i, const string& src_path)
{
    if (s[i][0].string() == "define"){
        if (s[i].size() != 3 || s[i][1].is_tree())
            throw runtime_error("parse: For top[" + to_string(i) + "] macro definition: Invalid format (needs a name plus one arbitrary field).");
        for (size_t j = i + 1, stride; j < s.size(); j += stride)
            stride = substitute_macro(s[j], s, j, s[i][1].string(), s[i][2]);
    } else if (s[i][0].string() == "import"){
        if (s[i].size() != 3 || s[i][1].is_tree() || s[i][2].is_tree())
            throw runtime_error("parse: For top[" + to_string(i) + "] macro importation: Invalid format (needs a name plus a file path).");
        for (size_t j = i + 1, stride; j < s.size(); j += stride)
            stride = substitute_macro(s[j], s, j, s[i][1].string(), sexpr_field(sexpr::read_file(path_relative_to(s[i][2].string(), src_path))));
    } else
        return false;
    return true;
}

template<typename Specific>
void top_level_parse(const string& caller, const string& preface, sexpr& s, const string& src_path, Specific&& specific)
{
    if (s.empty())
        throw runtime_error(caller + ": Top s-expression is empty.");
    if (s[0].is_tree() || s[0].string() != preface)
        throw runtime_error(caller + ": Wrong format (\"" + preface + "\" preface missing).");
    for (size_t i = 1; i < s.size(); ++i){
        if (s[i].is_leaf())
            continue;
        if (s[i].empty())
            throw runtime_error(caller + ": Stray empty s-expression encountered at top[" + to_string(i) + "].");
        if (s[i][0].is_tree())
            throw runtime_error(caller + ": Unnamed s-expression at top[" + to_string(i) + "].");
        if (!specific(i) && !parse_macro(s, i, src_path))
            throw runtime_error(caller + ": Unknown s-expression with name \"" + s[0][0].string() + "\" at top[" + to_string(i) + "].");
    }
}

vector<system_specification> parse(sexpr s, const string& src_path = "./")
{
    vector<system_specification> res;
    top_level_parse("parse", "nnet-codegen", s, src_path, [&](size_t i){
        if (s[i][0].string() == "network"){
            if (s[i].size() == 1 || s[i][1].is_leaf() || s[i][1].empty() || s[i][1][0].is_tree() || s[i][1][0].string() != "input")
                throw runtime_error("parse: Missing input specification at beginning of top[" + to_string(i) + "] network.");
            if (s[i][1].size() != 3)
                throw runtime_error("parse: Input specification at beginning of top[" + to_string(i) + "] network needs 2 arguments (not " + to_string(s[0][1].size() - 1) + ").");
            res.emplace_back();
            res.back().input_width = parse_positive_integer(s[i][1][1], "first argument of input of top[" + to_string(i) + "] network");
            res.back().input_spec = parse_fixed_pair(s[i][1][2], "second argument of input of top[" + to_string(i) + "] network");
            for (size_t j = 2; j < s[i].size(); ++j){
                if (s[i][j].is_leaf() || s[i][j].empty() || s[i][j][0].is_tree())
                    throw runtime_error("parse: For top[" + to_string(i) + "] network: Argument " + to_string(j - 1) + " is not a layer.");
                string pos_info = "top[" + to_string(i) + "] network, layer " + to_string(j);
                res.back().parts.push_back(layer_spec_parser_from_name(s[i][j][0].string(), pos_info)(s[i][j], pos_info));
            }
        } else
            return false;
        return true;
    });
    return move(res);

//    if (s.empty())
//        throw runtime_error("parse: Top s-expression is empty.");
//    if (s[0].is_tree() || s[0].string() != "nnet-codegen")
//        throw runtime_error("parse: Wrong format (\"nnet-codegen\" preface missing).");
//    vector<system_specification> res;
//    for (size_t i = 1; i < s.size(); ++i){
//        if (s[i].is_leaf())
//            continue;
//        if (s[i].empty())
//            throw runtime_error("parse: Stray empty s-expression encountered at top[" + to_string(i) + "].");
//        if (s[i][0].is_tree())
//            throw runtime_error("parse: Unnamed s-expression at top[" + to_string(i) + "].");
//        if (s[i][0].string() == "network"){
//            if (s[i].size() == 1 || s[i][1].is_leaf() || s[i][1].empty() || s[i][1][0].is_tree() || s[i][1][0].string() != "input")
//                throw runtime_error("parse: Missing input specification at beginning of top[" + to_string(i) + "] network.");
//            if (s[i][1].size() != 3)
//                throw runtime_error("parse: Input specification at beginning of top[" + to_string(i) + "] network needs 2 arguments (not " + to_string(s[0][1].size() - 1) + ").");
//            res.emplace_back();
//            res.back().input_width = parse_positive_integer(s[i][1][1], "first argument of input of top[" + to_string(i) + "] network");
//            res.back().input_spec = parse_fixed_pair(s[i][1][2], "second argument of input of top[" + to_string(i) + "] network");
//            for (size_t j = 2; j < s[i].size(); ++j){
//                if (s[i][j].is_leaf() || s[i][j].empty() || s[i][j][0].is_tree())
//                    throw runtime_error("parse: For top[" + to_string(i) + "] network: Argument " + to_string(j - 1) + " is not a layer.");
//                string pos_info = "top[" + to_string(i) + "] network, layer " + to_string(j);
//                res.back().parts.push_back(layer_spec_parser_from_name(s[i][j][0].string(), pos_info)(s[i][j], pos_info));
//            }
//        } else if (!parse_macro(s, i, src_path))
//            throw runtime_error("parse: Unknown s-expression with name \"" + s[0][0].string() + "\" at top[" + to_string(i) + "].");
//    }
//    return move(res);
}

//sexpr parse_interface(sexpr s, const string& src_path = "./")
//{
//    sexpr res;
//    top_level_parse("parse-interface", "int-codegen", s, src_path, [&](size_t i){
//        if (s[i][0].string() == "interface"){
//            if (s[i].size() == 1 || (s[i].size() > 1 && !s[i][1].is_leaf()))
//                throw runtime_error("parse_interface: Interface declaration at top[" + to_string(i) + "] is missing a name.");
//            res = s[i].sexpr();
//        } else
//            return false;
//        return true;
//    });
//    if (res.empty())
//        throw runtime_error("parse_interface: Could not find an interface declaration in the interface file \"" + src_path + "\".");
//    return move(res);
//}

}
