----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/18/2017 04:46:06 PM
-- Design Name: 
-- Module Name: test_bram_proc - arch
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_bram_proc is
--  Port ( );
port(
addr : out std_logic_vector (31 downto 0);
clk : in std_logic;
din : in std_logic_vector (31 downto 0);
dout : out std_logic_vector (31 downto 0);
rden : out std_logic
);
end test_bram_proc;

architecture arch of test_bram_proc is

signal data : std_logic_vector (31 downto 0);
signal rden_s : std_logic := '1';
signal addr_s : std_logic_vector (31 downto 0) := (others => '0');

begin

process(clk) begin
    if (rising_edge(clk)) then
        if (rden_s = '1') then
            data <= din;
            rden_s <= '0';
        else
            dout <= std_logic_vector(unsigned(data) + 1);
            rden_s <= '1';
            if (unsigned(addr_s) >= 8192) then
                addr_s <= (others => '0');
            else
                addr_s <= std_logic_vector(unsigned(addr_s) + 4);
            end if;
        end if;
    end if;
end process;

rden <= rden_s;
addr <= addr_s;

end arch;
