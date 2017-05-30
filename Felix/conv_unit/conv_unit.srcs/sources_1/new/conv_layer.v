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
    parameter integer stride = 1,
    parameter integer filter_size = 3,
    parameter integer filter_nb = 2,
    parameter integer input_width = 4,
    parameter integer root = 2,
    parameter integer conv_res_size = ((root+2*zero_padding) / stride)-filter_size+1
    )
    (
    input clk,
    input [input_width*8 - 1 : 0] image,
    input [filter_size**2*filter_nb*8-1 : 0] filters,
    input [filter_nb*8-1 : 0] biases,
    output reg done = 0,
    output reg [filter_nb*(round_to_next_two(filter_size**2)+15)*(conv_res_size**2) - 1 : 0] out
    );
    
    function integer round_to_next_two;
    input integer x;
    begin
    x = x - 1;
    x = x | (x >> 1);
    x = x | (x >> 2);
    x = x | (x >> 4);
    x = x | (x >> 8);
    x = x | (x >> 16);
    x = x + 1;
    round_to_next_two = x;
    end
    endfunction
    
    integer i, j;
    integer filter_i = 0;
    integer filter_j = 0;
    integer filter_k = 0;
    reg [2:0] operation = 0;
    reg [7:0] vram [input_width + 4*root*zero_padding + 4*zero_padding**2 - 1 : 0];
    reg [7:0] conv_filter [filter_size**2 - 1 : 0];
    reg [15:0] products [filter_size**2 - 1 : 0];
    reg [(round_to_next_two(filter_size**2)+15)-1:0] sum = 0;
    
    always @(posedge clk) begin
        case (operation)
            3'b000: begin   // INITIALIZE
                for (i = 0; i<input_width + 4*root*zero_padding + 4*zero_padding**2; i = i+1) begin
                    vram [i] <= 0;
                end
                for (i = 0; i<conv_res_size*conv_res_size*filter_nb; i = i+1) begin
                    out [i*(round_to_next_two(filter_size**2)+15) +: round_to_next_two(filter_size**2)+15] <= 0;
                end
                operation = 3'b001;
            end
            
            3'b001: begin    // LOAD AND PAD INPUTS
                for (i = zero_padding; i<root+zero_padding; i = i+1) begin
                    for (j = zero_padding; j<root+zero_padding; j = j+1) begin
                        vram [i*(root+2*zero_padding) + j] <= image[((i-zero_padding)*root + j - zero_padding)*8 +: 8];
                    end
                end
                i <= 0;
                j <= 0;
                operation = 3'b010;
            end
            3'b010: begin   // LOAD FILTER
                for (j = 0; j<filter_size**2*filter_nb; j = j+1) begin
                    conv_filter [j] <= filters[(filter_k*(filter_size**2)+j)*8 +: 8];
                end
                operation = 3'b011;
            end
            3'b011: begin    // CONVOLVE FILTER
                for (i = 0; i < filter_size; i = i + 1) begin
                    for (j = 0; j < filter_size; j = j + 1) begin
                        products [i*filter_size+j] = vram[(i+filter_i*stride)*(root+2*zero_padding)+(j+filter_j*stride)]
                        * conv_filter[i*filter_size+j];
                        sum = sum + products[i*filter_size+j];
                    end
                end
                out [((filter_i*conv_res_size+filter_j)
                *(round_to_next_two(filter_size**2)+15))
                +filter_k*(conv_res_size**2*(round_to_next_two(filter_size**2)+15))
                +: round_to_next_two(filter_size**2)+15] = sum;
                sum = 0;
                if (filter_i < conv_res_size - 1) begin
                    if (filter_j < conv_res_size-1) begin
                        filter_j <= filter_j + 1;
                    end
                    else begin
                        filter_j <= 0;
                        filter_i <= filter_i + 1;
                    end
                end
                else begin
                    if (filter_j < conv_res_size-1) begin
                        filter_j <= filter_j + 1;
                    end
                    else begin
                        filter_i <= 0;
                        filter_j <= 0;
                        operation = 3'b010;
                        if (filter_k < filter_nb-1) begin
                            filter_k <= filter_k + 1;
                            operation <= 3'b010;
                            done <= 1'b0;
                        end
                        else begin
                            filter_k <= 0;
                            operation <= 3'b100;
                            done <= 1'b1;
                        end
                    end
                end
            end
        endcase
    end    
endmodule
