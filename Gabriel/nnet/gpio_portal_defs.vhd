library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package gpio_portal_defs is

function dir(x : integer) return std_logic_vector;
constant none : integer := 0;
constant read1 : integer := 1;
constant read2 : integer := 2;
constant last : integer := 3;

end gpio_portal_defs;

package body gpio_portal_defs is

function dir(x : integer) return std_logic_vector is
begin
    return std_logic_vector(to_unsigned(x, 4));
end dir;

end gpio_portal_defs;
