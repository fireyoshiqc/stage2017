library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity sigmoid_op is
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
end sigmoid_op;

architecture sigmoid_op of sigmoid_op is

	function sigmoid(x : real) return real is
	begin
		 return 1.0 / (1.0 + exp(-x));
	end sigmoid;

	constant max_approx : integer := 6;
	constant step : real := 2.0**(-real(step_precision));
	constant n_steps : integer := max_approx * 2**step_precision;
	
	constant approx_spec : fixed_spec := (int => 1, frac => bit_precision);
	constant slope_spec : fixed_spec := (int => 0, frac => bit_precision);
	
	type coeff_t is record
		approx : sfixed(mk(approx_spec)'range);
		slope : sfixed(mk(slope_spec)'range);--(step_precision downto -bit_precision);--(d_range'range);
	end record coeff_t;

	type coeffs_t is array(0 to n_steps - 1) of coeff_t;
    function coeffs_init return coeffs_t is
		variable ret : coeffs_t;
		variable a, b, approx, slope : real;
    begin
        for i in ret'range loop
			a := real(i) * step;
			b := real(i + 1) * step;
			approx := sigmoid(a);
			slope := (sigmoid(b) - approx) / step;
			ret(i) := (approx => to_sfixed(approx, ret(i).approx), slope => to_sfixed(slope, ret(i).slope));
        end loop;
        return ret;
    end coeffs_init;
    constant coeffs : coeffs_t := coeffs_init;
begin
    process(input)
		variable x : sfixed(mk(abs(input_spec))'range);
		variable y : sfixed(mk(output_spec)'range);
		variable index : unsigned(bits_needed(max_approx) + step_precision - 1 downto 0);
		variable a : sfixed(bits_needed(max_approx) downto -step_precision);
		variable coeff : coeff_t;
		--variable dummy : coeffs_t;
	begin
		--dummy := coeffs_init;
		x := abs(input);
		if x >= real(max_approx) then
			y := to_sfixed(1.0, y);
		else
			index := unsigned(shift_range(std_logic_vector(x(bits_needed(max_approx) - 1 downto -step_precision)), step_precision));
			coeff := coeffs(to_integer(index));
			a := to_sfixed("0" & std_logic_vector(index), a);
			y := resize(coeff.approx + (x - a) * coeff.slope, y);
		end if;
		if input(input'high) = '1' then
			y := resize(1 - y, y);
		end if;
		output <= y;
	end process;
end sigmoid_op;