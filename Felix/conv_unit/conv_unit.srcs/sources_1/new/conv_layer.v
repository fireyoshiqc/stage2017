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
    //parameter integer dsp_max = 9,
    parameter integer bram_depth = 784,
    parameter integer zero_padding = 0,
    parameter integer stride = 1,
    parameter integer filter_size = 2,
    parameter integer filter_nb = 1,
    parameter integer input_size = 2,
    parameter integer channels = 1,
    parameter integer conv_res_size = ((input_size+2*zero_padding-filter_size)/stride) + 1
    )
    (
    input clk, ack, start,
    input [channels * 8 - 1 : 0] din,
    input [filter_size**2*filter_nb*8-1 : 0] filters,
    input [filter_nb*8-1 : 0] biases,
    output done_w,
    output ready_w,
    output load_done_w,
    output [8 - 1 : 0] dout_w,
    output [clogb2(round_to_next_two(bram_depth))-1 : 0] addr_w,
    output reg [clogb2(round_to_next_two(input_size))-1 : 0] row = 0,
    output reg wren = 0
    );
    
    `include "functions.vh"
    
    integer i = 0, j = 0;
    integer clocked_i = 0;
    integer clocked_j = 0;
    integer clocked_k = 0;
    
    reg done = 1'b0;
    reg ready = 1'b0;
    reg load_done = 1'b0;
    reg [filter_nb * 8 - 1 : 0] dout;
    reg [clogb2(round_to_next_two(input_size**2))-1 : 0] addr = 0;
    
    reg [2:0] operation = 0;
    reg [channels* 8 - 1:0] vram [input_size**2 + 4*input_size*zero_padding + 4*zero_padding**2 - 1 : 0];
    reg [channels * 8 - 1:0] conv_filter [filter_size**2 - 1 : 0];
    reg [15:0] products [filter_size**2 - 1 : 0];
    reg [clogb2(round_to_next_two(filter_size**2))+16-1:0] sum = 0;
    
    wire vram_addr [31:0];
    
    assign done_w = done;
    assign ready_w = ready;
    assign load_done_w = load_done;
    assign dout_w = dout;
    assign addr_w = addr;
    
    
    always @(posedge clk) begin
        case (operation)
            3'b000: begin   // INITIALIZE
                for (i = 0; i<input_size**2 + 4*input_size*zero_padding + 4*zero_padding**2; i = i+1) begin
                    vram [i] <= 0;
                end
                addr <= 0;
                dout <= 0;
                ready <= 1'b1;
                done <= 1'b0;
                load_done <= 1'b0;
                operation = 3'b101;
            end
            
            3'b001: begin    // LOAD AND PAD INPUTS
                // BRAM LOAD
                // MUST OPTIMIZE ADDRESSING
                vram [(clocked_i*(input_size+2*zero_padding) + clocked_j)] = din;
                
                if (addr == 0) begin // LOSE A CLOCK CYCLE TO ALLOW BRAM TO KEEP UP
                    clocked_i <= clocked_i;
                    clocked_j <= clocked_j;
                end
                else begin
                    if (clocked_i < input_size+zero_padding - 1) begin
                        if (clocked_j < input_size+zero_padding - 1) begin
                            clocked_j = clocked_j + 1;   
                        end
                        else begin
                            clocked_j = zero_padding;
                            clocked_i = clocked_i + 1;
                        end
                    end
                    else begin
                        if (clocked_j < input_size+zero_padding - 1) begin
                            clocked_j = clocked_j + 1;
                        end
                        else begin
                            clocked_i = 0;
                            clocked_j = 0;
                            ready <= 1'b0;
                            done <= 1'b0;
                            load_done <= 1'b1;
                            operation = 3'b010; // TO FILTER LOAD
                        end
                    end
                end
                
                addr = addr + 1;               

                // ALL-AT-ONCE-LOAD
//                for (i = zero_padding; i<input_size+zero_padding; i = i+1) begin
//                    for (j = zero_padding; j<input_size+zero_padding; j = j+1) begin
//                        vram [i*(input_size+2*zero_padding) + j] <= image[((i-zero_padding)*input_size + j - zero_padding)*8 +: 8];
//                    end
//                end
//                i <= 0;
//                j <= 0;
//                ready <= 1'b0;
//                done <= 1'b0;
//                operation = 3'b010;
            end
            3'b010: begin   // LOAD FILTER
                addr = 0;
                for (j = 0; j<filter_size**2; j = j+1) begin
                    conv_filter [j] <= filters[(clocked_k*(filter_size**2) +j)*8 +: 8];
                end
                ready <= 1'b0;
                done <= 1'b0;
                load_done <= 1'b1;
                operation = 3'b011;
                wren <= 1;
            end
            3'b011: begin    // CONVOLVE FILTER
                for (i = 0; i < filter_size; i = i + 1) begin
                    for (j = 0; j < filter_size; j = j + 1) begin
                        products [i*filter_size+j] = vram[(i+clocked_i*stride)*(input_size+2*zero_padding)+(j+clocked_j*stride)]
                        * conv_filter[i*filter_size+j];
                        sum = sum + products[i*filter_size+j];
                    end
                end
                sum = sum + biases[clocked_k*8 +: 8];
//                out [((clocked_i*conv_res_size+clocked_j)*8)+clocked_k*(conv_res_size**2*8) +: 8] 
//                = sum[(clogb2(round_to_next_two(filter_size**2))+16)-1 -: 8] ;
                dout = sum[(clogb2(round_to_next_two(filter_size**2))+16)-1 -: 8]+sum[(clogb2(round_to_next_two(filter_size**2))+8)-1];
                sum = 0;
                if (clocked_j == 0) begin
                    row = row + 1;
                    
                    if (clocked_i == 0) begin
                        addr = 0;
                        row = 0;
                    end
                    else begin
                        addr = addr + 1;
                    end
                end
                else begin
                    addr = addr + 1;
                end
                if (clocked_i < conv_res_size - 1) begin
                    if (clocked_j < conv_res_size-1) begin
                        clocked_j <= clocked_j + 1;
                    end
                    else begin
                        clocked_j <= 0;
                        clocked_i <= clocked_i + 1;
                    end
                end
                else begin
                    if (clocked_j < conv_res_size-1) begin
                        clocked_j <= clocked_j + 1;
                    end
                    else begin
                        clocked_i <= 0;
                        clocked_j <= 0;


                        if (clocked_k < filter_nb-1) begin
                            clocked_k <= clocked_k + 1;
                            operation <= 3'b010;
                            ready <= 1'b0;
                            done <= 1'b0;
                        end
                        else begin
                            clocked_k <= 0;
                            operation <= 3'b100;                     
                        end
                    end
                end
            end
            3'b100: begin // DONE (WAIT)
                addr <= 0;
                dout <= 0;
                row <= 0;
                wren <= 0; 
                if (ack) begin // TO READY
                    operation <= 3'b101;
                    ready <= 1'b1;
                    done <= 1'b0;
                    load_done <= 1'b0;
                end
                else begin // TO DONE
                    operation <= 3'b100;
                    ready <= 1'b0;
                    done <= 1'b1;
                    load_done <= 1'b1;
                end
            end
            3'b101: begin // READY
                if (start) begin // TO LOAD
                    operation <= 3'b001;
                    ready <= 1'b0;
                    done <= 1'b0;
                    load_done <= 1'b0;
                    clocked_i = zero_padding;
                    clocked_j = zero_padding;
                end
                else begin // TO READY
                    operation <= 3'b101;
                    ready <= 1'b1;
                    done <= 1'b0;
                    load_done <= 1'b0;
                end
            end
        endcase
    end    
endmodule
