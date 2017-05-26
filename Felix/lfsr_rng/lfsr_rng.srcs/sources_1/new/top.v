`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Laboratoire LIV4D - École Polytechnique de Montréal
// Engineer: Félix Boulet
// 
// Create Date: 05/24/2017 02:56:30 PM
// Design Name: 8-bit max-capped LFSR Random Number Generator
// Module Name: top
// Project Name: lfsr_rng
// Target Devices: Zynq-7000 (xc7z020clg400-1)
// Tool Versions: Vivado 2017.1
//
// Description:
// This design generates 8-bit random integers using 8 32-bit LFSR (Linear-Feedback
// Shift Register) units. It takes a maximum value in input so that it generates
// random integers in the range defined by ]0, MAX].
//
// Dependencies: 
// This design requires the lfsr module from the lfsr.v file in order to function.
//
// To achieve target frequency (300 MHz) with a reduced PL area on the Zynq-7000,
// it must be synthesized using the Flow_AreaMultThresholdDSP strategy from Vivado
// 2017.1, then implemented using the Area_ExploreWithRemap strategy from Vivado
// 2017.1 also. This will infer a DSP48E1 unit in the block design, which then needs
// to be parametrized to use PREG = 1.
// (it should be in the constraint file written as *** set_property PREG 1 [get_cells mul_reg] *** )
// If not, then the design will fail to meet timing specifications; the parameter must
// be changed through the design schematic (there's a single DSP48E1 block) and the
// implementation re-launched.
// 
// Revision:
// Revision 1.0 - Design completed
// Additional Comments:
//
// Board implementation :
// This design can be written as a bitstream on the Pynq-Z1 by using the included but
// disabled pynq_wrapper.v design file. This file enables the maximum input as a toggling
// of buttons (up to 4 bits), and the display of the random number that's generated on
// the RGB LEDs, creating up to 8 different colors on LD4 and putting LD5 on or off.
// The standard LEDs (LD0 to LD3) will display the current maximum.
// The enable signal is mapped to SW0, and the reset signal to SW1.
// The top module is also mapped to the PYNQ IO, but it's arbitrary (by default, it
// uses the LEDs as output and PMOD Header JA as input (maximum), and the switches
// for the same function as the pynq_wrapper module).
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input wire clk,
    input wire rst,
    input wire enb,
    input wire [7:0] max,
    output reg [7:0] out = 8'h00
    );
    
    wire [7:0] rand; // The output from the 8 LFSR units
    reg [7:0] randreg = 8'h00; // A register to pipeline that output
    reg [7:0] maxreg = 8'h00; // A register to pipeline the max input
    reg [31:0] mul = 0; // A register to enable pipelining the multiplication operation on the DSP48E1
    
// Seeds should be randomized externally if the bitstream is written multiple times,
// in order to prevent having predictable output.
    
    lfsr #(.SEED(32'h12345678)) l0 (.clk(clk), .rst(rst), .enb(enb), .rand(rand[0]));
    lfsr #(.SEED(32'h90ABCDEF)) l1 (.clk(clk), .rst(rst), .enb(enb), .rand(rand[1]));
    lfsr #(.SEED(32'hDEADBEEF)) l2 (.clk(clk), .rst(rst), .enb(enb), .rand(rand[2]));
    lfsr #(.SEED(32'hC0DEFACE)) l3 (.clk(clk), .rst(rst), .enb(enb), .rand(rand[3]));
    lfsr #(.SEED(32'h1EE7B055)) l4 (.clk(clk), .rst(rst), .enb(enb), .rand(rand[4]));
    lfsr #(.SEED(32'hAAC0FFEE)) l5 (.clk(clk), .rst(rst), .enb(enb), .rand(rand[5]));
    lfsr #(.SEED(32'h5E1F1E55)) l6 (.clk(clk), .rst(rst), .enb(enb), .rand(rand[6]));
    lfsr #(.SEED(32'hE5CA1ADE)) l7 (.clk(clk), .rst(rst), .enb(enb), .rand(rand[7]));

// Principle of using the max input :
// Transform rand to a fixed point number of the form {0.rand} and multiply it by the max
// ex. 0x00.89 * 0xAA.00 = 0x005A.FA00
// Only keep the [23:16] integer part (here, 0x5A)
// Then, add 1 so it's [1, max] (0x5A + 1 = 0x5B)
// The result is the generated random number normalized to the [1, max] range.

always @(posedge clk) begin
    // If reset is active, bring the outputs to their default state to ensure there is no
    // misinterpretation (0 is a "dead" value for the generator).
    if (rst) begin
        maxreg <= 8'h00;
        randreg <= 8'h00;
        mul <= 0;
        out <= 8'h00;
    end
    else begin
        // Maximize DSP performance by pipelining inputs/outputs.
        // This introduces a bit of latency (3 clock cycles) but it's not a concern here.
        maxreg <= max;
        randreg <= rand;
        
        // Perform the fixed point multiplication of the form 00.xx * xx.00.
        mul <= ({maxreg, 8'h00} * ({8'h00, randreg}));
        // Pick the [23:16] bits (8-bit integer part) and add one to achieve [1, max] range.
        out <= mul[23:16] + 1;
    end
end

endmodule
