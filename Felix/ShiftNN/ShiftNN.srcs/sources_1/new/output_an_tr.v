`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2017 11:40:08 AM
// Design Name: 
// Module Name: hidden_an
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


module output_an_tr
    (
    input clk, rst, enb,
    input signed [7:0] din,
    input signed [7:0] weight, // WEIGHTS HAVE 1 SIGN BIT AND 7 FRAC BITS
    input signed [7:0] bias, // BIAS HAS 1 SIGN BIT AND 7 FRAC BITS
    output reg signed [31:0] acc = 0
    );
    
    always @(posedge clk) begin
        if (rst) begin // LOAD BIAS ON RESET (DATA CHANGE)
            acc <= bias;
        end
        else if (enb) begin
            if (din) begin
                acc <= acc + din*weight;
            end
            else begin // SAVE POWER AND DO NOT SHIFT IF THE INPUT IS ZERO
                acc <= acc;
            end
        end   
        else begin
            acc <= acc;
        end
        
    end
endmodule
