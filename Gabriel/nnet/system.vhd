use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity system is
port(
    start : in std_logic;
    test_out : out std_logic_vector(8 - 1 downto 0);
    sel : in unsigned(8 - 1 downto 0)
);
end system;

architecture system of system is

component fc_layer is
generic(
    input_width : integer;
    output_width : integer;
    simd_width : integer;
    input_spec : fixed_spec;
    weight_spec : fixed_spec;
    op_arg_spec : fixed_spec;
    output_spec : fixed_spec;
    n_weights : integer;
    weights_filename : string;
    weight_values : reals
);
port(
    clk : in std_logic;
    rst : in std_logic;
    ready : out std_logic;
    done : out std_logic;
    start : in std_logic;
    ack : in std_logic;
    in_a : in std_logic_vector(53 downto 0);
    out_a : out std_logic_vector(29 downto 0);
    out_offset : out unsigned(1 downto 0);
    op_argument : out sfixed(8 downto -12);
    op_result : in sfixed(1 downto -8);
    op_send : out std_logic;
    op_receive : in std_logic
);
end component;

component interlayer is
generic(
    width : integer;
    word_size : integer
);
port(
    clk : in std_logic;
    rst : in std_logic;
    ready : in std_logic;
    done : in std_logic;
    start : out std_logic;
    ack : out std_logic;
    previous_a : in std_logic_vector(53 downto 0);
    next_a : out std_logic_vector(53 downto 0)
);
end component;

component bias_op is
generic(
    input_spec : fixed_spec;
    bias_spec : fixed_spec;
    biases : reals
);
port(
    input : in sfixed(8 downto -12);
    offset : in unsigned(1 downto 0);
    output : out sfixed(9 downto -12);
    op_send : out std_logic;
    op_receive : in std_logic
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
    clk : in std_logic;
    input : in sfixed(9 downto -12);
    output : out sfixed(1 downto -8);
    op_send : out std_logic;
    op_receive : in std_logic
);
end component;




signal ready_s12 : std_logic;
signal done_s13 : std_logic;
signal start_s14 : std_logic;
signal ack_s15 : std_logic;
signal in_a_s16 : std_logic_vector(53 downto 0);
signal out_a_s17 : std_logic_vector(29 downto 0);
signal out_offset_s18 : unsigned(1 downto 0);
signal op_argument_s19 : sfixed(8 downto -12);
signal op_result_s20 : sfixed(1 downto -8);
signal op_send_s21 : std_logic;
signal op_receive_s22 : std_logic;



signal ready_s25 : std_logic;
signal done_s26 : std_logic;
signal start_s27 : std_logic;
signal ack_s28 : std_logic;
signal previous_a_s29 : std_logic_vector(53 downto 0);
signal next_a_s30 : std_logic_vector(53 downto 0);

signal input_s6 : sfixed(8 downto -12);
signal offset_s7 : unsigned(1 downto 0);
signal output_s8 : sfixed(9 downto -12);
signal op_send_s9 : std_logic;
signal op_receive_s10 : std_logic;


signal input_s1 : sfixed(9 downto -12);
signal output_s2 : sfixed(1 downto -8);
signal op_send_s3 : std_logic;
signal op_receive_s4 : std_logic;


component ps is
port(
    clk, rst : out std_logic
);
end component;

signal clk, rst_sink : std_logic;
constant rst : std_logic := '0';

function to_vec(r : reals) return std_logic_vector is
    constant input_spec : fixed_spec := fixed_spec(fixed_spec'(int => 1, frac => 8));
    variable ret : std_logic_vector(6 * size(input_spec) - 1 downto 0);
begin
    for i in r'range loop
        ret((1 + i) * size(input_spec) - 1 downto i * size(input_spec)) :=
            std_logic_vector(to_sfixed(r(i), mk(input_spec)));
    end loop;
    return ret;
end to_vec;

begin

fc_layer_u11 : fc_layer generic map(
    input_width => 6,
    output_width => 3,
    simd_width => 2,
    input_spec => fixed_spec(fixed_spec'(int => 1, frac => 8)),
    weight_spec => fixed_spec(fixed_spec'(int => 4, frac => 4)),
    op_arg_spec => fixed_spec(fixed_spec'(int => 9, frac => 12)),
    output_spec => fixed_spec(fixed_spec'(int => 2, frac => 8)),
    n_weights => 18,
    weights_filename => "whatever",
    weight_values => reals(reals'( 1.3069030, -0.1601920, 1.9038220, -2.1906120, -2.6755830, -2.8119140, -2.6025150, -0.0591370, 2.7296700, -1.0891630, 2.6334260, 0.0042240, -0.8001130, 1.1119170, 1.6259810, 1.3307960, 0.1190470, -2.1411140))
) port map(
    clk => clk,
    rst => rst,
    ready => ready_s12,
    done => done_s13,
    start => start_s14,
    ack => ack_s15,
    in_a => in_a_s16,
    out_a => out_a_s17,
    out_offset => out_offset_s18,
    op_argument => op_argument_s19,
    op_result => op_result_s20,
    op_send => op_send_s21,
    op_receive => op_receive_s22
);
interlayer_u24 : interlayer generic map(
    width => 6,
    word_size => 9
) port map(
    clk => clk,
    rst => rst,
    ready => ready_s25,
    done => done_s26,
    start => start_s27,
    ack => ack_s28,
    previous_a => previous_a_s29,
    next_a => next_a_s30
);
bias_op_u5 : bias_op generic map(
    input_spec => fixed_spec(fixed_spec'(int => 9, frac => 12)),
    bias_spec => fixed_spec(fixed_spec'(int => 4, frac => 8)),
    biases => reals(reals'( -0.9324030, 1.9649760, 0.8496970))
) port map(
    input => input_s6,
    offset => offset_s7,
    output => output_s8,
    op_send => op_send_s9,
    op_receive => op_receive_s10
);
sigmoid_op_u0 : sigmoid_op generic map(
    input_spec => fixed_spec(fixed_spec'(int => 10, frac => 12)),
    output_spec => fixed_spec(fixed_spec'(int => 2, frac => 8)),
    step_precision => 2,
    bit_precision => 16
) port map(
    clk => clk,
    input => input_s1,
    output => output_s2,
    op_send => op_send_s3,
    op_receive => op_receive_s4
);

in_a_s16 <= next_a_s30;
start_s14 <= start_s27;
ready_s25 <= ready_s12;
input_s6 <= op_argument_s19;
op_receive_s10 <= op_send_s21;
op_result_s20 <= output_s2;
op_receive_s22 <= op_send_s3;
input_s1 <= output_s8;
op_receive_s4 <= op_send_s9;
offset_s7 <= out_offset_s18;
op_result_s20 <= resize(output_s2, mk(fixed_spec(fixed_spec'(int => 2, frac => 8))));

uPS : ps port map(
    clk => clk,
    rst => rst_sink
);
previous_a_s29 <= to_vec(reals'(0.2704780, 0.8084080, 0.4638900, 0.2913820, 0.8005990, 0.2030510));
done_s26 <= start;
test_out <= shift_range(std_logic_vector(get(out_a_s17, to_integer(sel), mk(fixed_spec(fixed_spec'(int => 2, frac => 8))))), 8)(test_out'range) when to_integer(sel) < 3 else "00000000";
end system;
