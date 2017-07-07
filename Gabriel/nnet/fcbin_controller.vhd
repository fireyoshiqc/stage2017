library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  
use ieee.math_real.all;

library work;
use work.util.all;

entity fcbin_controller is
generic(
    n_inputs : positive;
    n_outputs : positive;
    simd_width : positive
);
port(
    clk : in std_logic;
    start, ack : in std_logic;
    ready : out std_logic := '1';
    done : out std_logic := '0';
    simd_offset : out unsigned(bits_needed(n_outputs - simd_width) - 1 downto 0)
);
end fcbin_controller;

architecture fcbin_controller of fcbin_controller is

    type state_t is (ready_s, fire_s, done_s);
    signal state : state_t := ready_s;
    signal simd_offset_sig : unsigned(simd_offset'range) := to_unsigned(0, simd_offset'length);

begin

process(clk)
    variable simd_offset_var : unsigned(simd_offset_sig'range);
begin
    if rising_edge(clk) then
        case state is
        when ready_s =>
            if start = '1' then
                ready <= '0';
                if simd_width = n_outputs then
                    done <= '1';
                    state <= done_s;
                else
                    simd_offset_var := simd_offset_sig + simd_width;
                    simd_offset_sig <= simd_offset_var;
                    simd_offset <= simd_offset_var;
                    state <= fire_s;
                end if;
            end if;
        when fire_s =>
            if simd_width /= n_outputs then
                if simd_offset_sig = n_outputs - simd_width then
                    simd_offset_var := to_unsigned(0, simd_offset_sig'length);
                    done <= '1';
                    state <= done_s;
                else
                    simd_offset_var := simd_offset_sig + simd_width;
                end if;
                simd_offset_sig <= simd_offset_var;
                simd_offset <= simd_offset_var;
            end if;
        when done_s =>
            if ack = '1' then
                ready <= '1';
                done <= '0';
                state <= ready_s;
            end if;
        end case;
    end if;
end process;

end fcbin_controller;
