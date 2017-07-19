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
    parameter layer_size = 28,
    parameter fc_simd = 15, // FC LAYER SIMD WIDTH
    parameter out_channels = lcm(channels, fc_simd)
    )
    
    (
    input clk, done,
    input [clogb2(round_to_next_two(layer_size**2))-1 : 0] in_addr,
    input [channels*channel_width-1:0] din,
    input [channels - 1 : 0] wren_in,
    output reg [out_channels - 1 : 0] wren_out = 0,
    output reg [out_channels*channel_width-1:0] dout = 0,
    output reg [clogb2(round_to_next_two(channels*layer_size**2/out_channels))-1 : 0] out_addr = 0,
    output reg layer_done = 1'b1
    );
    
    
    `include "functions.vh"
      
    integer i = 0;
    integer count = 0;
    integer popcnt = 0;

    always @(posedge clk) begin
    
        if (done) begin // MODULE BEFORE IS DONE, LAST WORD HAS BEEN RECEIVED, SO END THE OUTPUT
            dout <= dout;
            out_addr <= out_addr;
            wren_out <= {out_channels{1'b1}};
            count <= count;
            layer_done <= 1'b1;
        
        end
        else if (layer_done) begin
            dout <= 0;
            out_addr <= 0;
            count <= 0;
            wren_out <= 0;
            layer_done <= 1'b0;
        end
        else begin
            if (wren_out) begin
                out_addr <= out_addr + 1;
            end
            else begin
                out_addr <= out_addr;
            end
        
            popcnt = 0;
            for (i=0; i<channels; i=i+1) begin
                if (wren_in[i]) begin
                    popcnt = popcnt + 1;
                    dout[(count+i)*channel_width +: channel_width] <= din[i*channel_width +: channel_width]; 
                end
            end
            
            if (count + popcnt >= out_channels) begin
                wren_out <= {out_channels{1'b1}};
                count <= 0;
            end
            else begin
                count <= count + popcnt;
                wren_out <= 0;
            end
        end
    end
endmodule
