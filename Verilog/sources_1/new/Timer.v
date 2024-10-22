`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/04 10:01:34
// Design Name: 
// Module Name: Timer
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

module timer2(
    input clk, reset,
    input [2:0] btn,
    output [23:0] value,
    output [1:0] cursor_pos,
    output reg alert
    );
    
    reg mode;
    parameter SET = 0;
    parameter TIMER = 1;
    
    reg [1:0] time_sel;
    
    wire clk_sec;
    clock_divider #(`CLOCK_FREQ) second(.clk(clk), .reset(reset), .clk_div(clk_sec));
    
    wire hour_flag, min_flag;
    assign dec_sec = (mode == TIMER)? clk_sec : 0;
    assign inc_hour = hour_flag? 1 : (mode == SET && time_sel == `HOUR)? btn[2] : 0;
    assign inc_min = min_flag? 1 : (mode == SET && time_sel == `MIN)? btn[2] : 0;
    assign inc_sec = (mode == SET && time_sel == `SEC)? btn[2] : 0;
    
    wire [3:0] hour10, hour1, min10, min1, sec10, sec1;
    wire [23:0] value_timer, value_set;
    assign value_set = {sec1, sec10, min1, min10, hour1, hour10};
    
    bcd_counter_hour decimal_hour(
        .clk(clk), .reset(reset), .source(inc_hour),
        .bcd10(hour10), .bcd1(hour1)
    );
    bcd_counter_flag decimal_min(
        .clk(clk), .reset(reset), .source(inc_min),
        .bcd10(min10), .bcd1(min1), .flag(hour_flag)
    );
    bcd_counter_flag decimal_sec(
        .clk(clk), .reset(reset), .source(inc_sec),
        .bcd10(sec10), .bcd1(sec1), .flag(min_flag)
    );
    bcd_down_counter timer_mode(
        .clk(clk), .reset(reset), .source(dec_sec), .start(btn[0]), .value(value_set),
        .value_timer(value_timer)
    );

    assign value = (mode == TIMER)? value_timer : value_set;
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            alert = 0;
            mode = 0;
            time_sel = 0;
        end
        else begin
            if(btn[0])
                mode = ~mode;
            else if(mode == TIMER && value_timer == 16'h0000) begin
                mode = SET;
                if(value_set != 16'h0000)
                    alert = 1;
            end
            else
                alert = 0;
            if(btn[1]) begin
                if(time_sel < 2)
                    time_sel = time_sel + 1;
                else
                    time_sel = 0;
            end
        end
    end
    
    assign cursor_pos = mode == TIMER? 0 : time_sel == `HOUR? `CUS_HOUR : time_sel == `MIN? `CUS_MIN : `CUS_SEC;
    
endmodule
