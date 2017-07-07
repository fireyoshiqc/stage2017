library IEEE;
use IEEE.STD_LOGIC_1164.ALL; 

library work;
use work.util.all;

entity fc_to_fcbin_interlayer is
generic(
    width : integer;
    word_size : integer
);
port(
    clk, rst : in std_logic;
    done, ready : in std_logic;
    ack, start : out std_logic;
    previous_a : in std_logic_vector(width * word_size - 1 downto 0);
    next_a : out std_logic_vector(width - 1 downto 0)
);
end fc_to_fcbin_interlayer;

architecture fc_to_fcbin_interlayer of fc_to_fcbin_interlayer is
begin

process(clk)
    variable pass : std_logic;
begin
    if rising_edge(clk) then
        pass := done and ready;
        ack <= pass;
        start <= pass;
        if pass = '1' then
            for i in next_a'range loop
                next_a(i) <= standard_range(previous_a((i + 1) * word_size downto i * word_size))(word_size - 2);
            end loop;
        end if;
    end if;
end process;

end fc_to_fcbin_interlayer;
