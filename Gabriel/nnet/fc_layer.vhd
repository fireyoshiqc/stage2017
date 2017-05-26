library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.fc_controller_defs.all;
use work.fc_computation_defs.all;
use work.util.all;

entity fc_layer is
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
end fc_layer;

architecture fc_layer of fc_layer is

component fc_controller is
generic(
    input_width : integer;
    output_width : integer;
    simd_width : integer
);
port(
    clk, rst : in std_logic;
    start, ack : in std_logic;
    controls : out controls_t;
    in_offset : out unsigned(bits_needed(input_width) - 1 downto 0);
    w_offset : out unsigned(bits_needed(input_width * output_width) - 1 downto 0);
    out_offset : out unsigned(bits_needed(output_width) - 1 downto 0)
);
end component;

component fc_computation is
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
end component;

component fc_weights is
generic(
    simd_width : integer;
    weight_spec : fixed_spec;
    ROM_weights : reals
);
port(
    w_offset : in unsigned(bits_needed(ROM_weights'length) - 1 downto 0);
    w_data : out std_logic_vector(simd_width * size(weight_spec) - 1 downto 0)
);
end component;

    signal controls : controls_t;
    signal in_offset : unsigned(bits_needed(input_width) - 1 downto 0);
    signal w_offset : unsigned(bits_needed(input_width * output_width) - 1 downto 0);
    signal out_offset_sig : unsigned(bits_needed(output_width) - 1 downto 0);
    
    signal directives : directives_t;
    
    signal w_data : std_logic_vector(simd_width * size(weight_spec) - 1 downto 0);
	
	signal out_a_sig : std_logic_vector(output_width * size(output_spec) - 1 downto 0);

begin
    assert input_width mod simd_width = 0 report "Input width must be a multiple of simd width. You can try padding the weight matrix with zeros or choosing another simd width." severity failure;

    ready <= controls(control_ready);
    done <= controls(control_done);
	
	directives <= (controls(control_mul_acc), controls(control_reduce), controls(control_reset_mul_acc));
	
	out_offset <= out_offset_sig;
	
u1 : fc_controller generic map(
    input_width => input_width,
    output_width => output_width,
    simd_width => simd_width
)
port map (
    clk => clk,
    rst => rst,
    start => start,
    ack => ack,
    controls => controls,
    in_offset => in_offset,
    w_offset => w_offset,
    out_offset => out_offset_sig
);

u2 : fc_computation generic map(
    input_width => input_width,
    simd_width => simd_width,
    output_width => output_width,
    input_spec => input_spec,
    weight_spec => weight_spec,
    op_arg_spec => op_arg_spec,
    output_spec => output_spec
)
port map (
    clk => clk,
    rst => rst,
    directives => directives,
    in_offset => in_offset,
    out_offset => out_offset_sig,
    in_a => in_a,
    w_data => w_data,
    out_a => out_a,
    op_argument => op_argument,
    op_result => op_result
);
u3 : fc_weights generic map(
    simd_width => simd_width,
    weight_spec => weight_spec,
    ROM_weights => ROM_weights
)
port map (
    w_offset => w_offset,
    w_data => w_data
);
end fc_layer;
