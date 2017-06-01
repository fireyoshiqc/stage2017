`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/31/2017 03:21:56 PM
// Design Name: 
// Module Name: top_nn
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


module top_nn #(
    parameter integer c1padding = 1,
    parameter integer c2padding = 1,
    parameter integer c1stride = 1,
    parameter integer c2stride = 2,
    parameter integer c1filter_size = 2,
    parameter integer c1filter_nb = 1,
    parameter integer c2filter_size = 2,
    parameter integer c2filter_nb = 1,
    parameter integer c1input_width = 9,
    parameter integer c2input_width = 16
    )
    (
    input clk,
    input start,
    input [7:0] din,
    input [c1filter_size**2*c1filter_nb*8-1 : 0] c1filters,
    input [c2filter_size**2*c2filter_nb*8-1 : 0] c2filters,
    input [c1filter_nb*8-1 : 0] c1biases,
    input [c2filter_nb*8-1 : 0] c2biases,
    output ready,
    output lddone,
    output done,
    output [7:0] dout
    );
    
    wire c2ackc1;
    wire c1doneb1;
    wire [7:0] c1dinb1;
    //wire [clogb2(round_to_next_two(c1input_width))-1 : 0] c1addrb1;
    //wire [clogb2(round_to_next_two(c1input_width))-1 : 0] c2addrb1;
    wire [9 : 0] c1addrb1;
    wire [9 : 0] c2addrb1;
    wire c2readyb1;
    wire [7:0] b1doutc2;
    wire b1startc2;
    
    `include "functions.vh"
    
    conv_layer #(
        .zero_padding(c1padding),
        .stride(c1stride),
        .filter_size(c1filter_size),
        .filter_nb(c1filter_nb),
        .input_width(c1input_width),
        .root(3)
        )
        conv1
        (
        .clk(clk),
        .ack(c2ackc1),
        .start(start),
        .din(din),
        .filters(c1filters),
        .biases(c1biases),
        .done_w(c1doneb1),
        .ready_w(ready),
        .load_done_w(lddone),
        .dout_w(c1dinb1),
        .addr_w(c1addrb1)
        );
        
    bram_interlayer #(
        
        )
        bram1
        (
        .clk(clk),
        .done(c1doneb1),
        .ready(c2readyb1),
        .wr_addr(c1addrb1),
        .rd_addr(c2addrb1),
        .din(c1dinb1),
        .dout(b1doutc2),
        .start(b1startc2)
        );
    
    wire c2doneb2;
    wire [7:0] c2dinb2;
    wire m1ackc2;
        
    conv_layer #(
        .zero_padding(c2padding),
        .stride(c2stride),
        .filter_size(c2filter_size),
        .filter_nb(c2filter_nb),
        .input_width(c2input_width),
        .root(4)
        )
        conv2
        (
        .clk(clk),
        .ack(m1ackc2),
        .start(b1startc2),
        .din(b1doutc2),
        .filters(c2filters),
        .biases(c2biases),
        .done_w(c2doneb2),
        .ready_w(c2readyb1),
        .load_done_w(c2ackc1),
        .dout_w(c2dinb2),
        .addr_w(c2addrb1)
        );
    
    wire m1readyb2;
    wire [9:0] m1addrb2;
    wire [7:0] b2doutm1;
    wire b2startm1;
        
    bram_interlayer #(
        
        )
        bram2
        (
        .clk(clk),
        .done(c2doneb2),
        .ready(m1readyb2),
        .wr_addr(c2addrb1),
        .rd_addr(m1addrb2),
        .din(c2dinb2),
        .dout(b2doutm1),
        .start(b2startm1)
        );
        
    maxpool_layer #(
        .pool_size(2),
        .input_width(9),
        .root(3),
        .stride(1)
        )
        max1
        (
        .clk(clk),
        .ack(1'b1),
        .start(b2startm1),
        .din(b2doutm1),
        .dout(dout),
        .ready(m1readyb2),
        .done(done),
        .load_done(m1ackc2),
        .addr(m1addrb2)
        );
    
endmodule
