#pragma once

#include <vector>
#include <memory>
#include <string>
#include <stdexcept>
#include <fstream>
#include <iomanip>
#include <sstream>

namespace util
{
using namespace std;

struct sexpr;
struct sexpr_field;
sexpr_field& access(sexpr& s, size_t index);
const sexpr_field& access(const sexpr& s, size_t index);
size_t get_size(const sexpr& s);
struct sexpr_field
{
    using stdstring = std::string;
    using sexpr_t = util::sexpr;
    enum type_t { sxempty, sxtree, sxleaf };
    template<typename T>
    sexpr_field(T&& val)
        : u(forward<T>(val), this) {}
    static runtime_error unhandled_err(const std::string& caller, type_t type)
    {
        return runtime_error(caller + ": Unhandled data type with code " + to_string(static_cast<int>(type)) + ".");
    }
    void discard()
    {
        switch (type){
        case sxtree: return u.tree.unique_ptr<sexpr_t>::~unique_ptr<sexpr_t>();
        case sxleaf: return u.leaf.stdstring::~stdstring();
        default: throw unhandled_err("sexpr_field::discard", type);
        }
        type = sxempty;
    }
    ~sexpr_field() { discard(); }
    void copy(const sexpr_field& other)
    {
        switch (other.type){
        case sxtree: ::new(&u.tree) unique_ptr<sexpr_t>(make_unique<sexpr_t>(*other.u.tree)); break;
        case sxleaf: ::new(&u.leaf) stdstring(other.u.leaf); break;
        default: throw unhandled_err("sexpr_field::copy", type);
        }
        type = other.type;
    }
    sexpr_field(const sexpr_field& other) : u(nullptr) { copy(other); }
    sexpr_field& operator=(const sexpr_field& other) { discard(); copy(other); return *this; }
    void move(sexpr_field&& other)
    {
        switch (other.type){
        case sxtree: ::new(&u.tree) unique_ptr<sexpr_t>(std::move(other.u.tree)); break;
        case sxleaf: ::new(&u.leaf) stdstring(std::move(other.u.leaf)); break;
        default: throw unhandled_err("sexpr_field::move", type);
        }
        type = other.type;
        other.discard();
    }
    sexpr_field(sexpr_field&& other) : u(nullptr) { move(std::move(other)); }
    sexpr_field& operator=(sexpr_field&& other) { discard(); move(std::move(other)); return *this; }
    union data_t
    {
        data_t(nullptr_t) : tree(nullptr) {}
        data_t(const sexpr_t& s, sexpr_field* that = nullptr)
            : tree(make_unique<sexpr_t>(s)) { if (that) that->type = sxtree; }
        data_t(unique_ptr<sexpr_t> s, sexpr_field* that = nullptr)
            : tree(std::move(s)) { if (that) that->type = sxtree; }
        data_t(stdstring s, sexpr_field* that = nullptr)
            : leaf(std::move(s)) { if (that) that->type = sxleaf; }
        ~data_t() {}
        unique_ptr<sexpr_t> tree;
        stdstring leaf;
    } u;
    type_t type;
    static stdstring type_str(type_t t)
    {
        switch (t){
        case sxempty: return "EMPTY";
        case sxtree: return "tree";
        case sxleaf: return "leaf";
        default: return "???";
        }
    }
    sexpr_field& operator[](size_t index)
    {
        if (type != sxtree)
            throw runtime_error("sexpr_field::operator[]: Trying to index (" + to_string(index) + ") directly into a leaf (try converting to a string first).");
        return access(*u.tree, index);
    }
    const sexpr_field& operator[](size_t index) const
    {
        if (type != sxtree)
            throw runtime_error("sexpr_field::operator[]: Trying to index (" + to_string(index) + ") directly into a leaf (try converting to a string first).");
        return access(*u.tree, index);
    }
    runtime_error err(type_t wanted) const
    {
        return runtime_error("S-expression field contains a " + type_str(type) + ", not a " + type_str(wanted) + ".");
    }
    sexpr_t& sexpr() & { if (type == sxtree) return *u.tree; else throw err(sxtree); }
    const sexpr_t& sexpr() const & { if (type == sxtree) return *u.tree; else throw err(sxtree); }
    sexpr_t&& sexpr() && { if (type == sxtree) { type = sxempty; return std::move(*u.tree); } else throw err(sxtree); }
    stdstring& string() & { if (type == sxleaf) return u.leaf; else throw err(sxleaf); }
    const stdstring& string() const & { if (type == sxleaf) return u.leaf; else throw err(sxleaf); }
    stdstring string() && { if (type == sxleaf) { auto ret = std::move(u.leaf); type = sxempty; return std::move(ret); } else throw err(sxleaf); }
    bool is_tree() const { return type == sxtree; }
    bool is_leaf() const { return type == sxleaf; }
    size_t size() const { return get_size(*u.tree); }
    bool empty() const { return get_size(*u.tree) == 0; }
};
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
struct sexpr
{
    static sexpr read(const string& text)
    {
        size_t cursor = 0;
        return read(text, cursor, 0);
    }
    static sexpr read(const string& text, size_t& cursor, size_t level)
    {
        sexpr res;
        for (size_t sz = text.size(); cursor < sz && text[cursor] != ')'; ++cursor){
            if (text[cursor] == '(')
                res.fields.push_back(read(text, ++cursor, level + 1));
            else if (text[cursor] == '"')
                res.fields.push_back(read_quoted(text, ++cursor));
            else if (!isspace(text[cursor]))
                res.fields.push_back(read_word(text, cursor)), --cursor;
        }
        if (level != 0 && cursor >= text.size())
            throw runtime_error("sexpr::read: Reached end of file before end of s-expression.");
        if (level == 0 && text[cursor] == ')')
            throw runtime_error("sexpr::read: Unexpected ')' encountered instead of end of file.");
        return move(res);
    }
    static sexpr read_file(const string& filename)
    {
        ifstream file(filename);
        if (!file.is_open())
            throw runtime_error("sexpr::read_file: Couldn't open file \"" + filename + "\".");

        file.seekg(0, ios::end);
        size_t sz = file.tellg();
        string content(sz, ' ');
        file.seekg(0, ios::beg);
        file.read(const_cast<char*>(content.data()), sz);
        return read(content);
    }
    string write(const string& indent = string()) const
    {
        string s;
        for (size_t i = 0; i < fields.size(); ++i){
            s += i != 0 ? "\n" + indent : "";
            if (fields[i].is_leaf())
                s += fields[i].string();
            else if (fields[i].is_tree())
                s += "(" + fields[i].sexpr().write(indent + "  ") + ")";
            else
                throw runtime_error("sexpr::write: Trying to write unknown type \"" + sexpr_field::type_str(fields[i].type) + "\".");
        }
        return s;
    }
    sexpr_field& operator[](size_t index)
    {
        if (index >= fields.size())
            throw runtime_error("sexpr_field::operator[]: Trying to access s-expression field at position " +
                                to_string(index) + ", which is beyond max position " + to_string((long long)(fields.size()) - 1) + ".");
        return fields[index];
    }
    const sexpr_field& operator[](size_t index) const
    {
        if (index >= fields.size())
            throw runtime_error("sexpr_field::operator[]: Trying to access s-expression field at position " +
                                to_string(index) + ", which is beyond max position " + to_string((long long)(fields.size()) - 1) + ".");
        return fields[index];
    }
    size_t size() const { return fields.size(); }
    bool empty() const { return fields.empty(); }
    vector<sexpr_field> fields;
};
sexpr_field& access(sexpr& s, size_t index) { return s[index]; }
const sexpr_field& access(const sexpr& s, size_t index) { return s[index]; }
size_t get_size(const sexpr& s) { return s.size(); }

} //namespace util
