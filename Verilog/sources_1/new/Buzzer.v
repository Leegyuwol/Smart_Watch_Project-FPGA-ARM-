`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/19 22:27:07
// Design Name: 
// Module Name: Buzzer
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

module buzzer(
    input clk, reset,
    input btn_clear,
    input alert, alarm,
    output reg buzz
    );
    
    parameter real BUZZ_FREQ = 1 / 0.4;   // 0.4s
    parameter integer PRESCALER = `CLOCK_FREQ / BUZZ_FREQ;
    
    reg [$clog2(PRESCALER)-1 : 0] count;
    reg buzz_flag;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            count = 0;
            buzz_flag = 0;
            buzz = 0;
        end
        else begin
            if(btn_clear) begin
                buzz_flag = 0;
                buzz = 0;
            end
            else if(alert || alarm)
                buzz_flag = 1;
            if(buzz_flag) begin
                if(count < PRESCALER - 1)
                    count = count + 1;
                else begin
                    count = 0;
                    buzz = ~buzz;
                end
            end
        end
    end
    
endmodule
