`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2017 11:10:09 AM
// Design Name: 
// Module Name: bram_ack
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


module bram_ack(
    addr,
    clk,
    din,
    dout,
    rden
    );
    
output [31:0] addr;
input clk;
input [31:0] din;
output [31:0] dout;
output rden;

reg [31:0] addr = 0;
reg rden = 1'b1;
reg [31:0] dout = 0;
reg ack = 1'b0;
reg [31:0] data = 0;

always @ (posedge clk) begin

    if (rden == 1'b1) begin
        addr <= 0;
        data <= din;
        rden <= 1'b0;
    end
    else begin
        if (ack == 1'b0) begin
            addr <= 4;
            dout <= data * 2;
            ack <= 1'b1;
        end
        else begin
            addr <= 8;
            dout <= 1;
            ack <= 1'b0;
            rden <= 1'b1;
        end
    end 
end

endmodule
