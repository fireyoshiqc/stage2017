#include "pool_layer.h"

namespace gen
{
using namespace std;
using namespace util;

conv2d_family_layer_component::conv2d_family_layer_component(string name, string instance_name, vector<datum> generic, vector<datum> port, const string& padding_previous)
        : layer_component(typeid(decay_t<decltype(*this)>), move(name), move(instance_name), move(generic), move(port)), padding_previous(padding_previous) {}

void conv2d_family_layer_component::propagate(component& prev)
{
    auto prevspec = [&]{
        datum& prevspec_int = find_by(prev.generic, Sem::output_spec_int),
             & prevspec_frac = find_by(prev.generic, Sem::output_spec_frac);
        if (prevspec_int.is_invalid() || prevspec_frac.is_invalid()){
            datum& inputspec_int = find_by(generic, Sem::input_spec_int),
                 & inputspec_frac = find_by(generic, Sem::input_spec_frac);
            if (inputspec_int.is_invalid() || inputspec_frac.is_invalid() || inputspec_int.value.num.empty() || inputspec_int.value.num.empty())
                throw runtime_error("conv2d_family_layer_component: Can't deduce (from previous layer) nor find (from self) input fixed-point spec.");
            return make_pair(inputspec_int.value[0], inputspec_frac.value[0]);
        }
        find_by(generic, Sem::input_spec_int).value.num = prevspec_int.value.num;
        find_by(generic, Sem::input_spec_frac).value.num = prevspec_frac.value.num;
        datum& curspec_int = find_by(generic, Sem::output_spec_int);
        if (curspec_int.is_invalid()){
            generic.push_back(datum(prevspec_int.name, prevspec_int.type, Sem::input_spec_int, { prevspec_int.value[0] }).hide());
            generic.push_back(datum(prevspec_frac.name, prevspec_frac.type, Sem::input_spec_frac, { prevspec_frac.value[0] }).hide());
            generic.push_back(datum(prevspec_int.name, prevspec_int.type, Sem::output_spec_int, { prevspec_int.value[0] }).hide());
            generic.push_back(datum(prevspec_frac.name, prevspec_frac.type, Sem::output_spec_frac, { prevspec_frac.value[0] }).hide());
        }
        return make_pair(prevspec_int.value[0], prevspec_frac.value[0]);
    }();

    input_size_before_padding = find_by(prev.generic, Sem::output_width, "output_size").value[0];
    auto n_out_filters_of = [&](auto&& comp) -> datum& {
        if (datum& prev_filter_nb = find_by(comp.generic, Sem::param, "filter_nb"))
            return prev_filter_nb;
        else if (datum& prev_channels = find_by(comp.generic, Sem::input_width, "channels"))
            return prev_channels;
        else
            return invalid_datum;
    };
    double n_channels = (find_by(generic, Sem::input_width, "channels").value.num = [&]{
        if (datum& n_out_filters_of_prev = n_out_filters_of(prev))
            return n_out_filters_of_prev.value.num;
        else
            throw runtime_error("conv2d_family_layer_component: Can't find deduce value for number of input channels from previous layer (should have param \"filter_nb\" or \"channels\").");
    }())[0];
    int stride = find_by(generic, Sem::param, "stride").value[0], filter_size = find_by(generic, Sem::param, "filter_size").value[0];
    zero_padding = [&]() -> size_t {
        if (padding_previous == "same")
            return (input_size_before_padding * (stride - 1) + filter_size - 1) / 2;
        else if (padding_previous == "valid")
            return 0;
        else
            throw runtime_error("conv2d_family_layer_component: Unknown padding specification \"" + padding_previous + "\".");
    }();
    size_t input_size = input_size_before_padding + 2 * zero_padding;
    find_by(generic, Sem::input_width, "input_size").value.num = { double(input_size) };
    find_by(port, Sem::main_input).type.set_range(n_channels * (prevspec.first + prevspec.second) - 1, 0);
    find_by(port, Sem::back_offset_outtake).type.set_range(clogb2(round_to_next_two(pow(input_size, 2))) - 1, 0);
    int conv_res_size = (input_size - filter_size) / stride + 1;
    find_by(port, Sem::front_offset_outtake).type.set_range(clogb2(round_to_next_two(pow(conv_res_size, 2))) - 1, 0);
    find_by(port, Sem::special_output_conv_row).type.set_range(clogb2(round_to_next_two(conv_res_size)) - 1, 0);
    find_by(generic, Sem::output_width).value.num = { double(conv_res_size) };
    datum& out_port = find_by(port, Sem::main_output);
    if (!out_port.type.range_specified)
        out_port.type.set_range(n_out_filters_of(*this).value[0] * (find_by(generic, Sem::output_spec_int).value[0] + find_by(generic, Sem::output_spec_frac).value[0]) - 1, 0);
    datum& wren_port = find_by(port, Sem::special_output_conv_wren);
    if (!wren_port.type.range_specified)
        wren_port.type.set_range(n_out_filters_of(*this).value[0] - 1, 0);
    prepended = interlayer_between(static_cast<layer_component*>(&prev), this);
}

string conv2d_family_layer_component::demand_signal(Sem sem)
{
    switch (sem){
    case Sem::main_input:
        return prepended->demand_signal(Sem::main_input);
    case Sem::main_output:
        return find_by(port, Sem::main_output).plugged_signal_name;
    case Sem::sig_out_back:
        return find_by(port, Sem::sig_out_back, "load_done").plugged_signal_name;
    case Sem::sig_out_front:
        return find_by(port, Sem::sig_out_front).plugged_signal_name;
    case Sem::sig_in_back:
        return prepended->demand_signal(Sem::sig_in_back);
    case Sem::sig_in_front:
        return find_by(port, Sem::sig_in_front).plugged_signal_name;
    case Sem::back_offset_intake:
        return prepended->demand_signal(Sem::back_offset_intake);
    case Sem::front_offset_outtake:
        return find_by(port, Sem::front_offset_outtake).plugged_signal_name;
    case Sem::special_input_conv_row:
        return prepended->demand_signal(Sem::special_input_conv_row);
    case Sem::special_input_conv_wren:
        return prepended->demand_signal(Sem::special_input_conv_wren);
    case Sem::special_output_conv_row:
        return find_by(port, Sem::special_output_conv_row).plugged_signal_name;
    case Sem::special_output_conv_wren:
        return find_by(port, Sem::special_output_conv_wren).plugged_signal_name;
    default:
        throw runtime_error("conv2d_family_layer_component can't produce port signal with semantics code " + to_string(static_cast<int>(sem)) + ".");
    }
};

string conv2d_family_layer_component::chain_internal()
{
    stringstream ss;
    ss << prepended->demand_signal(Sem::sig_in_front) << " <= " << find_by(port, Sem::sig_out_back).plugged_signal_name << ";\n"
       << prepended->demand_signal(Sem::front_offset_intake) << " <= " << find_by(port, Sem::back_offset_outtake).plugged_signal_name << ";\n"
       << find_by(port, Sem::sig_in_back).plugged_signal_name << " <= " << prepended->demand_signal(Sem::sig_out_front) << ";\n"
       << find_by(port, Sem::main_input).plugged_signal_name << " <= " << prepended->demand_signal(Sem::main_output) << ";\n";
    return ss.str();
}

} //namespace gen
