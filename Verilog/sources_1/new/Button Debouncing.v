`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/09/02 09:10:47
// Design Name: 
// Module Name: Button Debouncing
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


module button_debouncing(
    input clk, reset,
    input [5:0] btn,
    output btn_pedge,
    output [5:0] btn_nedge
    );
    
    short_button_nedge btn_set(
        .clk(clk), .reset(reset), .btn(btn[0]), .btn_nedge(btn_nedge[0])
    );
    short_button_nedge btn_sel(
        .clk(clk), .reset(reset), .btn(btn[1]), .btn_nedge(btn_nedge[1])
    );
    long_short_button_pedge btn_up(
        .clk(clk), .reset(reset), .btn(btn[2]), .btn_pedge(btn_pedge)
    );
    short_button_nedge btn_clear(
        .clk(clk), .reset(reset), .btn(btn[2]), .btn_nedge(btn_nedge[2])
    );
    short_button_nedge btn_mode(
        .clk(clk), .reset(reset), .btn(btn[3]), .btn_nedge(btn_nedge[3])
    );
    short_button_nedge btn_alarm_clear(
        .clk(clk), .reset(reset), .btn(btn[4]), .btn_nedge(btn_nedge[4])
    );
    short_button_nedge btn_sync(
        .clk(clk), .reset(reset), .btn(btn[5]), .btn_nedge(btn_nedge[5])
    );
    
endmodule
