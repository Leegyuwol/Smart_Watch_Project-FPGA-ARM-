`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/04 17:23:05
// Design Name: 
// Module Name: Alarm
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

module alarm_watch(
    input clk, reset,
    input [2:0] btn,
    input [15:0] value_input,
    output [15:0] value,
    output [1:0] cursor_pos,
    output alarm_on,
    output reg alarm
    );
    
    wire mode;
    parameter SET = 0;
    parameter ALARM = 1;
    t_flip_flop toggle_mode(.clk(clk), .reset(reset), .t(btn[0]), .q(mode));
    assign alarm_on = mode;
    
    reg [1:0] time_sel;
    always @(posedge clk, posedge reset) begin
        if(reset)
            time_sel = !`HOUR? `HOUR : `MIN;
        else if(btn[1]) begin
            if(time_sel == `HOUR)
                time_sel = `MIN;
            else if(time_sel == `MIN)
                time_sel = `HOUR;
        end
    end
    
    assign cursor_pos = time_sel == `HOUR? `CUS_HOUR : time_sel == `MIN? `CUS_MIN : 0;
    
    wire hour_flag, min_flag;
    wire inc_hour = hour_flag? 1 : (time_sel == `HOUR)? btn[2] : 0;
    wire inc_min = (time_sel == `MIN)? btn[2] : 0;
    
    wire [3:0] hour10, hour1, min10, min1;
    bcd_counter_hour decimal_hour(
        .clk(clk), .reset(reset), .source(inc_hour),
        .bcd10(hour10), .bcd1(hour1)
    );
    bcd_counter_flag decimal_min(
        .clk(clk), .reset(reset), .source(inc_min),
        .bcd10(min10), .bcd1(min1), .flag(hour_flag)
    );
    
    assign value = {min1, min10, hour1, hour10};
    
    always @(posedge clk, posedge reset) begin
        if(reset)
            alarm = 0;
        else if(mode == ALARM && value == value_input)
            alarm = 1;
        else
            alarm = 0;
    end
    
endmodule
