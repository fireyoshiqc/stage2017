library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

library work;
use work.util.all;
use work.fc_weights_defs.all;

entity fc_weights is
generic(
    simd_width : integer;
    weight_spec : fixed_spec;
    ROM_weights : reals
);
port(
    w_offset : in unsigned(bits_needed(ROM_weights'length) - 1 downto 0);
    w_data : out std_logic_vector(simd_width * size(weight_spec) - 1 downto 0)
);
end fc_weights;

architecture fc_weights of fc_weights is

    subtype weight_t is sfixed(mk(weight_spec)'range);
    type weights_t is array(ROM_weights'length - 1 downto 0) of weight_t;
    function to_weights(r : reals) return weights_t is
        variable mapped : weights_t;
    begin
        for i in r'range loop
            mapped(i) := to_sfixed(r(i), mapped(i));
        end loop;
        return mapped;
    end to_weights;
    constant ROM_weights_fix : weights_t := to_weights(ROM_weights);

begin
process(w_offset)
begin
    for i in 0 to simd_width - 1 loop
        set(w_data, i, ROM_weights_fix(to_integer(w_offset + i)));
    end loop;
end process;
end fc_weights;
