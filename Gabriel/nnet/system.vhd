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

component fcbin_layer is
generic(
    n_inputs : integer;
    n_outputs : integer;
    simd_width : integer;
    weights : integers;
    biases : integers
);
port(
    clk : in std_logic;
    ready : out std_logic;
    done : out std_logic;
    start : in std_logic;
    ack : in std_logic;
    in_a : in std_logic_vector;
    out_a : out std_logic_vector
);
end component;

component fcbin_to_fcbin_interlayer is
generic(
    width : integer
);
port(
    clk : in std_logic;
    ready : in std_logic;
    done : in std_logic;
    start : out std_logic;
    ack : out std_logic;
    previous_a : in std_logic_vector;
    next_a : out std_logic_vector
);
end component;



signal ready_s1 : std_logic;
signal done_s2 : std_logic;
signal start_s3 : std_logic;
signal ack_s4 : std_logic;
signal in_a_s5 : std_logic_vector(5 downto 0);
signal out_a_s6 : std_logic_vector(2 downto 0);


signal ready_s9 : std_logic;
signal done_s10 : std_logic;
signal start_s11 : std_logic;
signal ack_s12 : std_logic;
signal previous_a_s13 : std_logic_vector(5 downto 0);
signal next_a_s14 : std_logic_vector(5 downto 0);


component ps_clk is
port(
    clk, rst : out std_logic
);
end component;

signal clk, rst_sink : std_logic;
constant rst : std_logic := '0';



begin

fcbin_layer_u0 : fcbin_layer generic map(
    n_inputs => 6,
    n_outputs => 3,
    simd_width => 1,
    weights => integers(integers'( 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0)),
    biases => integers(integers'( 7, -2, -6))
) port map(
    clk => clk,
    ready => ready_s1,
    done => done_s2,
    start => start_s3,
    ack => ack_s4,
    in_a => in_a_s5,
    out_a => out_a_s6
);
fcbin_to_fcbin_interlayer_u8 : fcbin_to_fcbin_interlayer generic map(
    width => 6
) port map(
    clk => clk,
    ready => ready_s9,
    done => done_s10,
    start => start_s11,
    ack => ack_s12,
    previous_a => previous_a_s13,
    next_a => next_a_s14
);

in_a_s5 <= next_a_s14;
start_s3 <= start_s11;
ready_s9 <= ready_s1;

uPS : ps_clk port map(
    clk => clk,
    rst => rst_sink
);
previous_a_s13 <= "010110";
done_s10 <= start;
test_out <= "10101010" when to_integer(sel) >= 3 else "00000000" when out_a_s6(to_integer(sel)) = '0' else "11111111";

end system;
