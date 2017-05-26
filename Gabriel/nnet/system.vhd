library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity system is
port(clk, rst,
    start : in std_logic;
    ack, done : out std_logic;
    --in_a : in std_logic_vector(6 * 8 - 1 downto 0);
    out_a : out std_logic_vector(3 * 12  - 1 downto 0)
    --test_out : out std_logic_vector(8 - 1 downto 0);
    --clk_out : out std_logic;
    --sel : in unsigned(2 - 1 downto 0)
);
end system;

architecture system of system is

component ps is
port(
    clk, rst : out std_logic
);
end component;

component fc_layer is
generic(
    input_width : integer;
    output_width : integer;
    simd_width : integer;
    input_spec : fixed_spec;
    weight_spec : fixed_spec;
    op_arg_spec : fixed_spec;
    output_spec : fixed_spec;
    ROM_weights : reals
);
port(
    clk, rst : in std_logic;
    ready, done : out std_logic;
    start, ack : in std_logic;
    in_a : in std_logic_vector(input_width * size(input_spec) - 1 downto 0);
    out_a : out std_logic_vector(output_width * size(output_spec) - 1 downto 0);
    out_offset : out unsigned(bits_needed(output_width) - 1 downto 0);
    op_argument : out sfixed(mk(op_arg_spec)'range);
    op_result : in sfixed(mk(output_spec)'range)
);
end component;

component interlayer is
generic(
    width : integer;
    word_size : integer
);
port(
    clk, rst : in std_logic;
    done, ready : in std_logic;
    ack, start : out std_logic;
    previous_a : in std_logic_vector(width * word_size - 1 downto 0);
    next_a : out std_logic_vector(width * word_size - 1 downto 0)
);
end component;

component bias_op is
generic(
    input_spec : fixed_spec;
    bias_spec : fixed_spec;
    biases : reals
);
port(
    input : in sfixed(mk(input_spec)'range);
    offset : in unsigned(bits_needed(biases'length) - 1 downto 0);
    output : out sfixed(mk(input_spec + bias_spec)'range)
);
end component;

component relu_op is
generic(
    spec : fixed_spec
);
port(
    input : in sfixed(mk(spec)'range);
    output : out sfixed(mk(spec)'range)
);
end component;

component sigmoid_op is
generic(
	input_spec : fixed_spec;
	output_spec : fixed_spec;
    step_precision : integer;
	bit_precision : integer
);
port(
    input : in sfixed(mk(input_spec)'range);
    output : out sfixed(mk(output_spec)'range)
);
end component;


constant in_a_raw : reals := (0.854777, 0.359746, 0.381410, 0.256412, 0.337901, 0.529125);
--signal out_a : std_logic_vector(4 * output_word_size  - 1 downto 0);
--signal clk, rst_sink : std_logic;
--constant rst : std_logic := '0';

constant input_width1 : integer := 6;
constant output_width1 : integer := 3;
constant simd_width1 : integer := 2;
constant input_spec1 : fixed_spec := (int => 1, frac => 7);
constant weight_spec1 : fixed_spec := (int => 4, frac => 4);
constant bias_spec1 : fixed_spec := (int => 4, frac => 8);
constant op_arg_spec1 : fixed_spec := (int => 4, frac => 8);
constant output_spec1 : fixed_spec := (int => 4, frac => 8);

signal ready1, done1, start1, ack1 : std_logic;
signal in_a1 : std_logic_vector(input_width1 * size(input_spec1) - 1 downto 0);
signal out_a1 : std_logic_vector(output_width1 * size(output_spec1) - 1 downto 0);
signal out_offset1 : unsigned(bits_needed(output_width1) - 1 downto 0);
signal op_result1_a : sfixed(mk(op_arg_spec1 + bias_spec1)'range);
constant op_argument1_range : sfixed := mk(op_arg_spec1);
signal op_argument1 : sfixed(op_argument1_range'range);
constant op_result1_b_range : sfixed := mk(output_spec1);
signal op_result1_b : sfixed(op_result1_b_range'range);
signal op_result1_c : sfixed(op_result1_b_range'range);

signal done2 : std_logic;

constant in_a_test_raw : reals := (
    0.270478, 0.808408, 0.463890, 0.291382, 0.800599, 0.203051
);
function to_vec(r : reals) return std_logic_vector is
    variable ret : std_logic_vector(input_width1 * size(input_spec1) - 1 downto 0);
begin
    for i in in_a_test_raw'range loop
        ret((1 + i) * size(input_spec1) - 1 downto i * size(input_spec1)) :=
            std_logic_vector(to_sfixed(in_a_test_raw(i), mk(input_spec1)));
    end loop;
    return ret;
end to_vec;

constant ROM_weights1 : reals := (
    1.306903, -0.160192, 1.903822, -2.190612, -2.675583, -2.811914,
    -2.602515, -0.059137, 2.729670, -1.089163, 2.633426, 0.004224,
    -0.800113, 1.111917, 1.625981, 1.330796, 0.119047, -2.141114
);

constant ROM_biases1 : reals := (
    -0.932403, 1.964976, 0.849697
);

--signal clk_out_sig : std_logic := '0';
	signal dummy : sfixed(-1 downto -8) := to_sfixed(0.0, 7, 0);
begin
    --to_integer(sel)
    --test_out <= out_a1((2 + 1) * (output_int_part1 + output_frac_part1) - 1 downto 2 * (output_int_part1 + output_frac_part1));
    --clk_out <= clk_out_sig;
	done <= done1;

--uPS : ps port map(
--    clk => clk,
--    rst => rst_sink
--);

u0 : interlayer generic map(
    width => input_width1,
    word_size => size(input_spec1)
) port map(
    clk => clk,
    rst => rst,
    done => start,
    ready => ready1,
    --ack => 
    start => start1,
    previous_a => to_vec(in_a_test_raw),--in_a,
    next_a => in_a1
);

layer1 : fc_layer generic map(
    input_width => input_width1,
    output_width => output_width1,
    simd_width => simd_width1,
    input_spec => input_spec1,
    weight_spec => weight_spec1,
    op_arg_spec => op_arg_spec1,
    output_spec => output_spec1,
    ROM_weights => ROM_weights1
) port map(
    clk => clk,
    rst => rst,
    ready => ready1,
    done => done1,
    start => start1,
    ack => ack1,
    in_a => in_a1,
    out_a => out_a,
    out_offset => out_offset1,
    op_argument => op_argument1,
    op_result => op_result1_c
);
--out_a <= out_a1;
bias1 : bias_op generic map(
    input_spec => op_arg_spec1,
    bias_spec => bias_spec1,
    biases => ROM_biases1
) port map(
    input => op_argument1,
    offset => out_offset1,
    output => op_result1_a
);
	op_result1_b <= resize(op_result1_a, mk(output_spec1));
	--op_result1_c <= op_result1_b;
sig1 : sigmoid_op generic map(
	input_spec => output_spec1,
	output_spec => output_spec1,
	step_precision => 2,
	bit_precision => 16
) port map(
    input => op_result1_b,
    output => op_result1_c
);
--relu1 : relu_op generic map(
--    spec => output_spec1
--) port map(
--    input => op_result1_b,
--    output => op_result1_c
--);

--process(clk)
--    constant clk_div : integer := 24;
--    variable count : unsigned(clk_div - 1 downto 0) := to_unsigned(0, clk_div);
--begin
--    if rising_edge(clk) then
--        count := count + 1;
--        if count = to_unsigned(0, clk_div) then
--            clk_out_sig <= not clk_out_sig;
--        end if;
--    end if;
--end process;

end system;
