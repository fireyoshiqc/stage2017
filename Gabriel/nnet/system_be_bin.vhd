use std.textio.all;

library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity system_be_bin is
end system_be_bin;

architecture system_be_bin of system_be_bin is	

component system is
port(
	clk : in std_logic;
    rst : in std_logic;
    start : in std_logic;
    ready : out std_logic;
    ack : in std_logic;
    done : out std_logic;
    in_a : in std_logic_vector(783 downto 0);
    out_a : out std_logic_vector(9 downto 0)
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
		variable res : std_logic_vector(783 downto 0);
		file img_file : text;
		variable values : line;
		variable val_vec : std_logic_vector(9 - 1 downto 0);
		variable value : integer;
	begin
		file_open(img_file, "C:/Users/gademb/cpp/realnetbin_all/input-" & integer'image(cur) & ".nn", read_mode);
		readline(img_file, values);
		for i in 0 to 28 * 28 - 1 loop
			read(values, value);
			if value = 0 then
				res(i) := '0';
			else
				res(i) := '1';
			end if;
		end loop;
		file_close(img_file);
		return res;
	end load_image;
	procedure save_result(file f : text; signal out_a : in std_logic_vector) is
		variable curline : line;
	begin
		for i in 0 to 10 - 1 loop
			if out_a(i)	= '0' then
				write(curline, string'("0"));
			else
				write(curline, string'("1"));
			end if;
			write(curline, " ");
		end loop;
		writeline(f, curline);
	end save_result;

	signal clk, rst, start, ready, ack, done : std_logic;
	signal in_a : std_logic_vector(783 downto 0);
    signal out_a : std_logic_vector(9 downto 0);
begin
    
uut : system port map(
	clk, rst, start, ready, ack, done, in_a, out_a
);
	
process
	file res_file : text;
begin
	file_open(res_file, "C:/Users/gademb/cpp/realnetbin_all/actual.nn", write_mode);
	for i in 0 to 10 loop--10000 - 1 loop
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
end system_be_bin;