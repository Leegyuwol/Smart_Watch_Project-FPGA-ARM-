`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/03 20:48:52
// Design Name: 
// Module Name: short_button_negative_edge
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

`define TARGET_FREQ 200  // make 5ms sampling period
`define PRESCALER `CLOCK_FREQ / `TARGET_FREQ

module short_button_nedge(
    input clk, reset, btn,
    output btn_nedge
    );
    
    wire clk_div;
    // clock divider for debouncing (5ms)
    clock_divider #(`PRESCALER) debouncing_period(clk, reset, clk_div);

    reg btn_sampled;
    always @(posedge clk, posedge reset) begin
        if(reset)
            btn_sampled = 0;
        else if(clk_div) begin
            btn_sampled = btn;
        end
    end

    nedge_detector button_edge(
        .clk(clk), .reset(reset),
        .cp(btn_sampled),
        .nedge(btn_nedge)
    );
    
endmodule

module long_short_button_pedge(
    input clk, reset, btn,
    output btn_pedge
    );
    
    parameter HOLD_TIME = 70;   // 0.7s
    parameter SAMPLING_PERIOD = 10; // sampling long button input with 0.3s period
    
    wire clk_div;
    // clock divider for debouncing (5ms)
    clock_divider #(`PRESCALER) debouncing_period(
        clk, reset, clk_div
    );
    
    reg btn_sampled;
    reg [$clog2(HOLD_TIME)-1 : 0] count_hold;
    reg [$clog2(SAMPLING_PERIOD)-1 : 0] count_long;
    reg btn_long;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            btn_sampled = 0;
            count_hold = 0;
            count_long = 0;
            btn_long = 0;
        end
        else if(clk_div) begin
            btn_sampled = btn;
            if(btn_sampled) begin
                // 0.7초 대기
                if(count_hold < HOLD_TIME - 1) begin
                    count_hold = count_hold + 1;
                end
                else begin
                    // 0.1초 간격으로 입력
                    if(count_long < SAMPLING_PERIOD - 1) begin
                        count_long = count_long + 1;
                    end
                    else begin
                        count_long = 0;
                        btn_long = 1;
                    end
                end
            end
            else begin
                count_hold = 0;
                count_long = 0;
            end
        end
        else begin
            btn_long = 0;
        end
    end
    
    wire btn_short;
    pedge_detector button_edge(
        .clk(clk), .reset(reset),
        .cp(btn_sampled),
        .pedge(btn_short)
    );
    
    assign btn_pedge = btn_short || btn_long;
    
endmodule
