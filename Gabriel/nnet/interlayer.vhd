library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity interlayer is
generic(
    width : integer := 6;
    word_size : integer := 7
);
port(
    clk, rst : in std_logic;
    done, ready : in std_logic;
    ack, start : out std_logic;
    previous_a : in std_logic_vector(width * word_size - 1 downto 0);
    next_a : out std_logic_vector(width * word_size - 1 downto 0)
);
end interlayer;

architecture interlayer of interlayer is
begin
process(clk, rst)
    variable pass : std_logic;
begin
    if rst = '1' then
        ack <= '0';
        start <= '0';
        next_a <= (width * word_size - 1 downto 0 => '0');
    elsif rising_edge(clk) then
        pass := done and ready;
        ack <= pass;
        start <= pass;
        if pass = '1' then
            next_a <= previous_a;
        end if;
    end if;
end process;
end interlayer;
