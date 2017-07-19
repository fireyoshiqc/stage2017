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
    parameter weight_file = "",
    parameter bias_file = "",
    parameter integer stride = 1,
    parameter integer filter_size = 3,
    parameter integer filter_nb = 10,
    parameter integer input_size = 30,
    parameter integer channels = 1,
    parameter integer dsp_alloc = 1,
    parameter integer conv_res_size = ((input_size-filter_size)/stride) + 1,
    
    // SHOULD ALL BE LEFT LIKE THIS FOR NOW.
    parameter integer input_int_part = 0, // int_part=1 means a signed number between [0,1]
    // Usually, inputs would be unsigned (since the input goes through a ReLU before a conv layer).
    parameter integer input_frac_part = 8,
    parameter integer weight_int_part = 1,
    parameter integer weight_frac_part = 8,
    parameter integer bias_int_part = 1,
    parameter integer bias_frac_part = 8,
    parameter integer out_int_part = 0,
    parameter integer out_frac_part = 8
    )
    (
    input clk, ack, start,
    input [channels * (input_int_part+input_frac_part) - 1 : 0] din,
    output reg done = 1'b0,
    output reg ready = 1'b0,
    output reg load_done = 1'b0,
    output reg [filter_nb * (out_int_part+out_frac_part) - 1 : 0] dout,
    output reg [clogb2(round_to_next_two(input_size**2))-1 : 0] addr = 0,
    output reg [clogb2(round_to_next_two(conv_res_size**2))-1 : 0] out_addr = 0,
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
    reg [clogb2(round_to_next_two(filter_nb))-1:0] conv_k = 0;
    integer channel = 0;
    integer faddr = 0;
    
    reg [(weight_int_part+weight_frac_part)-1 : 0] filters [filter_size**2*filter_nb*channels-1:0];
    reg [(bias_int_part+bias_frac_part)-1 : 0] biases [filter_nb-1:0];
    reg [2:0] operation = 0;
    reg [channels * (weight_int_part+weight_frac_part) - 1:0] conv_filter [filter_size**2 - 1 : 0];
    reg signed [clogb2(round_to_next_two(channels*filter_size**2))+imax(bias_int_part+bias_frac_part, input_int_part+weight_int_part+input_frac_part+weight_frac_part):0] sum = 0;
    reg signed [imax(bias_int_part+bias_frac_part, input_int_part+weight_int_part+input_frac_part+weight_frac_part):0] psums [channels - 1 : 0];
    //integer signed sum;
    //integer signed psums[channels - 1 : 0];
    
    // Not -1, because we need the sign bit in case it falls below zero
    
    reg signed [input_int_part+input_frac_part:0] s_input = 0; //Add one to add a '0' as MSB.
    reg signed [weight_int_part+weight_frac_part-1:0] s_weight = 0;
    reg signed [bias_int_part+bias_frac_part-1:0] s_bias = 0;
    
    reg sumready = 1'b0;
    
    integer i;
    initial begin
        for (i=0; i<channels; i = i + 1) psums[i] = 0;
        for (i=0; i<filter_size**2; i = i + 1) conv_filter[i] = 0;
        if (weight_file != "") begin
            $readmemh(weight_file, filters);
        end
        else begin
            for (i=0; i<filter_size**2*filter_nb*channels; i=i+1) filters[i]=8'hff;
        end
        if (bias_file != "") begin
            $readmemh(bias_file, biases);
        end
        else begin
            for (i=0; i<filter_nb; i=i+1) biases[i]=12'hfff;
        end
    end
    
    
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
                
                //out_addr <= conv_i*conv_res_size + conv_j;
                row <= conv_i;
                
                
                if (load_done) begin
                    operation <= 3'b100;
                end
                else begin
                    for (channel = 0; channel < dsp_alloc; channel = channel + 1) begin
                        // It is assumed weights have a bigger integer part than inputs since they're signed
                        s_input = {{1'b0}, {din[(clocked_channel+channel)*(input_int_part+input_frac_part) +: (input_int_part+input_frac_part)]}};
                        s_weight = conv_filter[faddr][(clocked_channel+channel)*(weight_int_part+weight_frac_part) +: (weight_int_part+weight_frac_part)];
                        psums[clocked_channel+channel] <= psums[clocked_channel+channel] + (s_input << imax(weight_frac_part-input_frac_part, 0)) * (s_weight << imax(input_frac_part-weight_frac_part, 0));
                        //sum = sum + (s_input << imax(weight_frac_part-input_frac_part, 0)) * (s_weight << imax(input_frac_part-weight_frac_part, 0));    
                    end
                   
                    if (clocked_channel+dsp_alloc < channels) begin
                        clocked_channel <= clocked_channel + dsp_alloc;
                        sumready <= 1'b0;
                    end
                    else begin
                        sumready <= 1'b1;
                    end
                    if (sumready) begin
                    
                        sumready <= 1'b0;
                    
                    // LA LOGIQUE SUR CLOCKED_I ET CLOCKED_J EST À RETRAVAILLER POUR ATTEINDRE LES CONTRAINTES DE TIMING
                    // IL EN VA DE MEME POUR LES OPERATIONS MATHEMATIQUES
                        //***
                        clocked_channel <= 0;
                    
                        if (clocked_j + 1 == filter_size && clocked_i + 1 == filter_size) begin
                            clocked_j <= 0;
                            clocked_i <= 0;
                            faddr <= 0;
                            wren[conv_k] <= 1'b1;
                            //out_bias <= biases[conv_k*8 +: 8];
                            s_bias = biases[conv_k];
                            
                            for (channel = 0; channel < channels; channel = channel + 1) begin
                                sum = sum + psums[channel];
                                psums[channel] <= 0;
                            end
                            
                            sum = (sum << imax(bias_frac_part-(input_frac_part+weight_frac_part), 0)) + (s_bias << imax((input_frac_part+weight_frac_part)-bias_frac_part, 0));
                            
                            // STILL NEEDS SOME WORK TO DETERMINE BIT-LENGTH TO KEEP
                            // RELU FUNCTION
                            if (sum[imax(input_frac_part+weight_frac_part, bias_frac_part)] == 1'b1) begin
                                sum = 0; //NEGATIVE OR OVERFLOW THAT NEEDS HANDLING
                            end
                            // CAP THE RELU TO 1
                            if (sum[imax(input_frac_part+weight_frac_part, bias_frac_part) +: imax(input_int_part+weight_int_part, bias_int_part)]) begin
                                sum = 8'hff << (imax(input_frac_part+weight_frac_part, bias_frac_part)-(input_frac_part+weight_frac_part));
                            end
                            dout[conv_k*8 +: 8] = sum[imax(input_frac_part+weight_frac_part, bias_frac_part) - 1 : imax(input_frac_part+weight_frac_part, bias_frac_part)-(input_frac_part+weight_frac_part)];
                            // END OF THING THAT NEEDS WORK :)
                            
                            sum = 0;
                            
                            if (conv_i + 1 == conv_res_size && conv_j + 1 == conv_res_size) begin
                                addr <= 0;
                                out_addr <= 0;
                                conv_i <= 0;
                                conv_j <= 0;
                                if (conv_k + 1 == filter_nb) begin
                                    operation <= 3'b001; //LOAD_DONE SPECIAL STATE IN FIRST IF
                                    load_done <= 1'b1;
                                end
                                else begin
                                    operation <= 3'b010; //LOAD FILTER
                                    conv_k <= conv_k + 1;
                                end
                            end
                            else if (conv_j + 1 == conv_res_size) begin
                                conv_j <= 0;
                                conv_i <= conv_i + 1;
                                out_addr <= out_addr + 1;
                                operation <= 3'b001;
                                addr <= addr + input_size*(stride-filter_size)+1;
                            end
                            else begin
                                conv_j <= conv_j + 1;
                                out_addr <= out_addr + 1;
                                operation <= 3'b001;
                                addr <= addr + stride - (input_size+1)*(filter_size-1);
                            end
                            
                        end
                        else if (clocked_j + 1 == filter_size) begin
                            clocked_j <= 0;
                            clocked_i <= clocked_i + 1;
                            addr <= addr + input_size - filter_size + 1;
                            faddr <= faddr + 1;
                            operation <= 3'b001;
                            wren <= 0;
                        end
                        else begin
                            clocked_j <= clocked_j + 1;
                            addr <= addr + 1;
                            faddr <= faddr + 1;//clocked_i*filter_size+clocked_j;     
                            operation <= 3'b001;
                            wren <= 0;
                        end
                        //***
                    
//                        clocked_j = clocked_j + 1;
//                        clocked_channel = 0;
//                        if (clocked_j >= filter_size) begin
//                            addr <= addr + 1;
//                            clocked_j = 0;
//                            clocked_i = clocked_i + 1;
//                            if (clocked_i >= filter_size) begin
//                                clocked_i = 0;
//                                wren[conv_k]= 1'b1;
//                                //out_bias <= biases[conv_k*8 +: 8];
//                                s_bias = biases[conv_k];
//                                sum = (sum << imax(bias_frac_part-(input_frac_part+weight_frac_part), 0)) + (s_bias << imax((input_frac_part+weight_frac_part)-bias_frac_part, 0));
                                
//                                // STILL NEEDS SOME WORK TO DETERMINE BIT-LENGTH TO KEEP
//                                // RELU FUNCTION
//                                if (sum[imax(input_frac_part+weight_frac_part, bias_frac_part)] == 1'b1) begin
//                                    sum = 0; //NEGATIVE OR OVERFLOW THAT NEEDS HANDLING
//                                end
//                                // CAP THE RELU TO 1
//                                if (sum[imax(input_frac_part+weight_frac_part, bias_frac_part) +: imax(input_int_part+weight_int_part, bias_int_part)]) begin
//                                    sum = 8'hff << (imax(input_frac_part+weight_frac_part, bias_frac_part)-(input_frac_part+weight_frac_part));
//                                end
//                                dout[conv_k*8 +: 8] = sum[imax(input_frac_part+weight_frac_part, bias_frac_part) - 1 : imax(input_frac_part+weight_frac_part, bias_frac_part)-(input_frac_part+weight_frac_part)];
//                                // END OF THING THAT NEEDS WORK :)
                                
//                                sum = 0;
//                                conv_j = conv_j + 1;
//                                if (conv_j >= conv_res_size) begin
//                                    conv_j = 0;
//                                    conv_i = conv_i + 1;
//                                    if (conv_i >= conv_res_size) begin
//                                        conv_i = 0;
//                                        conv_k = conv_k + 1;
//                                        if (conv_k >= filter_nb) begin
//                                            operation <= 3'b001;
//                                            load_done <= 1'b1;
//                                        end
//                                        else begin
//                                            operation <= 3'b010;
//                                        end
//                                    end
//                                    else begin
//                                    conv_k = conv_k;
//                                    operation = 3'b001;
//                                    end
//                                end
//                                else begin
//                                    conv_i = conv_i;
//                                    conv_k = conv_k;
//                                    operation = 3'b001;
//                                end
//                            end
//                            else begin
//                                conv_i = conv_i;
//                                conv_j = conv_j;
//                                conv_k = conv_k;
//                                operation = 3'b001;
//                            end
//                        end
//                        else begin
//                            if (clocked_j == filter_size - 1) begin
//                                if (clocked_i == filter_size -1) begin
//                                    if (conv_j == conv_res_size - 1) begin
//                                        if (conv_i == conv_res_size - 1) begin
//                                            addr <= 0;
//                                        end
//                                        else begin
//                                            addr <= addr + input_size*(stride-filter_size)+1;
//                                        end
//                                    end
//                                    else begin
//                                        addr <= addr + stride - (input_size+1)*(filter_size-1);
//                                    end
//                                end
//                                else begin
//                                    addr <= addr + input_size - filter_size + 1;
//                                end
                                
//                            end
                            
//                            else begin
//                                addr <= addr + 1;
//                            end
//                            clocked_i = clocked_i;
//                            conv_i = conv_i;
//                            conv_j = conv_j;
//                            conv_k = conv_k;
//                            operation <= 3'b001;
//                        end
//                    end
                          
                end   

            end
            end
            3'b010: begin   // LOAD FILTER
                addr <= 0;
                dout <= 0;
                out_addr <= 0;
                wren <= 0;
                for (filter_itr = 0; filter_itr<filter_size**2; filter_itr = filter_itr+1) begin
                    for (i=0; i<channels; i = i + 1) begin
                        conv_filter[filter_itr][i*(weight_int_part+weight_frac_part) +: (weight_int_part+weight_frac_part)] <= filters[conv_k + filter_itr*channels*filter_nb+(i*filter_nb)];
                    end
                    
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

