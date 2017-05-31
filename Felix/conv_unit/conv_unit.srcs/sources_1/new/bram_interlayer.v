`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/31/2017 03:27:19 PM
// Design Name: 
// Module Name: bram_interlayer
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


module bram_interlayer
    #(
    parameter integer data_width = 8,
    parameter integer data_depth = 784
    )
    (
    input clk, done, ready,
    input [clogb2(round_to_next_two(data_depth))-1 : 0] wr_addr,
    input [clogb2(round_to_next_two(data_depth))-1 : 0] rd_addr,
    input [data_width-1:0] din,
    output reg [data_width-1:0] dout,
    output reg start = 1'b0
    );
    
    reg [data_width:0] bram [round_to_next_two(data_depth)-1:0];
    wire wren = ~done;
    
    
    `include "functions.vh"
    
    always @(posedge clk) begin
        if (wren) begin
            bram[wr_addr] <= din;
            start <= 1'b0;
        end
        else begin
            dout <= bram[rd_addr];
            start <= ready;
        end
    end
    
endmodule
