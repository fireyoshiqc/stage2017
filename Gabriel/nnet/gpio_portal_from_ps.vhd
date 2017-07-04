library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.gpio_portal_defs.all;
use work.util.all;

entity gpio_portal_from_ps is
generic(
    n_from : integer;
    word_size_from : integer;
    word_offset_from : integer
);
port(
    clk : in std_logic;
    blocked : in std_logic;
    completed : out std_logic;
    data : out std_logic_vector(n_from * word_size_from - 1 downto 0);
    data_from_ps : in std_logic_vector(7 downto 0);
    dir_low_from_ps : in std_logic_vector(3 downto 0);
    dir_low_to_ps : out std_logic_vector(3 downto 0);
    debug : out std_logic_vector(7 downto 0)
);
end gpio_portal_from_ps;

architecture gpio_portal_from_ps of gpio_portal_from_ps is

    constant word_size_sent : integer := 8;

    function pad_word(word : std_logic_vector) return std_logic_vector is
        variable ret : std_logic_vector(word_size_from - 1 downto 0);
    begin
        ret := (others => '0');
        ret(word_size_sent + word_offset_from - 1 downto word_offset_from) := word(word_size_sent - 1 downto 0);
        return ret;
    end pad_word;

    type state_t is (idle, read, await);
    signal state : state_t := idle;
    signal cur_dir_from : std_logic_vector := dir(none);
    signal cur_index : unsigned := to_unsigned(0, bits_needed(n_from));
    signal completed_sig : std_logic := '0';
    
    signal data_reg : std_logic_vector(n_from * word_size_from - 1 downto 0) := (others => '0');
    signal debug_reg : std_logic_vector(7 downto 0) := "00000000";

begin
    completed <= completed_sig;
    data <= data_reg;
    debug <= debug_reg;
process(clk)
    --variable offset : integer;
begin
    if rising_edge(clk) then
        if completed_sig = '1' then
            completed_sig <= '0';
        end if;
        if blocked = '0' then
            case state is
            when idle =>
                if dir_low_from_ps /= dir(none) then
                    state <= read;
                end if;
            when read =>
                if dir_low_from_ps /= cur_dir_from then
                    --offset := to_integer(cur_index * word_size_from);
                    --data_reg(offset + word_size_from - 1 downto offset) <= "0" & data_from_ps;--pad_word(data_from_ps); --FAIL??
                    data_reg(to_integer(cur_index) * word_size_from + word_size_from - (word_size_from - word_size_sent) - 1 downto to_integer(cur_index) * word_size_from) <= data_from_ps;
--                    if cur_index > 0 and debug_reg = "00000000" and unsigned(data_reg(7 downto 0)) /= 69 then
--                        debug_reg <= std_logic_vector(resize(cur_index, 8));
--                    end if;
                    dir_low_to_ps <= dir_low_from_ps;
                    case dir_low_from_ps is
                    when dir(read1) | dir(read2) =>
                        cur_index <= cur_index + 1;
                    when dir(last) =>
                        cur_index <= to_unsigned(0, cur_index'length);
                        state <= await;
                    when others =>
                    end case;
                end if;
                cur_dir_from <= dir_low_from_ps;
            when await =>
                if dir_low_from_ps = dir(none) then
                    debug <= data_reg(7 downto 0);
                    dir_low_to_ps <= dir(none);
                    completed_sig <= '1';
                    state <= idle;
                end if;
            end case;
        end if;
    end if;
end process;
end gpio_portal_from_ps;
