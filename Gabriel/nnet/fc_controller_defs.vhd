library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.all;

package fc_controller_defs is
 
type controls_t is array(0 to 6) of std_logic;
constant control_none : integer := -1;
constant control_ready : integer := 0;
constant control_load : integer := 1;
constant control_mul_acc : integer := 2;
constant control_reduce : integer := 3;
constant control_wait_for_result : integer := 4;
constant control_reset_mul_acc : integer := 5;
constant control_done : integer := 6;

function controls_from(cntrl : integer) return controls_t;

end fc_controller_defs;


package body fc_controller_defs is

function controls_from(cntrl : integer) return controls_t is
    variable res : controls_t := ('0', '0', '0', '0', '0', '0', '0');
begin
    if cntrl >= 0 then
        res(cntrl) := '1';
    end if;
    return res;
end controls_from;

end fc_controller_defs;