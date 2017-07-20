#include "interlayer.h"

#include <type_traits>

#include "dummy.h"

#include "fc_layer.h"
#include "fcbin_layer.h"
#include "conv2d_layer.h"

#include "fc_to_fc_interlayer.h"
#include "fc_to_fcbin_interlayer.h"
#include "fcbin_to_fc_interlayer.h"
#include "fcbin_to_fcbin_interlayer.h"
#include "bram_pad_interlayer.h"
#include "conv_to_fc_interlayer.h"

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
    interlayer_map.emplace(idid(id<conv2d_family_layer_component>(), id<conv2d_family_layer_component>()), +[](layer_component* a, layer_component* b)
    {
        auto* bb = dynamic_cast<conv2d_family_layer_component*>(b);
        return unique_ptr<component>(new bram_pad_interlayer(
            find_by(b->generic, Sem::input_width, "channels").value[0],
            find_by(b->generic, Sem::input_spec_int).value[0] + find_by(b->generic, Sem::input_spec_frac).value[0],
            bb->zero_padding,
            bb->input_size_before_padding
        ));
    });
    interlayer_map.emplace(idid(id<dummy_layer>(), id<conv2d_family_layer_component>()), +[](layer_component* a, layer_component* b)
    {
        auto* bb = dynamic_cast<conv2d_family_layer_component*>(b);
        return unique_ptr<component>(new bram_pad_interlayer(
            find_by(b->generic, Sem::input_width, "channels").value[0],
            find_by(b->generic, Sem::input_spec_int).value[0] + find_by(b->generic, Sem::input_spec_frac).value[0],
            bb->zero_padding,
            bb->input_size_before_padding
        ));
    });
    interlayer_map.emplace(idid(id<conv2d_family_layer_component>(), id<fc_layer_component>()), +[](layer_component* a, layer_component* b)
    {
        auto n_out_filters_of = [&](auto&& comp) -> datum& {
            if (datum& prev_filter_nb = find_by(comp.generic, Sem::param, "filter_nb"))
                return prev_filter_nb;
            else if (datum& prev_channels = find_by(comp.generic, Sem::input_width, "channels"))
                return prev_channels;
            else
                return invalid_datum;
        };
        return unique_ptr<component>(new conv_to_fc_interlayer(
            n_out_filters_of(*a).value[0],
            find_by(a->generic, Sem::output_spec_int).value[0] + find_by(a->generic, Sem::output_spec_frac).value[0],
            true,
            find_by(a->generic, Sem::output_width).value[0],
            find_by(b->generic, Sem::param, "simd_width").value[0]
        ));
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
