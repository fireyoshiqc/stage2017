`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/29/2017 03:41:59 PM
// Design Name: 
// Module Name: conv_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module conv_ctrl
    #(
    parameter integer input_width = 9,
    parameter integer ouput_width = 16,
    parameter integer simd_units = 4
    )
    (
    input wire rst, clk, start, ack
    );
endmodule
