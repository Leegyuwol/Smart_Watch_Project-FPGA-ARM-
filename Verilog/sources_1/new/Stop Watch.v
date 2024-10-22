`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/03 22:37:22
// Design Name: 
// Module Name: Stop Watch
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

`include "defines.v"

module stop_watch(
    input clk, reset,
    input [2:0] btn,
    output [19:0] value
    );
    
    reg [1:0] mode;
    parameter STOP  = 0;
    parameter START = 1;
    parameter LAP   = 2;
    always @(posedge clk, posedge reset) begin
        if(reset || btn[2])
            mode = STOP;
        else begin
            if(btn[0]) begin
                if(mode)
                    mode = STOP;
                else
                    mode = START;
            end
            if(btn[1]) begin
                if(mode == 1)
                    mode = 2;
                else if(mode == 2)
                    mode = 1;
            end
        end
    end
    
    parameter CSEC_FREQ = 100;
    parameter PRESCALER = `CLOCK_FREQ / CSEC_FREQ;
    
    wire enable;
    assign enable = mode? 1 : 0;
    wire clk_csec, clk_sec, clk_min;
    clock_divider_clear_enable #(PRESCALER) centi_second(
        .clk(clk), .reset(reset), .enable(enable), .clear(btn[2]), .clk_div(clk_csec)
    );
    source_divider_clear_enable #(100) second(
        .clk(clk), .reset(reset), .enable(enable), .clear(btn[2]), .source(clk_csec), .clk_div(clk_sec)
    );
    source_divider_clear_enable #(60) minute(
        .clk(clk), .reset(reset), .enable(enable), .clear(btn[2]), .source(clk_sec), .clk_div(clk_min)
    );
    
    wire [3:0] min10, min1, sec10, sec1, csec10;
    bcd_counter_clear_enable #(60) decimal_min(
        .clk(clk), .reset(reset),
        .clear(btn[2]), .enable(enable), .source(clk_min), .bcd10(min10), .bcd1(min1)
    );
    bcd_counter_clear_enable #(60) decimal_sec(
        .clk(clk), .reset(reset),
        .clear(btn[2]), .enable(enable), .source(clk_sec), .bcd10(sec10), .bcd1(sec1)
    );
    bcd_counter_clear_enable #(100) decimal_csec(
        .clk(clk), .reset(reset),
        .clear(btn[2]), .enable(enable), .source(clk_csec), .bcd10(csec10), .bcd1()
    );
    
    wire [19:0] value_start;
    reg [19:0] value_lapped;
    assign value_start = {csec10, sec1, sec10, min1, min10};
    always @(posedge clk, posedge reset) begin
        if(reset || btn[2])
            value_lapped = 0;
        else if(btn[1])
            value_lapped = value_start;
    end
    assign value = (mode == LAP)? value_lapped : value_start;

endmodule