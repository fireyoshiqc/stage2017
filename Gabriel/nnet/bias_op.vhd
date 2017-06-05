library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity bias_op is
generic(
    input_spec : fixed_spec;
    bias_spec : fixed_spec;
    biases : reals
);
port(
    input : in sfixed(mk(input_spec)'range);
    offset : in unsigned(bits_needed(biases'length) - 1 downto 0);
    output : out sfixed(mk(input_spec + bias_spec)'range);
    op_send : out std_logic := '0';
    op_receive : in std_logic := '0'
);
end bias_op;

architecture bias_op of bias_op is

    type biases_t is array(biases'range) of sfixed(mk(bias_spec)'range);
    function actual_biases_init return biases_t is
        variable ret : biases_t;
    begin
        for i in ret'range loop
            ret(i) := to_sfixed(biases(i), mk(bias_spec));
        end loop;
        return ret;
    end actual_biases_init;
    constant actual_biases : biases_t := actual_biases_init;
begin
    op_send <= op_receive;
    output <= input + actual_biases(to_integer(offset));
end bias_op;
