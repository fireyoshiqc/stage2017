`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2017 11:13:28 AM
// Design Name: 
// Module Name: mnist_test
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


module mnist_test(
    input wire enb,
    output reg [31:0] addr = 0,
    input wire [31:0] din,
    input wire clk,
    output reg done = 0,
    output reg [3:0] class = 0
    );

always @(posedge clk) begin
    if (enb) begin
        if (addr >= 783) begin
            done <= 1'b1;
        end
        else begin
            if (din > 127) begin
                if (class < 10) begin
                    class <= class + 1'b1;
                end
                else begin
                    class <= class;
                end
            end
            else begin
                if (class > 0) begin
                    class <= class - 1'b1;
                end
                else begin
                    class <= class;
                end
            end
            done <= 1'b0;
            addr <= addr + 1;
        end
    end
    else begin
        class <= 0;
        done <= 1'b0;
        addr <= 0;
    end
end

endmodule
