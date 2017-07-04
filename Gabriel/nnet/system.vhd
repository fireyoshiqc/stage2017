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
    debug : out std_logic_vector(7 downto 0)
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
    in_a : in std_logic_vector;
    out_a : out std_logic_vector;
    out_offset : out unsigned;
    op_argument : out sfixed;
    op_result : in sfixed;
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
    previous_a : in std_logic_vector;
    next_a : out std_logic_vector
);
end component;

component bias_op is
generic(
    input_spec : fixed_spec;
    bias_spec : fixed_spec;
    biases : reals
);
port(
    input : in sfixed;
    offset : in unsigned;
    output : out sfixed;
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
    input : in sfixed;
    output : out sfixed;
    op_send : out std_logic;
    op_receive : in std_logic
);
end component;




signal ready_s1 : std_logic;
signal done_s2 : std_logic;
signal start_s3 : std_logic;
signal ack_s4 : std_logic;
signal in_a_s5 : std_logic_vector(53 downto 0);
signal out_a_s6 : std_logic_vector(29 downto 0);
signal out_offset_s7 : unsigned(1 downto 0);
signal op_argument_s8 : sfixed(7 downto -13);
signal op_result_s9 : sfixed(1 downto -8);
signal op_send_s10 : std_logic;
signal op_receive_s11 : std_logic;



signal ready_s25 : std_logic;
signal done_s26 : std_logic;
signal start_s27 : std_logic;
signal ack_s28 : std_logic;
signal previous_a_s29 : std_logic_vector(53 downto 0);
signal next_a_s30 : std_logic_vector(53 downto 0);

signal input_s13 : sfixed(7 downto -13);
signal offset_s14 : unsigned(1 downto 0);
signal output_s15 : sfixed(8 downto -13);
signal op_send_s16 : std_logic;
signal op_receive_s17 : std_logic;


signal input_s19 : sfixed(8 downto -13);
signal output_s20 : sfixed(1 downto -8);
signal op_send_s21 : std_logic;
signal op_receive_s22 : std_logic;


component gpio_portal is
generic(
    n_from : integer;
    word_size_from : integer;
    word_offset_from : integer;
    n_to : integer;
    word_size_to : integer;
    word_offset_to : integer
);
port(
    clk, rst : out std_logic;
    from_done, to_ack : out std_logic;
    from_ack, to_done : in std_logic;
    from_ps : out std_logic_vector;
    to_ps : in std_logic_vector;
    debug : out std_logic_vector
);
end component gpio_portal;

signal clk, rst_sink : std_logic;
constant rst : std_logic := '0';


begin

fc_layer_u0 : fc_layer generic map(
    input_width => 6,
    output_width => 3,
    simd_width => 2,
    input_spec => fixed_spec(fixed_spec'(int => 1, frac => 8)),
    weight_spec => fixed_spec(fixed_spec'(int => 3, frac => 5)),
    op_arg_spec => fixed_spec(fixed_spec'(int => 8, frac => 13)),
    output_spec => fixed_spec(fixed_spec'(int => 2, frac => 8)),
    n_weights => 18,
    weights_filename => "whatever",
    weight_values => reals(reals'( 1.3069030, -0.1601920, 1.9038220, -2.1906120, -2.6755830, -2.8119140, -2.6025150, -0.0591370, 2.7296700, -1.0891630, 2.6334260, 0.0042240, -0.8001130, 1.1119170, 1.6259810, 1.3307960, 0.1190470, -2.1411140))
) port map(
    clk => clk,
    rst => rst,
    ready => ready_s1,
    done => done_s2,
    start => start_s3,
    ack => ack_s4,
    in_a => in_a_s5,
    out_a => out_a_s6,
    out_offset => out_offset_s7,
    op_argument => op_argument_s8,
    op_result => op_result_s9,
    op_send => op_send_s10,
    op_receive => op_receive_s11
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
bias_op_u12 : bias_op generic map(
    input_spec => fixed_spec(fixed_spec'(int => 8, frac => 13)),
    bias_spec => fixed_spec(fixed_spec'(int => 1, frac => 8)),
    biases => reals(reals'( -0.9324030, 1.9649760, 0.8496970))
) port map(
    input => input_s13,
    offset => offset_s14,
    output => output_s15,
    op_send => op_send_s16,
    op_receive => op_receive_s17
);
sigmoid_op_u18 : sigmoid_op generic map(
    input_spec => fixed_spec(fixed_spec'(int => 9, frac => 13)),
    output_spec => fixed_spec(fixed_spec'(int => 2, frac => 8)),
    step_precision => 2,
    bit_precision => 16
) port map(
    clk => clk,
    input => input_s19,
    output => output_s20,
    op_send => op_send_s21,
    op_receive => op_receive_s22
);

in_a_s5 <= next_a_s30;
start_s3 <= start_s27;
ready_s25 <= ready_s1;
input_s13 <= op_argument_s8;
op_receive_s17 <= op_send_s10;
op_receive_s11 <= op_send_s21;
input_s19 <= output_s15;
op_receive_s22 <= op_send_s16;
offset_s14 <= out_offset_s7;
op_result_s9 <= resize(output_s20, mk(fixed_spec(fixed_spec'(int => 2, frac => 8))));

u_gpio_portal: gpio_portal generic map(
    n_from => 6,
    word_size_from => 9,
    word_offset_from => 0,
    n_to => 3,
    word_size_to => 10,
    word_offset_to => 0
) port map(
    clk => clk,
    rst => rst_sink,
    from_done => done_s26,
    to_ack => ack_s4,
    from_ack => ack_s28,
    to_done => done_s2,
    from_ps => previous_a_s29,
    to_ps => out_a_s6,
    debug => debug
);

end system;
