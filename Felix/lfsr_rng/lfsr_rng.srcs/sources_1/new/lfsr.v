`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Laboratoire LIV4D - École Polytechnique de Montréal
// Engineer: Félix Boulet
// 
// Create Date: 05/24/2017 01:45:03 PM
// Design Name: Linear-Feedback Shift Register Random Number Generator (LFSR RNG)
// Module Name: lfsr
// Project Name: lfsr_rng
// Target Devices: Zynq-7000 (xc7z020clg400-1)
// Tool Versions: Vivado 2017.1
// Description: 
// This design generates a random bit (0 or 1) using a 32-bit LFSR (Linear-Feedback
// Shift Register). It uses the 32nd degree polynomial x^32 + x^22 + x^2 + 1
// to achieve this using simple XOR operations.
//
// Dependencies: 
// To achieve target frequency (300 MHz) of the top module with a reduced PL area on the Zynq-7000,
// it must be synthesized using the Flow_AreaMultThresholdDSP strategy from Vivado
// 2017.1, then implemented using the Area_ExploreWithRemap strategy from Vivado
// 2017.1 also.
// 
// Revision:
// Revision 1.0 - Design completed
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lfsr #(
    parameter SEED = 1 // The seed serves to initialize the 32-bit register.
    // It must ABSOLUTELY be different from 0, otherwise the design will NOT
    // produce random bits (the register will always contain a value = 0).
    )
    (
    input wire clk,
    input wire rst,
    input wire enb,
    output reg rand = 1'b0
    );

reg [31:0] lfsr1 = SEED; // The seed is loaded into the register at initialization
wire [31:0] x1;

// This wire describes the XOR operation on bits 22 and 2 (polynomial : 32, 22, 2, 1)
assign x1 = lfsr1 ^ {{10{1'b0}}, lfsr1[0], {19{1'b0}}, lfsr1[0], 1'b0};
    
always @(posedge clk) begin
    if (rst) begin
        lfsr1 <= SEED;
        rand <= 1'b0;
    end
    else begin
        if (enb) begin
            lfsr1 <= {x1[0], x1[31:1]};
            rand <= x1[0];
        end
        else begin
            lfsr1 <= lfsr1;
            rand <= rand;
        end
    end
end
    
endmodule
