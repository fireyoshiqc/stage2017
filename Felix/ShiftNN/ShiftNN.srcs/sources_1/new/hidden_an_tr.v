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


module hidden_an_tr
    (
    input clk, rst, enb,
    input signed [7:0] din,
    input signed [7:0] weight, // WEIGHTS HAVE 1 SIGN BIT AND 7 FRAC BITS
    input signed [7:0] bias, // BIAS HAS 1 SIGN BIT AND 7 FRAC BITS
    output reg signed [7:0] out_reg
    );
    
    reg signed [31:0] acc = 0;
    
    //reg signed [15:0] acc = 0;
    //reg signed [15:0] act;
    wire op_send_w;
    reg op_receive = 0;
    
    wire [7:0] sig_out;
    
    sigmoid_wrapper #(16, 16, 1, 7, 2, 16) sw (.clk(clk), .input_w(acc), .output_w(sig_out), .op_send(op_send_w), .op_receive(op_receive));
    
    always @(posedge clk) begin
        if (rst) begin // LOAD BIAS ON RESET (DATA CHANGE)
            acc <= bias;
            op_receive <= 1'b0;
        end
        else if (enb) begin
            if (din) begin
                acc <= acc + din*weight;
                op_receive <= 1'b0;
            end
            else begin // SAVE POWER AND DO NOT SHIFT IF THE INPUT IS ZERO
                acc <= acc;
            end
        end   
        else begin
            acc <= acc;
            op_receive <= 1'b1;
        end
        
        if (op_send_w) begin
            out_reg <= sig_out;
        end
    end
endmodule
