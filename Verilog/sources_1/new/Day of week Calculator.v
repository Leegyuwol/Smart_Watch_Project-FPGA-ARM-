`timescale 1ns / 1ps


module day_of_week(
    input clk, reset,
    input sync,
    input [3:0] weekday_in,
    input [3:0] day10, day1,    // 날짜
    input [3:0] month10, month1,// 월
    input [11:0] year,          // 연도
    output reg [3:0] weekday    // 요일 (0: 일요일, ..., 6: 토요일)
    );

    /* 윤년 계산 함수 */
    function is_leap_year(input [11:0] y);
        begin
            is_leap_year = ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0);
        end
    endfunction
    
    parameter IDLE = 0,
              SYNC = 1,
              CALC = 2;
    
    reg [1:0] state, next_state;
    always @(negedge clk, posedge reset) begin
        if(reset) state = IDLE;
        else state = next_state;
    end
    
    wire [4:0] day = day10 * 10 + day1;
    wire [3:0] month = month10 * 10 + month1;
    reg [4:0] prev_day;
    reg [3:0] prev_month;
    reg [11:0] prev_year;
    
    /* 요일 계산 */
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            next_state = IDLE;
            weekday = 1;
            prev_year = 2024;
            prev_month = 1;
            prev_day = 1;
        end
        else begin
            case(state)
                IDLE: begin
                    if(sync)
                        next_state = SYNC;
                    else if(prev_day != day || prev_month != month || prev_year != year)
                        next_state = CALC;
                end
                SYNC: begin
                    weekday = weekday_in[3:0];
                    prev_year = year;
                    prev_month = month;
                    prev_day = day;
                    next_state = IDLE;
                end
                CALC: begin
                    // 일
                    if(prev_day != day) begin
                        weekday = weekday + 1;
                        if(weekday > 6)
                            weekday = weekday % 7;
                        prev_day = day;
                        prev_month = month;
                        prev_year = year;
                    end
                    // 월
                    else if(prev_month != month) begin
                        case(prev_month)
                            4, 6, 9, 11: weekday = weekday + 2;
                            2: weekday = weekday + (is_leap_year(year) ? 1 : 0);
                            default: weekday = weekday + 3;
                        endcase
                        if(weekday > 6) begin
                            weekday = weekday % 7;
                        end
                        prev_month = month; // 현재 월로 업데이트
                        prev_year = year;
                    end
                    // 연
                    else if(prev_year != year) begin
                        weekday = weekday + (is_leap_year(prev_year) ? 2 : 1);
                        if(weekday > 6)
                            weekday = weekday % 7;
                        prev_year = year;
                    end
                    next_state = IDLE;
                end
            endcase
        end
    end

endmodule