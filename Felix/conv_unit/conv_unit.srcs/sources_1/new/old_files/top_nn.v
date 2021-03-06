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
    parameter integer input_channels = 1,
    parameter integer c1padding = 0,
    parameter integer c2padding = 0,
    parameter integer m1padding = 0,
    parameter integer c1stride = 1,
    parameter integer c2stride = 1,
    parameter integer m1stride = 1,
    parameter integer c1filter_size = 3,
    parameter integer c1filter_nb = 10,
    parameter integer c2filter_size = 5,
    parameter integer c2filter_nb = 10,
    parameter integer input_size = 3,
    parameter integer m1pool_size = 2,
    parameter integer c1dsp_alloc = 1,
    parameter integer c2dsp_alloc = 1
    )
    (
    input clk,
    //input start,
    //input [input_channels*8-1:0] din,
    //input [c1filter_size**2*c1filter_nb*input_channels*8-1 : 0] c1filters,
    //input [c2filter_size**2*c2filter_nb*c1filter_nb*8-1 : 0] c2filters,
    //input [c1filter_nb*8-1 : 0] c1biases,
    //input [c2filter_nb*8-1 : 0] c2biases,
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
    wire [c1filter_nb*8-1:0] c1dinb1;
    //wire [clogb2(round_to_next_two(c1input_width))-1 : 0] c1addrb1;
    //wire [clogb2(round_to_next_two(c1input_width))-1 : 0] c2addrb1;
    wire [9 : 0] c1addrb1;
    wire [9 : 0] c2addrb1;
    wire [9 : 0] c2addrb2;
    wire [9 : 0] c1addrb0;
    wire c2readyb1;
    wire [input_channels*8-1:0] b0doutc1;
    wire [c1filter_nb*8-1:0] b1doutc2;
    wire b1startc2;
    wire [clogb2(round_to_next_two(b1size))-1:0] c1rowb1;
    wire [c1filter_nb-1:0] c1wrenb1;
    
    `include "functions.vh"
    
    wire c1readyb0;
    wire b0startc1;
    
    bram_pad_interlayer #(
            .init_file("imagedata_7.txt"),
            .zero_padding(0),
            .layer_size(30),
            .channels(1),
            .data_depth(900)
            )
            bram0
            (
            .clk(clk),
            .done(1'b1),
            .ready(c1readyb0),
            .wr_addr(0),
            .rd_addr(c1addrb0),
            .din(0),
            .dout(b0doutc1),
            .start(b0startc1),
            .row(c1rowb1),
            .wren(c1wrenb1)
            );
    
    conv_layer_mc #(
        .stride(c1stride),
        .filter_size(c1filter_size),
        .filter_nb(c1filter_nb),
        .input_size(input_size),
        .channels(input_channels),
        .dsp_alloc(c1dsp_alloc),
        .weight_file("convtest_w0.txt"),
        .bias_file("convtest_b0.txt")
        )
        conv1
        (
        .clk(clk),
        .ack(c2ackc1),
        .start(b0startc1),
        .din(b0doutc1),
        .done(c1doneb1),
        .ready(c1readyb0),
        .load_done(lddone),
        .dout(c1dinb1),
        .out_addr(c1addrb1),
        .row(c1rowb1),
        .wren(c1wrenb1)
        );
        
    
        
    bram_pad_interlayer #(
        .zero_padding(c2padding),
        .layer_size(((input_size+2*c1padding-c1filter_size)/c1stride) + 1),
        .channels(c1filter_nb)
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
    wire [c2filter_nb*8-1:0] c2dinb2;
    wire m1ackc2;
    wire [clogb2(round_to_next_two(b2size))-1:0] c2rowb2;
    wire [c2filter_nb - 1:0] c2wrenb2;
    
    
        
    conv_layer_mc #(
        .zero_padding(0),
        .stride(c2stride),
        .filter_size(c2filter_size),
        .filter_nb(c2filter_nb),
        .input_size(c2size),
        .channels(c1filter_nb),
        .dsp_alloc(c2dsp_alloc)
        )
        conv2
        (
        .clk(clk),
        .ack(m1ackc2),
        .start(b1startc2),
        .din(b1doutc2),
        .filters(c2filters),
        .biases(c2biases),
        .done(c2doneb2),
        .ready(c2readyb1),
        .load_done(c2ackc1),
        .dout(c2dinb2),
        .addr(c2addrb1),
        .out_addr(c2addrb2),
        .row(c2rowb2),
        .wren(c2wrenb2)
        );
    
    wire m1readyb2;
    wire [9:0] m1addrb2;
    wire [c2filter_nb*8-1:0] b2doutm1;
    wire b2startm1;
    
    
        
    bram_pad_interlayer #(
        .zero_padding(0),
        .layer_size(b2size),
        .channels(c2filter_nb)
        )
        bram2
        (
        .clk(clk),
        .done(c2doneb2),
        .ready(m1readyb2),
        .wr_addr(c2addrb2),
        .rd_addr(m1addrb2),
        .din(c2dinb2),
        .dout(b2doutm1),
        .start(b2startm1),
        .row(c2rowb2),
        .wren(c2wrenb2)
        );
        
        localparam b3size = ((b2size - m1pool_size)/m1stride) + 1;
        
        wire m1doneb3;
        wire [c2filter_nb*8-1:0] m1dinb3;
        wire [clogb2(round_to_next_two(b3size))-1:0] m1rowb3;
        wire [c2filter_nb-1:0] m1wrenb3;
        wire [9:0] m1addrb3;
    
    maxpool_layer_mc #(
        .pool_size(m1pool_size),
        .input_size(b2size),
        .stride(m1stride),
        .channels(c2filter_nb)
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
        .wren(m1wrenb3),
        .row(m1rowb3)
        );
        
        wire [lcm(c2filter_nb, 3)*8-1 : 0] b3din;
        wire [lcm(c2filter_nb, 3)-1:0] b3wren;
        wire b3done;
        wire [clogb2(round_to_next_two(c2filter_nb*784/lcm(c2filter_nb, 3)))-1 : 0] b3addr;
        
       
     conv_to_fc_interlayer #(
        .channels(c2filter_nb),
        .fc_simd(3)
        )
        tofc1
        (
        .clk(clk),
        .done(m1doneb3),
        .in_addr(m1addrb3),
        .din(m1dinb3),
        .out_addr(b3addr),
        .wren_in(m1wrenb3),
        .wren_out(b3wren),
        .layer_done(b3done),
        .dout(b3din)
        );
        
     bram_pad_interlayer #(
       .zero_padding(0),
       .layer_size(0),
       .data_depth(c2filter_nb*784/lcm(c2filter_nb, 3)),
       .channels(lcm(c2filter_nb,3))
       )
       bram3
       (
       .clk(clk),
       .done(b3done),
       .ready(1'b1),
       .wr_addr(b3addr),
       .rd_addr(0),
       .din(b3din),
       .dout(dout),
       .start(start_end),
       .row(m1rowb3),
       .wren(b3wren)
       );
    
endmodule
