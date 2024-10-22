`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/03 20:42:08
// Design Name: 
// Module Name: Basic Watch
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

module basic_watch(
    input clk, reset,
    input [2:0] btn,
    input [51:0] sync_buffer,
    input sync,
    output [23:0] time_value,
    output [35:0] date_value,
    output reg [2:0] cursor_pos,
    output [55:0] send_buffer
    );
    
    reg mode;
    parameter START = 0;
    parameter SET = 1;
    
    reg [2:0] time_sel;
    
    always @(*) begin
        if(mode == SET) begin
            case(time_sel)
                `HOUR: cursor_pos = `CUS_HOUR;
                `MIN: cursor_pos = `CUS_MIN;
                `SEC: cursor_pos = `CUS_SEC;
                `YEAR: cursor_pos = `CUS_YEAR;
                `MONTH: cursor_pos = `CUS_MONTH;
                `DAY: cursor_pos = `CUS_DAY;
                default: cursor_pos = 0;
            endcase
        end
        else
            cursor_pos = 0;
    end
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            mode = START;
            time_sel = 0;
        end
        else begin
            if(btn[0]) begin
                time_sel = 0;
                mode = ~mode;
            end
            if(mode == SET && btn[1]) begin
                if(time_sel < 5)
                    time_sel = time_sel + 1;
                else
                    time_sel = 0;
            end
        end
    end
    
    wire [3:0] clk_time, inc_time;
    clock_divider #(`CLOCK_FREQ) second(.clk(clk), .reset(reset), .clk_div(clk_time[0]));   // make 1s edge
    source_divider #(60) minute(.clk(clk), .reset(reset), .source(inc_time[0]), .clk_div(clk_time[1]));
    source_divider #(60) hour(.clk(clk), .reset(reset), .source(inc_time[1]), .clk_div(clk_time[2]));
    source_divider #(24) day(.clk(clk), .reset(reset), .source(inc_time[2]), .clk_div(clk_time[3]));

    assign inc_time[0] = (mode == START)? clk_time[0] : ((mode == SET) && (time_sel == `SEC))? btn[2] : 0;
    assign inc_time[1] = (mode == START)? clk_time[1] : ((mode == SET) && (time_sel == `MIN))? btn[2] : 0;
    assign inc_time[2] = (mode == START)? clk_time[2] : ((mode == SET) && (time_sel == `HOUR))? btn[2] : 0;
    assign inc_time[3] = (mode == START)? clk_time[3] : ((mode == SET) && (time_sel == `DAY))? btn[2] : 0;
    
    wire [3:0] month10, day10, hour10, min10, sec10, month1, day1, hour1, min1, sec1;
    wire [11:0] year;
    wire [6:0] year_2digit = year - 2000;
    wire set_enable;
    assign set_enable = (mode == SET)? 1:0;
    bcd_counter_date decimal_date(
        .clk(clk), .reset(reset), .source(inc_time[3]),
        .btn_edge(btn[2]), .set_enable(set_enable), .time_sel(time_sel),
        .sync(sync), .year_in(sync_buffer[7:0]),
        .month10_in(sync_buffer[15:12]), .month1_in(sync_buffer[11:8]),
        .day10_in(sync_buffer[23:20]), .day1_in(sync_buffer[19:16]),
        .month10(month10), .month1(month1), .day10(day10), .day1(day1), .year(year)
    );
    bcd_counter_hour_sync decimal_hour(
        .clk(clk), .reset(reset), .source(inc_time[2]),
        .sync(sync), .bcd10_in(sync_buffer[31:28]), .bcd1_in(sync_buffer[27:24]),
        .bcd10(hour10), .bcd1(hour1)
    );
    bcd_counter_sync decimal_min(
        .clk(clk), .reset(reset), .source(inc_time[1]),
        .sync(sync), .bcd10_in(sync_buffer[39:36]), .bcd1_in(sync_buffer[35:32]),
        .bcd10(min10), .bcd1(min1)
    );
    bcd_counter_sync decimal_sec(
        .clk(clk), .reset(reset), .source(inc_time[0]),
        .sync(sync), .bcd10_in(sync_buffer[47:44]), .bcd1_in(sync_buffer[43:40]),
        .bcd10(sec10), .bcd1(sec1)
    );
    
    /* 요일 계산 */
    wire [3:0] weekday;
    wire [3:0] weekday_in = sync_buffer[51:48];
    day_of_week day_calc(
        .clk(clk), .reset(reset), .sync(sync), .weekday_in(weekday_in),
        .day10(day10), .day1(day1), .month10(month10), .month1(month1), .year(year),
        .weekday(weekday)
    );
    
    wire [15:0] year_dec;
    bin_to_dec(.bin(year), .bcd(year_dec));
    
    assign time_value = {sec1, sec10, min1, min10, hour1, hour10};
    assign date_value = {weekday, day1, day10, month1, month10, year_dec};
    
    wire [7:0] year_2digit_bcd;
    bin_to_bcd2 convert_year_to_bcd(
        .bin(year_2digit), .bcd(year_2digit_bcd)
    );
    assign send_buffer = {
        4'b0000, weekday, sec10, sec1, min10, min1, hour10, hour1,
        day10, day1, month10, month1, year_2digit_bcd
    };
    
endmodule

//module basic_watch(
//    input clk, reset,
//    input [2:0] btn,
//    output [23:0] time_value,
//    output [35:0] date_value,
//    output reg [2:0] cursor_pos
//    );
    
//    wire [2:0] btn_edge;
//    short_button_nedge mode_switch_button(.clk(clk), .reset(reset), .btn(btn[0]), .btn_nedge(btn_edge[0]));
//    short_button_nedge set_time_select_button(.clk(clk), .reset(reset), .btn(btn[1]), .btn_nedge(btn_edge[1]));
//    long_short_button_pedge inc_time_button(.clk(clk), .reset(reset), .btn(btn[2]), .btn_pedge(btn_edge[2]));
    
//    reg [1:0] mode;
//    parameter WATCH = 0;
//    parameter SET_TIME = 1;
//    parameter SET_DATE = 2;
    
//    reg [1:0] time_sel;
    
//    reg [1:0] date_sel;
//    parameter YEAR = 0;
//    parameter MONTH = 1;
//    parameter DAY = 2;
    
//    always @(*) begin
//        if(mode == SET_TIME) begin
//            case(time_sel)
//                `HOUR: cursor_pos = `CUS_HOUR;
//                `MIN: cursor_pos = `CUS_MIN;
//                `SEC: cursor_pos = `CUS_SEC;
//                default: cursor_pos = 0;
//            endcase
//        end
//        else if(mode == SET_DATE) begin
//            case(date_sel)
//                YEAR: cursor_pos = `CUS_YEAR;
//                MONTH: cursor_pos = `CUS_MONTH;
//                DAY: cursor_pos = `CUS_DAY;
//                default: cursor_pos = 0;
//            endcase
//        end
//        else
//            cursor_pos = 0;
//    end
    
//    always @(posedge clk, posedge reset) begin
//        if(reset) begin
//            mode = 0;
//            time_sel = 0;
//            date_sel = 0;
//        end
//        else if(btn_edge[0]) begin
//            time_sel = 0;
//            date_sel = 0;
//            if(mode < 2)
//                mode = mode + 1;
//            else
//                mode = 0;
//        end
//        else if(mode == 1 && btn_edge[1]) begin
//            if(time_sel < 2)
//                time_sel = time_sel + 1;
//            else
//                time_sel = 0;
//        end
//        else if(mode == 2 && btn_edge[1]) begin
//            if(date_sel < 2)
//                date_sel = date_sel + 1;
//            else
//                date_sel = 0;
//        end
//    end
    
//    wire [3:0] clk_time, inc_time;
//    clock_divider #(`CLOCK_FREQ) second(.clk(clk), .reset(reset), .clk_div(clk_time[0]));   // make 1s edge
//    source_divider #(60) minute(.clk(clk), .reset(reset), .source(inc_time[0]), .clk_div(clk_time[1]));
//    source_divider #(60) hour(.clk(clk), .reset(reset), .source(inc_time[1]), .clk_div(clk_time[2]));
//    source_divider #(24) day(.clk(clk), .reset(reset), .source(inc_time[2]), .clk_div(clk_time[3]));

//    assign inc_time[0] = (mode == WATCH)? clk_time[0] : ((mode == SET_TIME) && (time_sel == `SEC))? btn_edge[2] : 0;
//    assign inc_time[1] = (mode == WATCH)? clk_time[1] : ((mode == SET_TIME) && (time_sel == `MIN))? btn_edge[2] : 0;
//    assign inc_time[2] = (mode == WATCH)? clk_time[2] : ((mode == SET_TIME) && (time_sel == `HOUR))? btn_edge[2] : 0;
//    assign inc_time[3] = (mode == WATCH)? clk_time[3] : ((mode == SET_DATE) && (date_sel == DAY))? btn_edge[2] : 0;
    
//    wire [3:0] month10, day10, hour10, min10, sec10, month1, day1, hour1, min1, sec1;
//    wire [11:0] year;
//    wire set_enable;
//    assign set_enable = (mode == SET_DATE)? 1:0;
//    bcd_counter_date decimal_date(
//        .clk(clk), .reset(reset), .source(inc_time[3]),
//        .btn_edge(btn_edge[2]), .set_enable(set_enable), .date_sel(date_sel), 
//        .month10(month10), .month1(month1), .day10(day10), .day1(day1), .year(year)
//    );
//    bcd_counter_hour decimal_hour(.clk(clk), .reset(reset), .source(inc_time[2]), .bcd10(hour10), .bcd1(hour1));
//    bcd_counter decimal_min(.clk(clk), .reset(reset), .source(inc_time[1]), .bcd10(min10), .bcd1(min1));
//    bcd_counter decimal_sec(.clk(clk), .reset(reset), .source(inc_time[0]), .bcd10(sec10), .bcd1(sec1));
    
//    /* 요일 계산 */
//    wire [3:0] weekday;
//    day_of_week day_calc(clk, reset, day10, day1, month10, month1, year, weekday);
    
//    wire [15:0] year_dec;
//    bin_to_dec(.bin(year), .bcd(year_dec));
    
//    assign time_value = {sec1, sec10, min1, min10, hour1, hour10};
//    assign date_value = {weekday, day1, day10, month1, month10, year_dec};
    
//endmodule