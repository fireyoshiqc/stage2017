`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2017 02:41:30 PM
// Design Name: 
// Module Name: output_an
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


module output_an
    (
    input clk, rst, enb,
    input [2:0] activation,
    input signed [7:0] weight,
    output reg signed [15:0] acc = 0
    );
    
    always @(posedge clk) begin
        if (rst) begin
            acc <= 0;
        end
        else if (enb) begin
            if (activation == 3'b111) begin
                acc <= acc;
            end
            else if (activation[2]) begin
                acc <= acc - (weight >>> activation[1:0]);
            end
            else begin
                acc <= acc + (weight >>> activation[1:0]);
            end
        end
        else begin
            acc <= acc;
        end
    end
    
endmodule
