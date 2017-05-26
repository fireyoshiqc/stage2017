// (c) Copyright 1995-2017 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.


// IP VLNV: xilinx.com:user:npu_bram_ctrl:0.1
// IP Revision: 4

(* X_CORE_INFO = "npu_bram_ctrl,Vivado 2017.1" *)
(* CHECK_LICENSE_TYPE = "npu_bram_ctrl_npu_bram_ctrl_0_0,npu_bram_ctrl,{}" *)
(* CORE_GENERATION_INFO = "npu_bram_ctrl_npu_bram_ctrl_0_0,npu_bram_ctrl,{x_ipProduct=Vivado 2017.1,x_ipVendor=xilinx.com,x_ipLibrary=user,x_ipName=npu_bram_ctrl,x_ipVersion=0.1,x_ipCoreRevision=4,x_ipLanguage=VERILOG,x_ipSimLanguage=MIXED,RD_BITS=32}" *)
(* DowngradeIPIdentifiedWarnings = "yes" *)
module npu_bram_ctrl_npu_bram_ctrl_0_0 (
  addr,
  clk,
  dout,
  drd,
  rden,
  offset
);

output wire [31 : 0] addr;
input wire clk;
output wire [31 : 0] dout;
input wire [31 : 0] drd;
input wire rden;
input wire [31 : 0] offset;

  npu_bram_ctrl #(
    .RD_BITS(32)
  ) inst (
    .addr(addr),
    .clk(clk),
    .dout(dout),
    .drd(drd),
    .rden(rden),
    .offset(offset)
  );
endmodule
