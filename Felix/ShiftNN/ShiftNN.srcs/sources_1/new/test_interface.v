`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/24/2017 02:55:51 PM
// Design Name: 
// Module Name: test_interface
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


module test_interface
    #(
    //parameter input_size = 784,
    parameter max_hidden_neurons = 100,
    parameter max_output_classes = 30,
    parameter input_mem_size = 1024
    )
    (
    input clk, ext_rst, start,
    input [15:0] input_size,
    input [15:0] hidden_neurons,
    input [7:0] output_classes,
    input [max_hidden_neurons*8 -1 : 0] hdn_weights, // NEED TO CHOOSE SOMETHING TO ENTER WEIGHT DATA
    input [max_output_classes*8 -1 : 0] out_weights, // NEED TO CHOOSE SOMETHING TO ENTER WEIGHT DATA
    input [max_hidden_neurons*8 -1 : 0] hdn_bias,
    input [max_output_classes*8 -1 : 0] out_bias,
    output [max_output_classes*16 - 1 : 0] out_bus, // NEED TO CHOOSE SOMETHING TO OUTPUT DATA
    output reg done = 1'b1
    );
    
    `include "functions.vh"
    
    reg hdn_enb = 1'b1;
    reg out_enb = 1'b0;
    
    reg [2:0] input_data [input_mem_size-1:0];
    reg [clogb2(round_to_next_two(input_mem_size))-1:0] input_addr = 0;
    reg [1:0] mode = 2'b10;
    reg [2:0] din;
    reg [max_hidden_neurons-1:0] henb = 0;
    reg [max_output_classes-1:0] oenb = 0;
    reg [15:0] h_addr = 0;
    
    wire [3*max_hidden_neurons - 1:0] activations;
    reg [2:0] act_window = 0;
    reg hrst = 1'b1;
    reg orst = 1'b1;
    
    genvar i;
    for (i=0; i<max_hidden_neurons; i=i+1) begin
        hidden_an han (.clk(clk), .rst(hrst | ext_rst), .enb(henb[i]), .din(din), .weight(hdn_weights[i*8 +: 8]), .bias(hdn_bias[i*8 +: 8]), .activation(activations[i*3 +: 3]));
    end
    for (i=0; i<max_output_classes; i=i+1) begin
        output_an oan (.clk(clk), .rst(orst | ext_rst), .enb(oenb[i]), .activation(act_window), .weight(out_weights[i*8 +: 8]), .bias(out_bias[i*8 +: 8]), .acc(out_bus[i*16 +: 16]));
    end
    
    integer j;
    initial begin
        for (j=0; j<input_mem_size; j=j+1) input_data[j]=0;
        for (j=0; j<max_hidden_neurons; j=j+1) begin
            if (j<hidden_neurons) begin
                henb[j] <= 1'b1;
            end
            else begin
                henb[j] <= 1'b0;
            end
        end
        for (j=0; j<max_output_classes; j=j+1) begin
            if (j<output_classes) begin
                oenb[j] <= 1'b1;
            end
            else begin
                oenb[j] <= 1'b0;
            end
        end
    end
    
    
    
    always @(posedge clk) begin
        if (ext_rst) begin // EXTERNAL RESET
            input_addr <= 0;
            h_addr <= 0;
            din <= 0;
            act_window <= 3'b111;
            mode <= 2'b10;
            done <= 1'b1;
            for (j=0; j<max_hidden_neurons; j=j+1) begin
                if (j<hidden_neurons) begin
                    henb[j] <= 1'b1;
                end
                else begin
                    henb[j] <= 1'b0;
                end
            end
            for (j=0; j<max_output_classes; j=j+1) begin
                if (j<output_classes) begin
                    oenb[j] <= 1'b1;
                end
                else begin
                    oenb[j] <= 1'b0;
                end
            end
        end
        else begin
            case (mode)
                2'b00: begin // HIDDEN LAYER
                    hrst <= 1'b0;
                    orst <= 1'b1;
                    done <= 1'b0;
                    din <= input_data[input_addr];
                    if (input_addr + 1 < input_size) begin
                        input_addr <= input_addr + 1;
                        mode <= 2'b00;
                    end
                    else begin
                        input_addr <= 0;
                        mode <= 2'b01;
                    end
                end
                2'b01: begin // OUTPUT LAYER
                    din <= 0; // MAKE THE HIDDEN LAYER SAVE POWER
                    orst <= 1'b0;
                    hrst <= 1'b0;
                    done <= 1'b0;
                    act_window <= activations[h_addr*3 +: 3];
                    if (h_addr + 1 < hidden_neurons) begin
                        h_addr <= h_addr + 1;
                        mode <= 2'b01;
                    end
                    else begin
                        h_addr <= 0;
                        mode <= 2'b10;
                        done <= 1'b1;
                    end
                
                end
                2'b10: begin // DONE STATE, HOLD OUTPUT DATA
                    din <= 0; // MAKE THE HIDDEN LAYER SAVE POWER
                    act_window <= 3'b111; // MAKE THE OUTPUT LAYER SAVE POWER (AND DATA)
                    if (start) begin
                        mode <= 2'b00;
                        hrst <= 1'b1;
                        orst <= 1'b1;
                    end
                    else begin
                        mode <= 2'b10;
                        hrst <= 1'b0;
                        orst <= 1'b0;
                    end
                
                end
            endcase
        end
        
    end

endmodule
