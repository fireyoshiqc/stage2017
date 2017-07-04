`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2017 01:56:43 PM
// Design Name: 
// Module Name: weights_rom
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


module weights_rom
    #(
    parameter integer out_features = 32,
    parameter integer in_features = 3,
    parameter integer kernel_size = 3
    )
    (
    input clk, rd_enb,
    output reg [in_features*kernel_size**2 - 1 : 0] dout,
    input [clogb2(round_to_next_two(out_features)) - 1 : 0] addr
    );
 
`include "functions.vh"
    
    reg [in_features*kernel_size**2 - 1 : 0] bram [out_features - 1 : 0];
    
    
    integer i;
    initial for (i=0; i<out_features; i = i + 1) bram[i] = 0; //Replace by weight initialization
    
    always @(posedge clk) begin
        if (rd_enb) begin
            dout <= bram[addr];
        end
    end
endmodule
