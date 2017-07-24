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


module hidden_an
    (
    input clk, rst, enb,
    input [2:0] din,
    input signed [7:0] weight, // WEIGHTS HAVE 1 SIGN BIT AND 7 FRAC BITS
    //input [31:0] nb_inputs,
    output reg [2:0] activation = 0
    );
    
    reg signed [15:0] acc = 0;
    reg signed [15:0] act;
    
    always @(posedge clk) begin
        if (rst) begin
            acc <= 0;
        end
        else if (enb) begin
            if (din) begin
                acc <= acc + ((weight << din) >>> 1);
            end
            else begin // SAVE POWER AND DO NOT SHIFT IF THE INPUT IS ZERO
                acc <= acc;
            end
        end   
        else begin
            acc <= acc;
        end
    end
    
    always @(acc) begin
          
          if (acc[15] == 1'b1) begin
            activation[2] = 1'b1;
            act = -acc;
          end
          else begin
            activation[2] = 1'b0;
            act = acc;
          end
          if (act < 66) begin
            activation = 3'b111;
          end
          else if (act < 141) begin
            activation[1:0] = 2'b01;
          end
          else if (act < 250) begin
            activation[1:0] = 2'b10;
          end
          else begin
            activation[1:0] = 2'b00;
          end
          
    end
endmodule
