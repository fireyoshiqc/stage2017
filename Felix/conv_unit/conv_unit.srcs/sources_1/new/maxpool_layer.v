`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/31/2017 10:58:11 AM
// Design Name: 
// Module Name: maxpool_layer
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


module maxpool_layer
    #(
    parameter integer bram_depth = 784,
    parameter integer pool_size = 2,
    parameter integer input_width = 9,
    parameter integer root = 3,
    parameter integer stride = 1,
    parameter integer max_res_size = ((root-pool_size)/stride + 1)
    )
    (
    input clk, ack, start,
    //input [input_width*8 - 1 : 0] image,
    input [7:0] din,
    output reg [7:0] dout = 0,
    //output reg [(max_res_size**2)*8 - 1 : 0] out,
    output reg done = 1'b0,
    output reg ready = 1'b0,
    output reg load_done = 1'b0,
    output reg [clogb2(round_to_next_two(bram_depth))-1 : 0] addr
    );
    
    `include "functions.vh"
    
    integer i = 0;
    integer j = 0;
    integer clocked_i = 0;
    integer clocked_j = 0;
    //reg [7:0] max [max_res_size-1:0];
    reg [7:0] image [input_width-1:0];
    reg [2:0] operation = 0;
    reg [7:0] poolmax = 0;
    
    always @(posedge clk) begin
        case(operation)
            3'b000: begin // INITIALIZE
                for (i=0; i < input_width; i = i + 1) begin
                    image[i] <= 0;
                end
                ready <= 1'b1;
                done <= 1'b0;
                operation <= 3'b101;
            end
            3'b001: begin // LOAD INPUTS
                // THIS STATE IS NOT TO BE IMPLEMENTED UNLESS WE READ FROM BRAM
                 // BRAM LOAD
               // MUST OPTIMIZE ADDRESSING
               image [clocked_i*root + clocked_j] <= din;
               if (addr == 0) begin // LOSE A CLOCK CYCLE TO ALLOW BRAM TO KEEP UP
                   clocked_i <= clocked_i;
                   clocked_j <= clocked_j;
               end
               else begin
                       ;
                   
                   if (clocked_i < root - 1) begin
                       if (clocked_j < root - 1) begin
                           clocked_j = clocked_j + 1;   
                       end
                       else begin
                           clocked_j = 0;
                           clocked_i = clocked_i + 1;
                       end
                   end
                   else begin
                       if (clocked_j < root - 1) begin
                           clocked_j = clocked_j + 1;
                       end
                       else begin
                           clocked_i = 0;
                           clocked_j = 0;
                           ready <= 1'b0;
                           done <= 1'b0;
                           load_done <= 1'b1;
                           operation = 3'b011; // TO MAX POOL
                       end
                   end
               end
               addr = addr + 1;
            end
            3'b010: begin // LOAD MAX
                // THIS STATE IS NOT NEEDED UNLESS WE USE CUSTOM MAX FUNCTIONS
            end
            3'b011: begin // MAX POOL
                
                dout = 0;
                
                for (i=0; i < max_res_size; i = i + 1) begin
                    for (j=0; j < max_res_size; j = j + 1) begin
                        if (image[((i*stride+clocked_i)*root+(j*stride)+clocked_j)] > dout) begin
                            dout = image[((i*stride+clocked_i)*root+(j*stride)+clocked_j)];
                        end
                    end
                end
            
            
            
            
//                poolmax = 0;
//                for (i=0; i < pool_size; i = i + 1) begin
//                    for (j=0; j < pool_size; j = j + 1) begin
//                        if (image[((clocked_i+i)*root+clocked_j+j)*8 +: 8] > poolmax) begin
//                            poolmax = image[((clocked_i*stride+i)*root+(clocked_j*stride)+j)*8 +: 8];
//                        end
//                        else begin
//                            poolmax = poolmax;
//                        end
//                    end
//                end
                                
//                out[(clocked_i*max_res_size + clocked_j)*8 +: 8] = poolmax;
                
                if (clocked_i == 0 && clocked_j == 0) begin
                    addr = 0;
                end
                else begin
                    addr = addr + 1;
                end
                if (clocked_i < pool_size - 1) begin
                    if (clocked_j < pool_size-1) begin
                        clocked_j <= clocked_j + 1;
                    end
                    else begin
                        clocked_j <= 0;
                        clocked_i <= clocked_i + 1;
                    end
                end
                else begin
                    if (clocked_j < pool_size-1) begin
                        clocked_j <= clocked_j + 1;
                    end
                    else begin
                        operation <= 3'b100;
                    end
                end
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
                if (start) begin // TO LOAD
                    operation <= 3'b001;
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
