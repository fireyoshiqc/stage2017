`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/09/2017 02:15:00 PM
// Design Name: 
// Module Name: conv_layer_mc
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


module conv_layer_mc
    #(
    parameter integer bram_depth = 784,
    parameter integer stride = 1,
    parameter integer filter_size = 2,
    parameter integer filter_nb = 1,
    parameter integer input_size = 3,
    parameter integer channels = 1,
    parameter integer dsp_alloc = 1,
    parameter integer conv_res_size = ((input_size-filter_size)/stride) + 1,
    parameter integer input_int_part = 0, // int_part=1 means a signed number between [0,1]
    // Usually, inputs would be unsigned (since the input goes through a ReLU before a conv layer).
    parameter integer input_frac_part = 8,
    parameter integer weight_int_part = 1,
    parameter integer weight_frac_part = 8,
    parameter integer bias_int_part = 1,
    parameter integer bias_frac_part = 12,
    parameter integer out_int_part = 0,
    parameter integer out_frac_part = 8
    )
    (
    input clk, ack, start,
    input [channels * (input_int_part+input_frac_part) - 1 : 0] din,
    input [filter_size**2*filter_nb*channels*(weight_int_part+weight_frac_part)-1 : 0] filters,
    input [filter_nb*(bias_int_part+bias_frac_part)-1 : 0] biases,
    output reg done = 1'b0,
    output reg ready = 1'b0,
    output reg load_done = 1'b0,
    output reg [filter_nb * (out_int_part+out_frac_part) - 1 : 0] dout,
    output reg [clogb2(round_to_next_two(bram_depth))-1 : 0] addr = 0,
    output reg [clogb2(round_to_next_two(bram_depth))-1 : 0] out_addr = 0,
    output reg [clogb2(round_to_next_two(conv_res_size))-1 : 0] row = 0,
    output reg [filter_nb - 1 : 0] wren = 0//,
    //output reg [8-1 : 0] out_bias = 0
    );
    
    `include "functions.vh"
    
    integer filter_itr = 0;
    integer clocked_i = 0;
    integer clocked_j = 0;
    integer clocked_channel = 0;
    integer conv_i = 0;
    integer conv_j = 0;
    integer conv_k = 0;
    integer channel = 0;

    reg [2:0] operation = 0;
    reg [channels * (weight_int_part+weight_frac_part) - 1:0] conv_filter [filter_size**2 - 1 : 0];
    reg signed [clogb2(round_to_next_two(channels*filter_size**2))+imax(bias_int_part+bias_frac_part, input_int_part+weight_int_part+input_frac_part+weight_frac_part):0] sum = 0;
    reg signed [clogb2(round_to_next_two(channels*filter_size**2))+imax(bias_int_part+bias_frac_part, input_int_part+weight_int_part+input_frac_part+weight_frac_part):0] lsum = 0;
    // Not -1, because we need the sign bit in case it falls below zero
    
    reg signed [input_int_part+input_frac_part:0] s_input; //Add one to add a '0' as MSB.
    reg signed [weight_int_part+weight_frac_part-1:0] s_weight;
    reg signed [bias_int_part+bias_frac_part-1:0] s_bias;
    
    
    always @(posedge clk) begin
        case (operation)
            3'b000: begin   // INITIALIZE
                addr <= 0;
                dout <= 0;
                ready <= 1'b1;
                done <= 1'b0;
                load_done <= 1'b0;
                operation = 3'b101;
            end
            
            3'b001: begin //CONVOLVE
            // 1. Load needed data (filter should be pre-loaded).
            // 2. Multiply-Accumulate on DSP_ALLOC channels.
            // 3. If needed, iterate to next batch of channels.
            // 4. When done, iterate to next data to pass in kernel.
            // 5. When whole kernel has been iterated, write output to
            //      the corresponding byte (filter).
            // 6. Reset mul-acc to 0 and go to next kernel.
            // 7. When whole image has been treated, go to done.
                
                out_addr = conv_i*conv_res_size + conv_j;
                row = conv_i;
                wren = 0;
                
                if (load_done) begin
                    operation <= 3'b100;
                end
                else begin
                
                
                
                for (channel = clocked_channel; channel < clocked_channel+dsp_alloc; channel = channel + 1) begin
                    // It is assumed weights have a bigger integer part than inputs since they're signed
                    s_input = {{1'b0}, {din[channel*(input_int_part+input_frac_part) +: (input_int_part+input_frac_part)]}};
                    s_weight = conv_filter[clocked_i*filter_size+clocked_j][channel*(weight_int_part+weight_frac_part) +: (weight_int_part+weight_frac_part)];
                    sum = sum + (s_input << imax(weight_frac_part-input_frac_part, 0)) * (s_weight << imax(input_frac_part-weight_frac_part, 0));    
                end
               
                if (channel < channels) begin
                    clocked_channel = clocked_channel + dsp_alloc;
                end
                else begin
                    clocked_j = clocked_j + 1;
                    clocked_channel = 0;
                    if (clocked_j >= filter_size) begin
                        addr <= addr + 1;
                        clocked_j = 0;
                        clocked_i = clocked_i + 1;
                        if (clocked_i >= filter_size) begin
                            clocked_i = 0;
                            wren[conv_k]= 1'b1;
                            //out_bias <= biases[conv_k*8 +: 8];
                            s_bias = biases[conv_k*(bias_int_part+bias_frac_part) +: (bias_int_part+bias_frac_part)];
                            $display(sum << imax(bias_frac_part-(input_frac_part+weight_frac_part), 0));
                            sum = (sum << imax(bias_frac_part-(input_frac_part+weight_frac_part), 0)) + (s_bias << imax((input_frac_part+weight_frac_part)-bias_frac_part, 0));
                            lsum = sum;
                            
                            // STILL NEEDS SOME WORK TO DETERMINE BIT-LENGTH TO KEEP
                            // RELU FUNCTION
                            if (sum[imax(input_frac_part+weight_frac_part, bias_frac_part)] == 1'b1) begin
                                sum = 0; //NEGATIVE OR OVERFLOW THAT NEEDS HANDLING
                            end
                            dout[conv_k*8 +: 8] = sum[imax(input_frac_part+weight_frac_part, bias_frac_part) - 1 : 0];
                            // END OF THING THAT NEEDS WORK :)
                            
                            sum = 0;
                            conv_j = conv_j + 1;
                            if (conv_j >= conv_res_size) begin
                                conv_j = 0;
                                conv_i = conv_i + 1;
                                if (conv_i >= conv_res_size) begin
                                    conv_i = 0;
                                    conv_k = conv_k + 1;
                                    if (conv_k >= filter_nb) begin
                                        operation <= 3'b001;
                                        load_done <= 1'b1;
                                    end
                                    else begin
                                        operation <= 3'b010;
                                    end
                                end
                                else begin
                                conv_k = conv_k;
                                operation = 3'b001;
                                end
                            end
                            else begin
                                conv_i = conv_i;
                                conv_k = conv_k;
                                operation = 3'b001;
                            end
                        end
                        else begin
                            conv_i = conv_i;
                            conv_j = conv_j;
                            conv_k = conv_k;
                            operation = 3'b001;
                        end
                    end
                    else begin
                        if (clocked_j == filter_size - 1) begin
                            if (clocked_i == filter_size -1) begin
                                if (conv_j == conv_res_size - 1) begin
                                    if (conv_i == conv_res_size - 1) begin
                                        addr <= 0;
                                    end
                                    else begin
                                        addr <= addr + input_size*(stride-filter_size)+1;
                                    end
                                end
                                else begin
                                    addr <= addr + stride - (input_size+1)*(filter_size-1);
                                end
                            end
                            else begin
                                addr <= addr + input_size - filter_size + 1;
                            end
                            
                        end
                        
                        else begin
                            addr <= addr + 1;
                        end
                        clocked_i = clocked_i;
                        conv_i = conv_i;
                        conv_j = conv_j;
                        conv_k = conv_k;
                        operation <= 3'b001;
                    end
                end           
                end   

            end
            3'b010: begin   // LOAD FILTER
                addr <= 1;
                dout <= 0;
                out_addr <= 0;
                wren <= 0;
                for (filter_itr = 0; filter_itr<filter_size**2; filter_itr = filter_itr+1) begin
                    conv_filter[filter_itr] <= filters[(conv_k*(filter_size**2) + filter_itr)*channels*(weight_int_part+weight_frac_part) +: channels*(weight_int_part+weight_frac_part)];
                end
                ready <= 1'b0;
                done <= 1'b0;
                operation <= 3'b001;           
            end

            3'b100: begin // DONE (WAIT)
                addr <= 0;
                dout <= 0;
                out_addr <= 0;
                addr <= 0;
                dout <= 0;
                row <= 0;
                wren <= 0;
                conv_k <= 0;
                if (ack) begin // TO READY
                    operation <= 3'b101;
                    ready <= 1'b1;
                    done <= 1'b0;
                    load_done <= 1'b0;
                end
                else begin // TO DONE
                    operation <= 3'b100;
                    ready <= 1'b0;
                    done <= 1'b1;
                    load_done <= 1'b1;
                end
            end
            3'b101: begin // READY
                if (start) begin // TO LOAD FILTER
                    operation <= 3'b010;
                    ready <= 1'b0;
                    done <= 1'b0;
                    load_done <= 1'b0;
                    clocked_i = 0;
                    clocked_j = 0;
                end
                else begin // TO READY
                    operation <= 3'b101;
                    ready <= 1'b1;
                    done <= 1'b0;
                    load_done <= 1'b0;
                end
            end
        endcase
    end    
endmodule

