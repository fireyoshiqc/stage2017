#include "interlayer.h"

#include <type_traits>

#include "dummy.h"

#include "fc_layer.h"
#include "fcbin_layer.h"

#include "fc_to_fc_interlayer.h"
#include "fc_to_fcbin_interlayer.h"
#include "fcbin_to_fc_interlayer.h"
#include "fcbin_to_fcbin_interlayer.h"

namespace gen
{
using namespace std;

template<typename T, enable_if_t<is_base_of<layer_component, T>::value>* = nullptr>
uint8_t id() { return layer_component::id_of(typeid(T)); };

uint16_t idid(uint8_t id1, uint8_t id2) { return uint16_t(id1) | (uint16_t(id2) << 8); }

auto define_interlayers()
{
    unordered_map<uint16_t, unique_ptr<component>(*)(layer_component*, layer_component*)> interlayer_map;
    interlayer_map.emplace(idid(id<fc_layer_component>(), id<fc_layer_component>()), +[](layer_component* a, layer_component* b)
    {
        auto prev_spec = find_by(a->generic, Sem::output_spec).value.num;
        return unique_ptr<component>(new fc_to_fc_interlayer(int(find_by(a->generic, Sem::output_width).value[0]), pair<int, int>(prev_spec[0], prev_spec[1])));
    });
    interlayer_map.emplace(idid(id<fc_layer_component>(), id<fcbin_layer_component>()), +[](layer_component* a, layer_component* b)
    {
        auto prev_spec = find_by(a->generic, Sem::output_spec).value.num;
        return unique_ptr<component>(new fc_to_fcbin_interlayer(int(find_by(a->generic, Sem::output_width).value[0]), pair<int, int>(prev_spec[0], prev_spec[1])));
    });
    interlayer_map.emplace(idid(id<fcbin_layer_component>(), id<fc_layer_component>()), +[](layer_component* a, layer_component* b)
    {
        auto prev_spec = find_by(b->generic, Sem::input_spec).value.num;
        return unique_ptr<component>(new fcbin_to_fc_interlayer(int(find_by(b->generic, Sem::input_width).value[0]), pair<int, int>(prev_spec[0], prev_spec[1])));
    });
    interlayer_map.emplace(idid(id<dummy_layer>(), id<fc_layer_component>()), +[](layer_component* a, layer_component* b)
    {
        auto prev_spec = find_by(a->generic, Sem::output_spec).value.num;
        return unique_ptr<component>(new fc_to_fc_interlayer(int(find_by(a->generic, Sem::output_width).value[0]), pair<int, int>(prev_spec[0], prev_spec[1])));
    });
    interlayer_map.emplace(idid(id<dummy_layer>(), id<fcbin_layer_component>()), +[](layer_component* a, layer_component* b)
    {
        return unique_ptr<component>(new fcbin_to_fcbin_interlayer(int(find_by(a->generic, Sem::output_width).value[0])));
    });
    interlayer_map.emplace(idid(id<fcbin_layer_component>(), id<fcbin_layer_component>()), +[](layer_component* a, layer_component* b)
    {
        return unique_ptr<component>(new fcbin_to_fcbin_interlayer(int(find_by(a->generic, Sem::output_width).value[0])));
    });
    return move(interlayer_map);
}

auto& interlayer_get(uint8_t id1, uint8_t id2)
{
    static auto interlayer_map = define_interlayers();
    return interlayer_map[idid(id1, id2)];
}

unique_ptr<component> interlayer_between(layer_component* a, layer_component* b)
{
    return interlayer_get(a->get_id(), b->get_id())(a, b);
}

} //namespace gen
