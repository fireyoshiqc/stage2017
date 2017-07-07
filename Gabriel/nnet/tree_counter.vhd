library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

entity tree_counter is
generic(
    n_bits : integer
);
port(
    bits_input : in std_logic_vector(n_bits - 1 downto 0);
    count_output : out unsigned(integer(floor(log2(real(n_bits)))) downto 0)
);
end tree_counter;

architecture tree_counter of tree_counter is

component tree_counter is
generic(
    n_bits : integer
);
port(
    bits_input : in std_logic_vector;
    count_output : out unsigned
);
end component tree_counter;

    signal count1 : unsigned(count_output'range) := (others => '0');
    signal count2 : unsigned(count_output'range) := (others => '0');

begin

gen_tree_counter_leaf: if n_bits = 1 generate
    count_output <= to_unsigned(0, count_output'length) when bits_input = "0" else to_unsigned(1, count_output'length);
end generate gen_tree_counter_leaf;
gen_tree_counter_branch: if n_bits /= 1 generate
u_branch1: tree_counter generic map(
    n_bits => n_bits / 2
) port map(
    bits_input => bits_input(n_bits / 2 - 1 downto 0),
    count_output => count1(integer(floor(log2(real(n_bits / 2)))) downto 0)
);
u_branch2: tree_counter generic map(
    n_bits => n_bits - n_bits / 2
) port map(
    bits_input => bits_input(n_bits - 1 downto n_bits / 2),
    count_output => count2(integer(floor(log2(real(n_bits - n_bits / 2)))) downto 0)
);
    count_output <= count1 + count2;
end generate gen_tree_counter_branch;

end tree_counter;
