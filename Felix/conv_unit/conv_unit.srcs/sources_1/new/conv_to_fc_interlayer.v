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
    parameter channels = 4,
    parameter channel_width = 8,
    parameter data_depth = 784,
    parameter fc_simd = 3 // FC LAYER SIMD WIDTH
    // THIS INTERLAYER DOES NOT SUPPORT ZERO PADDING
    )
    (
    input clk, done, ready,
    input [clogb2(round_to_next_two(data_depth))-1 : 0] in_addr,
    input [channels*channel_width-1:0] din,
    input [channels - 1 : 0] wren_in,
    output reg [fc_simd - 1 : 0] wren_out = 0,
    output reg [fc_simd*channel_width-1:0] dout = 0,
    output reg [clogb2(round_to_next_two(channels*data_depth/fc_simd))-1 : 0] out_addr = 0,
    output reg start = 1'b0,
    output reg hold_cycle = 1'b1
    );
    //reg [clogb2(round_to_next_two(channels*data_depth/fc_simd))-1 : 0] mod_addr = 0;
    //reg [channels*channel_width-1:0] hold_data;
    //wire wren = ~done;
    
    
    `include "functions.vh"
    
    integer i = 0;
    integer j = 0;
    integer last_read = 0;
    //localparam integer smallest = fc_simd < channels ? fc_simd : channels;
    //localparam integer biggest = fc_simd > channels ? fc_simd : channels;
    
    // WORKS FOR FC_SIMD SMALLER THAN CHANNELS, AND ONLY ONE WRITEBYTE ENABLE AT A TIME...
    // STILL NEEDS SOME IMPROVEMENTS.
    
    always @(posedge clk) begin
        wren_out = 0;
        for (i=0; i<channels; i=i+1) begin
            if (wren_in[i]) begin
                if (j >= fc_simd) begin
                    j <= 0;
                    out_addr <= out_addr + 1;
                end
                else begin
                    j <= j + 1;
                end
                    wren_out[j] = 1'b1;
                    dout[j*channel_width +: channel_width] <= din[i*channel_width +: channel_width];
            end
        end
    end
endmodule
