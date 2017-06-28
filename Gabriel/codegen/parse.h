#pragma once

#include "util.h"

namespace gen
{
using namespace std;

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
int parse_bits(const sexpr_field& s, const string& pos_info)
{
    if (s.is_leaf() || s.size() != 2 || s[0].is_tree() || s[0].string() != "bits" || s[1].is_tree())
        throw runtime_error("parse_bits: At " + pos_info + ": Wrong format for \"bits\" fiels (Name \"bits\" + 1 positive integer argument expected).");
    int res;
    try {
        res = stoi(s[1].string());
        if (res <= 0)
            throw runtime_error("parse_bits: At " + pos_info + ": Value should be positive.");
    } catch (exception&){
        throw runtime_error("parse_bits: At " + pos_info + ": Value has invalid format.");
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
}

sexpr parse_interface(sexpr s, const string& src_path = "./")
{
    sexpr res;
    top_level_parse("parse-interface", "int-codegen", s, src_path, [&](size_t i){
        if (s[i][0].string() == "interface"){
            if (s[i].size() == 1 || (s[i].size() > 1 && !s[i][1].is_leaf()))
                throw runtime_error("parse_interface: Interface declaration at top[" + to_string(i) + "] is missing a name.");
            res = s[i].sexpr();
        } else
            return false;
        return true;
    });
    if (res.empty())
        throw runtime_error("parse_interface: Could not find an interface declaration in the interface file \"" + src_path + "\".");
    return move(res);
}

} //namespace gen
