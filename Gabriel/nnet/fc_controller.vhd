library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.math_real.all;

library work;
use work.fc_controller_defs.all;
use work.util.all;

entity fc_controller is
generic(
    input_width : integer;
    output_width : integer;
    simd_width : integer
);
port(
    clk, rst : in std_logic;
    start, ack : in std_logic;
    controls : out controls_t;
    in_offset : out unsigned(bits_needed(input_width) - 1 downto 0);
    w_offset : out unsigned(bits_needed(input_width * output_width) - 1 downto 0);
    out_offset : out unsigned(bits_needed(output_width) - 1 downto 0)
);
end fc_controller;

architecture fc_controller of fc_controller is
    constant n_weights : integer := input_width * output_width;
    constant n_iter_per_output : integer := input_width / simd_width;
    signal in_offset_sig : unsigned(bits_needed(input_width) - 1 downto 0) := to_unsigned(0, bits_needed(input_width));
    signal w_offset_sig : unsigned(bits_needed(n_weights) - 1 downto 0) := to_unsigned(0, bits_needed(n_weights));
    signal out_offset_sig : unsigned(bits_needed(output_width) - 1 downto 0) := to_unsigned(0, bits_needed(output_width));
    signal in_counter : unsigned(bits_needed(n_iter_per_output) - 1 downto 0) := to_unsigned(0, bits_needed(n_iter_per_output));
    signal out_counter : unsigned(bits_needed(output_width) - 1 downto 0) := to_unsigned(0, bits_needed(output_width));
    type state_t is (ready, load, mul_acc, load_next, reduce, reset_mul_acc, done);
    signal state : state_t := ready;
	procedure reset(signal a : out unsigned; signal b : out unsigned; signal c : out unsigned; signal d : out unsigned; signal ee : out unsigned) is 
	begin
		a <= to_unsigned(0, a'length);
		b <= to_unsigned(0, b'length);
		c <= to_unsigned(0, c'length);
		d <= to_unsigned(0, d'length);
		ee <= to_unsigned(0, ee'length);
	end reset;
begin
    in_offset <= in_offset_sig;
process(rst, clk)
begin	
    if rst = '1' then
        controls <= controls_from(control_none);
        reset(in_offset_sig, w_offset_sig, out_offset_sig, in_counter, out_counter);
        state <= ready;
    elsif rising_edge(clk) then
        case state is
        when ready =>
            controls <= controls_from(control_ready);
            reset(in_offset_sig, w_offset_sig, out_offset_sig, in_counter, out_counter);
            if start = '1' then
                state <= load;
			else
				state <= ready;
            end if;
        when load =>
			controls <= controls_from(control_load);
			in_counter <= in_counter + 1;
			out_offset <= out_offset_sig;
            state <= mul_acc;
        when mul_acc =>
            controls <= controls_from(control_mul_acc);
			w_offset <= w_offset_sig;
            if in_counter = n_iter_per_output then
                state <= reduce;
            else
                state <= load_next;
            end if;
		when load_next =>
			controls <= controls_from(control_load);
			in_counter <= in_counter + 1;
			w_offset_sig <= w_offset_sig + simd_width;
			in_offset_sig <= in_offset_sig + simd_width;
			state <= mul_acc;
        when reduce =>
            controls <= controls_from(control_reduce);
            out_counter <= out_counter + 1;
			w_offset_sig <= w_offset_sig + simd_width;
            in_offset_sig <= to_unsigned(0, in_offset_sig'length);
            in_counter <= to_unsigned(0, in_counter'length);
            state <= reset_mul_acc;
        when reset_mul_acc =>
			controls <= controls_from(control_reset_mul_acc);
			out_offset_sig <= out_offset_sig + 1;
            if out_counter = output_width then
                state <= done;
            else
                state <= load;
            end if;
        when done =>
            controls <= controls_from(control_done);
            if ack = '1' then
                state <= ready;
            else
                state <= done;
            end if;
        end case;
    end if;
end process;
end fc_controller;
