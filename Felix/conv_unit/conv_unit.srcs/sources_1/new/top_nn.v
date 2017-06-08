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
    parameter integer c1padding = 0,
    parameter integer c2padding = 0,
    parameter integer m1padding = 0,
    parameter integer c1stride = 1,
    parameter integer c2stride = 1,
    parameter integer m1stride = 1,
    parameter integer c1filter_size = 2,
    parameter integer c1filter_nb = 1,
    parameter integer c2filter_size = 2,
    parameter integer c2filter_nb = 1,
    parameter integer input_size = 3,
    parameter integer m1pool_size = 2
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
    output start_end,
    output [7:0] dout,
    output [clogb2(round_to_next_two(784))-1 : 0] out_addr
    );
    
    localparam integer b1size = ((input_size+2*c1padding-c1filter_size)/c1stride) + 1;
    
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
    wire [clogb2(round_to_next_two(b1size))-1:0] c1rowb1;
    wire c1wrenb1;
    
    `include "functions.vh"
    
    conv_layer #(
        .zero_padding(c1padding),
        .stride(c1stride),
        .filter_size(c1filter_size),
        .filter_nb(c1filter_nb),
        .input_size(input_size)
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
        .addr_w(c1addrb1),
        .row(c1rowb1),
        .wren(c1wrenb1)
        );
        
    
        
    bram_pad_interlayer #(
        .zero_padding(c2padding),
        .layer_size(((input_size+2*c1padding-c2filter_size)/c2stride) + 1)
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
        .start(b1startc2),
        .row(c1rowb1),
        .wren(c1wrenb1)
        );
        
        localparam integer c2size = b1size + 2*c2padding;
        localparam integer b2size = ((c2size+2*0-c2filter_size)/c2stride) + 1;
    
    wire c2doneb2;
    wire [7:0] c2dinb2;
    wire m1ackc2;
    wire [clogb2(round_to_next_two(b2size))-1-1:0] c2rowb2;
    wire c2wrenb2;
    
    
        
    conv_layer #(
        .zero_padding(0),
        .stride(c2stride),
        .filter_size(c2filter_size),
        .filter_nb(c2filter_nb),
        .input_size(c2size)
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
        .addr_w(c2addrb1),
        .row(c2rowb2),
        .wren(c2wrenb2)
        );
    
    wire m1readyb2;
    wire [9:0] m1addrb2;
    wire [7:0] b2doutm1;
    wire b2startm1;
    
    
        
    bram_pad_interlayer #(
        .zero_padding(0),
        .layer_size(b2size)
        
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
        .start(b2startm1),
        .row(c2rowb2),
        .wren(c2wrenb2)
        );
        
        localparam b3size = ((b2size - m1pool_size)/m1stride) + 1;
        
        wire m1doneb3;
        wire [7:0] m1dinb3;
        wire [clogb2(round_to_next_two(b3size))-1-1:0] m1rowb3;
        wire m1wrenb3;
        wire [9:0] m1addrb3;
    
    maxpool_layer_mc #(
        .pool_size(2),
        .input_size(b2size),
        .stride(1),
        .channels(1)
        )
        max1
        (
        .clk(clk),
        .ack(1'b1),
        .start(b2startm1),
        .din(b2doutm1),
        .dout(m1dinb3),
        .ready(m1readyb2),
        .done(m1doneb3),
        .load_done(m1ackc2),
        .addr(m1addrb2),
        .out_addr(m1addrb3),
        .wren(m1wrenb3)
        );
       
     
        
     bram_pad_interlayer #(
       .zero_padding(0),
       .layer_size(b3size),
       .pool_size(m1pool_size)
       
       )
       bram3
       (
       .clk(clk),
       .done(m1doneb3),
       .ready(1'b1),
       .wr_addr(m1addrb3),
       .rd_addr(0),
       .din(m1dinb3),
       .dout(dout),
       .start(start_end),
       .row(0),
       .wren(m1wrenb3)
       );
    
endmodule
