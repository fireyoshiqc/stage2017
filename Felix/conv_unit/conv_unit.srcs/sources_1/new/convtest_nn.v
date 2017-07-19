`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2017 02:50:44 PM
// Design Name: 
// Module Name: convtest_nn
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

// NEURAL NET ARCHITECTURE :
// LAYER 1 : INPUT MEMORY (ROM). SIZE 900, 1 CHANNEL. 1 PADDING (IMPLICIT)
// LAYER 2 : CONV LAYER. SIZE 30X30, 1 CHANNEL IN, 10 CHANNELS OUT. KERNEL 3X3 (STRIDE 1).
// LAYER 3 : BRAM INTERLAYER. SIZE 784, 10 CHANNELS. 0 PADDING.
// LAYER 4 : MAXPOOL LAYER. SIZE 28X28, 10 CHANNELS. MAX 2X2 (STRIDE 2). OUT 14X14.
// LAYER 5 : BRAM INTERLAYER. SIZE 324, 10 CHANNELS. 2 PADDING.
// LAYER 6 : CONV LAYER. SIZE 18X18, 10 CHANNELS IN, 10 CHANNELS OUT. KERNEL 5X5 (STRIDE 1).
// LAYER 7 : BRAM INTERLAYER, SIZE 196, 10 CHANNELS. 0 PADDING.
// LAYER 8 : MAXPOOL LAYER. SIZE 14X14, 10 CHANNELS. MAX 2X2 (STRIDE 2). OUT 7X7.
// LAYER 8.5 : CONV-TO-FC LAYER (TO ADD WHEN FULLY IMPLEMENTED).
// LAYER 9 : BRAM INTERLAYER. SIZE 49, 10 CHANNELS. 0 PADDING.
// LAYER 10 : FC LAYER. SIZE 490.
// LAYER 11 : FC LAYER. SIZE 10.


module convtest_nn(
    input wire clk, start,
    output wire lddone,
    
    output wire ostart,
    output wire [5:0] rgb
    );
    
`include "functions.vh"

wire [8*10-1:0] dout;

wire u2readyu1;
wire [clogb2(round_to_next_two(900))-1:0] u2addru1;
wire [7:0] u1datau2;
wire u1startu2;
    
bram_pad_interlayer #(
    .init_file("imagedata_7.txt"),
    .channels(1),
    .zero_padding(1),
    .layer_size(28)) 
u1 (
    .clk(clk),
    .done(start),
    .ready(u2readyu1),
    .wr_addr(0),
    .rd_addr(u2addru1),
    .din(0),
    .row(0),
    .wren(0),
    .dout(u1datau2),
    .start(u1startu2)
);

wire u4acku2;
wire u2doneu3;
wire [8*10-1:0] u2datau3;
wire [clogb2(round_to_next_two(784))-1:0] u2addru3;
wire [clogb2(round_to_next_two(28))-1:0] u2rowu3;
wire [9:0] u2wrenu3;

conv_layer_mc #(
    .weight_file("convtest_w0.txt"),
    .bias_file("convtest_b0.txt"),
    .stride(1),
    .filter_size(3),
    .filter_nb(10),
    .channels(1),
    .dsp_alloc(1),
    .input_size(30)
)
u2 (
    .clk(clk),
    .ack(u4acku2),
    .start(u1startu2),
    .din(u1datau2),
    .done(u2doneu3),
    .ready(u2readyu1),
    .load_done(lddone),
    .dout(u2datau3),
    .addr(u2addru1),
    .out_addr(u2addru3),
    .row(u2rowu3),
    .wren(u2wrenu3)
);

wire u4readyu3;
wire [clogb2(round_to_next_two(784))-1:0] u4addru3;
wire [8*10 - 1:0] u3datau4;
wire u3startu4;
    
bram_pad_interlayer #(
    .channels(10),
    .zero_padding(0),
    .layer_size(28)) 
u3 (
    .clk(clk),
    .done(u2doneu3),
    .ready(u4readyu3),
    .wr_addr(u2addru3),
    .rd_addr(u4addru3),
    .din(u2datau3),
    .row(u2rowu3),
    .wren(u2wrenu3),
    .dout(u3datau4),
    .start(u3startu4)
);

wire u6acku4;
wire u4doneu5;
wire [8*10-1:0] u4datau5;
wire [clogb2(round_to_next_two(196))-1:0] u4addru5;
wire [clogb2(round_to_next_two(14))-1:0] u4rowu5;
wire [9:0] u4wrenu5;

maxpool_layer_mc #(
    .pool_size(2),
    .input_size(28),
    .stride(2),
    .channels(10)
)
u4 (
    .clk(clk),
    .ack(u6acku4),
    .start(u3startu4),
    .din(u3datau4),
    .dout(u4datau5),
    .done(u4doneu5),
    .ready(u4readyu3),
    .load_done(u4acku2),
    .addr(u4addru3),
    .out_addr(u4addru5),
    .wren(u4wrenu5),
    .row(u4rowu5)
);

wire u6readyu5;
wire [clogb2(round_to_next_two(324))-1:0] u6addru5;
wire [8*10 - 1:0] u5datau6;
wire u5startu6;
    
bram_pad_interlayer #(
    .channels(10),
    .zero_padding(2),
    .layer_size(14)) 
u5 (
    .clk(clk),
    .done(u4doneu5),
    .ready(u6readyu5),
    .wr_addr(u4addru5),
    .rd_addr(u6addru5),
    .din(u4datau5),
    .row(u4rowu5),
    .wren(u4wrenu5),
    .dout(u5datau6),
    .start(u5startu6)
);

wire u8acku6;
wire u6doneu7;
wire [8*10-1:0] u6datau7;
wire [clogb2(round_to_next_two(196))-1:0] u6addru7;
wire [clogb2(round_to_next_two(14))-1:0] u6rowu7;
wire [9:0] u6wrenu7;

conv_layer_mc #(
    .weight_file("convtest_w1.txt"),
    .bias_file("convtest_b1.txt"),
    .stride(1),
    .filter_size(5),
    .filter_nb(10),
    .channels(10),
    .dsp_alloc(10),
    .input_size(18)
)
u6 (
    .clk(clk),
    .ack(u8acku6),
    .start(u5startu6),
    .din(u5datau6),
    .done(u6doneu7),
    .ready(u6readyu5),
    .load_done(u6acku4),
    .dout(u6datau7),
    .addr(u6addru5),
    .out_addr(u6addru7),
    .row(u6rowu7),
    .wren(u6wrenu7)
);

wire u8readyu7;
wire [clogb2(round_to_next_two(196))-1:0] u8addru7;
wire [8*10 - 1:0] u7datau8;
wire u7startu8;
    
bram_pad_interlayer #(
    .channels(10),
    .zero_padding(0),
    .layer_size(14)) 
u7 (
    .clk(clk),
    .done(u6doneu7),
    .ready(u8readyu7),
    .wr_addr(u6addru7),
    .rd_addr(u8addru7),
    .din(u6datau7),
    .row(u6rowu7),
    .wren(u6wrenu7),
    .dout(u7datau8),
    .start(u7startu8)
);

//wire u10acku8;
wire u8doneu9;
wire [8*10-1:0] u8datau9;
wire [clogb2(round_to_next_two(49))-1:0] u8addru9;
wire [clogb2(round_to_next_two(7))-1:0] u8rowu9;
wire [9:0] u8wrenu9;

maxpool_layer_mc #(
    .pool_size(2),
    .input_size(14),
    .stride(2),
    .channels(10)
)
u8 (
    .clk(clk),
    .ack(1'b1),
    .start(u7startu8),
    .din(u7datau8),
    .dout(u8datau9),
    .done(u8doneu9),
    .ready(u8readyu7),
    .load_done(u8acku6),
    .addr(u8addru7),
    .out_addr(u8addru9),
    .wren(u8wrenu9),
    .row(u8rowu9)
);

//wire u10readyu9;
//wire [clogb2(round_to_next_two(49))-1:0] u10addru9;
//wire [8*10 - 1:0] u9datau10;
//wire u9startu10;
    
bram_pad_interlayer #(
    .channels(10),
    .zero_padding(0),
    .layer_size(7)) 
u9 (
    .clk(clk),
    .done(u8doneu9),
    .ready(1'b1),
    .wr_addr(u8addru9),
    .rd_addr(0),
    .din(u8datau9),
    .row(u8rowu9),
    .wren(u8wrenu9),
    .dout(dout),
    .start(ostart)
);

assign rgb = u8datau9[5:0];

endmodule
