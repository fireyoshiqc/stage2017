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
    clk : in std_logic;
    input : in sfixed(mk(input_spec)'range);
    output : out sfixed(mk(output_spec)'range);
    op_send : out std_logic := '0';
    op_receive : in std_logic := '0'
);
end sigmoid_op;

architecture sigmoid_op of sigmoid_op is  
    
	type state_t is (idle, calculating, done);
	signal in_sgn : std_logic;
	signal state : state_t := idle;
	signal abs_input_reg : sfixed(mk(abs(input_spec))'range);
    signal DEBUG_INPUT_REG : sfixed(mk(input_spec)'range);
	--signal input_reg : sfixed(input'range);
    signal output_reg : sfixed(output'range);
    --signal op_send_sig : std_logic := '0';
    
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
    signal coeff : coeff_t;
    
begin
process(clk)
    variable abs_input_var : sfixed(mk(abs(input_spec))'range);
    variable index : unsigned(bits_needed(max_approx) + step_precision - 1 downto 0);
    variable y : sfixed(output_spec.int - 1 downto -output_spec.frac);
    variable a : sfixed(bits_needed(max_approx) downto -step_precision);
begin
    if rising_edge(clk) then
		case state is
		when idle =>
			op_send <= '0';
			if op_receive = '1'	then
                DEBUG_INPUT_REG <= input;
                state <= calculating;
--				abs_input_var := abs(input);
--				in_sgn <= input(input'high);
--				if abs_input_var >= real(max_approx) then
--					output_reg <= to_sfixed(1.0, output_reg);
--					state <= done;
--				else
--				    index := unsigned(shift_range(std_logic_vector(abs_input_var(bits_needed(max_approx) - 1 downto -step_precision)), step_precision));
--				    coeff <= coeffs(to_integer(index));
--				    abs_input_reg <= abs_input_var;
--				    state <= calculating;
--				end if;
			end if;
		when calculating =>
--			a := to_sfixed("0" & std_logic_vector(index), a);
--            y := resize(coeff.approx + (abs_input_reg - a) * coeff.slope, y);
--            output_reg <= y;
			state <= done;
        when done =>
--            if in_sgn = '1' then
--                output <= resize(1 - output_reg, output_reg);
--            else
--                output <= output_reg;
--            end if;
            output <= resize(DEBUG_INPUT_REG, mk(output_spec));
            op_send <= '1';
			state <= idle;
		end case;
    end if;
end process;
end sigmoid_op;