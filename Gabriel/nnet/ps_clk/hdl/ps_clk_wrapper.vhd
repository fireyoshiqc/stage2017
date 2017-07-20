--Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2015.4 (win64) Build 1412921 Wed Nov 18 09:43:45 MST 2015
--Date        : Wed Jul 12 14:03:58 2017
--Host        : M4202-04 running 64-bit Service Pack 1  (build 7601)
--Command     : generate_target ps_clk_wrapper.bd
--Design      : ps_clk_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity ps_clk_wrapper is
  port (
    clk : out STD_LOGIC;
    rst : out STD_LOGIC
  );
end ps_clk_wrapper;

architecture STRUCTURE of ps_clk_wrapper is
  component ps_clk is
  port (
    clk : out STD_LOGIC;
    rst : out STD_LOGIC
  );
  end component ps_clk;
begin
ps_clk_i: component ps_clk
     port map (
      clk => clk,
      rst => rst
    );
end STRUCTURE;
