--Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2017.1 (lin64) Build 1846317 Fri Apr 14 18:54:47 MDT 2017
--Date        : Fri Jul 21 14:41:01 2017
--Host        : nalla-510T running 64-bit CentOS release 6.9 (Final)
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
