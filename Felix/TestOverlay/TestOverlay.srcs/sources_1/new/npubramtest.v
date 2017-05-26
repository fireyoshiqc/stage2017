`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/17/2017 12:55:29 PM
// Design Name: 
// Module Name: npubramtest
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


module npubramtest(
    addr,
    clk,
    din,
    dout,
    rden,
    rst
    );
    output [31:0] addr;
    input [31:0] din;
    output [31:0] dout;
    input clk;
    input rst;
    output rden;
    
    reg [31:0] addr = 0;
    reg rden = 0;
    reg [1:0] rdcnt = 2'b01;
    reg [31:0] cc1 = 0;
    reg [31:0] cc2 = 0;
    reg [31:0] cc3 = 0;
    reg [31:0] dout = 0;
    
    always @ (posedge clk) begin
    if (rst == 1) begin
        if (rden == 1) begin
            case (rdcnt)
                2'b00 : rden <= 1'b0;
                2'b01 : cc1 <= din;
                2'b10 : cc2 <= din;
                2'b11 : begin
                cc3 <= din;
                rdcnt <= 2'b00;
                end
                default :;
            endcase
        end
        else begin   
            case (rdcnt)
                2'b00 : rden <= 1'b1;
                2'b01 : dout <= cc1+1;
                2'b10 : dout <= cc2+1;
                2'b11 : begin
                dout <= cc3+1;
                rdcnt <= 2'b00;
                end
                default :;
            endcase
        end
        
        rdcnt <= rdcnt + 1;
        addr <= addr + 4;
        
        if (addr >= 8192)
            addr <= 0;
        
    end
    else begin
    cc1 <= 0;
    cc2 <= 0;
    cc3 <= 0;
    addr <= 0;
    rden <= 0;
    rdcnt <= 2'b00;
    dout <= 0;
    end
    end
endmodule
