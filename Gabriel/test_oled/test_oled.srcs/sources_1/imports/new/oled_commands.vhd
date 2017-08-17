use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.util.all;

package oled_com is

type scroll_step_interval_t is record
    val : std_logic_vector(2 downto 0);
end record scroll_step_interval_t;
constant scroll_step_5_frames : scroll_step_interval_t := (val => "000");
constant scroll_step_64_frames : scroll_step_interval_t := (val => "001");
constant scroll_step_128_frames : scroll_step_interval_t := (val => "010");
constant scroll_step_256_frames : scroll_step_interval_t := (val => "011");
constant scroll_step_3_frames : scroll_step_interval_t := (val => "100");
constant scroll_step_4_frames : scroll_step_interval_t := (val => "101");
constant scroll_step_25_frames : scroll_step_interval_t := (val => "110");
constant scroll_step_2_frames : scroll_step_interval_t := (val => "111");

type addressing_mode_t is record
    val : std_logic_vector(1 downto 0);
end record addressing_mode_t;
constant horizontal_addressing_mode : addressing_mode_t := (val => "00");
constant vertical_addressing_mode : addressing_mode_t := (val => "01");
constant page_addressing_mode : addressing_mode_t := (val => "10");

type vcomh_deselect_level_t is record
    val : std_logic_vector(2 downto 0);
end record vcomh_deselect_level_t;
constant vcomh_deselect_level_065vcc : vcomh_deselect_level_t := (val => "000");
constant vcomh_deselect_level_077vcc : vcomh_deselect_level_t := (val => "010");
constant vcomh_deselect_level_083vcc : vcomh_deselect_level_t := (val => "011");


function set_contrast(v : unsigned(7 downto 0)) return std_logic_vector;
function entire_display_on(v : std_logic) return std_logic_vector;
function set_inverse_display(v : std_logic) return std_logic_vector;
function set_display_on(v : std_logic) return std_logic_vector;

function horizontal_scroll_setup(to_the_left : std_logic; start_page : unsigned(2 downto 0);
                                 scroll_step_interval : scroll_step_interval_t; end_page : unsigned(2 downto 0)) return std_logic_vector;
function vert_horiz_scroll_setup(to_the_left : std_logic; start_page : unsigned(2 downto 0);
                                 scroll_step_interval : scroll_step_interval_t; end_page : unsigned(2 downto 0);
                                 vertical_scrolling_offset : unsigned(5 downto 0)) return std_logic_vector;
function deactivate_scroll return std_logic_vector;
function activate_scroll return std_logic_vector;
function set_vertical_scroll_area(n_rows_in_top_fixed_area : unsigned(5 downto 0); n_rowns_in_scroll_area : unsigned(6 downto 0)) return std_logic_vector;

function set_lower_column_start_x_page_addr(col_addr_lower_nibble : unsigned(3 downto 0)) return std_logic_vector;
function set_higher_column_start_x_page_addr(col_addr_higher_nibble : unsigned(3 downto 0)) return std_logic_vector;
function set_memory_addressing_mode(addressing_mode : addressing_mode_t) return std_logic_vector;
function set_column_address_x_horiz_vert_addr(start_addr : unsigned(6 downto 0); end_addr : unsigned(6 downto 0)) return std_logic_vector;
function set_page_address_x_horiz_vert_addr(start_addr : unsigned(2 downto 0); end_addr : unsigned(2 downto 0)) return std_logic_vector;
function set_page_start_x_page_addr(page_addr : unsigned(3 downto 0)) return std_logic_vector;

function set_display_start_line(v : unsigned(5 downto 0)) return std_logic_vector;
function set_segment_remap(v : std_logic) return std_logic_vector;
function set_multiplex_ratio(v : unsigned(5 downto 0)) return std_logic_vector;
function set_com_output_scan_direction(v : std_logic) return std_logic_vector;
function set_display_offset(v : unsigned(5 downto 0)) return std_logic_vector;
function set_com_pins_hardware_config(is_alternative_config : std_logic; enable_left_right_remap : std_logic) return std_logic_vector;

function set_clock(divide_ratio : unsigned(3 downto 0); oscillator_frequency : unsigned(3 downto 0)) return std_logic_vector;
function set_precharge_period(phase_1_period : unsigned(3 downto 0); phase_2_period : unsigned(3 downto 0)) return std_logic_vector;
function set_vcomh_deselect_level(v : vcomh_deselect_level_t) return std_logic_vector;
function no_op return std_logic_vector;

function enable_charge_pump(v : std_logic) return std_logic_vector;

end oled_com;


package body oled_com is

function set_contrast(v : unsigned(7 downto 0)) return std_logic_vector is
    -- default: v := 0x7f (max contrast)
begin
    return "10000001" &
           std_logic_vector(v);
end set_contrast;

function entire_display_on(v : std_logic) return std_logic_vector is
    -- default: v := '0' (follow RAM)
begin
    return "1010010" & (0 => v);
end entire_display_on;

function set_inverse_display(v : std_logic) return std_logic_vector is
    -- default: v := '0' (pixel intensities not inverted)
begin
    return "1010011" & (0 => v);
end set_inverse_display;

function set_display_on(v : std_logic) return std_logic_vector is
    -- default: v := '0' (display off)
begin
    return "1010111" & (0 => v);
end set_display_on;

function horizontal_scroll_setup(to_the_left : std_logic; start_page : unsigned(2 downto 0);
                                 scroll_step_interval : scroll_step_interval_t; end_page : unsigned(2 downto 0)) return std_logic_vector is
    -- no default
begin
    return "0010011" & (0 => to_the_left) &
           "00000000" &
           "00000" & std_logic_vector(start_page) &
           "00000" & scroll_step_interval.val &
           "00000" & std_logic_vector(end_page) &
           "00000000" &
           "11111111";
end horizontal_scroll_setup;

function vert_horiz_scroll_setup(to_the_left : std_logic; start_page : unsigned(2 downto 0);
                                 scroll_step_interval : scroll_step_interval_t; end_page : unsigned(2 downto 0);
                                 vertical_scrolling_offset : unsigned(5 downto 0)) return std_logic_vector is
    -- no default
    variable vert_to : std_logic_vector(1 downto 0);
begin
    if to_the_left = '0' then vert_to := "01"; else vert_to := "10"; end if;
    return "0010011" & vert_to &
           "00000000" &
           "00000" & std_logic_vector(start_page) &
           "00000" & scroll_step_interval.val &
           "00000" & std_logic_vector(end_page) &
           "00" & std_logic_vector(vertical_scrolling_offset);
end vert_horiz_scroll_setup;

function deactivate_scroll return std_logic_vector is
begin
    return "00101110";
end deactivate_scroll;

function activate_scroll return std_logic_vector is
begin
    return "00101111";
end activate_scroll;

function set_vertical_scroll_area(n_rows_in_top_fixed_area : unsigned(5 downto 0); n_rowns_in_scroll_area : unsigned(6 downto 0)) return std_logic_vector is
    --default: n_rows_in_top_fixed_area := 0; n_rowns_in_scroll_area := 64
begin
    return "10100011" &
           "00" & std_logic_vector(n_rows_in_top_fixed_area) &
           "0" & std_logic_vector(n_rowns_in_scroll_area);
end set_vertical_scroll_area;

function set_lower_column_start_x_page_addr(col_addr_lower_nibble : unsigned(3 downto 0)) return std_logic_vector is
    -- default: col_addr_lower_nibble := 0
begin
    return "0000" & std_logic_vector(col_addr_lower_nibble);
end set_lower_column_start_x_page_addr;

function set_higher_column_start_x_page_addr(col_addr_higher_nibble : unsigned(3 downto 0)) return std_logic_vector is
    -- default: col_addr_higher_nibble := 0
begin
    return "0001" & std_logic_vector(col_addr_higher_nibble);
end set_higher_column_start_x_page_addr;

function set_memory_addressing_mode(addressing_mode : addressing_mode_t) return std_logic_vector is
    -- default: addressing_mode := page_addressing_mode
begin
    return "00100000" & 
           "000000" & addressing_mode.val;
end set_memory_addressing_mode;

function set_column_address_x_horiz_vert_addr(start_addr : unsigned(6 downto 0); end_addr : unsigned(6 downto 0)) return std_logic_vector is
    -- default: start_addr := 0; end_addr := 127
begin
    return "00100001" & 
           "0" & std_logic_vector(start_addr) &
           "0" & std_logic_vector(end_addr);
end set_column_address_x_horiz_vert_addr;

function set_page_address_x_horiz_vert_addr(start_addr : unsigned(2 downto 0); end_addr : unsigned(2 downto 0)) return std_logic_vector is
    -- default: start_addr := 0; end_addr := 7
begin
    return "00100010" & 
           "00000" & std_logic_vector(start_addr) &
           "00000" & std_logic_vector(end_addr);
end set_page_address_x_horiz_vert_addr;

function set_page_start_x_page_addr(page_addr : unsigned(3 downto 0)) return std_logic_vector is
    -- no default
begin
    return "10110" & std_logic_vector(page_addr);
end set_page_start_x_page_addr;

function set_display_start_line(v : unsigned(5 downto 0)) return std_logic_vector is
    -- default: v := 0
begin
    return "01" & std_logic_vector(v);
end set_display_start_line;

function set_segment_remap(v : std_logic) return std_logic_vector is
    -- default: v := '0' (column address 0 mapped to SEG0)
begin
    return "1010000" & (0 => v);
end set_segment_remap;

function set_multiplex_ratio(v : unsigned(5 downto 0)) return std_logic_vector is
    -- default: v := 63 (=> MUX = v + 1 = 64)
begin
    if v < 15 then
        return "10101000" & 
               "00111111";
    end if;
    return "10101000" &
           "00" & std_logic_vector(v);
end set_multiplex_ratio;

function set_com_output_scan_direction(v : std_logic) return std_logic_vector is
    -- default: v := '0' (normal mode, scan from COM0 to COM[MUX - 1])
begin
    return "1100" & (0 => v) & "000";
end set_com_output_scan_direction;

function set_display_offset(v : unsigned(5 downto 0)) return std_logic_vector is
    -- default: v := 0
begin
    return "11010011" &
           "00" & std_logic_vector(v);
end set_display_offset;

function set_com_pins_hardware_config(is_alternative_config : std_logic; enable_left_right_remap : std_logic) return std_logic_vector is
    -- default: is_alternative_config := '1'; enable_left_right_remap := '0'
begin
    return "11011010" &
           "00" & (0 => enable_left_right_remap) & (0 => is_alternative_config) & "0010";
end set_com_pins_hardware_config;

function set_clock(divide_ratio : unsigned(3 downto 0); oscillator_frequency : unsigned(3 downto 0)) return std_logic_vector is
    -- default: divide_ratio := 0 (actual_divide_ratio = divide_ratio + 1 = 1); oscillator_frequency := 8
begin
    return "11010101" &
           std_logic_vector(oscillator_frequency) & std_logic_vector(divide_ratio);
end set_clock;

function set_precharge_period(phase_1_period : unsigned(3 downto 0); phase_2_period : unsigned(3 downto 0)) return std_logic_vector is
    -- default: phase_1_period := 2 (2 x DCLK); phase_2_period := 2 (2 x DCLK)
    variable phase_1_p : unsigned(3 downto 0) := phase_1_period;
    variable phase_2_p : unsigned(3 downto 0) := phase_2_period;
begin
    if phase_1_p = 0 then phase_1_p := to_unsigned(1, phase_1_p'length); end if;
    if phase_2_p = 0 then phase_2_p := to_unsigned(1, phase_2_p'length); end if;
    return "11011001" &
           std_logic_vector(phase_2_period) & std_logic_vector(phase_1_period);
end set_precharge_period;

function set_vcomh_deselect_level(v : vcomh_deselect_level_t) return std_logic_vector is
    -- default: v := vcomh_deselect_level_077vcc
begin
    return "11011001" &
           "0" & v.val & "0000";
end set_vcomh_deselect_level;

function no_op return std_logic_vector is
begin
    return "11100011";
end no_op;

function enable_charge_pump(v : std_logic) return std_logic_vector is
    -- default: v := '0' (charge pump disabled)
begin
return "10001101" &
       "00010" & (0 => v) & "00";
end enable_charge_pump;

end oled_com;