//Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2017.1 (lin64) Build 1846317 Fri Apr 14 18:54:47 MDT 2017
//Date        : Wed May 17 13:13:28 2017
//Host        : nalla-510T running 64-bit CentOS release 6.9 (Final)
//Command     : generate_target npu_bram_ctrl_wrapper.bd
//Design      : npu_bram_ctrl_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module npu_bram_ctrl_wrapper
   (BRAM_PORTA_addr,
    BRAM_PORTA_clk,
    BRAM_PORTA_din,
    BRAM_PORTA_dout,
    BRAM_PORTA_en,
    BRAM_PORTA_rst,
    BRAM_PORTA_we,
    clk,
    offset,
    rden);
  input [31:0]BRAM_PORTA_addr;
  input BRAM_PORTA_clk;
  input [31:0]BRAM_PORTA_din;
  output [31:0]BRAM_PORTA_dout;
  input BRAM_PORTA_en;
  input BRAM_PORTA_rst;
  input [3:0]BRAM_PORTA_we;
  input clk;
  input [31:0]offset;
  input rden;

  wire [31:0]BRAM_PORTA_addr;
  wire BRAM_PORTA_clk;
  wire [31:0]BRAM_PORTA_din;
  wire [31:0]BRAM_PORTA_dout;
  wire BRAM_PORTA_en;
  wire BRAM_PORTA_rst;
  wire [3:0]BRAM_PORTA_we;
  wire clk;
  wire [31:0]offset;
  wire rden;

  npu_bram_ctrl npu_bram_ctrl_i
       (.BRAM_PORTA_addr(BRAM_PORTA_addr),
        .BRAM_PORTA_clk(BRAM_PORTA_clk),
        .BRAM_PORTA_din(BRAM_PORTA_din),
        .BRAM_PORTA_dout(BRAM_PORTA_dout),
        .BRAM_PORTA_en(BRAM_PORTA_en),
        .BRAM_PORTA_rst(BRAM_PORTA_rst),
        .BRAM_PORTA_we(BRAM_PORTA_we),
        .clk(clk),
        .offset(offset),
        .rden(rden));
endmodule
