library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity op_be is
end op_be;

architecture op_be of op_be is	

component sigmoid_op is
generic(
	input_spec : fixed_spec;
	output_spec : fixed_spec;
    step_precision : integer;
	bit_precision : integer
);
port(
    input : in sfixed(mk(input_spec)'range);
    output : out sfixed(mk(output_spec)'range)
);
end component;

	constant input_spec : fixed_spec := (int => 8, frac => 8);
	constant output_spec : fixed_spec := (int => 2, frac => 8);


	signal input : sfixed(mk(input_spec)'range);
	constant output_range : sfixed := mk(output_spec);
    signal output : sfixed(output_range'range);

	function sigmoid(x : real) return real is
	begin
		 return 1.0 / (1.0 + exp(-x));
	end sigmoid;
	
	constant inputs	: reals := (
		-7.0, -6.99645, -6.57709, -6.39292, -6.3569, -6.25371, -6.22315, -6.21396, -5.9875, -5.61329, -5.52769, -5.22786, -5.11797, -4.65207, -4.59343, -4.42638, -4.01457, -3.83028, -3.59428, -3.4983, -3.38094, -3.25908, -2.88861, -2.5841, -2.55683, -2.43536, -2.19483, -1.84378, -1.49058, -1.08444, -0.947727, -0.513532, -0.382082, -0.111697, 0.251342, 0.503704, 0.904826, 1.32483, 1.35298, 1.37895, 1.47232, 1.90905, 2.34356, 2.45472, 2.50266, 2.87441, 3.26074, 3.32629, 3.37578, 3.45341, 3.48745, 3.79178, 3.94349, 4.29877, 4.58937, 4.7345, 5.21263, 5.28909, 5.65446, 6.15281, 6.33782, 6.39712, 6.53066, 6.62255, 6.99479, 7.0
	);

begin
    
uut : sigmoid_op generic map (
	input_spec => input_spec,
	output_spec => output_spec,
	step_precision => 1,
	bit_precision => 16
) port map(
	input => input, output => output
);
	
process
	variable expect : real;
begin
	for i in inputs'range loop
		input <= to_sfixed(inputs(i), input);
		wait for 1ns;
		expect := sigmoid(inputs(i));
		assert false report "initial: " & real'image(inputs(i)) & ";expected: " & real'image(expect) & "; obtained: " & real'image(to_real(output)) & "; diff: " & real'image(expect - to_real(output));
		wait for 1ns;
	end loop;
	assert false report "!!!!!!!!!!!!!!!!!!!!!" severity failure;
end process;
end op_be;