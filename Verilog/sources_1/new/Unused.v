`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/20 10:50:03
// Design Name: 
// Module Name: Unused
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


/* 알람이 켜지면 타이머가 00:00으로 초기화되는 방식 */
module timer(
    input clk, reset,
    input [3:0] btn,
    output [6:0] seg, [3:0] an,
    output reg alert
    );
    
    wire btn_mode_nedge, btn_min_pedge, btn_sec_pedge, btn_off_pedge;
    short_button_nedge mode_switch_button_edge(
        .clk(clk), .reset(reset), .btn(btn[0]), .btn_nedge(btn_mode_nedge)
    );
    long_short_button_pedge inc_min_button_edge(
        .clk(clk), .reset(reset), .btn(btn[1]), .btn_pedge(btn_min_pedge)
    );
    long_short_button_pedge inc_sec_button_edge(
        .clk(clk), .reset(reset), .btn(btn[2]), .btn_pedge(btn_sec_pedge)
    );
    short_button_nedge alert_off_button_edge(
        .clk(clk), .reset(reset), .btn(btn[3]), .btn_nedge(btn_off_nedge)
    );
    reg mode;
    parameter SET = 0;
    parameter TIMER = 1;
    
    wire clk_sec, clk_min;
    clock_divider #(100_000_000) second(
        .clk(clk), .reset(reset), .clk_div(clk_sec)
    );
    source_divider #(60) minute(
        .clk(clk), .reset(reset), .source(inc_sec), .clk_div(clk_min)
    );
    
    assign dec_min = (mode == TIMER)? clk_min : 0;
    assign dec_sec = (mode == TIMER)? clk_sec : 0;
    assign inc_min = (mode == SET)? btn_min_pedge : 0;
    assign inc_sec = (mode == SET)? btn_sec_pedge : 0;
    wire [2:0] min10, sec10;
    wire [3:0] min1, sec1;
    bcd_up_down_counter decimal_min(
        .clk(clk), .reset(reset), .source_down(dec_min), .source_up(inc_min), .bcd10(min10), .bcd1(min1)
    );
    bcd_up_down_counter decimal_sec(
        .clk(clk), .reset(reset), .source_down(dec_sec), .source_up(inc_sec), .bcd10(sec10), .bcd1(sec1)
    );
    
    wire [15:0] value;
    assign value = {1'b0, min10, min1, 1'b0, sec10, sec1};
    fnd_controller fnd_print(
        clk, reset, value, seg, an
    );
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            alert = 0;
            mode = 0;
        end
        else begin
            if(btn_mode_nedge)
                mode = ~mode;
            else if(mode == TIMER && value == 16'h0000) begin
                mode = SET;
                alert = 1;
            end
            else if(btn_off_nedge)
                alert = 0;
        end
    end
    
endmodule

module bcd_up_down_counter(
    input clk, reset, source_up, source_down,
    output reg [3:0] bcd10, bcd1
    );
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            bcd10 = 0;
            bcd1 = 0;
        end
        else if(source_down) begin
            if(bcd1 > 0) begin
                bcd1 = bcd1 - 1;
            end
            else begin
                if(bcd10 > 0) begin
                    bcd1 = 9;
                    bcd10 = bcd10 - 1;
                end
            end
        end
        else if(source_up) begin
            if(bcd1 < 9) begin
                bcd1 = bcd1 + 1;
            end
            else begin
                bcd1 = 0;
                if(bcd10 < 5) begin
                    bcd10 = bcd10 + 1;
                end
                else begin
                    bcd10 = 0;
                end
            end
        end
    end
    
endmodule

module bcd_counter(
    input clk, reset, source,
    output reg [3:0] bcd10, bcd1
    );
    
    parameter ONES_MAX = 9;
    parameter TENS_MAX = 5;
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            bcd10 = 0;
            bcd1 = 0;
        end
        else if(source) begin
            if(bcd1 < ONES_MAX) begin
                bcd1 = bcd1 + 1;
            end
            else begin
                bcd1 = 0;
                if(bcd10 < TENS_MAX) begin
                    bcd10 = bcd10 + 1;
                end
                else begin
                    bcd10 = 0;
                end
            end
        end
    end
    
endmodule

/* Set Mode가 2가지로 나뉜 예전 방식 */
module basic_watch(
    input clk, reset,
    input [2:0] btn,
    output [23:0] time_value,
    output [35:0] date_value,
    output reg [2:0] cursor_pos
    );
    
    wire [2:0] btn_edge;
    short_button_nedge mode_switch_button(.clk(clk), .reset(reset), .btn(btn[0]), .btn_nedge(btn_edge[0]));
    short_button_nedge set_time_select_button(.clk(clk), .reset(reset), .btn(btn[1]), .btn_nedge(btn_edge[1]));
    long_short_button_pedge inc_time_button(.clk(clk), .reset(reset), .btn(btn[2]), .btn_pedge(btn_edge[2]));
    
    reg [1:0] mode;
    parameter WATCH = 0;
    parameter SET_TIME = 1;
    parameter SET_DATE = 2;
    
    reg [1:0] time_sel;
    
    reg [1:0] date_sel;
    parameter YEAR = 0;
    parameter MONTH = 1;
    parameter DAY = 2;
    
    always @(*) begin
        if(mode == SET_TIME) begin
            case(time_sel)
                `HOUR: cursor_pos = `CUS_HOUR;
                `MIN: cursor_pos = `CUS_MIN;
                `SEC: cursor_pos = `CUS_SEC;
                default: cursor_pos = 0;
            endcase
        end
        else if(mode == SET_DATE) begin
            case(date_sel)
                YEAR: cursor_pos = `CUS_YEAR;
                MONTH: cursor_pos = `CUS_MONTH;
                DAY: cursor_pos = `CUS_DAY;
                default: cursor_pos = 0;
            endcase
        end
        else
            cursor_pos = 0;
    end
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            mode = 0;
            time_sel = 0;
            date_sel = 0;
        end
        else if(btn_edge[0]) begin
            time_sel = 0;
            date_sel = 0;
            if(mode < 2)
                mode = mode + 1;
            else
                mode = 0;
        end
        else if(mode == 1 && btn_edge[1]) begin
            if(time_sel < 2)
                time_sel = time_sel + 1;
            else
                time_sel = 0;
        end
        else if(mode == 2 && btn_edge[1]) begin
            if(date_sel < 2)
                date_sel = date_sel + 1;
            else
                date_sel = 0;
        end
    end
    
    wire [3:0] clk_time, inc_time;
    clock_divider #(`CLOCK_FREQ) second(.clk(clk), .reset(reset), .clk_div(clk_time[0]));   // make 1s edge
    source_divider #(60) minute(.clk(clk), .reset(reset), .source(inc_time[0]), .clk_div(clk_time[1]));
    source_divider #(60) hour(.clk(clk), .reset(reset), .source(inc_time[1]), .clk_div(clk_time[2]));
    source_divider #(24) day(.clk(clk), .reset(reset), .source(inc_time[2]), .clk_div(clk_time[3]));

    assign inc_time[0] = (mode == WATCH)? clk_time[0] : ((mode == SET_TIME) && (time_sel == `SEC))? btn_edge[2] : 0;
    assign inc_time[1] = (mode == WATCH)? clk_time[1] : ((mode == SET_TIME) && (time_sel == `MIN))? btn_edge[2] : 0;
    assign inc_time[2] = (mode == WATCH)? clk_time[2] : ((mode == SET_TIME) && (time_sel == `HOUR))? btn_edge[2] : 0;
    assign inc_time[3] = (mode == WATCH)? clk_time[3] : ((mode == SET_DATE) && (date_sel == DAY))? btn_edge[2] : 0;
    
    wire [3:0] month10, day10, hour10, min10, sec10, month1, day1, hour1, min1, sec1;
    wire [11:0] year;
    wire set_enable;
    assign set_enable = (mode == SET_DATE)? 1:0;
    bcd_counter_date decimal_date(
        .clk(clk), .reset(reset), .source(inc_time[3]),
        .btn_edge(btn_edge[2]), .set_enable(set_enable), .date_sel(date_sel), 
        .month10(month10), .month1(month1), .day10(day10), .day1(day1), .year(year)
    );
    bcd_counter_hour decimal_hour(.clk(clk), .reset(reset), .source(inc_time[2]), .bcd10(hour10), .bcd1(hour1));
    bcd_counter decimal_min(.clk(clk), .reset(reset), .source(inc_time[1]), .bcd10(min10), .bcd1(min1));
    bcd_counter decimal_sec(.clk(clk), .reset(reset), .source(inc_time[0]), .bcd10(sec10), .bcd1(sec1));
    
    /* 요일 계산 */
    wire [3:0] weekday;
    day_of_week day_calc(clk, reset, day10, day1, month10, month1, year, weekday);
    
    wire [15:0] year_dec;
    bin_to_dec(.bin(year), .bcd(year_dec));
    
    assign time_value = {sec1, sec10, min1, min10, hour1, hour10};
    assign date_value = {weekday, day1, day10, month1, month10, year_dec};
    
endmodule
