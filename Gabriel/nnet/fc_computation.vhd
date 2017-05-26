library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.fc_computation_defs.all;
use work.util.all;

entity fc_computation is
generic(
    input_width : integer;
    simd_width : integer;
    output_width : integer;
    input_spec : fixed_spec;
    weight_spec : fixed_spec;
    op_arg_spec : fixed_spec;
    output_spec : fixed_spec
);
port(
    clk, rst : in std_logic;
    directives : in directives_t;
    in_offset : in unsigned(bits_needed(input_width) - 1 downto 0);
    out_offset : in unsigned(bits_needed(output_width) - 1 downto 0);
    in_a : in std_logic_vector(input_width * size(input_spec) - 1 downto 0);
    w_data : in std_logic_vector(simd_width * size(weight_spec) - 1 downto 0);
    out_a : out std_logic_vector(output_width * size(output_spec) - 1 downto 0);
    op_argument : out sfixed(mk(op_arg_spec)'range);
    op_result : in sfixed(mk(output_spec)'range)
);
end fc_computation;

architecture fc_computation of fc_computation is
    
    subtype input_word_t is sfixed(mk(input_spec)'range);
    subtype weight_word_t is sfixed(mk(weight_spec)'range);
    subtype op_arg_word_t is sfixed(mk(op_arg_spec)'range);
    subtype output_word_t is sfixed(mk(output_spec)'range);
    subtype mulacc_word_t is sfixed(input_spec.int + weight_spec.int + input_width / simd_width - 1 downto -(input_spec.frac + weight_spec.frac));
    subtype final_word_t is sfixed(input_spec.int + weight_spec.int + input_width - 1 downto -(input_spec.frac + weight_spec.frac));
    
    type accumulated_t is array(simd_width - 1 downto 0) of mulacc_word_t;
    type reduced_t is array(simd_width - 1 downto 0) of final_word_t;
    
	signal accumulated : accumulated_t := (others => (others => '0'));
	
	function resize_each_to_final(acc : accumulated_t) return reduced_t is
        variable red : reduced_t;
	begin
        for i in acc'range loop
            red(i) := resize(acc(i), red(i));
        end loop;
        return red;
	end resize_each_to_final;
	
    function reduce(acc : accumulated_t) return final_word_t is
        variable p : reduced_t := resize_each_to_final(acc);
        variable end_of_p : integer := p'length;
        variable i : integer := 0;
    begin
        while end_of_p > 1 loop
            while 2 * i < end_of_p loop
                if 2 * i = end_of_p - 1 then
                    p(i) := p(2 * i);
                else
                    p(i) := resize(p(2 * i) + p(2 * i + 1), p(i));
                end if;
                i := i + 1;
            end loop;
            end_of_p := i;
            i := 0;
        end loop;
        return p(0);
    end reduce;
	
	signal out_a_sig : std_logic_vector(output_width * size(output_spec) - 1 downto 0);
	
begin
    
process(clk, rst, op_result)
    variable input_dummy : input_word_t;
    variable weight_dummy : weight_word_t;
    variable op_arg_dummy : op_arg_word_t;
begin
	set(out_a, to_integer(out_offset), op_result);
    if rst = '1' then
        out_a <= (others => '0');
    elsif rising_edge(clk) then
        case directives is
        when directives_from(directive_mul_acc) =>
            for i in accumulated'range loop
                accumulated(i) <= resize(accumulated(i) + resize(get(w_data, i, weight_dummy) * get(in_a, to_integer(in_offset) + i, input_dummy), accumulated(i)), accumulated(i));
            end loop;
        when directives_from(directive_reduce) =>
			op_argument <= resize(reduce(accumulated), op_arg_dummy);
        when directives_from(directive_reset_mul_acc) =>
            accumulated <= (others => (others => '0'));
        when others =>
        end case;
    end if;
end process;

end fc_computation;
