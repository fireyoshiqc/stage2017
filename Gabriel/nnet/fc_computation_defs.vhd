library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

package fc_computation_defs is

type directives_t is array(0 to 2) of std_logic;
constant directive_none : integer := -1;
constant directive_mul_acc : integer := 0;
constant directive_reduce : integer := 1;
constant directive_reset_mul_acc : integer := 2;

function directives_from(cntrl : integer) return directives_t;

function post_reduce_spec(input_spec : fixed_spec; weight_spec : fixed_spec; input_width : integer; simd_width : integer) return fixed_spec;

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

function post_reduce_spec(input_spec : fixed_spec; weight_spec : fixed_spec; input_width : integer; simd_width : integer) return fixed_spec is
    constant mulacc_spec : fixed_spec := (int => input_spec.int + weight_spec.int + input_width / simd_width, frac => input_spec.frac + weight_spec.frac);
begin
    return fixed_spec'(int => mulacc_spec.int + integer(ceil(log2(real(simd_width)))), frac => mulacc_spec.frac);--
end post_reduce_spec;

end fc_computation_defs;