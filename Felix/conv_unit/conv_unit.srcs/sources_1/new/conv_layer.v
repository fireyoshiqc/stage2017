`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/29/2017 11:27:31 AM
// Design Name: 
// Module Name: conv_layer
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


module conv_layer
    #(
    parameter integer zero_padding = 1,
    parameter integer stride = 2,
    parameter integer filter_size = 3,
    parameter integer filter_nb = 1,
    parameter integer input_width = 9,
    parameter integer root = 3,
    parameter integer simd_units = 9,
    parameter integer conv_res_size = (root+2*zero_padding) / stride
    )
    (
    input clk,
    input [input_width*8 - 1 : 0] image,
    output reg [conv_res_size*conv_res_size*16-1:0] out,
    output reg done = 0
    );
    
    //localparam integer conv_res_size = (root+2*zero_padding) / stride;
    integer i, j;
    integer filter_i = 0;
    integer filter_j = 0;
    reg [1:0] operation = 0;
    reg [7:0] vram [input_width + 4*root*zero_padding + 4*zero_padding*zero_padding - 1 : 0];
    reg [7:0] conv_filter [filter_size*filter_size*filter_nb - 1 : 0];
    reg [15:0] products [filter_size * filter_size - 1 : 0];
    reg [31:0] sum = 0;
    
    always @(posedge clk) begin
        case (operation)
            2'b00: begin
                for (i = 0; i<input_width + 4*root*zero_padding + 4*zero_padding*zero_padding; i = i+1) begin
                    vram [i] <= 0;
                end
                for (j = 0; j<filter_size*filter_size*filter_nb; j = j+1) begin
                    conv_filter [j] <= 8'h01;
                end
                for (i = 0; i<16; i = i+1) begin
                    out [i*16 +: 16] <= 0;
                end
                operation = 2'b01;
            end
            
            2'b01: begin
                for (i = zero_padding; i<root+zero_padding; i = i+1) begin
                    for (j = zero_padding; j<root+zero_padding; j = j+1) begin
                        vram [i*(root+2*zero_padding) + j] <= image[((i-zero_padding)*root + j - zero_padding)*8 +: 8];
                    end
                end
                i <= 0;
                j <= 0;
                operation = 2'b10;
            end
            2'b10: begin
                for (i = 0; i < filter_size; i = i + 1) begin
                    for (j = 0; j < filter_size; j = j + 1) begin
                        products [i*filter_size+j] = vram[(i+filter_i*stride)*(root+2*zero_padding)+(j+filter_j*stride)]
                        * conv_filter[i*filter_size+j];
                        sum = sum + products[i*filter_size+j];
                    end
                end
                out [(filter_i*conv_res_size+filter_j)*16 +: 16] = sum[15:0];
                sum = 0;
                if (filter_j*stride < conv_res_size) begin
                    filter_j <= filter_j + 1;
                end
                else if (filter_i*stride >= conv_res_size) begin
                    filter_i <= 0;
                    filter_j <= 0;
                    operation = 2'b11;
                end
                else begin
                    filter_j <= 0;
                    filter_i <= filter_i + 1;
                end
            end
        endcase
    end    
endmodule
