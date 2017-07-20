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
    w_query : out std_logic;
    in_offset : out unsigned(bits_needed(input_width) - 1 downto 0);
    w_offset : out unsigned(bits_needed(input_width * output_width / simd_width) - 1 downto 0);
    out_offset : out unsigned(bits_needed(output_width) - 1 downto 0);
    simd_offset : out unsigned(bits_needed(input_width / simd_width - 1) - 1 downto 0);
    op_receive : in std_logic := '0'
);
end fc_controller;

architecture fc_controller of fc_controller is
    constant n_weights : integer := input_width * output_width;
    constant n_iter_per_output : integer := input_width / simd_width;
    signal in_offset_sig : unsigned(in_offset'range);
    signal w_offset_sig : unsigned(w_offset'range);
    signal out_offset_sig : unsigned(out_offset'range);
    signal in_counter : unsigned(bits_needed(n_iter_per_output) - 1 downto 0);
    signal out_counter : unsigned(bits_needed(output_width) - 1 downto 0);
    type state_t is (ready, load, mul_acc, load_next, reduce, wait_for_result, reset_mul_acc, done);
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
process(rst, clk, in_offset_sig, w_offset_sig, out_offset_sig, in_counter, out_counter)
    variable w_offset_var : unsigned(w_offset'range);
    variable in_offset_var : unsigned(in_offset'range);
begin	
    if rst = '1' then
        controls <= controls_from(control_none);
        reset(in_offset_sig, w_offset_sig, out_offset_sig, in_counter, out_counter);
        in_offset <= to_unsigned(0, in_offset'length);
        w_offset <= to_unsigned(0, w_offset'length);
        w_query <= '0';
        state <= ready;
    elsif rising_edge(clk) then
        case state is
        when ready =>
            controls <= controls_from(control_ready);
            reset(in_offset_sig, w_offset_sig, out_offset_sig, in_counter, out_counter);
            in_offset <= to_unsigned(0, in_offset'length);
            w_offset <= to_unsigned(0, w_offset'length);
            simd_offset <= to_unsigned(0, simd_offset'length);
            w_query <= '0';	
            if start = '1' then
                state <= load;
            else
                state <= ready;
            end if;
        when load =>
            controls <= controls_from(control_load);
            in_counter <= in_counter + 1;
            out_offset <= out_offset_sig;
            w_query <= '1';
            state <= mul_acc;
        when mul_acc =>
            controls <= controls_from(control_mul_acc);
            w_offset_var := w_offset_sig + 1;
            w_offset_sig <= w_offset_var;
            w_offset <= w_offset_var;
            simd_offset <= resize(in_counter, simd_offset'length);
            w_query <= '0';
            if in_counter = n_iter_per_output then
                state <= reduce;
            else
                state <= load_next;
            end if;
        when load_next =>
            controls <= controls_from(control_load);
            in_counter <= in_counter + 1;
            w_query <= '1';
            in_offset_var := in_offset_sig + simd_width;
            in_offset_sig <= in_offset_var;
            in_offset <= in_offset_var;
            state <= mul_acc;
        when reduce =>
            controls <= controls_from(control_reduce);
            out_counter <= out_counter + 1;
            in_offset_var := to_unsigned(0, in_offset_sig'length);
            in_offset_sig <= in_offset_var;
            in_offset <= in_offset_var;
            in_counter <= to_unsigned(0, in_counter'length);
            simd_offset <= to_unsigned(0, simd_offset'length);
            state <= wait_for_result;
        when wait_for_result =>
            if op_receive = '0'	then
                state <= wait_for_result;
            else
                state <= reset_mul_acc;
            end if;
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
