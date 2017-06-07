/// this code is meant to be compiled with C++14 (-std=c++14)

#include <vector>
#include <fstream>
#include <stdexcept>

using namespace std;

#include "gen.h"

using namespace gen;

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
    file << eval(network, interface);
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
    auto interface = test_interface({ 0.270478, 0.808408, 0.463890, 0.291382, 0.800599, 0.203051 });
    ofstream file("system.vhd", ios::trunc);
    if (!file.is_open())
        throw runtime_error("Can't open system.vhd.");
    file << eval(network, interface);
}

int main()
{
    toy_network();
}


