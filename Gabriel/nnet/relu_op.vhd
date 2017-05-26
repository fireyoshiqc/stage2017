library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;

entity relu_op is
generic(
    spec : fixed_spec
);
port(
    input : in sfixed(mk(spec)'range);
    output : out sfixed(mk(spec)'range)
);
end relu_op;

architecture relu_op of relu_op is
begin
	output <= input when input(input'high) = '0' else to_sfixed(0.0, input);
end relu_op;