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
    parameter integer input_size = 3,
    parameter integer stride = 1,
    parameter integer channels = 1,
    parameter integer max_res_size = ((input_size-pool_size)/stride + 1)
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
    output reg [clogb2(round_to_next_two(bram_depth))-1 : 0] addr = 0,
    output reg [clogb2(round_to_next_two(bram_depth))-1 : 0] out_addr = 0
    );
    
    `include "functions.vh"
    
    integer i = 0;
    integer max_i = 0;
    integer max_j = 0;
    integer channel = 0;
    integer clocked_i = 0;
    integer clocked_j = 0;
    integer clocked_channel = 0;
    //reg [7:0] max [max_res_size-1:0];
    reg [7:0] image [input_size**2 -1:0];
    reg [2:0] operation = 0;
    reg [7:0] poolmax = 0;
    
    reg [7:0] tempram [8:0];
    
    always @(posedge clk) begin
        case(operation)
            3'b000: begin // INITIALIZE
                for (i=0; i < input_size**2; i = i + 1) begin
                    tempram[i] <= i;
                end
                ready <= 1'b1;
                done <= 1'b0;
                operation <= 3'b101;
            end
//            3'b001: begin // LOAD INPUTS
//                // THIS STATE IS NOT TO BE IMPLEMENTED UNLESS WE READ FROM BRAM
//                 // BRAM LOAD
//               // MUST OPTIMIZE ADDRESSING
//               image [clocked_i*input_size + clocked_j] <= din;
//               if (addr == 0) begin // LOSE A CLOCK CYCLE TO ALLOW BRAM TO KEEP UP
//                   clocked_i <= clocked_i;
//                   clocked_j <= clocked_j;
//               end
//               else begin
                   
//                   if (clocked_i < input_size - 1) begin
//                       if (clocked_j < input_size - 1) begin
//                           clocked_j = clocked_j + 1;   
//                       end
//                       else begin
//                           clocked_j = 0;
//                           clocked_i = clocked_i + 1;
//                       end
//                   end
//                   else begin
//                       if (clocked_j < input_size - 1) begin
//                           clocked_j = clocked_j + 1;
//                       end
//                       else begin
//                           clocked_i = 0;
//                           clocked_j = 0;
//                           ready <= 1'b0;
//                           done <= 1'b0;
//                           load_done <= 1'b1;
//                           operation = 3'b011; // TO MAX POOL
//                       end
//                   end
//               end
//               addr = addr + 1;
//            end
            3'b010: begin // LOAD MAX
                // THIS STATE IS NOT NEEDED UNLESS WE USE CUSTOM MAX FUNCTIONS
                dout = 0;
                
                for (channel=0; channel<channels; channel = channel + 1) begin
                    if (tempram[addr] > dout[channel*8 +: 8]) begin
                        dout[channel*8 +: 8] <= tempram[addr];
//                    if (din[channel*8 +: 8] > dout[channel*8 +: 8]) begin
                        //dout[channel*8 +: 8] <= din[channel*8 +: 8];
                    end
                end
                channel = 0;
                if (clocked_i == 0 && clocked_j == 0) begin
                    addr = max_j*stride+max_i*stride*input_size; // STILL NEED TO FIND OUT HOW TO IMPLEMENT MULTI-CHANNEL ON ADDR
                end
                if (clocked_i < pool_size - 1) begin
                    if (clocked_j < pool_size-1) begin
                        clocked_j <= clocked_j + 1;
                        addr = addr + 1;
                    end
                    else begin
                        clocked_j <= 0;
                        clocked_i <= clocked_i + 1;
                        addr = addr + input_size - 1; 
                    end
                end
                else begin
                    if (clocked_j < pool_size-1) begin
                        clocked_j <= clocked_j + 1;
                        addr = addr + 1;
                    end
                    else begin
                        out_addr = out_addr + 1;
                        clocked_i <= 0;
                        clocked_j <= 0;
                        
                        if (max_i < max_res_size-1) begin
                            if (max_j < max_res_size-1) begin
                                max_j <= max_j + 1;
                            end
                            else begin
                                max_j <= 0;
                                max_i <= max_i + 1;
                            end
                        end
                        else begin
                            if (max_j < max_res_size-1) begin
                                max_j <= max_j + 1;
                            end
                            else begin
                                max_j <= 0;
                                max_i <= 0;
                                operation <= 3'b100;
                            end
                        end 
                    end
                end
                
//                for (i=0; i < max_res_size; i = i + 1) begin
//                    for (j=0; j < max_res_size; j = j + 1) begin
//                        if (image[((i*stride+clocked_i)*input_size+(j*stride)+clocked_j)] > dout) begin
//                            dout = image[((i*stride+clocked_i)*input_size+(j*stride)+clocked_j)];
//                        end
//                    end
//                end
                
            end
//            3'b011: begin // MAX POOL
                
//                dout = 0;
                
//                for (i=0; i < max_res_size; i = i + 1) begin
//                    for (j=0; j < max_res_size; j = j + 1) begin
//                        if (image[((i*stride+clocked_i)*input_size+(j*stride)+clocked_j)] > dout) begin
//                            dout = image[((i*stride+clocked_i)*input_size+(j*stride)+clocked_j)];
//                        end
//                    end
//                end
            
            
            
            
////                poolmax = 0;
////                for (i=0; i < pool_size; i = i + 1) begin
////                    for (j=0; j < pool_size; j = j + 1) begin
////                        if (image[((clocked_i+i)*input_size+clocked_j+j)*8 +: 8] > poolmax) begin
////                            poolmax = image[((clocked_i*stride+i)*input_size+(clocked_j*stride)+j)*8 +: 8];
////                        end
////                        else begin
////                            poolmax = poolmax;
////                        end
////                    end
////                end
                                
////                out[(clocked_i*max_res_size + clocked_j)*8 +: 8] = poolmax;
                
//                if (clocked_i == 0 && clocked_j == 0) begin
//                    addr = 0;
//                end
//                else begin
//                    addr = addr + 1;
//                end
//                if (clocked_i < pool_size - 1) begin
//                    if (clocked_j < pool_size-1) begin
//                        clocked_j <= clocked_j + 1;
//                    end
//                    else begin
//                        clocked_j <= 0;
//                        clocked_i <= clocked_i + 1;
//                    end
//                end
//                else begin
//                    if (clocked_j < pool_size-1) begin
//                        clocked_j <= clocked_j + 1;
//                    end
//                    else begin
//                        operation <= 3'b100;
//                    end
//                end
//            end
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
                    clocked_i = 0;
                    clocked_j = 0;
                    out_addr = 0;
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

