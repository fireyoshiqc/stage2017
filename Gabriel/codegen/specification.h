#pragma once

#include <vector>
#include <string>
#include <stdexcept>
#include <unordered_map>
#include <memory>

namespace gen
{
using namespace std;

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
    size_t input_channels = 1;
};

inline system_specification input(size_t input_width, pair<int, int> input_spec)
{
    return system_specification{ vector<layer_specification>{}, input_width, input_spec };
}

inline system_specification neuron()
{
    return system_specification{};
}

inline auto spec(int int_part, int frac_part)
{
    return make_pair(int_part, frac_part);
}
inline auto int_pair(int a, int b)
{
    return make_pair(a, b);
}

struct Output { size_t output_width; pair<int, int> output_spec; };
struct BinOutput { size_t output_width; };
inline auto output(size_t output_width, pair<int, int> output_spec)
{
    return Output{ output_width, output_spec };
}
inline auto output(size_t output_width)
{
    return BinOutput{ output_width };
}

struct Weights { vector<double> w; pair<int, int> w_spec; };
struct BinWeights { vector<bool> w; };
inline auto weights(const vector<double>& w, pair<int, int> w_spec)
{
    return Weights{ w, w_spec };
}
inline auto weights(const vector<bool>& w)
{
    return BinWeights{ w };
}

struct Biases { vector<int> b; };
inline auto biases(const vector<int>& b)
{
    return Biases{ b };
}

auto weights(const vector<vector<double>>& w2d, pair<int, int> w_spec);

struct Simd { size_t simd_width; };
inline auto simd(size_t simd_width)
{
    return Simd{ simd_width };
}

inline system_specification operator|(system_specification sys, layer_specification&& ls)
{
    sys.parts.push_back(move(ls));
    return move(sys);
}
inline system_specification operator|(system_specification sys, const layer_specification& ls)
{
    sys.parts.push_back(ls);
    return move(sys);
}

} //namespace gen
