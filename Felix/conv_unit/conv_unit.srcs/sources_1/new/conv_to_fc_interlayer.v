`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/14/2017 11:35:18 AM
// Design Name: 
// Module Name: conv_to_fc_interlayer
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


module conv_to_fc_interlayer#(
    parameter channels = 10,
    parameter channel_width = 8,
    parameter [0:0] signbit = 1'b1, // CAN BE ONE OR ZERO
    parameter layer_size = 28,
    parameter fc_simd = 15, // FC LAYER SIMD WIDTH
    parameter out_channels = lcm(channels, fc_simd),
    parameter data_depth = out_channels / channels
    )
    
    (
    input clk, done, ready,
    input [clogb2(round_to_next_two(layer_size**2))-1 : 0] wr_addr,
    input [clogb2(round_to_next_two(data_depth))-1 : 0] rd_addr,
    input [channels*channel_width-1:0] din,
    input [channels - 1 : 0] wren_in,
    //input [clogb2(round_to_next_two(layer_size))-1 : 0] row, // CET INPUT PEUT ETRE IGNORÉ
    //output reg [out_channels - 1 : 0] wren_out = 0,
    output reg [out_channels*(signbit+channel_width)-1:0] dout = 0,
    //output reg [clogb2(round_to_next_two(channels*layer_size**2/out_channels))-1 : 0] out_addr = 0,
    output reg start = 1'b0,
    output reg ack = 1'b0
    );

    `include "functions.vh"
      
    integer i = 0;
    integer count = 0;
    integer popcnt = 0;
    
    reg [out_channels*(signbit+channel_width)-1:0] bram [data_depth-1:0];
    reg [clogb2(round_to_next_two(out_channels/channels))-1 : 0] bram_addr = 0;
    //reg [out_channels - 1 : 0] bram_wren = 0;
    reg bram_wren = 1'b0;
    reg [out_channels*(signbit+channel_width)-1:0] bram_din = 0;
    reg layer_done = 1'b1;
    
    initial begin
        for (i=0; i<data_depth; i=i+1) bram[i]=0;
    end

    always @(posedge clk) begin
        
        if (layer_done) begin
                bram_din <= 0;
                bram_addr <= 0;
                count <= 0;
                bram_wren <= 0;
                layer_done <= 1'b0;
        end
        else if (done) begin // MODULE BEFORE IS DONE, LAST WORD HAS BEEN RECEIVED, SO END THE OUTPUT
            bram_din <= bram_din;
            bram_addr <= bram_addr;
            bram_wren <= 1'b1;
            count <= count;
            layer_done <= 1'b1;
        
        end
        
        else begin
            if (bram_wren) begin
                bram_addr <= bram_addr + 1;
            end
            else begin
                bram_addr <= bram_addr;
            end
        
            popcnt = 0;
            for (i=0; i<channels; i=i+1) begin
                if (wren_in[i]) begin
                    popcnt = popcnt + 1;
                    bram_din[(count+i)*(channel_width+signbit) +: (channel_width+signbit)] <= {{signbit{1'b0}}, din[i*channel_width +: channel_width]}; 
                end
            end
            
            if (count + popcnt >= out_channels) begin
                bram_wren <= 1'b1;
                count <= 0;
            end
            else begin
                count <= count + popcnt;
                bram_wren <= 0;
            end
        end
    end
    
    always @(posedge clk) begin
        if (bram_wren) begin
        //WRITE AT ZERO_PADDING*(LAYER_SIZE+ZERO_PADDING) + WR_ADDR + 2*ZERO_PADDING*[ROW]-1
        //USE BYTEWRITE WRITE ENABLE MODE WITH THE CHANNEL INPUT TO ALLOW CONV LAYERS TO WRITE SEPARATE CHANNELS IN THE SAME WORD
            bram[bram_addr] <= bram_din;
            start <= 1'b0;
        end
        else begin
            dout <= bram[rd_addr];
            start <= ready & done;
            ack <= ready & done;
        end
    end
    
endmodule
