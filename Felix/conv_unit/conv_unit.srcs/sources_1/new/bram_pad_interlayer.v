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
    parameter channels = 4,
    parameter channel_width = 8,
    parameter data_depth = 784,
    parameter zero_padding = 0,
    parameter layer_size = 2 //WITHOUT PADDING
    )
    (
    input clk, done, ready,
    input [clogb2(data_depth)-1 : 0] wr_addr,
    input [clogb2(round_to_next_two(data_depth))-1 : 0] rd_addr,
    input [channels*channel_width-1:0] din,
    input [clogb2(round_to_next_two(layer_size))-1 : 0] row,
    input [channels - 1 : 0] wren,
    output reg [channels*channel_width-1:0] dout,
    output reg start = 1'b0
    );

    reg [channels*channel_width-1:0] bram [round_to_next_two(data_depth)-1:0];
    //wire wren = ~done;
    
    
    `include "functions.vh"
    
    integer i;
    initial for (i=0; i<data_depth; i=i+1) bram[i]=0;
    
    always @(posedge clk) begin
        
        if (wren) begin
        //WRITE AT ZERO_PADDING*(LAYER_SIZE+ZERO_PADDING) + WR_ADDR + 2*ZERO_PADDING*[ROW]-1
        //USE BYTEWRITE WRITE ENABLE MODE WITH THE CHANNEL INPUT TO ALLOW CONV LAYERS TO WRITE SEPARATE CHANNELS IN THE SAME WORD
            for (i = 0; i < channels; i = i+1) begin
                if (wren[i]) begin
                    bram[zero_padding*(layer_size+2*zero_padding+1+2*row)+wr_addr][i*channel_width +: channel_width] <= din[i*channel_width +: channel_width];
                end
            end
            
            start <= 1'b0;
        end
        else begin
            dout <= bram[rd_addr];
            start <= ready & done;
        end
    end

endmodule
