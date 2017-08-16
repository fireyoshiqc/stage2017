library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
library work;
use work.util.all;

entity clock_reducer is
generic(
	mode : string;
	divider : integer := -1;
	count : integer := -1;
	input_period : time := 0ns;
	target_period : time := 0ns
);
port(
    in_clk, rst : in std_logic;
    out_clk : out std_logic
);
end clock_reducer;

architecture clock_reducer of clock_reducer is

	constant check1 : integer :=
		synth_assert(                                         mode = "divider" or mode = "counter" or mode = "timer",
		             "clock_reducer: Parameter 'mode' must be one of 'divider', " &     "'counter' or " &   "'timer'.");
	constant check2 : integer :=
		synth_assert(mode /= "divider" or divider >= 0, "clock_reducer: In 'divider' mode, parameter 'divider' must be given a non-negative value.");
	constant check3 : integer :=
		synth_assert(mode /= "counter" or count >= 1, "clock_reducer: In 'counter' mode, parameter 'count' must be given a strictly positive value.");
	constant check4 : integer :=
		synth_assert(mode /= "timer" or (input_period > 0ns and target_period > 0ns), "clock_reducer: In 'timer' mode, both parameters 'input_period' and 'target_period' must be greater than zero."); 
	
	signal out_clk_sig : std_logic := '0';
	
	signal divider_counter : unsigned(relu(divider - 2) downto 0) := to_unsigned(0, relu(divider - 1, 1));
	
	function count_from_periods return integer is
	begin
		if mode /= "timer" or round(real(time'pos(target_period)) / real(time'pos(input_period))) = 0.0 then
			return 1;
		else
			return integer(round(real(time'pos(target_period)) / real(time'pos(input_period))));
		end if;
	end count_from_periods;
	constant actual_count : integer := if_expr(mode = "counter", count, count_from_periods);
	constant counter_counter_length : integer := inclusive_range_u(actual_count)'length;
	signal counter_counter : unsigned(counter_counter_length - 1 downto 0) := to_unsigned(0, counter_counter_length);

begin

	out_clk <= out_clk_sig;
	
divider_gen: if mode = "divider" generate

process(in_clk, rst)
	variable divider_counter_plus_one : unsigned(divider_counter'range);
begin
	if rst = '1' then
		out_clk_sig <= '0';
		divider_counter <= to_unsigned(0, divider_counter'length);
	elsif divider = 0 then
		out_clk_sig <= in_clk;
	elsif rising_edge(in_clk) then
		if divider = 1 then
			out_clk_sig <= not out_clk_sig;
		else
			divider_counter_plus_one := divider_counter + 1;
			if divider_counter_plus_one = 0 then
				out_clk_sig <= not out_clk_sig;
			end if;
			divider_counter <= divider_counter_plus_one;
		end if;
	end if;
end process;

end generate divider_gen;

counter_gen: if mode = "counter" or mode = "timer" generate

process(in_clk, rst)
	variable counter_counter_var : unsigned(counter_counter'range);
begin
	if rst = '1' then
		out_clk_sig <= '0';
		counter_counter <= to_unsigned(0, counter_counter'length);
	elsif in_clk'event then
		counter_counter_var := counter_counter + 1;
		if counter_counter_var = actual_count then
			out_clk_sig <= not out_clk_sig;
			counter_counter_var := to_unsigned(0, counter_counter'length);
		end if;
		counter_counter <= counter_counter_var;
	end if;
end process;

end generate counter_gen;

end clock_reducer;