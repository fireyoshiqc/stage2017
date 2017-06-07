`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2017 04:06:29 PM
// Design Name: 
// Module Name: maxpool_layer_mc
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


module maxpool_layer_mc
#(
    parameter integer bram_depth = 784,
    parameter integer pool_size = 2,
    parameter integer input_size = 4,
    parameter integer stride = 2,
    parameter integer channels = 3,
    parameter integer max_res_size = ((input_size-pool_size)/stride + 1)
    )
    (
    input clk, ack, start,
    //input [input_width*8 - 1 : 0] image,
    input [channels*8-1:0] din,
    output reg [channels*8-1:0] dout = 0,
    
    //output reg [(max_res_size**2)*8 - 1 : 0] out,
    output reg done = 1'b0,
    output reg ready = 1'b0,
    output reg load_done = 1'b0,
    output reg [clogb2(round_to_next_two(bram_depth))-1 : 0] addr = 0,
    output reg [clogb2(round_to_next_two(bram_depth))-1 : 0] out_addr = 0
    );
    
    `include "functions.vh"
    
    integer max_i = 0;
    integer max_j = 0;
    integer channel = 0;
    integer clocked_i = 0;
    integer clocked_j = 0;
    integer clocked_channel = 0;
    reg [2:0] operation = 0;
    reg [channels*8-1:0] max = 0;
    
//    reg [8*channels - 1:0] tempram [15:0];
    
    always @(posedge clk) begin
        case(operation)
            3'b000: begin // INITIALIZE
//                for (channel=0; channel < input_size**2; channel = channel + 1) begin
//                    tempram[channel] <= 639852 - 872*channel;
//                end
                ready <= 1'b1;
                done <= 1'b0;
                operation <= 3'b101;
            end
            
            3'b010: begin // LOAD MAX
                // THIS STATE IS NOT NEEDED UNLESS WE USE CUSTOM MAX FUNCTIONS
                
//                if (clocked_j == 0) begin
//                    //row = row + 1;
                    
//                    if (clocked_i == 0) begin
//                        addr = 0;
//                        //row = 0;
//                    end
//                    else begin
//                        addr = addr + 1;
//                    end
//                end
//                else begin
//                    addr = addr + 1;
//                end
                
                if (clocked_i == 0 &&clocked_j == 1) begin //LOSE A CLOCK CYCLE TO ALLOW BRAM TO KEEP UP
//                    if (max_i == 0 && max_j == 0) begin
//                        out_addr = 0;
//                    end
//                    else begin
//                        out_addr = out_addr + 1;
//                    end
                    
                    dout = max;
                    max = 0;
                end
                else if (clocked_i*pool_size + clocked_j == 2) begin
                    if (max_i == 0 && max_j == 0) begin
                        out_addr <= out_addr;
                    end
                    else if (load_done) begin
                        operation = 3'b100;
                    end
                    else begin
                        out_addr <= out_addr + 1;
                    end
                end
                
                if (clocked_i < pool_size - 1) begin
                    if (clocked_j < pool_size-1) begin
                        clocked_j = clocked_j + 1;
                    end
                    else begin
                        clocked_j = 0;
                        clocked_i = clocked_i + 1;
                        
                        //addr = addr + input_size - 1; 
                    end
                end
                else begin
                    if (clocked_j < pool_size-1) begin
                        clocked_j = clocked_j + 1;
                        //addr = addr + 1;
                    end
                    else begin

                        clocked_i = 0;
                        clocked_j = 0;
                        
                        
                        if (max_i < max_res_size-1) begin
                            if (max_j < max_res_size-1) begin
                                max_j = max_j + 1;
                                //out_addr = out_addr + 1;
                            end
                            else begin
                                max_j = 0;
                                max_i = max_i + 1;
                                //out_addr = out_addr + 1;
                            end
                        end
                        else begin
                            if (max_j < max_res_size-1) begin
                                max_j = max_j + 1;
                                //out_addr = out_addr + 1;
                            end
                            else begin
                                max_j = 0;
                                max_i = 0;
                                load_done <= 1'b1;
                            end
                        end
                        
                         
                        
                    end
                end
                
                for (channel=0; channel<channels; channel = channel + 1) begin
//                    if (tempram[addr][channel*8 +: 8] > dout[channel*8 +: 8]) begin
//                        dout[channel*8 +: 8] = tempram[addr][channel*8 +: 8];
                    if (din[channel*8 +: 8] > max[channel*8 +: 8]) begin
                        max[channel*8 +: 8] <= din[channel*8 +: 8];
                    end
                end
                
                addr = max_j*stride+max_i*stride*input_size + clocked_i*input_size+clocked_j;
                
                


                


//                for (i=0; i < max_res_size; i = i + 1) begin
//                    for (j=0; j < max_res_size; j = j + 1) begin
//                        if (image[((i*stride+clocked_i)*input_size+(j*stride)+clocked_j)] > dout) begin
//                            dout = image[((i*stride+clocked_i)*input_size+(j*stride)+clocked_j)];
//                        end
//                    end
//                end
                
            end
            
            3'b100: begin // DONE (WAIT)
                addr <= 0;
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
                if (start) begin // TO LOAD MAX
                    operation <= 3'b010;
                    ready <= 1'b0;
                    done <= 1'b0;
                    load_done <= 1'b0;
                    clocked_i <= 0;
                    clocked_j <= 0;
                    out_addr <= 0;
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

