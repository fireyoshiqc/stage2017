`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2017 01:13:54 PM
// Design Name: 
// Module Name: top_nn_tb
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


module top_nn_tb(

    );
    
    reg clk = 1'b1;
    reg [8-1:0] din = 0;
    wire ready, lddone, done;
    wire [7:0] dout;
    wire [9:0] out_addr;
    wire start_end;
    
    top_nn #(
        .input_channels(1),//3
        .input_size(4),
        .c1padding(0),
        .c2padding(1),
        .c1stride(1),
        .c2stride(1),
        .m1stride(1),
        .c1filter_size(2),
        .c1filter_nb(1),
        .c2filter_size(2),
        .c2filter_nb(1),
        .m1pool_size(2),
        .c1dsp_alloc(1),
        .c2dsp_alloc(1)
        )
        uut 
        (
        .clk(clk),
        .start(1'b1),
        .din(din),
        .c1filters({2*2{8'hFF}}),
        .c2filters({2*2{8'hFF}}),
        .c1biases({1{8'hFF}}),
        .c2biases({1{8'hFF}}),
        .ready(ready),
        .lddone(lddone),
        .done(done),
        .dout(dout),
        .out_addr(out_addr),
        .start_end(start_end)
        );
        
        always begin
            #10 clk = ~clk;
            din = 8'hFF;
        end
endmodule
