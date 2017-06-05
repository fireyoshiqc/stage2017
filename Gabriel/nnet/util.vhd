library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

package util is

function bits_needed(n : integer) return integer;

type reals is array(natural range <>) of real;

function get(buf : std_logic_vector; index : integer; example : sfixed) return sfixed;
procedure set(signal buf : out std_logic_vector; index : integer; value : sfixed);
procedure set_var(variable buf : out std_logic_vector; index : integer; value : sfixed);

function max(a : integer; b : integer) return integer;

type fixed_spec is record
    int : integer;
    frac : integer;
end record fixed_spec;

function size(fs : fixed_spec) return integer;
function mk(fs : fixed_spec) return sfixed;
function specof(x : sfixed) return fixed_spec;
function "+" (fs1 : fixed_spec; fs2 : fixed_spec) return fixed_spec;
function "-" (fs1 : fixed_spec; fs2 : fixed_spec) return fixed_spec;
function "*" (fs1 : fixed_spec; fs2 : fixed_spec) return fixed_spec;
function "abs" (fs : fixed_spec) return fixed_spec;

function vec_image(arg : std_logic_vector) return string;

function identity(sf : sfixed) return sfixed;

function shift_range(x : std_logic_vector; n : integer) return std_logic_vector;

--procedure write(variable s : out string; w : in string; variable pos : inout integer);
function write(s : string; w : in string; pos : integer) return string;

end util;


package body util is

function bits_needed(n : integer) return integer is
begin
    return integer(ceil(log2(real(n) + 0.5)));
end bits_needed;

function get(buf : std_logic_vector; index : integer; example : sfixed) return sfixed is
begin
    return to_sfixed(buf((index + 1) * example'length - 1 downto index * example'length), example);
end get;

procedure set(signal buf : out std_logic_vector; index : integer; value : sfixed) is
begin
    buf((index + 1) * value'length - 1 downto index * value'length) <= std_logic_vector(value);
end set;
procedure set_var(variable buf : out std_logic_vector; index : integer; value : sfixed) is --procedures can possibly not work right during static initialization?
begin
    buf((index + 1) * value'length - 1 downto index * value'length) := std_logic_vector(value);
end set_var;

function max(a : integer; b : integer) return integer is
begin
    if a < b then
        return b;
    else
        return a;
    end if;
end max;

function size(fs : fixed_spec) return integer is
begin
    return fs.int + fs.frac;
end size;
function mk(fs : fixed_spec) return sfixed is
begin
    return to_sfixed(0.0, fs.int - 1, -fs.frac);
end mk;
function specof(x : sfixed) return fixed_spec is
begin
    return fixed_spec'(int => x'high + 1, frac => -x'low);
end specof;
function "+" (fs1 : fixed_spec; fs2 : fixed_spec) return fixed_spec is
begin
    return (max(fs1.int, fs2.int) + 1, max(fs1.frac, fs2.frac));
end "+";
function "-" (fs1 : fixed_spec; fs2 : fixed_spec) return fixed_spec is
begin
    return fs1 + fs2;
end "-";
function "*" (fs1 : fixed_spec; fs2 : fixed_spec) return fixed_spec is
begin
    return (fs1.int + fs2.int + 1, fs1.frac + fs2.frac);
end "*";
function "abs" (fs : fixed_spec) return fixed_spec is
begin
	return (fs.int + 1, fs.frac);
end "abs";

function vec_image(arg : std_logic_vector) return string is 
   constant arg_norm        : std_logic_vector(1 to arg'length) := arg; 
   constant center          : natural                           := 2; 
   variable just_the_number : character;
   variable bit_image       : string(1 to 3); 
begin 
   if (arg'length > 0) then 
      bit_image       := std_logic'image( arg_norm(1) );
      just_the_number := bit_image(center);
      return just_the_number
         & vec_image(arg_norm(2 to arg_norm'length));
   else 
      return "";
   end if; 
end function vec_image;

function identity(sf : sfixed) return sfixed is
begin
	return sf;
end identity;

function identity(slv : std_logic_vector) return std_logic_vector is
begin
	return slv;
end identity;

function shift_range(x : std_logic_vector; n : integer) return std_logic_vector is
	variable res : std_logic_vector(x'high + n downto x'low + n);
begin
	for i in res'range loop--x'range loop 
		res(i) := x(i - n);--res(i + n) := x(i);
	end loop;
	return res;
end shift_range;

--procedure write(variable s : out string; w : in string; variable pos : inout integer) is
--    variable curw : integer := 1;
--begin
--    while curw <= w'length loop
--        s(pos) := w(curw);
--        curw := curw + 1;
--        pos := pos + 1;
--    end loop;
--end write;

function write(s : string; w : in string; pos : integer) return string is
    variable curp : integer := pos;
    variable ss : string(s'range) := s;
begin
    for i in w'range loop
        ss(pos + i) := w(i);
    end loop;
    return ss;
end write;

end util;