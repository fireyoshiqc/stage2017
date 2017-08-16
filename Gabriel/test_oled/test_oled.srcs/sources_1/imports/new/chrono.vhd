library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
library work;
use work.util.all;

entity chrono is
generic(
	mode : string;
	count : integer := -1;
	input_period : time := 0ns;
	target_delay : time := 0ns
);
port(
    clk, rst : in std_logic;
    start : in std_logic;
    stop : out std_logic
);
end chrono;

architecture chrono of chrono is

	constant check1 : integer :=
		synth_assert(                           mode = "counter" or mode = "timer",
		             "chrono: Parameter 'mode' must be 'counter' or " &   "'timer'.");
	constant check2 : integer :=
		synth_assert(mode /= "counter" or count >= 0, "chrono: In 'counter' mode, parameter 'count' must be given a non-negative value.");
	constant check3 : integer :=
		synth_assert(mode /= "timer" or input_period > 0ns, "chrono: In 'timer' mode, parameters 'input_period' must be greater than zero.");
	constant check4 : integer :=
		synth_assert(mode /= "timer" or input_period >= 1ns, "chrono: In 'timer' mode, 'input_period' must be greater or equal to 1ns.");

	
	function count_from_periods return integer is
		variable input_p : time := input_period + (1ns * if_expr(input_period = 0ns, 1, 0));
		variable ratio : integer := (target_delay / 1ns) / (input_p / 1ns);
		variable modulo : integer := (target_delay / 1ns) mod (input_p / 1ns);
	begin
		if modulo < (input_p / 1ns) / 2 then
			return ratio;
		else
			return ratio + 1;
		end if;
		--return integer(round(real(time'pos(target_delay)) / real(time'pos(input_period))));
	end count_from_periods;
	constant actual_count : integer := if_expr(mode = "counter", count, count_from_periods);
	constant counter_counter_length : integer := inclusive_range_u(actual_count)'length;
	signal counter_counter : unsigned(counter_counter_length - 1 downto 0) := to_unsigned(actual_count, counter_counter_length);
	signal counting : std_logic := '0';
	signal stop_sig : std_logic := '0';

begin

	stop <= stop_sig;

process(clk, rst)
	variable counter_counter_var : unsigned(counter_counter'range);
begin
	if rst = '1' then
		stop_sig <= '0';
		counter_counter <= to_unsigned(0, counter_counter'length);
		counting <= '0';
	elsif rising_edge(clk) then
		if actual_count = 0 then
			stop_sig <= start;
		else
			if start = '1' then
	            counting <= '1';
	        end if;
	        if start = '1' or counting = '1' then
	            if counter_counter = 0 then
	                stop_sig <= '1';
	                counter_counter <= to_unsigned(actual_count, counter_counter_length);
	                counting <= start;
	            else
	                stop_sig <= '0';
	                counter_counter <= counter_counter - 1;
	            end if;
	        else
	            stop_sig <= '0';
	        end if;
		end if;
        
	end if;
end process;

end chrono;