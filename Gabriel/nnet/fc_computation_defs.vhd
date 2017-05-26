library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

package fc_computation_defs is

type directives_t is array(0 to 2) of std_logic;
constant directive_none : integer := -1;
constant directive_mul_acc : integer := 0;
constant directive_reduce : integer := 1;
constant directive_reset_mul_acc : integer := 2;

function directives_from(cntrl : integer) return directives_t;

end fc_computation_defs;

package body fc_computation_defs is

function directives_from(cntrl : integer) return directives_t is
    variable res : directives_t := ('0', '0', '0');
begin
    if cntrl >= 0 then
        res(cntrl) := '1';
    end if;
    return res;
end directives_from;

end fc_computation_defs;