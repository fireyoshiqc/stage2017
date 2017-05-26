library ieee;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.util.all;

entity system_be is
generic(
    width : integer := 2;
    word_size : integer := 3
);
end system_be;

architecture system_be of system_be is	

component system is
port(
    clk, rst, start : in std_logic;
    ack, done : out std_logic;
    out_a : out std_logic_vector(3 * 12  - 1 downto 0)
);
end component;

	signal clk, rst, start, done, ack : std_logic;
    --signal in_a : std_logic_vector(9 * input_word_size - 1 downto 0);
    signal out_a : std_logic_vector(3 * 12  - 1 downto 0);
begin
    
uut : system port map(
	clk, rst, start, ack, done, out_a
);
	
process
	constant p : time := 20ns;
begin
	clk <= '0';
	rst <= '0';
	start <= '0';
	wait for p / 2;
	clk <= '1';
	wait for p / 2;
	clk <= '0';
	start <= '1';
	for i in 0 to 150 loop
		wait for p / 2;
		clk <= '1';
		wait for p / 2;
		clk <= '0';
	end loop;
	assert false report "!!!!!!!!!!!!!!!!!!!!!" severity failure;
end process;
end system_be;