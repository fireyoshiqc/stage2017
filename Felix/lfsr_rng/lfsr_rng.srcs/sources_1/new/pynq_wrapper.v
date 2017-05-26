`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2017 04:47:27 PM
// Design Name: 
// Module Name: pynq_wrapper
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


module pynq_wrapper(
    input wire clk,
    input wire rst,
    input wire enb,
    input wire [3:0] btns,
    output reg [3:0] leds = 4'b0000,
    output reg [5:0] rgb = 6'b000000
    );
    
    reg [3:0] bounce = 4'b0000;
    reg [7:0] max = 8'b00000000;
    wire [7:0] out;
    

    top top_inst (.clk(clk), .rst(rst), .enb(enb), .max(max), .out(out));
    
    always @(posedge clk) begin
        if (rst) begin
            leds <= 4'b0000;
            bounce <= 4'b0000;
            rgb <= rgb;
        end
        else begin
            max <= {4'b0000, leds};
            rgb <= out[5:0];
            if (bounce == btns || ~enb) begin
                leds <= leds;
                bounce <= bounce;
            end
            else begin
                leds <= leds ^ btns;
                bounce <= btns;
                
            end
        end
    end

endmodule
