#pragma once

#include "util.h"
#include "specification.h"
#include "dynamic.h"

namespace gen
{
using namespace std;
using namespace util;

pair<int, int> parse_fixed_pair(const sexpr_field& s, const string& pos_info);
int parse_bits(const sexpr_field& s, const string& pos_info);
size_t parse_positive_integer(const sexpr_field& s, const string& pos_info);
int parse_integer(const sexpr_field& s, const string& pos_info);
double parse_double(const sexpr_field& s, const string& pos_info);
vector<double> parse_data(const sexpr_field& s, const string& pos_info);
size_t substitute_macro(sexpr_field& target, sexpr& target_parent, size_t target_index, const string& label, const sexpr_field& body);
bool parse_macro(sexpr& s, size_t i, const string& src_path);

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

vector<system_specification> parse(sexpr s, const string& src_path = "./");
sexpr parse_interface(sexpr s, const string& src_path = "./");

} //namespace gen
