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
    clk : in std_logic;
    rst : in std_logic;
    start : in std_logic;
    out_a : out std_logic_vector(29 downto 0)
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
    pick_from_ram : boolean;
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
    simd_offset : out std_logic_vector;
    op_argument : out sfixed;
    op_result : in sfixed;
    op_send : out std_logic;
    op_receive : in std_logic
);
end component;

component fc_to_fc_interlayer is
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
signal in_a_s5 : std_logic_vector(17 downto 0);
signal out_a_s6 : std_logic_vector(29 downto 0);
signal out_offset_s7 : unsigned(1 downto 0);
signal simd_offset_s8 : std_logic_vector(1 downto 0);
signal op_argument_s9 : sfixed(7 downto -13);
signal op_result_s10 : sfixed(1 downto -8);
signal op_send_s11 : std_logic;
signal op_receive_s12 : std_logic;



signal ready_s26 : std_logic;
signal done_s27 : std_logic;
signal start_s28 : std_logic;
signal ack_s29 : std_logic;
signal previous_a_s30 : std_logic_vector(53 downto 0);
signal next_a_s31 : std_logic_vector(53 downto 0);

signal input_s14 : sfixed(7 downto -13);
signal offset_s15 : unsigned(1 downto 0);
signal output_s16 : sfixed(8 downto -13);
signal op_send_s17 : std_logic;
signal op_receive_s18 : std_logic;


signal input_s20 : sfixed(8 downto -13);
signal output_s21 : sfixed(1 downto -8);
signal op_send_s22 : std_logic;
signal op_receive_s23 : std_logic;

constant input_spec : fixed_spec := fixed_spec(fixed_spec'(int => 1, frac => 8));
function to_vec(r : reals) return std_logic_vector is
    variable ret : std_logic_vector(6 * size(input_spec) - 1 downto 0);
begin
    for i in r'range loop
        ret((1 + i) * size(input_spec) - 1 downto i * size(input_spec)) :=
            std_logic_vector(to_sfixed(r(i), mk(input_spec)));
    end loop;
    return ret;
end to_vec;

constant in_bitwidth : integer := 9;
type ram_t is array(0 to 2) of std_logic_vector(2 * in_bitwidth - 1 downto 0);
function init_ram(r : reals) return ram_t is
    variable ram : ram_t;
begin
    for i in ram'range loop
        for j in 0 to ram(i)'length / in_bitwidth - 1 loop
            ram(i)((j + 1) * in_bitwidth - 1 downto j * in_bitwidth) := std_logic_vector(to_sfixed(r(i), mk(input_spec)));
        end loop;
    end loop;
    return ram;
end init_ram;
signal ram : ram_t := init_ram(reals'(0.2704780, 0.8084080, 0.4638900, 0.2913820, 0.8005990, 0.2030510));

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
    pick_from_ram => true,
    weights_filename => "whatever",
    weight_values => reals(reals'( 1.3069030, -0.1601920, 1.9038220, -2.1906120, -2.6755830, -2.8119140, -2.6025150, -0.0591370, 2.7296700, -1.0891630, 2.6334260, 0.0042240, -0.8001130, 1.1119170, 1.6259810, 1.3307960, 0.1190470, -2.1411140))
) port map(
    clk => clk,
    rst => rst,
    ready => ready_s1,
    done => done_s2,
    start => start,
    ack => ack_s4,
    in_a => in_a_s5,
    out_a => out_a_s6,
    out_offset => out_offset_s7,
    simd_offset => simd_offset_s8,
    op_argument => op_argument_s9,
    op_result => op_result_s10,
    op_send => op_send_s11,
    op_receive => op_receive_s12
);
--fc_to_fc_interlayer_u25 : fc_to_fc_interlayer generic map(
--    width => 6,
--    word_size => 9
--) port map(
--    clk => clk,
--    rst => rst,
--    ready => ready_s26,
--    done => done_s27,
--    start => start_s28,
--    ack => ack_s29,
--    previous_a => previous_a_s30,
--    next_a => next_a_s31
--);
bias_op_u13 : bias_op generic map(
    input_spec => fixed_spec(fixed_spec'(int => 8, frac => 13)),
    bias_spec => fixed_spec(fixed_spec'(int => 2, frac => 10)),
    biases => reals(reals'( -0.9324030, 1.9649760, 0.8496970))
) port map(
    input => input_s14,
    offset => offset_s15,
    output => output_s16,
    op_send => op_send_s17,
    op_receive => op_receive_s18
);
sigmoid_op_u19 : sigmoid_op generic map(
    input_spec => fixed_spec(fixed_spec'(int => 9, frac => 13)),
    output_spec => fixed_spec(fixed_spec'(int => 2, frac => 8)),
    step_precision => 2,
    bit_precision => 16
) port map(
    clk => clk,
    input => input_s20,
    output => output_s21,
    op_send => op_send_s22,
    op_receive => op_receive_s23
);

--in_a_s5 <= next_a_s31;
start_s3 <= start_s28;
ready_s26 <= ready_s1;
input_s14 <= op_argument_s9;
op_receive_s18 <= op_send_s11;
op_receive_s12 <= op_send_s22;
input_s20 <= output_s16;
op_receive_s23 <= op_send_s17;
offset_s15 <= out_offset_s7;
op_result_s10 <= resize(output_s21, mk(fixed_spec(fixed_spec'(int => 2, frac => 8))));

--previous_a_s30 <= to_vec(reals'(0.2704780, 0.8084080, 0.4638900, 0.2913820, 0.8005990, 0.2030510));
process(clk)
begin
    if rising_edge(clk) then
        in_a_s5 <= ram(to_integer(unsigned(simd_offset_s8)));
    end if;
end process;
done_s27 <= start;
out_a <= out_a_s6;
end system;
