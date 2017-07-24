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
    parameter input_size = 784,
    parameter hidden_neurons = 2,
    parameter output_classes = 10
    )
    (
    input clk,
    input [2:0] din,
    input [hidden_neurons*8 -1 : 0] hdn_weights, // NEED TO CHOOSE SOMETHING TO ENTER WEIGHT DATA
    input [output_classes*8 -1 : 0] out_weights, // NEED TO CHOOSE SOMETHING TO ENTER WEIGHT DATA
    output [output_classes*16 - 1 : 0] out_bus // NEED TO CHOOSE SOMETHING TO OUTPUT DATA
    );
    
    integer counter = 0;
    reg hdn_enb = 1'b1;
    reg out_enb = 1'b0;
    
    genvar i;
    wire [hidden_neurons*3 - 1 : 0] activations;
    reg [2:0] act_window;
    reg rst = 1'b0;
    for (i=0; i<hidden_neurons; i=i+1) begin
        hidden_an han (.clk(clk), .rst(rst), .enb(hdn_enb), .din(din), .weight(hdn_weights[i*8 +: 8]), .activation(activations[i*3 +: 3]));
    end
    for (i=0; i<output_classes; i=i+1) begin
        output_an oan (.clk(clk), .rst(rst), .enb(out_enb), .activation(act_window), .weight(out_weights[i*8 +: 8]), .acc(out_bus[i*16 +: 16]));
    end
    
    always @(posedge clk) begin
        if (counter + 1 < input_size) begin
            act_window <= 0;
            hdn_enb <= 1'b1;
            out_enb <= 1'b0;
            rst <= 1'b0;
            counter <= counter + 1;
            // FETCH NEW DATA IN
        end
        else if (counter + 1 < (input_size + hidden_neurons)) begin
            act_window <= activations[(counter+1-input_size)*3 +: 3];
            hdn_enb <= 1'b0;
            out_enb <= 1'b1;
            rst <= 1'b0;
            counter <= counter + 1;
        end
        else begin
            act_window <= 0;
            hdn_enb <= 1'b0;
            out_enb <= 1'b0;
            rst <= 1'b1;
            counter <= 0;
        end
        
    end
    
//    always @(posedge clk) begin
//        if (ocounter + 1 < hidden_neurons) begin
//            //rst <= 1'b0;
//            ocounter <= ocounter + 1;
//            // FETCH NEW DATA IN
//        end
//        else begin
//            //rst <= 1'b1;
//            ocounter <= 1'b0;
//        end
        
//        act_window <= activations[ocounter*3 +: 3];
        
//    end
endmodule
