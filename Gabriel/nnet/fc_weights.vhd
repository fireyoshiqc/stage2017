library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

library work;
use work.util.all;
use work.fc_weights_defs.all;

entity fc_weights is
generic(
    simd_width : integer;-- := 14;
    weight_spec : fixed_spec;-- := (int => 4, frac => 4);
    weight_values : reals;
    n_weights : integer;-- := 28 * 28 * 40;
    weights_filename : string-- := "C:\\Users\\gademb\\stage2017\\Gabriel\\nnet\\test_weights.txt"
);
port(
    query : in std_logic;
    w_offset : in unsigned(bits_needed(n_weights / simd_width) - 1 downto 0);--(bits_needed(ROM_weights'length) - 1 downto 0);
    w_data : out std_logic_vector(simd_width * size(weight_spec) - 1 downto 0)----std_logic_vector(size(weight_spec) - 1 downto 0)
);
end fc_weights;

architecture fc_weights of fc_weights is

--    subtype weight_t is sfixed(mk(weight_spec)'range);
--    type weights_t is array(ROM_weights'length - 1 downto 0) of weight_t;

    subtype simd_weight_t is std_logic_vector(simd_width * size(weight_spec) - 1 downto 0);
    
    --constant test_n_weights : integer := 28 * 28;
    type simd_weights_t is array(0 to n_weights / simd_width - 1) of simd_weight_t;--weight_t;
    
    impure function weights_from_file(filename : string) return simd_weights_t is
        file weight_file : text;
        variable cur_line : line;
        variable cur_bin : std_logic_vector(64 - 1 downto 0);
        variable w : simd_weights_t;
        variable f64 : float64;
    begin
        file_open(weight_file, filename, read_mode);
        readline(weight_file, cur_line); --skip length
        for i in w'range loop
            for j in 0 to simd_width - 1 loop
                readline(weight_file, cur_line);
                hread(cur_line, cur_bin);
                set_var(w(i), j, to_sfixed(to_float(cur_bin, f64), mk(weight_spec)));
            end loop;
        end loop;
        file_close(weight_file);
        return w;
    end weights_from_file;

    function weights_from_values(r : reals) return simd_weights_t is
        variable mapped : simd_weights_t;
        file dummy : text; variable info : string(1 to 1000); variable cursor : integer := 1;
    begin
        for i in mapped'range loop
            for j in 0 to simd_width - 1 loop
                mapped(i)((j + 1) * size(weight_spec) - 1 downto j * size(weight_spec)) := std_logic_vector(to_sfixed(r(i * simd_width + j), mk(weight_spec)));
            end loop;
        end loop;
--        for i in mapped'range loop
--            info := write(info, vec_image(mapped(i)) & " ", cursor);
--            cursor := cursor + 17;
--        end loop;
--        file_open(dummy, "not a file: " & info, read_mode);
        return mapped;
    end weights_from_values;
    
    signal weights_ROM : simd_weights_t := weights_from_values(weight_values);--weights_from_file(weights_filename);
    
    attribute rom_style : string;
    attribute rom_style of weights_ROM : signal is "block";
    
--    function dbg(w : simd_weights_t) return integer is
--        file dummy : text; variable info : string(1 to 1000); variable cursor : integer := 1;
--    begin
----        for i in w'range loop
----            info := write(info, real'image(to_real(to_sfixed(w(i)(size(weight_spec) - 1 downto 0), mk(weight_spec)))) & " ", cursor);
----            cursor := cursor + 22;
----        end loop;
--        file_open(dummy, "not a file: " & vec_image(std_logic_vector(w(0))), read_mode);
--        return 0;
--    end dbg;
    
--    constant dummy : integer := dbg(weights_from_values(weight_values));

begin
process(query)
begin
    if rising_edge(query) then
        w_data <= weights_ROM(to_integer(w_offset));
    end if;
end process;
end fc_weights;
