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
    reg [7:0] din = 0;
    wire ready, lddone, done;
    wire [7:0] dout;
    wire [9:0] out_addr;
    
    top_nn uut (
        .clk(clk),
        .start(1'b1),
        .din(din),
        .c1filters(32'hFFFFFFFF),
        .c2filters(32'hFFFFFFFF),
        .c1biases(8'hFF),
        .c2biases(8'hFF),
        .ready(ready),
        .lddone(lddone),
        .done(done),
        .dout(dout),
        .out_addr(out_addr)
        );
        
        always begin
            #10 clk = ~clk;
            din = din + 1;
        end
endmodule
