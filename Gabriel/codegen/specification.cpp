#include "specification.h"

namespace gen
{
using namespace std;

system_specification* clone_system_specification(const system_specification& other)
{
    return new system_specification(other);
}
void delete_system_specification(system_specification* s)
{
    delete s;
}

auto weights(const vector<vector<double>>& w2d, pair<int, int> w_spec)
{
    vector<double> w;
    size_t expected_row_size = size_t(-1);
    for (const vector<double>& row : w2d){
        if (expected_row_size == size_t(-1))
            expected_row_size = row.size();
        else if (row.size() != expected_row_size)
            throw runtime_error("weights: Inconsistent row sizes (" + to_string(expected_row_size) + " and " + to_string(row.size()) + ").");
        copy(row.begin(), row.end(), back_inserter(w));
    }
    return Weights{ w, w_spec };
}

} //namespace gen
