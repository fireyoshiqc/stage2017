use std.textio.all;

library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity system_be2 is
end system_be2;

architecture system_be2 of system_be2 is	

component system is
port(
	clk : in std_logic;
    rst : in std_logic;
    start : in std_logic;
    ready : out std_logic;
    ack : in std_logic;
    done : out std_logic;
    in_a : in std_logic_vector(7055 downto 0);
    out_a : out std_logic_vector(99 downto 0)
);
end component;

	constant p : time := 20ns;
	
	procedure cycle(signal clk : out std_logic) is
	begin
		wait for p / 2;
		clk <= '1';
		wait for p / 2;
		clk <= '0';
	end;
	impure function load_image(cur : integer) return std_logic_vector is
		variable res : std_logic_vector(7055 downto 0);
		file img_file : text;
		variable values : line;
		variable val_vec : std_logic_vector(9 - 1 downto 0);
		variable value : real;
	begin
		file_open(img_file, "C:/Users/gademb/cpp/realnet_all/input-" & integer'image(cur) & ".nn", read_mode);
		readline(img_file, values);
		for i in 0 to 28 * 28 - 1 loop
			read(values, value);
			val_vec := "0" & std_logic_vector(to_unsigned(integer(round(value * 255.0)), 8));
			res(9 * (i + 1) - 1 downto 9 * i) := std_logic_vector(to_sfixed(val_vec, 0, -8));
		end loop;
		file_close(img_file);
		return res;
	end load_image;
	procedure save_result(file f : text; signal out_a : in std_logic_vector) is
		variable curline : line;
	begin
		for i in 0 to 10 - 1 loop
			write(curline, to_real(to_sfixed(out_a((i + 1) * 10 - 1 downto i * 10), 1, -8)));
			write(curline, " ");
		end loop;
		writeline(f, curline);
	end save_result;

	signal clk, rst, start, ready, ack, done : std_logic;
	signal in_a : std_logic_vector(7055 downto 0);
    signal out_a : std_logic_vector(99 downto 0);
begin
    
uut : system port map(
	clk, rst, start, ready, ack, done, in_a, out_a
);
	
process
	file res_file : text;
begin
	file_open(res_file, "C:/Users/gademb/cpp/realnet_all/actual.nn", write_mode);
	for i in 0 to 10000 - 1 loop
		clk <= '0';
		rst <= '0';
		start <= '1';
		ack <= '1';
		in_a <= load_image(i);
		cycle(clk);
		cycle(clk);
		start <= '0';
		while done /= '1' loop
			cycle(clk);
		end loop;
		save_result(res_file, out_a);
		assert false report "Done for image " & integer'image(i) & ".";
	end loop;
	file_close(res_file);
	assert false report "All done." severity failure;
end process;
end system_be2;
