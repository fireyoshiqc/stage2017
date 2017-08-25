library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all; 

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity system_be is
end system_be;

architecture system_be of system_be is	

component system is
port(clk, rst,
    start : in std_logic;
    out_a : out std_logic_vector(10 * 10  - 1 downto 0)
);
end component;

	constant p : time := 20ns;
	
	signal clk, rst, start : std_logic;
    signal out_a : std_logic_vector(10 * 10  - 1 downto 0);
	
	procedure cycle(signal clk : out std_logic) is
	begin
		wait for p / 2;
		clk <= '1';
		wait for p / 2;
		clk <= '0';
	end procedure cycle;
	
begin
    
uut : system port map(
	clk => clk,
	rst => rst,
	start => start,
	out_a => out_a
);
	
process
begin
	clk <= '0';
	rst <= '0';
	start <= '0';
	cycle(clk);
	start <= '1';
	for i in 0 to 800000 loop--while done_port = '0' loop--
		cycle(clk);
		start <= '0';
	end loop;
--	for i in 0 to 10 - 1 loop
--		assert false report real'image(to_real(to_sfixed(out_a((i + 1) * 10 - 1 downto i * 10), 1, -8)));
--		assert false report vec_image(std_logic_vector(to_sfixed(out_a((i + 1) * 10 - 1 downto i * 10), 1, -8)));
--	end loop;
	assert false report "!!!!!!!!!!!!!!!!!!!!!" severity failure;
end process;
end system_be;
