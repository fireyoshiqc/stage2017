use std.textio.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

library work;
use work.util.all;

entity fcbin_layer is
generic(
    n_inputs : positive;
    n_outputs : positive;
    simd_width : positive;
    weights : integers;
    biases : integers
);
port(
    clk : in std_logic;
    start, ack : in std_logic;
    ready, done : out std_logic;
    in_a : in std_logic_vector(n_inputs - 1 downto 0);
    out_a : out std_logic_vector(n_outputs - 1 downto 0);
        debug : out std_logic_vector(7 downto 0)
);
end fcbin_layer;

architecture fcbin_layer of fcbin_layer is

	constant check1 : integer :=
        synth_assert(simd_width > 0, "simd_width (" & integer'image(simd_width) & ") must be positive.");
	constant check2 : integer :=
        synth_assert(n_outputs >= simd_width, "simd_width (" & integer'image(simd_width) & ") cannot be greater than n_outputs (" & integer'image(n_outputs) & ").");
	constant check3 : integer :=
	    synth_assert(n_outputs mod simd_width = 0, "n_outputs (" & integer'image(n_outputs) & ") not a multiple of simd_width (" & integer'image(simd_width) & ").");
    
component fcbin_controller is
generic(
    n_inputs : positive;
    n_outputs : positive;
    simd_width : positive
);
port(
    clk : in std_logic;
    start, ack : in std_logic;
    ready : out std_logic;
    done : out std_logic;
    simd_offset : out unsigned(bits_needed(n_outputs - simd_width) - 1 downto 0)
);
end component fcbin_controller;

component fcbin_computation is
generic(
    n_inputs : positive;
    n_outputs : positive;
    simd_width : positive;
    weights : integers;
    biases : integers
);
port(
    clk : std_logic;
    input : in std_logic_vector;
    output : out std_logic_vector;
    simd_offset : in unsigned(bits_needed(n_outputs - simd_width) - 1 downto 0);
        debug : out std_logic_vector(7 downto 0)
);
end component fcbin_computation;
    
    signal simd_offset : unsigned(bits_needed(n_outputs - simd_width) - 1 downto 0);
    
begin

fcbin_cont: fcbin_controller generic map(
    n_inputs => n_inputs,
    n_outputs => n_outputs,
    simd_width => simd_width
) port map(
    clk => clk,
    start => start,
    ack => ack,
    ready => ready,
    done => done,
    simd_offset => simd_offset
);

fcbin_comp: fcbin_computation generic map(
    n_inputs => n_inputs,
    n_outputs => n_outputs,
    simd_width => simd_width,
    weights => weights,
    biases => biases
) port map(
    clk => clk,
    input => in_a,
    output => out_a,
    simd_offset => simd_offset,
    debug => debug
);

end fcbin_layer;
