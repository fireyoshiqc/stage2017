library ieee;
use ieee.std_logic_1164.all;

library work;
use work.util.all;

package microfont is

function get_letter(ascii_letter : ascii_char_t) return std_logic_vector;

end microfont;

package body microfont is

function get_letter(ascii_letter : ascii_char_t) return std_logic_vector is
begin
    case ascii_letter is
    when "01000001" => return "11111100001100111111110000000000";
    when "01000010" => return "11111111111100110011110000000000";
    when "01000011" => return "00111100110000111100001100000000";
    when "01000100" => return "11111111110000110011110000000000";
    when "01000101" => return "11111111111100111100001100000000";
    when "01000110" => return "11111111001100110011001100000000";
    when "01000111" => return "00111100110000111111001100110000";
    when "01001000" => return "11111111001100001111111100000000";
    when "01001001" => return "11000011111111111100001100000000";
    when "01001010" => return "00110000110000000011111100000000";
    when "01001011" => return "11111111001111001100001100000000";
    when "01001100" => return "11111111110000001100000000000000";
    when "01001101" => return "11111111001111000011110011111111";
    when "01001110" => return "11111111000011000011000011111111";
    when "01001111" => return "00111100110000111100001100111100";
    when "01010000" => return "11111111001100110000110000000000";
    when "01010001" => return "00111100110000111111001111111100";
    when "01010010" => return "11111111001100111100110000000000";
    when "01010011" => return "11001100110011111111001100110011";
    when "01010100" => return "00000011111111110000001100000000";
    when "01010101" => return "00111111110000001100000000111111";
    when "01010110" => return "00001111111100001111000000001111";
    when "01010111" => return "00111111111111001111110000111111";
    when "01011000" => return "11000011001111000011110011000011";
    when "01011001" => return "00001111111100000000111100000000";
    when "01011010" => return "11000011111100111100111111000011";
    when "00110000" => return "00111100110000110011110000000000";
    when "00110001" => return "00000000000011001111111100000000";
    when "00110010" => return "11000011111100111100110000000000";
    when "00110011" => return "11000011111100111111001100111100";
    when "00110100" => return "00111111001100001111111100000000";
    when "00110101" => return "11001111111100111111001100000000";
    when "00110110" => return "00111100111100111111001100000000";
    when "00110111" => return "11000011001100110000111100000000";
    when "00111000" => return "11111111111100111111111100000000";
    when "00111001" => return "11001100111100110011110000000000";
    when "00101110" => return "00000000110000000000000000000000";
    when "00101100" => return "00000000111100000000000000000000";
    when "00100001" => return "00000000110011110000000000000000";
    when "00111111" => return "00001100000000111111001100001100";
    when "01011111" => return "11000000110000001100000011000000";
    when "00100111" => return "00000000000011110000000000000000";
    when "00100000" => return "00000000000000000000000000000000";
        when others => return "11111111111111111111111111111111";
    end case;
end get_letter;

end microfont;
