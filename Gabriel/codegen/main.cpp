/// this code is meant to be compiled with C++14 (-std=c++14)

#include <vector>
#include <fstream>
#include <stdexcept>

using namespace std;

#include "gen.h"

using namespace gen;

int main()
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
