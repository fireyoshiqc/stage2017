`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Laboratoire LIV4D - École Polytechnique de Montréal
// Engineer: Félix Boulet
// 
// Create Date: 05/25/2017 11:09:13 AM
// Design Name: 8-bit max-capped LFSR Random Number Generator (Test Bench)
// Module Name: top_tb
// Project Name: lfsr_rng
// Target Devices: Zynq-7000 (xc7z020clg400-1)
// Tool Versions: Vivado 2017.1
// Description: 
// This is a testbench for the top module (8-bit max-capped LFSR Random Number Generator).
// Please refer to that module for more in-depth documentation.
// 
// Dependencies:
// This testbench requires the top module from top.v.
// 
// Revision:
// Revision 1.0 - Testbench completed
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module top_tb();

reg clk_tb;
reg rst_tb;
reg enb_tb;
reg [7:0] max_tb;
wire [7:0] out_tb;
integer i;

// Note that there is some latency between the max input and the output (about 3 clock cycles).
// Same goes for reset and enable since they're synchronous in order to maximize DSP inference.

// Initialize a sequence where the reset is put on then removed, and the enable is momentarily
// put to 0 then back to 1.
// Observed behavior should be that the top module holds its output value while enable is 0, and
// should ouput 0 while reset is active.
initial begin
    clk_tb = 0;
    rst_tb = 1;
    enb_tb = 1;
    max_tb = 0;
    #10
    rst_tb = 0;
    max_tb = 8'hFF;
    #50
    enb_tb = 0;
    #50
    enb_tb = 1;
    #50
    
    // Generate all supported maximums to verify maximum capping capability.
    // Remember that there is a 3 clock cycle delay between changing the maximum
    // input and the receiving a capped output for that maximum.
    for (i=255; i>0; i=i-1) begin
        #50 max_tb <= i;
    end
    
    #50 $finish;
    
    
end

always begin
// Generate desired 300 MHz clock.
    #1.661
    clk_tb <= ~clk_tb;
end

// Instanciate top module using the testbench-defined ports.
top uut (.clk(clk_tb), .rst(rst_tb), .enb(enb_tb), .max(max_tb), .out(out_tb));

endmodule
