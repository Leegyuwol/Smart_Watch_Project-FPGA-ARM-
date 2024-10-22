`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/17 14:34:28
// Design Name: 
// Module Name: Top
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

module top(
    input clk, reset,
    input [5:0] btn,
    input rx,
    output buzz,
    output sda, scl,
    output tx
    );
    
    wire btn_pedge;
    wire [5:0] btn_nedge;
    button_debouncing button_0to4(
        clk, reset, btn, btn_pedge, btn_nedge
    );
    
    reg [1:0] mode;
    always @(posedge clk, posedge reset) begin
        if(reset)
            mode = 0;
        else if(btn_nedge[3]) begin
            if(mode < 3)
                mode = mode + 1;
            else
                mode = 0;
        end
    end
    
    wire [2:0] btn_watch, btn_sw, btn_timer, btn_alarm;
    assign btn_watch = (mode == `WATCH)? {btn_pedge, btn_nedge[1:0]} : 3'b000;
    assign btn_sw = (mode == `STOP_WATCH)? btn_nedge[2:0] : 3'b000;
    assign btn_timer = (mode == `TIMER)? {btn_pedge, btn_nedge[1:0]} : 3'b000;
    assign btn_alarm = (mode == `ALARM)? {btn_pedge, btn_nedge[1:0]} : 3'b000;
    
    wire [55:0] received_buffer;
    wire [51:0] received_buffer_modified = received_buffer[51:0];
    wire sync;
    sync_receive receive_value(
        .clk(clk), .reset(reset), .rx(rx),
        .received_value(received_buffer), .rx_done(sync)
    );
    
    /* WATCH */
    wire [23:0] time_value;
    wire [35:0] date_value;
    wire [2:0] cursor_pos_watch;
    wire [55:0] send_buffer;
    basic_watch rx_time_value(
        .clk(clk), .reset(reset), .btn(btn_watch), .sync_buffer(received_buffer_modified), .sync(sync),
        .time_value(time_value), .date_value(date_value), .cursor_pos(cursor_pos_watch), .send_buffer(send_buffer)
    );
    wire [31:0] date_value_without_weekday = date_value[31:0];
    wire [3:0] weekday = date_value[35:32];
    wire [47:0] ascii_time_value;
    wire [63:0] ascii_date_value;
    ascii_convert_time cv_time_value(.value(time_value), .ascii_value(ascii_time_value));
    ascii_convert_date cv_date_value(.value(date_value_without_weekday), .ascii_value(ascii_date_value));
    
    /* STOP WATCH */
    wire [19:0] sw_value;
    stop_watch rx_sw_value(.clk(clk), .reset(reset), .btn(btn_sw), .value(sw_value));
    wire [39:0] ascii_sw_value;
    ascii_convert_sw cv_sw_value(.value(sw_value), .ascii_value(ascii_sw_value));
    
    /* TIMER */
    wire [23:0] timer_value;
    wire [1:0] cursor_pos_timer;
    wire alert;
    timer2 rx_timer_value(
        .clk(clk), .reset(reset),
        .btn(btn_timer), .value(timer_value), .cursor_pos(cursor_pos_timer), .alert(alert)
    );
    wire [47:0] ascii_timer_value;
    ascii_convert_time cv_timer_value(.value(timer_value), .ascii_value(ascii_timer_value));
    
    /* ALARM */
    wire [15:0] alarm_value;
    wire [15:0] value_input_for_alarm = time_value[15:0];
    wire [1:0] cursor_pos_alarm;
    wire alarm_on, alarm;
    alarm_watch rx_alarm_value(
        .clk(clk), .reset(reset), .btn(btn_alarm), .value_input(value_input_for_alarm),
        .value(alarm_value), .cursor_pos(cursor_pos_alarm), .alarm_on(alarm_on), .alarm(alarm)
    );
    wire [31:0] ascii_alarm_value;
    ascii_convert_timer cv_alarm_value(.value(alarm_value), .ascii_value(ascii_alarm_value));
    
    wire raising = btn[2];
    wire [2:0] cursor_pos = (mode == `WATCH && cursor_pos_watch == `CUS_HOUR) || (mode == `TIMER && cursor_pos_timer == `CUS_HOUR) || (mode == `ALARM && cursor_pos_alarm == `CUS_HOUR)? `CUS_HOUR:
                            (mode == `WATCH && cursor_pos_watch == `CUS_MIN) || (mode == `TIMER && cursor_pos_timer == `CUS_MIN) || (mode == `ALARM && cursor_pos_alarm == `CUS_MIN)? `CUS_MIN:
                            (mode == `WATCH && cursor_pos_watch == `CUS_SEC) || (mode == `TIMER && cursor_pos_timer == `CUS_SEC)? `CUS_SEC:
                            (mode == `WATCH && cursor_pos_watch == `CUS_YEAR)? `CUS_YEAR:
                            (mode == `WATCH && cursor_pos_watch == `CUS_MONTH)? `CUS_MONTH:
                            (mode == `WATCH && cursor_pos_watch == `CUS_DAY)? `CUS_DAY : 0;
    
    i2c_lcd_print input_time_value(
        clk, reset,
        mode,
        raising,
        cursor_pos,
        ascii_time_value, ascii_date_value, weekday,
        ascii_sw_value,
        ascii_timer_value,
        ascii_alarm_value, alarm_on,
        sda, scl
    );
    
    sync_send send_value(
        .clk(clk), .reset(reset), .btn_sync(btn_nedge[5]), .data_buffer(send_buffer),
        .tx(tx)
    );
    
    wire btn_clear = btn_nedge[4];
    buzzer notion(clk, reset, btn_clear, alert, alarm, buzz);
    
endmodule
