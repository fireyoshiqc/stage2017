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
    parameter integer pool_size = 2,
    parameter integer input_width = 9,
    parameter integer root = 3,
    parameter integer stride = 1,
    parameter integer max_res_size = ((root-pool_size)/stride + 1)
    )
    (
    input clk, ack, start,
    input [input_width*8 - 1 : 0] image,
    output reg [(max_res_size**2)*8 - 1 : 0] out,
    output reg done = 1'b0,
    output reg ready = 1'b0
    );
    
    integer i = 0;
    integer j = 0;
    integer pool_i = 0;
    integer pool_j = 0;
    //reg [7:0] max [max_res_size-1:0];
    reg [2:0] operation = 0;
    reg [7:0] poolmax = 0;
    
    always @(posedge clk) begin
        case(operation)
            3'b000: begin // INITIALIZE
                for (i=0; i < max_res_size**2; i = i + 1) begin
                    out[i*8 +: 8] <= 0;
                end
                ready <= 1'b1;
                done <= 1'b0;
                operation <= 3'b101;
            end
            3'b001: begin // LOAD INPUTS
                // THIS STATE IS NOT TO BE IMPLEMENTED UNLESS WE READ FROM BRAM
            end
            3'b010: begin // LOAD MAX
                // THIS STATE IS NOT NEEDED UNLESS WE USE CUSTOM MAX FUNCTIONS
            end
            3'b011: begin // MAX POOL
            
                for (i=0; i < max_res_size; i = i + 1) begin
                    for (j=0; j < max_res_size; j = j + 1) begin
                        if (image[((i*stride+pool_i)*root+(j*stride)+pool_j)*8 +: 8] > out[(i*max_res_size + j)*8 +: 8]) begin
                            out[(i*max_res_size + j)*8 +: 8] = image[((i*stride+pool_i)*root+(j*stride)+pool_j)*8 +: 8];
                        end
                    end
                end
            
            
            
            
//                poolmax = 0;
//                for (i=0; i < pool_size; i = i + 1) begin
//                    for (j=0; j < pool_size; j = j + 1) begin
//                        if (image[((pool_i+i)*root+pool_j+j)*8 +: 8] > poolmax) begin
//                            poolmax = image[((pool_i*stride+i)*root+(pool_j*stride)+j)*8 +: 8];
//                        end
//                        else begin
//                            poolmax = poolmax;
//                        end
//                    end
//                end
                                
//                out[(pool_i*max_res_size + pool_j)*8 +: 8] = poolmax;
                
                if (pool_i < pool_size - 1) begin
                    if (pool_j < pool_size - 1) begin
                        pool_j <= pool_j + 1;
                    end
                    else begin
                        pool_j <= 0;
                        pool_i <= pool_i + 1;
                    end
                end
                else begin
                    if (pool_j < pool_size - 1) begin
                        pool_j <= pool_j + 1;
                    end
                    else begin
                        pool_i <= 0;
                        pool_j <= 0;
                        operation = 3'b100;
                        ready <= 1'b0;
                        done <= 1'b1;
                    end
                end
            end
            3'b100: begin // DONE (WAIT)
                if (ack) begin
                    operation <= 3'b000;
                    ready <= 1'b1;
                    done <= 1'b0;
                end
                else begin
                    operation <= 3'b100;
                    ready <= 1'b0;
                    done <= 1'b1;
                end
            end
            3'b101: begin // READY
                if (start) begin
                    operation <= 3'b011;
                    ready <= 1'b0;
                    done <= 1'b0;
                end
                else begin
                    operation <= 3'b101;
                    ready <= 1'b1;
                    done <= 1'b0;
                end
            end
        endcase
    end
    
endmodule
