library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.gpio_portal_defs.all;
use work.util.all;

entity gpio_portal_to_ps is
generic(
    n_to : integer;
    word_size_to : integer;
    word_offset_to : integer
);
port(
    clk : in std_logic;
    blocked : in std_logic;
    completed : out std_logic;
    data : in std_logic_vector(n_to * word_size_to - 1 downto 0);
    data_to_ps : out std_logic_vector(7 downto 0);
    dir_low_to_ps : out std_logic_vector(3 downto 0);
    dir_low_from_ps : in std_logic_vector(3 downto 0);
    debug : out std_logic_vector(7 downto 0)
);
end gpio_portal_to_ps;

architecture gpio_portal_to_ps of gpio_portal_to_ps is

    constant word_size_sent : integer := 8;

    function unpad_word(word : std_logic_vector) return std_logic_vector is
        variable ret : std_logic_vector(word_size_sent - 1 downto 0);
    begin
        ret(word_size_sent - 1 downto 0) := word(word_size_sent + word_offset_to - 1 downto word_offset_to);
        return ret;
    end unpad_word;

    type state_t is (idle, read, await);
    signal state : state_t := idle;
    signal cur_dir_to : std_logic_vector := dir(none);
    signal cur_index : unsigned := to_unsigned(0, bits_needed(n_to));
    signal completed_sig : std_logic := '0';

begin
    completed <= completed_sig;
process(clk)
    --variable offset : integer;
    variable dir_sent : std_logic_vector(3 downto 0);
begin
    if rising_edge(clk) then
        if completed_sig = '1' then
            completed_sig <= '0';
        end if;
        if blocked = '0' and dir_low_from_ps = cur_dir_to then
            if cur_dir_to = dir(last) then
                dir_sent := dir(none);
                completed_sig <= '1';
            else
                --offset := to_integer(cur_index * word_size_to);
                --data_to_ps <= unpad_word(data(offset + word_size_to - 1 downto offset));
                data_to_ps <= data(to_integer(cur_index) * word_size_to + word_size_to - (word_size_to - word_size_sent) - 1 downto to_integer(cur_index) * word_size_to);
--                if offset = 1 then
--                    debug <= unpad_word(data(offset + word_size_to - 1 downto offset));
--                end if;
                if cur_index = n_to - 1 then
                    dir_sent := dir(last);
                    cur_index <= to_unsigned(0, cur_index'length);
                else
                    if cur_dir_to = dir(read1) then
                        dir_sent := dir(read2);
                    else
                        dir_sent := dir(read1);
                    end if;
                    cur_index <= cur_index + 1;
                end if;
            end if;
            dir_low_to_ps <= dir_sent;
            cur_dir_to <= dir_sent;
        end if;
    end if;
end process;
end gpio_portal_to_ps;