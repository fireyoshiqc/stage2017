//Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2017.1 (win64) Build 1846317 Fri Apr 14 18:55:03 MDT 2017
//Date        : Fri May 12 16:53:12 2017
//Host        : Typhoon-PC running 64-bit major release  (build 9200)
//Command     : generate_target npu_bram_ctrl.bd
//Design      : npu_bram_ctrl
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module NPU_WEIGHT_BRAM_imp_4OD27
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

  wire [31:0]Conn1_ADDR;
  wire Conn1_CLK;
  wire [31:0]Conn1_DIN;
  wire [31:0]Conn1_DOUT;
  wire Conn1_EN;
  wire Conn1_RST;
  wire [3:0]Conn1_WE;
  wire [31:0]blk_mem_gen_0_doutb;
  wire clk_1;
  wire [31:0]npu_bram_ctrl_0_addr;
  wire [31:0]offset_1;
  wire rden_1;
  wire [3:0]xlconstant_0_dout;

  assign BRAM_PORTA_dout[31:0] = Conn1_DOUT;
  assign Conn1_ADDR = BRAM_PORTA_addr[31:0];
  assign Conn1_CLK = BRAM_PORTA_clk;
  assign Conn1_DIN = BRAM_PORTA_din[31:0];
  assign Conn1_EN = BRAM_PORTA_en;
  assign Conn1_RST = BRAM_PORTA_rst;
  assign Conn1_WE = BRAM_PORTA_we[3:0];
  assign clk_1 = clk;
  assign offset_1 = offset[31:0];
  assign rden_1 = rden;
  npu_bram_ctrl_blk_mem_gen_0_0 blk_mem_gen_0
       (.addra(Conn1_ADDR),
        .addrb(npu_bram_ctrl_0_addr),
        .clka(Conn1_CLK),
        .clkb(clk_1),
        .dina(Conn1_DIN),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(Conn1_DOUT),
        .doutb(blk_mem_gen_0_doutb),
        .ena(Conn1_EN),
        .enb(1'b0),
        .rsta(Conn1_RST),
        .rstb(1'b0),
        .wea(Conn1_WE),
        .web(xlconstant_0_dout));
  npu_bram_ctrl_npu_bram_ctrl_0_0 npu_bram_ctrl_0
       (.addr(npu_bram_ctrl_0_addr),
        .clk(clk_1),
        .drd(blk_mem_gen_0_doutb),
        .offset(offset_1),
        .rden(rden_1));
  npu_bram_ctrl_xlconstant_0_0 xlconstant_0
       (.dout(xlconstant_0_dout));
endmodule

(* CORE_GENERATION_INFO = "npu_bram_ctrl,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=npu_bram_ctrl,x_ipVersion=1.00.a,x_ipLanguage=VERILOG,numBlks=4,numReposBlks=3,numNonXlnxBlks=0,numHierBlks=1,maxHierDepth=1,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=1,bdsource=USER,synth_mode=OOC_per_IP}" *) (* HW_HANDOFF = "npu_bram_ctrl.hwdef" *) 
module npu_bram_ctrl
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

  wire [31:0]BRAM_PORTA_1_ADDR;
  wire BRAM_PORTA_1_CLK;
  wire [31:0]BRAM_PORTA_1_DIN;
  wire [31:0]BRAM_PORTA_1_DOUT;
  wire BRAM_PORTA_1_EN;
  wire BRAM_PORTA_1_RST;
  wire [3:0]BRAM_PORTA_1_WE;
  wire clk_1;
  wire [31:0]offset_1;
  wire rden_1;

  assign BRAM_PORTA_1_ADDR = BRAM_PORTA_addr[31:0];
  assign BRAM_PORTA_1_CLK = BRAM_PORTA_clk;
  assign BRAM_PORTA_1_DIN = BRAM_PORTA_din[31:0];
  assign BRAM_PORTA_1_EN = BRAM_PORTA_en;
  assign BRAM_PORTA_1_RST = BRAM_PORTA_rst;
  assign BRAM_PORTA_1_WE = BRAM_PORTA_we[3:0];
  assign BRAM_PORTA_dout[31:0] = BRAM_PORTA_1_DOUT;
  assign clk_1 = clk;
  assign offset_1 = offset[31:0];
  assign rden_1 = rden;
  NPU_WEIGHT_BRAM_imp_4OD27 NPU_WEIGHT_BRAM
       (.BRAM_PORTA_addr(BRAM_PORTA_1_ADDR),
        .BRAM_PORTA_clk(BRAM_PORTA_1_CLK),
        .BRAM_PORTA_din(BRAM_PORTA_1_DIN),
        .BRAM_PORTA_dout(BRAM_PORTA_1_DOUT),
        .BRAM_PORTA_en(BRAM_PORTA_1_EN),
        .BRAM_PORTA_rst(BRAM_PORTA_1_RST),
        .BRAM_PORTA_we(BRAM_PORTA_1_WE),
        .clk(clk_1),
        .offset(offset_1),
        .rden(rden_1));
endmodule
