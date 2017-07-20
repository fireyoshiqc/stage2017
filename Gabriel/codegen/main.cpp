/// this code is meant to be compiled with C++14 (-std=c++14)

#include <vector>
#include <fstream>
#include <stdexcept>
#include <iostream>

using namespace std;

#include "gen.h"
#include "fc_layer.h"
#include "bias_op.h"
#include "sigmoid_op.h"
#include "block_interface.h"
#include "sim_interface.h"
#include "test_interface.h"
#include "feed_interface.h"

using namespace gen;
using namespace util;

//#define COMPILED_AS_TOOL

#ifdef COMPILED_AS_TOOL

#include <string>
#include <iostream>
#include <tuple>
#include <unordered_map>

void help()
{
    cout << R"(usage: nngen [<options>] <source>
             [-g [<interface-file> <dest-file>]...]
             [-f [<data-file> <dest-file>]...]

The following options are available:
   -h (--help): Display this text.
   -d (--direct): <source> is itself a string containing the network
                  description.
If -d is absent, then <source> is the path to a file containing the network
description.

The following actions can be undertaken:
   -g (--generate): Generates a VHDL file implementing the fixed-point neural
                    network(s) described by <source> using interface(s) given
                    in the <interface-file>(s) and writes the result(s) to the
                    <dest-file>(s).
   -f (--feedforward): Feedforwards some data through the (floating point)
                       network described by source. <data-file> is a file
                       containing the inputs and <dest-file> is the destination
                       file where the outputs are written (1 line = output of 1
                       network).
<dest-file> can alternatively take the following values:
    _ : Discard the code for that network.
    * : Send the generated code to stdout.

example: nngen -h my-network.nn -g my-interf1.int * my-interf2.int system.vhd
               -f inputs1.txt result1.txt inputs2.txt _
         Assuming my-network.nn contains 3 networks, this command:
         - Displays this text.
         - Generates VHDL code (with my-interf1.int interface) for the first
           network and sends it to stdout.
         - Generates VHDL code (with my-interf2.int interface) for the second
           network and writes it to a file named "system.vhd".
         - Ignores the third network.
         - Feedforwards values located in inputs1.txt and stores the results
           in result1.txt.
         - Ignores the second and third networks.
)";
}

enum opt_t { opt_help, opt_direct, opt_SIZE };
unordered_map<string, opt_t> opt_map = {
    {"h", opt_help}, {"help", opt_help},
    {"d", opt_direct}, {"direct", opt_direct},
};

tuple<vector<bool>, size_t> options(const vector<string>& opts)
{
    vector<bool> optvec(opt_SIZE, false);
    size_t i = 0;
    for (; i < opts.size(); ++i)
        if (opts[i].empty() || opts[i][0] != '-')
            break;
        else if (opts[i].size() > 1 && opts[i][1] == '-'){
            auto it = opt_map.find(opts[i].substr(2));
            if (it != opt_map.end())
                optvec[it->second] = true;
            else
                cerr << "Unknown option \"" << opts[i].substr(2) << "\" ignored.\n";
        } else
            for (size_t j = 1; j < opts[i].size(); ++j){
                auto it = opt_map.find(string(1, opts[i][j]));
                if (it != opt_map.end())
                    optvec[it->second] = true;
                else
                    cerr << "Unknown option '" << opts[i][j] << "' ignored.\n";
            }
    return make_tuple(move(optvec), i);
}

int main(int argc, char* argv[])
{
    vector<string> args; args.reserve(argc - 1);
    for (int i = 1; i < argc; ++i)
        args.push_back(argv[i]);
    vector<bool> opt; size_t sourcep;
    tie(opt, sourcep) = options(args);
    if (args.empty() || opt[opt_help]){
        help();
        return 0;
    }
    if (sourcep == args.size()){
        cerr << "Source missing from arguments.\n";
        help();
        return 1;
    }
    try {
        auto networks = parse(!opt[opt_direct] ? sexpr::read_file(args[sourcep]) : sexpr::read(args[sourcep]));
        for (size_t i = 0; i < args.size(); ++i)
            if (args[i] == "-g" || args[i] == "--generate"){
                ++i;
                unique_ptr<system_interface> interface = nullptr;
                for (size_t curnet = 0; i < args.size(); ++i)
                    if (args[i].empty() || args[i][0] == '-'){
                        ++i;
                        break;
                    } else if (interface == nullptr){
                        interface = generate_interface(parse_interface(sexpr::read_file(args[i])));
                    } else {
                        if (args[i] != "_"){
                            if (args[i] == "*")
                                cout << gen_code(networks[curnet], *interface);
                            else {
                                ofstream outfile(args[i], ios::trunc);
                                if (!outfile.is_open())
                                    throw runtime_error("Can't open file \"" + args[i] + "\".");
                                outfile << gen_code(networks[curnet], *interface);
                            }
                        }
                        ++curnet;
                        interface = nullptr;
                    }
                --i;
            } else if (args[i] == "-f" || args[i] == "--feedforward"){
                ++i;
                vector<double> inputs; bool got_inputs = false;
                for (size_t curnet = 0; i < args.size(); ++i)
                    if (args[i].empty() || args[i][0] == '-'){
                        ++i;
                        break;
                    } else if (!got_inputs){
                        inputs = read_data(args[i]);
                        got_inputs = true;
                    } else {
                        if (args[i] != "_"){
                            if (args[i] == "*")
                                for (double d : gen_feedforward(networks[curnet])(inputs))
                                    cout << d << ' ';
                            else {
                                ofstream outfile(args[i], ios::trunc);
                                if (!outfile.is_open())
                                    throw runtime_error("Can't open file \"" + args[i] + "\".");
                                for (double d : gen_feedforward(networks[curnet])(inputs))
                                    outfile << d << ' ';
                            }
                        }
                        ++curnet;
                        got_inputs = false;
                    }
                --i;
            } else
                cerr << "Unexpected argument \"" << args[i] << "\" encountered (arg " << i << ").\n";
    } catch (exception& e) {
        cerr << "Error: " << e.what() << '\n';
        return 1;
    }
    return 0;
}

#else

void example()
{
    vector<double> w1(28 * 28 * 40), b1(40), w2(40 * 10), b2(10);
    auto network =
        input(28 * 28, spec(1, 8))
        | fc(output(40, spec(2, 8)), weights(w1, spec(4, 4)), simd(14),
             neuron()
             | bias(b1, spec(4, 8))
             | sigmoid(spec(2, 8), 2, 16) )
        | fc(output(10, spec(2, 8)), weights(w2, spec(4, 4)), simd(10),
             neuron()
             | bias(b2, spec(4, 8))
             | sigmoid(spec(1, 8), 2, 16) )
        ;
    auto interface = test_interface(vector<double>(28 * 28));
    ofstream file("testgen.vhd", ios::trunc);
    if (!file.is_open())
        throw runtime_error("Can't open testgen.vhd.");
    file << gen_code(network, interface);
}

void toy_network()
{
    vector<double> w({
        1.306903, -0.160192, 1.903822, -2.190612, -2.675583, -2.811914,
        -2.602515, -0.059137, 2.729670, -1.089163, 2.633426, 0.004224,
        -0.800113, 1.111917, 1.625981, 1.330796, 0.119047, -2.141114
    });
    vector<double> b({ -0.932403, 1.964976, 0.849697 });
    auto network =
        input(6, spec(1, 8))
        | fc(output(3, spec(2, 8)), weights(w, spec(4, 4)), simd(2),
             neuron()
             | bias(b, spec(4, 8))
             | sigmoid(spec(2, 8), 2, 16) )
        ;
    assert_valid(network);
//    auto interface = test_interface({ 0.270478, 0.808408, 0.463890, 0.291382, 0.800599, 0.203051 });
//    ofstream file("system.vhd", ios::trunc);
//    if (!file.is_open())
//        throw runtime_error("Can't open system.vhd.");
//    file << gen_code(network, interface);
    for (double out : gen_feedforward(network)({ 0.270478, 0.808408, 0.463890, 0.291382, 0.800599, 0.203051 }))
        cout << out << ' ';
}

void toy_network2()
{
    auto network = parse(sexpr::read_file("C:/Users/gademb/stage2017/Gabriel/codegen/toynetwork.nn"))[0];
    assert_valid(network);
    for (double out : gen_feedforward(network)({ 0.270478, 0.808408, 0.463890, 0.291382, 0.800599, 0.203051 }))
        cout << out << ' ';
    auto interface = sim_interface({ 0.270478, 0.808408, 0.463890, 0.291382, 0.800599, 0.203051 });
    ofstream file("C:/Users/gademb/stage2017/Gabriel/nnet/system.vhd", ios::trunc);
    if (!file.is_open())
        throw runtime_error("Can't open system.vhd.");
    file << gen_code(network, interface);
}

string actual_path = "C:/Users/gademb/stage2017/Gabriel/codegen";

void real_network()
{
    auto network = parse(sexpr::read_file(actual_path + "/realnet/realnet.nn"), actual_path + "/realnet/")[0];
    assert_valid(network);
    for (double out : gen_feedforward(network)(read_data(actual_path + "/realnet/translated-mnist-ex/index-217-N-input.nn")))
        cout << out << ' ';
    auto interface = sim_interface(read_data(actual_path + "/realnet/translated-mnist-ex/index-217-N-input.nn"));
    ofstream file("C:/Users/gademb/stage2017/Gabriel/nnet/system.vhd", ios::trunc);
    if (!file.is_open())
        throw runtime_error("Can't open system.vhd.");
    file << gen_code(network, interface);
}

void toy_network_bin()
{
    auto network = parse(sexpr::read_file("C:/Users/gademb/stage2017/Gabriel/codegen/toynetwork2.nn"))[0];
    assert_valid(network);
    for (double out : gen_feedforward(network)({ 0.0, 1.0, 1.0, 0.0, 1.0, 0.0 }))
        cout << out << ' ';
    auto interface = test_interface({ 0.0, 1.0, 1.0, 0.0, 1.0, 0.0 });
    ofstream file("C:/Users/gademb/stage2017/Gabriel/nnet/system.vhd", ios::trunc);
    if (!file.is_open())
        throw runtime_error("Can't open system.vhd.");
    file << gen_code(network, interface);
}

void real_network_bin()
{
    auto network = parse(sexpr::read_file(actual_path + "/realnetbin/realnet.nn"), actual_path + "/realnetbin/")[0];
    assert_valid(network);
    auto interface = block_interface();
    ofstream file("C:/Users/gademb/stage2017/Gabriel/nnet/system.vhd", ios::trunc);
    if (!file.is_open())
        throw runtime_error("Can't open system.vhd.");
    file << gen_code(network, interface);
}

void conv_network()
{
    auto network = parse(sexpr::read_file(actual_path + "/convgentest/conv.nn"), actual_path + "/convgentest/")[0];
    //assert_valid(network);
    auto interface = block_interface();
    ofstream file("C:/Users/gademb/stage2017/Gabriel/codegen/convgentest/system.vhd", ios::trunc);
    if (!file.is_open())
        throw runtime_error("Can't open system.vhd.");
    file << gen_code(network, interface);
}

int main()
{
    //toy_network2();
    //real_network();
    //toy_network_bin();
    //real_network_bin();
    conv_network();
}

#endif // COMPILED_AS_TOOL

#undef COMPILED_AS_TOOL
