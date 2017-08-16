use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package util is

function bits_to_represent_u(value : integer) return integer;
function exclusive_range_u(value : integer) return unsigned;
function inclusive_range_u(value : integer) return unsigned;

procedure cycle(signal clk : inout std_logic; constant period : time);

function vec_image(arg : std_logic_vector) return string;

impure function synth_assert(cond : boolean; msg : string) return integer;

function relu(x : integer) return integer;
function relu(x : integer; bottom : integer) return integer;

function if_expr(cond : boolean; then_clause : integer; else_clause : integer) return integer;

function is_power_of_2(x : integer) return boolean;

subtype ascii_char_t is std_logic_vector(7 downto 0);
type ascii_string_t is array(natural range <>) of ascii_char_t;

function ascii(c : character) return ascii_char_t;
function ascii(s : string) return ascii_string_t;
function ascii_nibble(nib : unsigned(3 downto 0)) return ascii_char_t;
function ascii_u(u : unsigned) return ascii_string_t; --causes exception

function "&"(a : ascii_string_t; b : ascii_string_t) return ascii_string_t;

end util;


package body util is

function bits_to_represent_u(value : integer) return integer is
begin
    if value <= 0 then
        return 0;
    else
        return integer(floor(log2(real(value) + 0.5))) + 1;
    end if;
end bits_to_represent_u;

function exclusive_range_u(value : integer) return unsigned is
    variable res : unsigned(bits_to_represent_u(value - 1) - 1 downto 0);
begin
    return res;
end exclusive_range_u;

function inclusive_range_u(value : integer) return unsigned is
    variable res : unsigned(bits_to_represent_u(value) - 1 downto 0);
begin
    return res;
end inclusive_range_u;

procedure cycle(signal clk : inout std_logic; constant period : time) is
begin
    wait for period / 2;
    clk <= not clk;
    wait for period / 2;
    clk <= not clk;
end cycle;

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

impure function synth_assert(cond : boolean; msg : string) return integer is
    file f : text;
begin
    assert cond report msg severity failure;
    if not cond then file_open(f, "Error: " & msg, read_mode); end if;
    return 0;
end;

function relu(x : integer) return integer is
begin
	if x < 0 then
		return 0;
	else
		return x;
	end if;
end relu;
function relu(x : integer; bottom : integer) return integer is
begin
	if x < bottom then
		return bottom;
	else
		return x;
	end if;
end relu;

function if_expr(cond : boolean; then_clause : integer; else_clause : integer) return integer is
begin
	if cond then
		return then_clause;
	else
		return else_clause;
	end if;
end if_expr;

function is_power_of_2(x : integer) return boolean is
    variable p : integer := 1;
begin
    if x > 0 then
        while p <= x and p > 0 loop
            if p = x then
                return true;
            end if;
            p := p * 2;
        end loop;
    end if;
    return false;
end is_power_of_2;

function ascii(c : character) return ascii_char_t is
begin
    return std_logic_vector(to_unsigned(character'pos(c), 8));
end ascii;

function ascii(s : string) return ascii_string_t is
    variable res : ascii_string_t(0 to s'length - 1);
begin
    for i in res'range loop
        res(i) := ascii(s(i + 1));
    end loop;
    return res;
end ascii;

function ascii_nibble(nib : unsigned(3 downto 0)) return ascii_char_t is
begin
    if nib < 10 then
        return std_logic_vector(to_unsigned(character'pos('0'), 8) + nib);
    else
        return std_logic_vector(to_unsigned(character'pos('A') - 10, 8) + nib);
    end if;
end ascii_nibble;

function ascii_u(u : unsigned) return ascii_string_t is
    variable res : ascii_string_t(0 to (u'length - 1) / 4);
    variable i : integer := 1;
begin
    res(0) := ascii_nibble(u(u'length - 1 downto (u'length / 4) * 4));
    while i < res'length loop
        res(i) := ascii_nibble(u((u'length / 4) * 4 - 1 - 4 * (i - 1) downto (u'length / 4) * 4 - 4 - 4 * (i - 1)));
        i := i + 1;
    end loop;
    return res;
end ascii_u;

function "&"(a : ascii_string_t; b : ascii_string_t) return ascii_string_t is
    variable res : ascii_string_t(0 to a'length + b'length - 1);
begin
    for i in a'range loop
        res(i) := a(i);
    end loop;
    for i in b'range loop
        res(i + a'length) := b(i);
    end loop;
    return res;
end "&";

end util;