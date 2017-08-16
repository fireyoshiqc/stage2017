library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.util.all;
use work.oled_com.all;
use work.microfont;

entity top is
port(
    --clk : in std_logic;
    debug : out std_logic_vector(7 downto 0) := "00000000";
    start : in std_logic;
    OLED_DC : out std_logic := '0';
    OLED_RES : out std_logic := '1';
    OLED_SCLK : out std_logic := '0';--
    OLED_SDIN : out std_logic := '0';--
    OLED_VBAT : out std_logic := '1';
    OLED_VDD : out std_logic := '1'
);
end top;

architecture top of top is

component ps_clk is
port(
    clk : out std_logic
);
end component ps_clk;

component chrono is
generic(
	mode : string;
	count : integer := -1;
    input_period : time := 0ns;
    target_delay : time := 0ns
);
port(
    clk, rst : in std_logic;
    start : in std_logic;
    stop : out std_logic
);
end component chrono;

component clock_reducer is
generic(
	mode : string;
	divider : integer := -1;
    count : integer := -1;
    input_period : time := 0ns;
    target_period : time := 0ns
);
port(
    in_clk, rst : in std_logic;
    out_clk : out std_logic
);
end component clock_reducer;

component serializer is
generic(
    width : positive := 8;
    high_to_low : boolean := true;
    eager : boolean := true
);
port(
    clk, rst : in std_logic;
    word : in std_logic_vector;
    serial : out std_logic;
	pulse : out std_logic;
    start : in std_logic;
    done : out std_logic
);
end component serializer;

signal clk : std_logic;
signal dont_start_again : std_logic := '0';

type state_t is (
    idle_s,
    wait1ms_s,
    wait100ms_s,
    send_s,
    send_intermediate_s,
    send_wait_s,
    clear_s,
    clear_check_s,
    write_s,
    write_check_s,
    com0_s,
    com1_s,
    com2_s,
    com3_s,
    com4_s,
    com5_s,
    com6_s,
    com7_s,
    com8_s,
    com9_s,
    com10_s--,
--    com11_s
);
signal state : state_t := idle_s;
signal next_state : state_t := idle_s;
signal next_state2 : state_t := idle_s;

signal command_buffer : std_logic_vector(8 * 8 - 1 downto 0);
signal command_size, command_counter : unsigned(inclusive_range_u(command_buffer'length)'range);

procedure send_command(command : std_logic_vector; signal command_buffer : out std_logic_vector; signal command_size : out unsigned; signal command_counter : out unsigned; signal state : out state_t) is
begin 
	command_buffer(command_buffer'high downto command_buffer'length - command'length) <= command;
    command_size <= to_unsigned(command'length, command_size'length);
    command_counter <= to_unsigned(0, command_counter'length);
    state <= send_s;
end send_command;

signal chrono1ms_start : std_logic := '0';
signal chrono1ms_stop : std_logic := '0';
signal chrono100ms_start : std_logic := '0';
signal chrono100ms_stop : std_logic := '0';

procedure wait_1ms(signal chrono1ms_start : out std_logic; signal state : out state_t) is
begin
    chrono1ms_start <= '1';
    state <= wait1ms_s;
end wait_1ms;

procedure wait_100ms(signal chrono100ms_start : out std_logic; signal state : out state_t) is
begin
    chrono100ms_start <= '1';
    state <= wait100ms_s;
end wait_100ms;

signal serializer_word : std_logic_vector(7 downto 0);
signal serializer_serial, serializer_pulse : std_logic;
signal serializer_start : std_logic := '0';
signal serializer_done : std_logic;

signal div_clk : std_logic;

procedure dbg(msg : string) is
begin
	assert false report msg severity error;
end dbg;

signal clear_counter : unsigned(7 - 1 downto 0) := to_unsigned(0, 7);

procedure clear_screen(signal command_buffer : out std_logic_vector; signal command_size : out unsigned; signal state : out state_t) is
begin 
	command_buffer <= (others => '0');
    command_size <= to_unsigned(64, command_size'length);
    state <= clear_s;
end clear_screen;

signal text_field : ascii_string_t(0 to 256 - 1);

signal write_counter : unsigned(9 - 1 downto 0);
signal n_letters_to_write : unsigned(9 - 1 downto 0);

procedure write(text_input : ascii_string_t; signal text_field : out ascii_string_t(0 to 256 - 1); signal write_counter : out unsigned(9 - 1 downto 0); signal n_letters_to_write : out unsigned(9 - 1 downto 0); signal command_size : out unsigned; signal state : out state_t) is
    variable new_text_field : ascii_string_t(0 to 256 - 1) := (others => (others => '0'));
begin
    for i in text_input'range loop
        new_text_field(i) := text_input(i);
    end loop;
    text_field <= new_text_field;
    write_counter <= to_unsigned(0, write_counter'length);
    n_letters_to_write <= to_unsigned(text_input'length, write_counter'length);
    command_size <= to_unsigned(32, command_size'length);
    state <= write_s;
end write;

begin

ps_clk_u: ps_clk port map(
    clk => clk
);

chrono1ms_u: chrono generic map(
    mode => string'("counter"),--mode => string'("timer"),
	count => 50_000--50_000_000
	--input_period => 20ns,
	--target_delay => 1ms
) port map(
    clk => clk,
    rst => std_logic'('0'),
    start => chrono1ms_start,
    stop => chrono1ms_stop
);
chrono100ms_u: chrono generic map(
    mode => string'("counter"),--string'("timer"),
	count => 5_000_000--150_000_000
	--input_period => 20ns,
	--target_delay => 100ms
) port map(
    clk => clk,
    rst => std_logic'('0'),
    start => chrono100ms_start,
    stop => chrono100ms_stop
);

clock_reducer_u: clock_reducer generic map(
    mode => string'("divider"),
    divider => 3
) port map(
    in_clk => clk,
    rst => std_logic'('0'),
    out_clk => div_clk
);

serializer_u: serializer generic map(
    width => 8,
    high_to_low => true,
    eager => false
) port map(
    clk => div_clk,
    rst => std_logic'('0'),
    word => serializer_word,
    serial => serializer_serial,
	pulse => serializer_pulse,
    start => serializer_start,
    done => serializer_done
);

OLED_SCLK <= serializer_pulse;
OLED_SDIN <= serializer_serial;

process(clk)
    variable com_offset : integer;
begin
    if rising_edge(clk) then
        case state is
                              when com0_s   => OLED_VDD <= '0'; wait_1ms                                                              (chrono1ms_start,state);
        next_state <= com1_s; when com1_s   => send_command(set_display_on('0'),                                                      command_buffer,command_size,command_counter,state);
        next_state <= com2_s; when com2_s   => OLED_RES <= '0'; wait_1ms                                                              (chrono1ms_start,state);
        next_state <= com3_s; when com3_s   => OLED_RES <= '1'; wait_1ms                                                              (chrono1ms_start,state);
        next_state <= com4_s; when com4_s   => send_command(enable_charge_pump('1'),                                                  command_buffer,command_size,command_counter,state);
        next_state <= com5_s; when com5_s   => send_command(set_precharge_period("0001", "1111"),                                     command_buffer,command_size,command_counter,state);
        next_state <= com6_s; when com6_s   => OLED_VBAT <= '0'; wait_100ms                                                           (chrono100ms_start,state);
        next_state <= com7_s; when com7_s   => send_command(set_memory_addressing_mode(horizontal_addressing_mode),                   command_buffer,command_size,command_counter,state);
        next_state <= com8_s; when com8_s   => send_command(set_display_on('1'),                                                      command_buffer,command_size,command_counter,state);
        next_state <= com9_s; when com9_s   => OLED_DC <= '1'; clear_screen                                                           (command_buffer,command_size,state);
        next_state <= com10_s; when com10_s => write(ascii("HELLO, WORLD!"),                            text_field,write_counter,n_letters_to_write,command_size,state); --ascii("HELLO,WORLD!") & ascii_u(to_unsigned(141, 8)
--        next_state <= com11_s; when com11_s => send_command("11111111" & "11111111" & "11111111" & "11111111" & "11111111" & "11111111" & "11111111" & "11111111",                        command_buffer,command_size,command_counter,state);
        next_state <= idle_s;
        
        when idle_s =>
            if start = '1' and dont_start_again = '0' then
                dont_start_again <= '1';
                state <= com0_s;
            end if;
        when wait1ms_s =>
			chrono1ms_start <= '0';
            if chrono1ms_stop = '1' then
                state <= next_state;
            end if;
        when wait100ms_s =>
            chrono100ms_start <= '0';
            if chrono100ms_stop = '1' then
                state <= next_state;
            end if;
        when send_s =>
            com_offset := command_buffer'length - to_integer(command_counter);
            serializer_word <= command_buffer(com_offset - 1 downto com_offset - 8);
            serializer_start <= '1';
            command_counter <= command_counter + 8;
            state <= send_intermediate_s;
        when send_intermediate_s =>
            if serializer_done = '0' then
				serializer_start <= '0';
                state <= send_wait_s;
            end if;
        when send_wait_s =>
            if serializer_done = '1' then
                if command_counter < command_size then
                    state <= send_s;
                else
                    state <= next_state;
                end if;
            end if;
        when clear_s =>
            next_state <= clear_check_s;
            next_state2 <= next_state;
            clear_counter <= clear_counter + 1;
            command_counter <= to_unsigned(0, command_counter'length);
            state <= send_s;
        when clear_check_s =>
            clear_counter <= clear_counter + 1;
            if clear_counter = 0 then
                state <= next_state2;
            else
                command_counter <= to_unsigned(0, command_counter'length);
                state <= send_s;
            end if;
        when write_s =>
            next_state <= write_check_s;
            next_state2 <= next_state;
            state <= write_check_s;
        when write_check_s =>
            write_counter <= write_counter + 1;
            if write_counter = n_letters_to_write then
                state <= next_state2;
            else
                command_buffer(command_buffer'high downto command_buffer'length - 32) <= microfont.get_letter(text_field(to_integer(write_counter)));
                command_counter <= to_unsigned(0, command_counter'length);
                state <= send_s;
            end if;
        end case;
    end if;
end process;

end top;
