----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/18/2017 04:04:02 PM
-- Design Name: 
-- Module Name: test_bram_ctrl - Behavioral
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

entity test_bram_ctrl is
--  Port ( );
port(
addr : out std_logic_vector (31 downto 0);
clk : in std_logic;
din : in std_logic_vector (31 downto 0);
dout : out std_logic_vector (31 downto 0);
drd : in std_logic_vector (31 downto 0);
dwr : out std_logic_vector (31 downto 0);
offset : in std_logic_vector (31 downto 0);
rden : in std_logic;
rst : in std_logic;
wren : out std_logic_vector (3 downto 0)
);
end test_bram_ctrl;

architecture arch of test_bram_ctrl is

begin

process(clk) begin

    if (rising_edge(clk)) then
    
        if (rst = '1') then
            wren <= (others => '0');      
        else
            addr <= offset;
            
            if (rden = '0') then
                wren <= (others => '1');
                dwr <= din;
            else
                wren <= (others => '0');
                dout <= drd;
            end if;
            
        end if;
    end if;
end process;

end arch;
