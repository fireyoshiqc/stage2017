#include "dynamic.h"

namespace gen
{
using namespace std;
using namespace util;

unordered_map<string, component_generator>& component_generators() { static auto x = unordered_map<string, component_generator>(); return x; }
unordered_map<string, feedforward_behavior_generator>& feedforward_behavior_generators() { static auto x = unordered_map<string, feedforward_behavior_generator>(); return x; }
unordered_map<string, activation_behavior_generator>& activation_behavior_generators() { static auto x = unordered_map<string, activation_behavior_generator>(); return x; }
unordered_map<string, validity_assertion_generator>& validity_assertion_generators() { static auto x = unordered_map<string, validity_assertion_generator>(); return x; }
unordered_map<string, layer_spec_parser>& layer_spec_parsers() { static auto x = unordered_map<string, layer_spec_parser>(); return x; }

} //namespace gen
