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
    input c1start,
    input [7:0] c1din,
    input [c1filter_size**2*c1filter_nb*8-1 : 0] c1filters,
    input [c2filter_size**2*c2filter_nb*8-1 : 0] c2filters,
    input [c1filter_nb*8-1 : 0] c1biases,
    input [c2filter_nb*8-1 : 0] c2biases,
    output c1ready,
    output c1lddone,
    output c2done,
    output [7:0] c2dout
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
        .start(c1start),
        .din(c1din),
        .filters(c1filters),
        .biases(c1biases),
        .done_w(c1doneb1),
        .ready_w(c1ready),
        .load_done_w(c1lddone),
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
        .ack(1'b1),
        .start(b1startc2),
        .din(b1doutc2),
        .filters(c2filters),
        .biases(c2biases),
        .done_w(c2done),
        .ready_w(c2readyb1),
        .load_done_w(c2ackc1),
        .dout_w(c2dout),
        .addr_w(c2addrb1)
        );
    
endmodule
