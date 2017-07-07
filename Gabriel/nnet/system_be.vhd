library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all; 

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;
use work.test_data;

entity system_be is
generic(
    width : integer := 2;
    word_size : integer := 3
);
end system_be;

architecture system_be of system_be is	

component system is
port(clk, rst,
    start : in std_logic;
    --ack, done : out std_logic;
    --in_a : in std_logic_vector(6 * 8 - 1 downto 0);
    --out_a : out std_logic_vector(3 * 10  - 1 downto 0)
    --in_a : in std_logic_vector(test_data.inputs'length * 9 - 1 downto 0);
	--first_done : out std_logic;
	--first_out_off : out unsigned(5 downto 0);
    out_a : out std_logic_vector(3 - 1 downto 0)--std_logic_vector(3 * 10  - 1 downto 0)
    --test_out : out std_logic_vector(8 - 1 downto 0);
    --clk_out : out std_logic;
    --sel : in unsigned(5 - 1 downto 0)--(8 - 1 downto 0)
);
end component;

	signal clk, rst, start : std_logic;--, done, ack : std_logic;
	signal test_out : std_logic_vector(8 - 1 downto 0);
	--signal first_done : std_logic;	 
	--signal first_out_off : unsigned(5 downto 0);
	--signal sel : unsigned(5 - 1 downto 0);
    --signal in_a : std_logic_vector(9 * input_word_size - 1 downto 0);
    signal out_a : std_logic_vector(3 - 1 downto 0);--std_logic_vector(3 * 10  - 1 downto 0);
begin
    
uut : system port map(
	clk, rst, start, out_a--, sel--ack, done, test_out, first_done, first_out_off, 
);
	
process
	constant p : time := 20ns;
begin
	clk <= '0';
	rst <= '0';
	start <= '0';
	--sel <= "00001";
	wait for p / 2;
	clk <= '1';
	wait for p / 2;
	clk <= '0';
	start <= '1';
	for i in 0 to 15 loop	--5600
		wait for p / 2;
		clk <= '1';
		wait for p / 2;
		clk <= '0';
		start <= '0';
	end loop;
--	for i in 0 to 10 - 1 loop
--		assert false report real'image(to_real(to_sfixed(out_a((i + 1) * 10 - 1 downto i * 10), 1, -8)));
--		assert false report vec_image(std_logic_vector(to_sfixed(out_a((i + 1) * 10 - 1 downto i * 10), 1, -8)));
--	end loop;
	assert false report "!!!!!!!!!!!!!!!!!!!!!" severity failure;
end process;
end system_be;