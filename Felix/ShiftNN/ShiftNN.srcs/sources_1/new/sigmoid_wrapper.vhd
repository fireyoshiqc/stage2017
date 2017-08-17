library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity sigmoid_wrapper is
generic(
	input_spec_int : integer;
	input_spec_frac : integer;
	output_spec_int : integer;
	output_spec_frac : integer;
    step_precision : integer;
	bit_precision : integer
);
port(
    clk : in std_logic;
    input_w : in std_logic_vector(input_spec_int + input_spec_frac - 1 downto 0);
    output_w : out std_logic_vector(output_spec_int + output_spec_frac - 1 downto 0);
    op_send : out std_logic := '0';
    op_receive : in std_logic := '0'
);
end sigmoid_wrapper;

architecture Behavioral of sigmoid_wrapper is

component sigmoid_op is
generic(
	input_spec : fixed_spec;
	output_spec : fixed_spec;
    step_precision : integer;
	bit_precision : integer
);
port(
    clk : in std_logic;
    input : in sfixed(mk(input_spec)'range);
    output : out sfixed(mk(output_spec)'range);
    op_send : out std_logic := '0';
    op_receive : in std_logic := '0'
);
end component sigmoid_op;

signal output_sig : sfixed(mk(fixed_spec(fixed_spec'(int => output_spec_int, frac => output_spec_frac)))'range);

begin

output_w <= std_logic_vector(output_sig);

sigmoid_op_u: sigmoid_op generic map(
    input_spec => fixed_spec(fixed_spec'(int => input_spec_int, frac => input_spec_frac)),
    output_spec => fixed_spec(fixed_spec'(int => output_spec_int, frac => output_spec_frac)),
    step_precision => step_precision,
    bit_precision => bit_precision
) port map(
    clk => clk,
    input => to_sfixed(input_w, input_spec_int - 1, -input_spec_frac),
    output => output_sig,
    op_send => op_send,
    op_receive => op_receive
);


end Behavioral;
