/// Author: Gabriel Demers
/// Generates a VHDL file from a specification of a fixed-point neural network.

#include <string>
#include <vector>
#include <functional>
#include <sstream>
#include <cmath>
#include <unordered_set>
#include <algorithm>
#include <iomanip>

namespace gen
{
using namespace std;

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
    datum(string name, data_type type, Sem sem, initializer_list<double> value) : name(move(name)), type(move(type)), sem(sem), value(move(value)) {}
    datum(string name, data_type type, Sem sem, vector<double> value) : name(move(name)), type(move(type)), sem(sem), value(move(value)) {}
    datum(string name, data_type type, Sem sem, string value) : name(move(name)), type(move(type)), sem(sem), value(move(value)) {}
    string generic_decl() { return name + " : " + type.full_name(); }
    string port_decl() { return name + " : " + (is_in ? "in " : "out ") + type.full_name(); }
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
    //component* prev, * next;
    unique_ptr<component> prepended;
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
    component* cur = start();
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
        op_arg_spec.value = { prevspec[0] + weight_spec.value[0] + prevwidth / size_t(simd_width.value[0]) + ceil(log2(simd_width.value[0])),
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
               << demand_signal(Sem::side_input) << " <= " << last->demand_signal(Sem::main_output) << ";\n"
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

struct system_specification
{
    system sys;
    size_t input_width;
    pair<int, int> input_spec;
};

system_str_parts process(system_specification& s)
{
    s.sys.push_front(make_unique<component>("DUMMY", "DUMMY", vector<datum>{
        datum("output_width", integer_type,    Sem::output_width, { double(s.input_width) }),
        datum("output_spec",  fixed_spec_type, Sem::output_spec,  { double(s.input_spec.first), double(s.input_spec.second) }),
    }, vector<datum>{
        datum("output", sfixed_type.with_range(s.input_width * (s.input_spec.first + s.input_spec.second), 0), Sem::main_output),
    }));
    s.sys.propagate();
    s.sys.pop_front();
    s.sys.propagate();
    system_str_parts res;
    res << s.sys;
    return move(res);
}

string generate_from(system& sys, system_str_parts parts, system_interface& interface)
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

auto spec(int int_part, int frac_part)
{
    return make_pair(int_part, frac_part);
}

auto input(size_t input_width, pair<int, int> input_spec)
{
    return system_specification{ system(), input_width, input_spec };
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

struct Simd { size_t simd_width; };
auto simd(size_t simd_width)
{
    return Simd{ simd_width };
}

auto fc(Output o, Weights w, Simd s, system side_path)
{
    unique_ptr<component> ret(new fc_layer_component(o.output_width, o.output_spec, move(w.w), w.w_spec, s.simd_width));
    if (!side_path.components.empty())
        ret->subsystem = make_unique<system>(move(side_path));
    return move(ret);
}

auto neuron()
{
    return system();
}

auto bias(const vector<double>& b, pair<int, int> b_spec)
{
    return unique_ptr<component>(new bias_op_component(b, b_spec));
}

auto sigmoid(pair<int, int> ospec, int step_prec, int bit_prec)
{
    return unique_ptr<component>(new sigmoid_op_component(ospec, step_prec, bit_prec));
}

system operator|(system&& sys, unique_ptr<component> c)
{
    sys.push_back(move(c));
    return move(sys);
}

system_specification operator|(system_specification&& ssp, unique_ptr<component> c)
{
    ssp.sys.push_back(move(c));
    return move(ssp);
}

string eval(system_specification& ssp, system_interface& interf)
{
    string res = generate_from(ssp.sys, process(ssp), interf);
    return move(res);
}

}
