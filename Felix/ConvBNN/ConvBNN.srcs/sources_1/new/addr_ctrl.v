`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2017 02:27:42 PM
// Design Name: 
// Module Name: addr_ctrl
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


module addr_ctrl
    #(
    parameter integer in_features = 3,
    parameter integer out_features = 32,
    parameter integer kernel_size = 3
    )
    (
    input clk
    //output reg [clogb2(round_to_next_two(out_features)) - 1 : 0] w_addr
    );
    
`include "functions.vh"

    reg [clogb2(round_to_next_two(out_features)) - 1 : 0] w_addr = 0;
    wire [in_features*kernel_size**2 - 1 : 0] dwin;
    wire pixel;
    wire start;
    reg ready = 1'b0;
    reg waitsig = 1'b0;
    
    b_conv_ctrl 
    #(
    .kernel_size(kernel_size),
    .channels(in_features)) bcc
    (
    .clk(clk),
    .wide_fmap(0),
    .wide_weights(dwin),
    .pixel(pixel),
    .start(start),
    .ready(ready)
    );
    
    weights_rom 
    #(
    .kernel_size(kernel_size),
    .in_features(in_features),
    .out_features(out_features)) wr
    (
    .clk(clk),
    .addr(w_addr),
    .dout(dwin),
    .rd_enb(start)
    );
    
    always @(posedge clk) begin
        w_addr <= w_addr + 1;
        ready <= 1'b1;
//        if (start) begin
//            w_addr <= w_addr + 1;
//            ready <= 1'b1;
//        end
//        else begin
//            w_addr <= w_addr;
//            ready <= 1'b0;
//        end       
    end
    
endmodule
