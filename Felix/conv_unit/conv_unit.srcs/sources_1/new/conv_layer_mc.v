`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/09/2017 02:15:00 PM
// Design Name: 
// Module Name: conv_layer_mc
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


module conv_layer_mc
    #(
    parameter integer bram_depth = 784,
    parameter integer stride = 1,
    parameter integer filter_size = 2,
    parameter integer filter_nb = 2,
    parameter integer input_size = 3,
    parameter integer channels = 2,
    parameter integer dsp_alloc = 1,
    parameter integer conv_res_size = ((input_size-filter_size)/stride) + 1
    )
    (
    input clk, ack, start,
    input [channels * 8 - 1 : 0] din,
    input [filter_size**2*filter_nb*channels*8-1 : 0] filters,
    input [filter_nb*8-1 : 0] biases,
    output reg done = 1'b0,
    output reg ready = 1'b0,
    output reg load_done = 1'b0,
    output reg [filter_nb * 8 - 1 : 0] dout,
    output reg [clogb2(round_to_next_two(bram_depth))-1 : 0] addr = 0,
    output reg [clogb2(round_to_next_two(bram_depth))-1 : 0] out_addr = 0,
    output reg [clogb2(round_to_next_two(conv_res_size))-1 : 0] row = 0,
    output reg [filter_nb - 1 : 0] wren = 0
    );
    
    `include "functions.vh"
    
    integer i = 0, j = 0;
    integer clocked_i = 0;
    integer clocked_j = 0;
    integer clocked_channel = 0;
    integer conv_i = 0;
    integer conv_j = 0;
    integer conv_k = 0;
    integer channel = 0;
    
    
    
    
    
    reg [2:0] operation = 0;
    reg [channels * 8 - 1:0] conv_filter [filter_size**2 - 1 : 0];
    reg [clogb2(round_to_next_two(channels*filter_size**2))+16-1:0] sum = 0;
    
    
    always @(posedge clk) begin
        case (operation)
            3'b000: begin   // INITIALIZE
//                for (i = 0; i<input_size**2 + 4*input_size*zero_padding + 4*zero_padding**2; i = i+1) begin
//                    vram [i] <= 0;
//                end
                addr <= 0;
                dout <= 0;
                ready <= 1'b1;
                done <= 1'b0;
                load_done <= 1'b0;
                operation = 3'b101;
            end
            
            3'b001: begin //CONVOLVE
            // 1. Load needed data (filter should be pre-loaded).
            // 2. Multiply-Accumulate on DSP_ALLOC channels.
            // 3. If needed, iterate to next batch of channels.
            // 4. When done, iterate to next data to pass in kernel.
            // 5. When whole kernel has been iterated, write output to
            //      the corresponding byte (filter).
            // 6. Reset mul-acc to 0 and go to next kernel.
            // 7. When whole image has been treated, go to done.
                
                out_addr = conv_i*conv_res_size + conv_j;
                row = conv_i;
                wren = 0;
                
                if (load_done) begin
                    operation <= 3'b100;
                end
                else begin
                
                
                
                for (channel = clocked_channel; channel < clocked_channel+dsp_alloc; channel = channel + 1) begin
                    sum = sum + din[channel*8 +: 8] * conv_filter[clocked_i*filter_size+clocked_j][channel*8 +: 8];    
                end
               
                if (channel < channels) begin
                    clocked_channel = clocked_channel + dsp_alloc;
                end
                else begin
                    clocked_j = clocked_j + 1;
                    clocked_channel = 0;
                    if (clocked_j >= filter_size) begin
                        addr <= addr + 1;
                        clocked_j = 0;
                        clocked_i = clocked_i + 1;
                        if (clocked_i >= filter_size) begin
                            clocked_i = 0;
                            wren[conv_k]= 1'b1;
                            sum = sum + biases[conv_k*8 +: 8];
                            dout[conv_k*8 +: 8] = sum[(clogb2(round_to_next_two(channels*filter_size**2))+16)-1 -: 8]+sum[(clogb2(round_to_next_two(channels*filter_size**2))+8)-1];
                            sum = 0;
                            conv_j = conv_j + 1;
                            if (conv_j >= conv_res_size) begin
                                conv_j = 0;
                                conv_i = conv_i + 1;
                                if (conv_i >= conv_res_size) begin
                                    conv_i = 0;
                                    conv_k = conv_k + 1;
                                    if (conv_k >= filter_nb) begin
                                        operation <= 3'b001;
                                        load_done <= 1'b1;
                                    end
                                    else begin
                                        operation <= 3'b010;
                                    end
                                end
                                else begin
                                conv_k = conv_k;
                                operation = 3'b001;
                                end
                            end
                            else begin
                                conv_i = conv_i;
                                conv_k = conv_k;
                                operation = 3'b001;
                            end
                        end
                        else begin
                            conv_i = conv_i;
                            conv_j = conv_j;
                            conv_k = conv_k;
                            operation = 3'b001;
                        end
                    end
                    else begin
                        if (clocked_j == filter_size - 1) begin
                            if (clocked_i == filter_size -1) begin
                                if (conv_j == conv_res_size - 1) begin
                                    if (conv_i == conv_res_size - 1) begin
                                        addr <= 0;
                                    end
                                    else begin
                                        addr <= addr + input_size*(stride-filter_size)+1;
                                    end
                                end
                                else begin
                                    addr <= addr + stride - (input_size+1)*(filter_size-1);
                                end
                            end
                            else begin
                                addr <= addr + input_size - filter_size + 1;
                            end
                            
                        end
                        
                        else begin
                            addr <= addr + 1;
                        end
                        clocked_i = clocked_i;
                        conv_i = conv_i;
                        conv_j = conv_j;
                        conv_k = conv_k;
                        operation <= 3'b001;
                    end
                end           
                end   

            end
            3'b010: begin   // LOAD FILTER
                addr <= 1;
                dout <= 0;
                out_addr <= 0;
                wren <= 0;
                for (j = 0; j<filter_size**2; j = j+1) begin
                    conv_filter [j] <= filters[(conv_k*(filter_size**2) +j)*channels*8 +: channels*8];
                end
                ready <= 1'b0;
                done <= 1'b0;

                operation <= 3'b001;
                
            end

            3'b100: begin // DONE (WAIT)
                addr <= 0;
                dout <= 0;
                out_addr <= 0;
                addr <= 0;
                dout <= 0;
                row <= 0;
                wren <= 0;
                conv_k <= 0;
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
                if (start) begin // TO LOAD FILTER
                    operation <= 3'b010;
                    ready <= 1'b0;
                    done <= 1'b0;
                    load_done <= 1'b0;
                    clocked_i = 0;
                    clocked_j = 0;
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

