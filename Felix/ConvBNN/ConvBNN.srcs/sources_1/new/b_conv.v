`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/30/2017 03:56:31 PM
// Design Name: 
// Module Name: b_conv
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


module b_conv
    #(
    parameter integer kernel_size = 3
    )
    (
    input clk, start,
    input [kernel_size**2 - 1 : 0] fmap,
    input [kernel_size**2 - 1 : 0] weights,
    output reg [7:0] popcnt = 0
    );
    
    integer i;
    reg [kernel_size**2 - 1 : 0] xnored;
    
    always @(posedge clk) begin
        if (~start) begin
            xnored = 0;
            popcnt = 0;
        end
        xnored = weights ^~ fmap;
        
        for (i=0; i<kernel_size**2; i = i + 1) begin
            popcnt = popcnt + xnored[i];
        end
    end
    
endmodule
