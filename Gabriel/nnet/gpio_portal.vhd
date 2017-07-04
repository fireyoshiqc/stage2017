library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gpio_portal is
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
    from_done : out std_logic := '0';
    to_ack : out std_logic := '0';
    from_ack, to_done : in std_logic;
    from_ps : out std_logic_vector(n_from * word_size_from - 1 downto 0);
    to_ps : in std_logic_vector(n_to * word_size_to - 1 downto 0);
    debug : out std_logic_vector(7 downto 0)
);
end gpio_portal;

architecture gpio_portal of gpio_portal is

component ps is
port(
    clk, rst : out std_logic;
    gpio_from_ps : out std_logic_vector(31 downto 0);
    gpio_to_ps : in std_logic_vector(31 downto 0)
);
end component ps;

component gpio_portal_from_ps is
generic(
    n_from : integer;
    word_size_from : integer;
    word_offset_from : integer
);
port(
    clk : in std_logic;
    blocked : in std_logic;
    completed : out std_logic;
    data : out std_logic_vector;
    data_from_ps : in std_logic_vector;
    dir_low_from_ps : in std_logic_vector;
    dir_low_to_ps : out std_logic_vector;
    debug : out std_logic_vector
);
end component gpio_portal_from_ps;

component gpio_portal_to_ps is
generic(
    n_to : integer;
    word_size_to : integer;
    word_offset_to : integer
);
port(
    clk : in std_logic;
    blocked : in std_logic;
    completed : out std_logic;
    data : in std_logic_vector;
    data_to_ps : out std_logic_vector;
    dir_low_to_ps : out std_logic_vector;
    dir_low_from_ps : in std_logic_vector--;
    --debug : out std_logic_vector
);
end component gpio_portal_to_ps;

    signal clk_sig, rst_sig : std_logic;
    signal gpio_from_ps, gpio_to_ps : std_logic_vector(31 downto 0);
    signal data_from_ps, data_to_ps : std_logic_vector(7 downto 0);
    signal dir_low_from_ps, dir_high_from_ps, dir_low_to_ps_a, dir_low_to_ps_b, dir_high_to_ps : std_logic_vector(3 downto 0);
    signal completed_from, completed_to : std_logic;
    signal blocked_from : std_logic := '1';
    signal blocked_to : std_logic := '1';
    signal from_ack_reg : std_logic := '1';
    
    signal debug_reg : std_logic_vector(7 downto 0) := "00000000";

begin
    
    clk <= clk_sig;
    rst <= rst_sig;
    data_from_ps <= gpio_from_ps(7 downto 0);
    dir_low_from_ps <= gpio_from_ps(11 downto 8);
    dir_high_from_ps <= gpio_from_ps(15 downto 12);
    gpio_to_ps(23 downto 16) <= data_to_ps;
    gpio_to_ps(27 downto 24) <= dir_low_to_ps_a or dir_low_to_ps_b;
    gpio_to_ps(31 downto 28) <= dir_high_to_ps;

uPS: ps port map(
    clk => clk_sig,
    rst => rst_sig,
    gpio_from_ps => gpio_from_ps,
    gpio_to_ps => gpio_to_ps
);

u_portal_from: gpio_portal_from_ps generic map(
    n_from => n_from,
    word_size_from => word_size_from,
    word_offset_from => word_offset_from
) port map(
    clk => clk_sig,
    blocked => blocked_from,
    completed => completed_from,
    data => from_ps,
    data_from_ps => data_from_ps,
    dir_low_from_ps => dir_low_from_ps,
    dir_low_to_ps => dir_low_to_ps_a,
    debug => debug_reg
);

u_portal_to: gpio_portal_to_ps generic map(
    n_to => n_to,
    word_size_to => word_size_to,
    word_offset_to => word_offset_to
) port map(
    clk => clk_sig,
    blocked => blocked_to,
    completed => completed_to,
    data => to_ps,
    data_to_ps => data_to_ps,
    dir_low_to_ps => dir_low_to_ps_b,
    dir_low_from_ps => dir_low_from_ps--,
    --debug => debug_reg
);

    debug <= debug_reg;

process(clk_sig)
begin
    if rising_edge(clk_sig) then
        if from_ack = '1' then
            from_ack_reg <= '1';
            from_done <= '0';
        end if;
        --if to_done = '1' then
        --    to_done_reg <= '1';
        --end if;
        if blocked_from = '0' then
            --debug <= "00000010";
            --if to_done = '1' then debug_reg <= "00000010"; end if;
            --if debug_reg /= "00000000" and to_done = '0' then debug_reg <= "00000101"; end if;
            --if to_ack = '1' then debug_reg <= "00000010"; end if;
            if completed_from = '1' then
                from_ack_reg <= '0';
                from_done <= '1';
                blocked_from <= '1';
            end if;
        elsif blocked_to = '0' then
            --debug <= "00000011";
            --if debug_reg(2) = '0' then debug_reg(1) <= '1'; end if;
            --if to_done = '1' then debug_reg <= "00000011"; end if;
            --if debug_reg /= "00000000" and to_done = '0' then debug_reg <= "00000110"; end if;
            if completed_to = '1' then
                --to_done_reg
                --debug_reg(2) <= '1';
                to_ack <= '1';
                blocked_to <= '1';
            end if;
        else --waiting
            --debug <= "00000001";
            --if to_done = '1' then debug_reg <= "00000001"; end if;
            --if debug_reg /= "00000000" and to_done = '0' then debug_reg <= "00000100"; end if; ----------
            dir_high_to_ps <= "00" & to_done & from_ack_reg;
            if dir_high_from_ps(1) = '1' then
                --if debug_reg(1) = '0' then debug_reg(0) <= '1'; end if;
                blocked_to <= '0';
            elsif dir_high_from_ps(0) = '1' then
                blocked_from <= '0';
            end if;
        end if;
    end if;
end process;

end gpio_portal;
