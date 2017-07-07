library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity fcbin_to_fcbin_interlayer is
generic(
    width : integer
);
port(
    clk : in std_logic;
    done, ready : in std_logic;
    ack, start : out std_logic;
    previous_a : in std_logic_vector(width - 1 downto 0);
    next_a : out std_logic_vector(width - 1 downto 0)--;
    --debug : out std_logic_vector(8 - 1 downto 0)
);
end fcbin_to_fcbin_interlayer;

architecture fcbin_to_fcbin_interlayer of fcbin_to_fcbin_interlayer is
begin
process(clk)
    variable pass : std_logic;
begin
    if rising_edge(clk) then
        pass := done and ready;
        ack <= pass;
        start <= pass;
        if pass = '1' then
            next_a <= previous_a;
        end if;
    end if;
end process;
end fcbin_to_fcbin_interlayer;