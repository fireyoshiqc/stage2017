library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;
library work;
use work.util.all;

entity serializer is
generic(
    width : positive := 8;
    high_to_low : boolean := true;
    eager : boolean := true
);
port(
    clk, rst : in std_logic;
    word : in std_logic_vector(width - 1 downto 0);
    serial : out std_logic := '0';
	pulse : out	std_logic;
    start : in std_logic;
    done : out std_logic := '1'
);
end serializer;

architecture serializer of serializer is

    type state_t is (idle_s, send_s);
    signal state : state_t := idle_s;
    signal counter : unsigned(inclusive_range_u(width)'range) := to_unsigned(0, inclusive_range_u(width)'length);
    signal word_reg : std_logic_vector(word'range);
	signal pulse_reg : std_logic := '0';
	
procedure shift_into_serial(signal source : in std_logic_vector; signal dest : out std_logic_vector; signal serial : out std_logic) is
begin
	if high_to_low then
        serial <= source(source'high);
        dest <= source(source'high - 1 downto source'low) & '0';
    else
        serial <= source(source'low);
        dest <= '0' & source(source'high downto source'low + 1);
    end if; 
end shift_into_serial;

begin
	
	pulse <= pulse_reg;
	
eager_gen: if eager generate
	pulse_reg <= not clk when state = send_s else pulse_reg;
process(clk, rst)
    variable counter_plus_one : unsigned(counter'range);
begin
    if rst = '1' then
        serial <= '0';
        done <= '1';
        counter <= to_unsigned(0, counter'length);
        state <= idle_s;	   
	elsif rising_edge(clk) then
        case state is
        when idle_s =>
            --done <= '1';
            if start = '1' then
                shift_into_serial(word, word_reg, serial);
				if width > 1 then
					done <= '0';
					counter <= to_unsigned(1, counter'length);
					state <= send_s;
				end if;
            end if;
        when send_s =>
            shift_into_serial(word_reg, word_reg, serial);
            counter_plus_one := counter + 1;
            --done <= '0';
            if counter_plus_one = width then
				done <= '1';
				counter <= to_unsigned(0, counter'length);
                state <= idle_s;
            else
                done <= '0';
                counter <= counter_plus_one;
				state <= send_s;
            end if;
        end case;
    end if;
end process;
end generate eager_gen;

not_eager_gen: if not eager generate
	pulse_reg <= not clk when counter /= 0 else pulse_reg;
process(clk, rst)
    variable counter_plus_one : unsigned(counter'range);
begin
    if rst = '1' then
        serial <= '0';
        done <= '1';
        counter <= to_unsigned(0, counter'length);
        state <= idle_s;
    elsif rising_edge(clk) then
        case state is
            when idle_s =>
            done <= '1';
            counter <= to_unsigned(0, counter'length);
            word_reg <= word;
            if start = '1' then
                state <= send_s;
            end if;
        when send_s =>
            done <= '0';
            counter_plus_one := counter + 1;
            counter <= counter_plus_one;
            shift_into_serial(word_reg, word_reg, serial);
            if counter_plus_one = width then
                state <= idle_s;
            end if;
        end case;
    end if;
end process;
end generate not_eager_gen;

end serializer;
