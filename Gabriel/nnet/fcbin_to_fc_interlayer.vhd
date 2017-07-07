library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fcbin_to_fc_interlayer is
generic(
    width : integer;
    word_size : integer
);
port(
    clk, rst : in std_logic;
    done, ready : in std_logic;
    ack, start : out std_logic;
    previous_a : in std_logic_vector(width - 1 downto 0);
    next_a : out std_logic_vector(width * word_size - 1 downto 0)
);
end fcbin_to_fc_interlayer;

architecture fcbin_to_fc_interlayer of fcbin_to_fc_interlayer is

    function stretch(b : std_logic) return std_logic_vector is
        variable res : std_logic_vector(word_size - 2 downto 0);
    begin
        for i in res'range loop
            res(i) := b;
        end loop;
        return "0" & res;
    end stretch;

begin

process(clk)
    variable pass : std_logic;
begin
    if rising_edge(clk) then
        pass := done and ready;
        ack <= pass;
        start <= pass;
        if pass = '1' then
            for i in previous_a'range loop
                next_a((i + 1) * word_size downto i * word_size) <= stretch(previous_a(i));
            end loop;
        end if;
    end if;
end process;

end fcbin_to_fc_interlayer;
