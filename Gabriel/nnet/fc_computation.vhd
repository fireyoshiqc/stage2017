library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.math_real.all;

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
    output_spec : fixed_spec;
    pick_from_ram : boolean
);
port(
    clk, rst : in std_logic;
    directives : in directives_t;
    in_offset : in unsigned(bits_needed(input_width) - 1 downto 0);
    out_offset : in unsigned(bits_needed(output_width) - 1 downto 0);
    in_a : in std_logic_vector(if_then_else(pick_from_ram,
                                   simd_width * size(input_spec),
                                   input_width * size(input_spec)) - 1 downto 0);
    w_data : in std_logic_vector(simd_width * size(weight_spec) - 1 downto 0);
    out_a : out std_logic_vector(output_width * size(output_spec) - 1 downto 0);
    op_argument : out sfixed(mk(op_arg_spec)'range);
    op_result : in sfixed(mk(output_spec)'range);
	op_send : out std_logic := '0'
);
end fc_computation;

architecture fc_computation of fc_computation is

--component mulacc is
--generic(
--    a_spec, b_spec, c_spec : fixed_spec
--);
--port(
--    acc, clr : in std_logic;
--    a : in sfixed(mk(a_spec)'range);
--    b : in sfixed(mk(b_spec)'range);
--    c : out sfixed(mk(c_spec)'range)
--);
--end component mulacc;
    
    subtype input_word_t is sfixed(mk(input_spec)'range);
    subtype weight_word_t is sfixed(mk(weight_spec)'range);
    subtype op_arg_word_t is sfixed(mk(op_arg_spec)'range);
    subtype output_word_t is sfixed(mk(output_spec)'range);
    constant mul_spec : fixed_spec := input_spec * weight_spec;
    constant n_accumulated : integer := input_width / simd_width;
    constant mulacc_int_sz : integer := integer(ceil(log2(real(n_accumulated * 2**mul_spec.int + 1))));
    subtype mulacc_word_t is sfixed(mulacc_int_sz - 1 downto -mul_spec.frac);
	
    function half_upper(x : integer) return integer is
    begin
        if x mod 2 = 0 then
            return x / 2;
        else
            return (x + 1) / 2;
        end if;
    end half_upper;
    
    
--    function reduce(vals : std_logic_vector; remaining : integer; spec : fixed_spec) return sfixed is
--        variable res : std_logic_vector(half_upper(remaining) * size(spec + spec) - 1 downto 0);
--    begin
--        if remaining = 1 then
--            return resize(to_sfixed(vals, mk(spec)), mk(op_arg_spec));
--        else
--            for i in 0 to remaining / 2 - 1 loop
--                set_var(res, i, get(vals, 2 * i, mk(spec)) + get(vals, 2 * i + 1, mk(spec)));
--            end loop;
--            if remaining mod 2 /= 0 then
--                set_var(res, half_upper(remaining) - 1, resize(get(vals, remaining - 1, mk(spec)), mk(spec + spec)));
--            end if;
--            return reduce(res, half_upper(remaining), spec + spec);
--        end if;
--    end reduce;
	
	type simd_mulacc_cells_t is array(0 to simd_width - 1) of mulacc_word_t;
	signal simd_mulacc_cells : simd_mulacc_cells_t := (others => (others => '0'));
	
	function prepare2(cells : simd_mulacc_cells_t) return std_logic_vector is
        variable prep : std_logic_vector(cells'length * cells(0)'length - 1 downto 0);
    begin
        for i in cells'range loop
            prep((i + 1) * cells(0)'length - 1 downto i * cells(0)'length) := std_logic_vector(cells(i));
        end loop;
        return prep;
    end prepare2;
    
--    function reduceX(cells : simd_mulacc_cells_t; i : integer) return sfixed is
--    begin
--        if cells'length - 1 = i then
--            return cells(i);
--        else
--            return cells(i) + reduceX(cells, i + 1);
--        end if;
--    end reduceX;
    
    function reduce2(vals : std_logic_vector; remaining : integer; spec : fixed_spec) return sfixed is
        variable res : std_logic_vector(half_upper(remaining) * size(spec + spec) - 1 downto 0);
    begin
        if remaining = 1 then
            return resize(to_sfixed(vals, mk(spec)), mk(op_arg_spec));
        else
            for i in 0 to remaining / 2 - 1 loop
                --set_var(res, i, get(vals, 2 * i, mk(spec)) + get(vals, 2 * i + 1, mk(spec)));
                res((i + 1) * size(spec + spec) - 1 downto i * size(spec + spec))
                    := std_logic_vector(
                        to_sfixed(vals((2 * i + 1) * size(spec) - 1 downto 2 * i * size(spec)), mk(spec)) +
                        to_sfixed(vals((2 * i + 2) * size(spec) - 1 downto (2 * i + 1) * size(spec)), mk(spec))
                    );
            end loop;
            if remaining mod 2 /= 0 then
                --set_var(res, half_upper(remaining) - 1, resize(get(vals, remaining - 1, mk(spec)), mk(spec + spec)));
                res(half_upper(remaining) * size(spec + spec) - 1 downto (half_upper(remaining) - 1) * size(spec + spec))
                    := std_logic_vector(
                        resize(to_sfixed(vals(remaining * size(spec) - 1 downto (remaining - 1) * size(spec)), mk(spec)), mk(spec + spec))
                    );
            end if;
            return reduce2(res, half_upper(remaining), spec + spec);
        end if;
    end reduce2;
	
    signal out_a_reg : std_logic_vector(output_width * size(output_spec) - 1 downto 0);
    signal op_argument_reg : sfixed(mk(op_arg_spec)'range);
    --attribute dont_touch : string;
    --attribute dont_touch of op_argument_reg : signal is "true";
    
    signal op_send_off_delay : std_logic := '0';
	signal debug : op_arg_word_t;
begin
    
    --out_a <= out_a_reg;
    --op_argument <= op_argument_reg;

process(clk, rst, in_a, in_offset, w_data)
begin
    if rising_edge(clk) then
        if op_send_off_delay = '1' then
            op_argument <= op_argument_reg;
            op_send <= '1';
            op_send_off_delay <= '0';
        end if;
        case directives is
        when directives_from(directive_mul_acc) =>
            for i in simd_mulacc_cells'range loop
                simd_mulacc_cells(i) <= resize(simd_mulacc_cells(i) + get(w_data, i, mk(weight_spec)) * get(in_a, if_then_else(pick_from_ram, 0, to_integer(in_offset)) + i, mk(input_spec)), simd_mulacc_cells(i));
			end loop;
        when directives_from(directive_reduce) =>
            op_argument_reg <= reduce2(prepare2(simd_mulacc_cells), simd_mulacc_cells'length, specof(simd_mulacc_cells(0)));--resize(reduce(prepare2(simd_mulacc_cells), simd_mulacc_cells'length, specof(simd_mulacc_cells(0))), mk(op_arg_spec));--resize(reduceX(simd_mulacc_cells, 0), mk(op_arg_spec));
            --op_send <= '1';
            op_send_off_delay <= '1';
        when directives_from(directive_reset_mul_acc) =>
            set(out_a, to_integer(out_offset), op_result);
            for i in simd_mulacc_cells'range loop
                simd_mulacc_cells(i) <= (others => '0');
            end loop;
        when others =>
            if op_send_off_delay = '0' then
                op_send <= '0';
            end if;
        end case;
    end if;
end process;

end fc_computation;
