`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/14/2017 10:40:43 AM
// Design Name: 
// Module Name: bram_fc_interlayer
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


module bram_fc_interlayer #(
    parameter channels = 4,
    parameter channel_width = 8,
    parameter data_depth = 784,
    parameter fc_simd = 3 // FC LAYER SIMD WIDTH
    // THIS INTERLAYER DOES NOT SUPPORT ZERO PADDING
    )
    (
    input clk, done, ready,
    input [clogb2(round_to_next_two(data_depth))-1 : 0] wr_addr,
    input [clogb2(round_to_next_two(channels*data_depth/fc_simd))-1 : 0] rd_addr,
    input [channels*channel_width-1:0] din,
    input [channels - 1 : 0] wren,
    output reg [fc_simd*channel_width-1:0] dout,
    output reg start = 1'b0
    //output reg wr_ready = 1'b0
    );

    (* ramstyle = "block" *) reg [round_to_next_two(channels*data_depth/fc_simd)*fc_simd*channel_width-1:0] bram;
    //reg [clogb2(round_to_next_two(channels*data_depth/fc_simd))-1 : 0] mod_addr = 0;
        //reg [channels*channel_width-1:0] hold_data;
    //wire wren = ~done;
    
    
    `include "functions.vh"
    
    integer i;
    integer j;
    initial for (i=0; i<round_to_next_two(channels*data_depth/fc_simd); i=i+1) bram[i]=0;
    
     always @(posedge clk) begin
       if (wren) begin
       //WRITE AT ZERO_PADDING*(LAYER_SIZE+ZERO_PADDING) + WR_ADDR + 2*ZERO_PADDING*[ROW]-1
       //USE BYTEWRITE WRITE ENABLE MODE WITH THE CHANNEL INPUT TO ALLOW CONV LAYERS TO WRITE SEPARATE CHANNELS IN THE SAME WORD
           for (i = 0; i < channels; i = i+1) begin
               if (wren[i]) begin
                   bram[(wr_addr*channels+i)*channel_width +: channel_width] <= din[i*channel_width +: channel_width];
               end
           end
           
           start <= 1'b0;
       end
       else begin
           dout <= bram[rd_addr*fc_simd*channel_width +: fc_simd*channel_width];
           start <= ready & done;
       end
   end
endmodule
