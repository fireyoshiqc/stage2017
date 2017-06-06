`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/06/2017 11:25:48 AM
// Design Name: 
// Module Name: bram_pad_interlayer
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


module bram_pad_interlayer
    #(
    parameter integer data_width = 8,
    parameter integer data_depth = 784,
    parameter integer zero_padding = 0,
    parameter integer layer_size = 2 //WITHOUT PADDING
    )
    (
    input clk, done, ready,
    input [clogb2(round_to_next_two(data_depth))-1 : 0] wr_addr,
    input [clogb2(round_to_next_two(data_depth))-1 : 0] rd_addr,
    input [data_width-1:0] din,
    input [clogb2(round_to_next_two(layer_size))-1 : 0] row,
    output reg [data_width-1:0] dout,
    output reg start = 1'b0
    );

    reg [data_width-1:0] bram [round_to_next_two(data_depth)-1:0];
    wire wren = ~done;
    
    
    `include "functions.vh"
    
    integer i;
    initial for (i=0; i<data_depth; i=i+1) bram[i]=0;
    
    always @(posedge clk) begin
        if (wren) begin
        //WRITE AT ZERO_PADDING*(LAYER_SIZE+ZERO_PADDING) + WR_ADDR + 2*ZERO_PADDING*[ROW]-1
            bram[zero_padding*(layer_size+2*zero_padding+1+2*row)+wr_addr] <= din;
            start <= 1'b0;
        end
        else begin
            dout <= bram[rd_addr];
            start <= ready;
        end
    end

endmodule
