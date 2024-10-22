`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/03 16:10:45
// Design Name: 
// Module Name: bcd_counter
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

module bcd_counter_sync(
    input clk, reset, source,
    input sync,
    input [3:0] bcd10_in, bcd1_in,
    output reg [3:0] bcd10, bcd1
    );
    
    parameter ONES_MAX = 9;
    parameter TENS_MAX = 5;
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            bcd10 = 0;
            bcd1 = 0;
        end
        else if(sync) begin
            bcd10 = bcd10_in;
            bcd1 = bcd1_in;
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

module bcd_counter_flag(
    input clk, reset, source,
    output reg [3:0] bcd10, bcd1,
    output reg flag
    );
    
    parameter ONES_MAX = 9;
    parameter TENS_MAX = 5;
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            bcd10 = 0;
            bcd1 = 0;
            flag = 0;
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
                    flag = 1;
                end
            end
        end
        else flag = 0;
    end
    
endmodule

module bcd_counter_hour(
    input clk, reset, source,
    output reg [3:0] bcd10, bcd1
    );
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            bcd10 = 0;
            bcd1 = 0;
        end
        else if(source) begin
            if(bcd10 == 2 && bcd1 == 3) begin
                bcd10 = 0;
                bcd1 = 0;
            end
            else if(bcd1 < 9) begin
                bcd1 = bcd1 + 1;
            end
            else begin
                bcd1 = 0;
                bcd10 = bcd10 + 1;
            end
        end
    end
    
endmodule

module bcd_counter_hour_sync(
    input clk, reset, source,
    input sync,
    input [3:0] bcd10_in, bcd1_in,
    output reg [3:0] bcd10, bcd1
    );
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            bcd10 = 0;
            bcd1 = 0;
        end
        else if(sync) begin
            bcd10 = bcd10_in;
            bcd1 = bcd1_in;
        end
        else if(source) begin
            if(bcd10 == 2 && bcd1 == 3) begin
                bcd10 = 0;
                bcd1 = 0;
            end
            else if(bcd1 < 9) begin
                bcd1 = bcd1 + 1;
            end
            else begin
                bcd1 = 0;
                bcd10 = bcd10 + 1;
            end
        end
    end
    
endmodule

module bcd_counter_date(
    input clk, reset, source,
    input btn_edge,
    input set_enable,
    input [2:0] time_sel,
    input sync,
    input [3:0] month10_in, month1_in, day10_in, day1_in,
    input [7:0] year_in,
    output reg [3:0] day10, day1,
    output reg [3:0] month10, month1,
    output reg [11:0] year
);

    reg [1:0] tens_max;
    reg [3:0] ones_max;
    // 윤년 계산 함수
    function is_leap_year(input [11:0] y);
        begin
            is_leap_year = ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0);
        end
    endfunction

    // 각 월의 일수를 계산
    always @(*) begin
        case({month10, month1})
            8'h04, 8'h06, 8'h09, 8'h11: begin
                tens_max = 3;
                ones_max = 0;
            end
            8'h02: begin // 2월
                if(is_leap_year(year)) begin
                    tens_max = 2;
                    ones_max = 9;
                end
                else begin
                    tens_max = 2;
                    ones_max = 8;
                end
            end
            default: begin
                tens_max = 3;
                ones_max = 1;
            end
        endcase
    end
    
    parameter MIN_YEAR = 2024;
    parameter MAX_YEAR = 2100;
    
    // 날짜, 월, 연도를 카운트 및 버튼 입력 처리
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            day10 = 0;
            day1 = 1;
            month10 = 0;
            month1 = 1;
            year = MIN_YEAR; // 기본값: 2020년 1월
        end
        else if(sync) begin
            day10 = day10_in;
            day1 = day1_in;
            month10 = month10_in;
            month1 = month1_in;
            year = year_in + 2000;
        end
        else if(source) begin
            if(day10 == tens_max && day1 == ones_max) begin
                if(month10 == 1 && month1 == 2) begin
                    month10 = 0;
                    month1 = 1;
                    if(year < MAX_YEAR)
                        year = year + 1;
                    else
                        year = MIN_YEAR;
                end
                else if(month1 < 9)
                    month1 = month1 + 1;
                else begin
                    month10 = 1;
                    month1 = 0;
                end
                day10 = 0;
                day1 = 1;
            end
            else if(day1 < 9) begin
                day1 = day1 + 1;
            end
            else begin
                day1 = 0;
                day10 = day10 + 1;
            end
        end
        else if(set_enable && btn_edge) begin
            if(time_sel == `MONTH) begin
                if(month10 == 1 && month1 == 2) begin
                    month10 = 0;
                    month1 = 1;
                    if(year < MAX_YEAR)
                        year = year + 1;
                    else
                        year = MIN_YEAR;
                end
                else if(month1 < 9)
                    month1 = month1 + 1;
                else begin
                    month10 = 1;
                    month1 = 0;
                end
            end
            else if(time_sel == `YEAR) begin
                if(year < MAX_YEAR)
                    year = year + 1;
                else
                    year = MIN_YEAR;
            end
        end
    end

endmodule

module bcd_counter_clear_enable #(N = 60)(
    input clk, reset, clear, enable, source,
    output reg [3:0] bcd10, bcd1
    );
    
    always @(posedge clk, posedge reset) begin
        if(reset || clear) begin
            bcd10 = 0;
            bcd1 = 0;
        end
        else if(source && enable) begin
            if(bcd1 < 9) begin
                bcd1 = bcd1 + 1;
            end
            else begin
                bcd1 = 0;
                if(bcd10 < N/10 - 1) begin
                    bcd10 = bcd10 + 1;
                end
                else begin
                    bcd10 = 0;
                end
            end
        end
    end
    
endmodule

module bcd_down_counter(
    input clk, reset,
    input source, start,
    input [23:0] value,
    output [23:0] value_timer
    );
    
    reg [3:0] hour10, hour1, min10, min1, sec10, sec1;
    assign value_timer = {sec1, sec10, min1, min10, hour1, hour10};
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            hour10 = 0; hour1 = 0; min10 = 0; sec10 = 0; min1 = 0; sec1 = 0;
        end
        else if(start) begin
            hour10 = value[3:0];
            hour1 = value[7:4];
            min10 = value[11:8];
            min1 = value[15:12];
            sec10 = value[19:16];
            sec1 = value[23:20];
        end
        else if(source) begin
            if(sec1 > 0)
                sec1 = sec1 - 1;
            else begin
                sec1 = 9;
                if(sec10 > 0)
                    sec10 = sec10 - 1;
                else begin
                    sec10 = 5;
                    if(min1 > 0)
                        min1 = min1 - 1;
                    else begin
                        min1 = 9;
                        if(min10 > 0)
                            min10 = min10 - 1;
                        else begin
                            min10 = 5;
                            if(hour1 > 0)
                                hour1 = hour1 - 1;
                            else begin
                                hour1 = 9;
                                if(hour10 > 0)
                                    hour10 = hour10 - 1;
                                // do nothing when 00:00:00
                            end        
                        end
                    end
                end
            end
        end
    end
    
endmodule
