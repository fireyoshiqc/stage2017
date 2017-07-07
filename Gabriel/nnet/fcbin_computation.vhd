library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 
use ieee.math_real.all;

library work;
use work.util.all;

entity fcbin_computation is
generic(
    n_inputs : positive;
    n_outputs : positive;
    simd_width : positive;
    weights : integers;
    biases : integers
);
port(
    clk : std_logic;
    input : in std_logic_vector(n_inputs - 1 downto 0);
    output : out std_logic_vector(n_outputs - 1 downto 0);
    simd_offset : in unsigned(bits_needed(n_outputs - simd_width) - 1 downto 0);
    debug : out std_logic_vector(7 downto 0)
);
end fcbin_computation;

architecture fcbin_computation of fcbin_computation is

	function weights_r_init return std_logic_vector is
		variable res : std_logic_vector(weights'length - 1 downto 0);
	begin
		for i in 0 to res'length - 1 loop
			if weights(i) = 0 then
				res(i) := '0';
			else
				res(i) := '1';
			end if;
		end loop;
		return res;
	end weights_r_init;
	constant weights_r : std_logic_vector := weights_r_init;--weights;
	
	function max_abs_b return integer is
	    variable max_v : integer := 0;
	begin
	    for i in biases'range loop
	        if abs(biases(i)) > max_v then
	            max_v := abs(biases(i));
	        end if;
	    end loop;
	    return max_v;
	end max_abs_b;
	type biases_t is array(0 to biases'length - 1) of signed(bits_needed(max_abs_b) downto 0);
	function biases_as_signed return biases_t is
	    variable b : biases_t;
	begin
	    for i in biases'range loop
	        b(i) := to_signed(biases(i), b(0)'length);
	    end loop;
	    return b;
	end biases_as_signed;
	constant biases_r : biases_t := biases_as_signed;
	constant sz_with_bias : integer := bits_needed(max_abs_b + input'length) + 1;
	
	function threshold return integer is
    begin
        if n_inputs mod 2 = 0 then return n_inputs / 2; else return n_inputs / 2 + 1; end if;
    end threshold;
    function step(val : signed) return std_logic is
    begin
        if val < threshold then return '0'; else return '1'; end if;
    end step;
    function step(val : unsigned) return std_logic is
    begin
        if val < threshold then return '0'; else return '1'; end if;
    end step;
    
component tree_counter is
generic(
    n_bits : integer
);
port(
    bits_input : in std_logic_vector(n_bits - 1 downto 0);
    count_output : out unsigned(integer(floor(log2(real(n_bits)))) downto 0)
);
end component tree_counter;

    type count_sigs_t is array(0 to n_outputs - 1) of unsigned(bits_needed(n_inputs) - 1 downto 0);
    signal count_sigs : count_sigs_t;
    type weight_slices_t is array(0 to n_outputs - 1) of std_logic_vector(n_inputs - 1 downto 0);
    signal weight_slices : weight_slices_t;	
	type bits_input_sigs_t is array(0 to simd_width - 1) of std_logic_vector(input'length - 1 downto 0);
	signal bits_input_sigs : bits_input_sigs_t;

begin


gen_full_simd_case: if simd_width = n_outputs generate

gen_fcbin_outputs: for i in 0 to simd_width - 1 generate
	
	bits_input_sigs(i) <= standard_range(input xnor standard_range(weights_r(n_inputs * (i + 1) - 1 downto n_inputs * i)));
u_count_tree: tree_counter generic map(
    n_bits => input'length
) port map(
    bits_input => bits_input_sigs(i),
    count_output => count_sigs(i)
);
    
process(clk)
begin
    if rising_edge(clk) then
        if biases'length = 0 then
            output(i) <= step(count_sigs(i));
        else
            output(i) <= step(signed(resize(count_sigs(i), sz_with_bias)) + resize(biases_r(i), sz_with_bias));
        end if;
    end if;
end process;

end generate gen_fcbin_outputs;

end generate gen_full_simd_case;


gen_partial_simd_case: if simd_width /= n_outputs generate

gen_weight_slices: for i in 0 to n_outputs - 1 generate
    weight_slices(i) <= standard_range(weights_r(n_inputs * (i + 1) - 1 downto n_inputs * i));
end generate gen_weight_slices;
    
gen_fcbin_outputs: for i in 0 to simd_width - 1 generate
	
	bits_input_sigs(i) <= standard_range(input xnor weight_slices(i + to_integer(simd_offset)));
u_count_tree: tree_counter generic map(
    n_bits => input'length
) port map(
    bits_input => bits_input_sigs(i),
    count_output => count_sigs(i)
);

process(clk)
    variable index : integer;
begin
    if rising_edge(clk) then
        index := i + to_integer(simd_offset);
        if biases'length = 0 then
            output(index) <= step(count_sigs(i));
        else
            output(index) <= step(signed(resize(count_sigs(i), sz_with_bias)) + resize(biases_r(index), sz_with_bias));
        end if;
    end if;
end process;

end generate gen_fcbin_outputs;

end generate gen_partial_simd_case;


end fcbin_computation;
