`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2017 03:00:41 PM
// Design Name: 
// Module Name: mac_test
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


module mac_test(
    din,
    dout
    );
input [31:0] din;
output [31:0] dout;

assign dout = (din[31:24] * din[23:16]) + (din[15:8] * din[7:0]);

endmodule
