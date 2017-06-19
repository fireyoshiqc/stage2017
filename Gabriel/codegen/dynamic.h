#pragma once

#include <unordered_map>
#include <string>

#include "component.h"

namespace gen
{
using namespace std;

inline auto checked_get(const string& caller_type)
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
inline auto generator_definer(unordered_map<string, Contained>& cont)
{
    return [&](const string& name, Contained cgen){
        cont.emplace(name, cgen);
        return 0;
    };
}
template<typename Contained>
inline auto from_specification(unordered_map<string, Contained>& cont, const string& subject)
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
inline layer_spec_parser layer_spec_parser_from_name(const string& name, const string& pos_info)
{
    auto it = layer_spec_parsers.find(name);
    if (it != layer_spec_parsers.end())
        return it->second;
    else
        throw runtime_error("layer_spec_parser_from_name: At " + pos_info + ": Can't find parser for layer type \"" + name + "\".");
};

} //namespace gen
