`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2017 10:00:47 AM
// Design Name: 
// Module Name: b_conv_ctrl
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



module b_conv_ctrl
    #(
    parameter integer kernel_size = 3,
    parameter integer channels = 3,
    parameter integer parallelism = channels
    )
    (
    input clk, ready,
    input [channels*kernel_size**2 - 1 : 0] wide_fmap,
    input [channels*kernel_size**2 - 1 : 0] wide_weights,
    output reg pixel = 1'b0,
    output reg start = 1'b1
    );
    
    `include "functions.vh"
    genvar i;
    
    reg [parallelism*kernel_size**2 - 1 : 0] fmap_window = {parallelism*kernel_size**2{1'b1}};
    reg [parallelism*kernel_size**2 - 1 : 0] weights_window = 0;
    wire [parallelism*8 - 1 : 0] adder_bus;
    reg [clogb2(round_to_next_two(parallelism))*8 - 1 : 0] rescnt = 0;
   
    
    generate
        for (i=0; i<parallelism; i = i + 1) begin
            b_conv #(
            .kernel_size(kernel_size)
            ) U 
            (
            .clk(clk), .start(start),
            .fmap(fmap_window[i*kernel_size**2 +: kernel_size**2]),
            .weights(weights_window[i*kernel_size**2 +: kernel_size**2]),
            .popcnt(adder_bus[i*8 +: 8])
            );
        end
    endgenerate
    
    reg [clogb2(round_to_next_two(channels/parallelism)) : 0] window_offset = 0;
    integer j, cur_channel = 0;
    always @(posedge clk) begin
//        if (ready & ~start) begin
//            cur_channel <= 0;
//            start <= 1'b1;
//            rescnt <= 0;
//        end
        if (ready) begin
            if (cur_channel < channels) begin
                start <= 1'b1;
                fmap_window <= wide_fmap[cur_channel*parallelism*kernel_size**2 +: parallelism*kernel_size**2];
                weights_window <= wide_weights[cur_channel*parallelism*kernel_size**2 +: parallelism*kernel_size**2];
                for (j=0; j<parallelism; j = j + 1) begin
                    rescnt = rescnt + adder_bus[j*8 +: 8];
                end
                cur_channel = cur_channel + parallelism;
                if (cur_channel >= channels) begin
                    for (j=0; j<parallelism; j = j + 1) begin
                        rescnt = rescnt + adder_bus[j*8 +: 8];
                    end
                    start <= 1'b0;
                    if (rescnt >= (channels*kernel_size**2)/2+1) begin
                        pixel <= 1;
                    end
                    else begin
                        pixel <= 0;
                    end
                    cur_channel = 0;
                    rescnt = 0;
                    
                end
            end
        end
        
    end
endmodule
