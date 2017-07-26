#include "util.h"

#include <iostream>
namespace util
{
using namespace std;

string read_word(const string& text, size_t& cursor)
{
    string res;
    for (; cursor < text.size() && !isspace(text[cursor]) && text[cursor] != '(' && text[cursor] != ')'; ++cursor)
        res.push_back(text[cursor]);
    return res;
}
string read_quoted(const string& text, size_t& cursor)
{
    string res;
    for (; cursor < text.size() && text[cursor] != '"'; ++cursor){
        if (text[cursor] == '\\')
            ++cursor;
        res.push_back(text[cursor]);
    }
    if (cursor == text.size())
        throw runtime_error("read_quoted: Reached end of file before end of quote.");
    return res;
}

sexpr_field& access(sexpr& s, size_t index) { return s[index]; }
const sexpr_field& access(const sexpr& s, size_t index) { return s[index]; }
size_t get_size(const sexpr& s) { return s.size(); }

vector<double> read_data(const string& filename)
{
    ifstream file(filename);
    if (!file.is_open())
        throw runtime_error("read_data: Couldn't open file \"" + filename + "\".");
    vector<double> res;
    for (;;){
        double d; file >> d;
        if (file.eof()) break;
        res.push_back(d);
    }
    return move(res);
}

void pop_path(string& path)
{
    if (path.empty())
        return;
    if (path == "./"){
        path = "../";
        return;
    }
    if (path.size() >= 3 && path.substr(0, 3) == "../"){
        path = "../" + path;
        return;
    }
    if (path.back() == '/' || path.back() == '\\')
        path.pop_back();
    if (path.empty())
        return;
    while (path.back() != '/' && path.back() != '\\')
        path.pop_back();
}

string path_relative_to(string rel_path, string abs_path)
{
    if (abs_path == "./")
        return rel_path;
    for (;;) {
        cerr << "\npath_relative_to: \"" << rel_path << "\" and \"" << abs_path << "\"\n";// ../dfgfdg ./
        if (rel_path.find("./") == 0)
            cerr << 'a',rel_path = rel_path.substr(2);
        else if (rel_path.find("../") == 0){
            cerr << 'b';
            rel_path = rel_path.substr(3);
            pop_path(abs_path);
        } else if (rel_path == "."){
            cerr << 'c';
            rel_path.clear();
            break;
        } else if (rel_path == ".."){
            cerr << 'd';
            rel_path.clear();
            pop_path(abs_path);
            break;
        } else
            {cerr << 'e';break;}
    }
    cerr << 'f';
    if (abs_path.empty() || abs_path.back() != '/')
        cerr << 'g', abs_path.push_back('/');
    cerr << 'h';
    return abs_path + rel_path;
}

} //namespace util
