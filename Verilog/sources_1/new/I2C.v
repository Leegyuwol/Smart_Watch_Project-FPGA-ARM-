`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/13 09:42:36
// Design Name: 
// Module Name: I2C
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

module i2c_lcd_print(
    /* COMMON INPUT PORT */
    input clk, reset,
    input [1:0] mode,
    input raising,
    input [2:0] cursor_pos,
    /* WATCH */
    input [47:0] ascii_time_value,
    input [63:0] ascii_date_value,
    input [3:0] weekday,
    /* STOP WATCH */
    input [39:0] ascii_sw_value,
    /* TIMER */
    input [47:0] ascii_timer_value,
    /* ALARM WATCH */
    input [31:0] ascii_alarm_value,
    input alarm_on,
    /* OUTPUT PORT */
    output sda, scl
);
    
    reg [7:0] data;
    reg send, rs;
    wire busy;
    i2c_lcd send_byte(
        .clk(clk), .reset(reset),
        .send_buffer(data), .send(send), .rs(rs), .busy(busy), .sda(sda), .scl(scl)
    );
    
    reg [3:0] state, next_state;
    parameter IDLE              = 0;
    parameter INIT              = 1;
    parameter SEND_DATA1        = 2;
    parameter CURSOR_MOVE1      = 3;
    parameter SEND_DATA2        = 4;
    parameter CURSOR_MOVE2      = 5;
    parameter SET_BLINK_CURSOR  = 6;
    parameter BLINK             = 7;
    parameter MAKE_IMAGE1       = 8;
    parameter MAKE_IMAGE2       = 9;
    parameter MAKE_IMAGE3       = 10;
    
    always @(negedge clk, posedge reset) begin
        if(reset) state = IDLE;
        else state = next_state;
    end
    
    wire [7:0] data_buffer1 [0:14]; // Array to store characters
    wire [7:0] data_buffer2 [0:13];
    
    wire [23:0] ascii_weekday;
    weekday_converter make_weekday_string(weekday, ascii_weekday);
    
    assign data_buffer1[0]  = (mode == `WATCH)? ascii_time_value[7:0]   : (mode == `STOP_WATCH)? ascii_sw_value[7:0]   : (mode == `TIMER)? ascii_timer_value[7:0]   : ascii_alarm_value[7:0];
    assign data_buffer1[1]  = (mode == `WATCH)? ascii_time_value[15:8]  : (mode == `STOP_WATCH)? ascii_sw_value[15:8]  : (mode == `TIMER)? ascii_timer_value[15:8]  : ascii_alarm_value[15:8];
    assign data_buffer1[2]  = ":";
    assign data_buffer1[3]  = (mode == `WATCH)? ascii_time_value[23:16] : (mode == `STOP_WATCH)? ascii_sw_value[23:16] : (mode == `TIMER)? ascii_timer_value[23:16] : ascii_alarm_value[23:16];
    assign data_buffer1[4]  = (mode == `WATCH)? ascii_time_value[31:24] : (mode == `STOP_WATCH)? ascii_sw_value[31:24] : (mode == `TIMER)? ascii_timer_value[31:24] : ascii_alarm_value[31:24];
    assign data_buffer1[5]  = (mode == `ALARM)? " " : ":";
    assign data_buffer1[6]  = (mode == `WATCH)? ascii_time_value[39:32] : (mode == `STOP_WATCH)? ascii_sw_value[39:32] : (mode == `TIMER)? ascii_timer_value[39:32] : " ";
    assign data_buffer1[7]  = (mode == `WATCH)? ascii_time_value[47:40] : (mode == `STOP_WATCH)? " "                   : (mode == `TIMER)? ascii_timer_value[47:40] : " ";
    assign data_buffer1[8]  = " ";
    assign data_buffer1[`WATCH + 9]  = (mode == `WATCH)? 8'h00 : 8'h01;
    assign data_buffer1[`TIMER + 9] = (mode == `TIMER)? 8'h00 : 8'h01;
    assign data_buffer1[`STOP_WATCH + 9] = (mode == `STOP_WATCH)? 8'h00 : 8'h01;
    assign data_buffer1[`ALARM + 9] = (mode == `ALARM)? 8'h00 : 8'h01;
    assign data_buffer1[13] = " ";
    assign data_buffer1[14] = alarm_on? 8'h02 : " ";
    
    assign data_buffer2[0]  = ascii_date_value[31:24];
    assign data_buffer2[1]  = ascii_date_value[23:16];
    assign data_buffer2[2]  = ascii_date_value[15:8];
    assign data_buffer2[3]  = ascii_date_value[7:0];
    assign data_buffer2[4]  = "/";
    assign data_buffer2[5]  = ascii_date_value[39:32];
    assign data_buffer2[6]  = ascii_date_value[47:40];
    assign data_buffer2[7]  = "/";
    assign data_buffer2[8]  = ascii_date_value[55:48];
    assign data_buffer2[9]  = ascii_date_value[63:56];
    assign data_buffer2[10] = " ";
    assign data_buffer2[11] = ascii_weekday[7:0];
    assign data_buffer2[12] = ascii_weekday[15:8];
    assign data_buffer2[13] = ascii_weekday[23:16];
    
    parameter real BLINK_FREQ = 1 / 0.4; // 0.4s
    parameter integer BLINK_PRESCALER = `CLOCK_FREQ / BLINK_FREQ;
    
    reg [$clog2(BLINK_PRESCALER)-1 : 0] cnt_blink;
    reg [3:0] index;
    reg init_flag, blink_flag;
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            next_state = IDLE;
            data = 0;
            send = 0;
            rs = 0;
            index = 0;
            cnt_blink = 0;
            init_flag = 0;
            blink_flag = 0;
        end
        else begin
            if(cnt_blink < BLINK_PRESCALER - 1)
                cnt_blink = cnt_blink + 1;
            else begin
                cnt_blink = 0;
                blink_flag = ~blink_flag;
            end
            case(state)
                IDLE: begin
                    if(init_flag) begin
                        if(!busy) begin
                            if(blink_flag && cursor_pos && !raising)
                                next_state = SET_BLINK_CURSOR;
                            else
                                next_state = SEND_DATA1;
                        end
                    end
                    else
                        next_state = INIT;
                end
                INIT: begin
                    if(busy)
                        send = 0;
                    else if(!send) begin
                        case(index)
                            0: data = 8'h33;    // send 0011, 0011
                            1: data = 8'h32;    // send 0011, 0010
                            2: data = 8'h28;    // N = 1, F = 0
                            3: data = 8'h0C;    // send 0000, 1100
                            4: data = 8'h01;    // send 0000, 0001
                            5: data = 8'h06;    // I/D = 1, S = 0
                        endcase
                        send = 1;
                        index = index + 1;
                        if(index > 5) begin
                            init_flag = 1;
                            index = 0;
                            next_state = MAKE_IMAGE1;
                        end
                    end
                end
                MAKE_IMAGE1: begin
                    if(busy)
                        send = 0;
                    else if(!send) begin
                        if(!index) begin
                            data = 8'h40;
                            index = 1;
                            send = 1;
                        end
                        else begin
                            if(index < 9) begin
                                case(index)
                                    1: data = 8'b000_00000;
                                    2: data = 8'b000_01110;
                                    3: data = 8'b000_11111;
                                    4: data = 8'b000_11111;
                                    5: data = 8'b000_11111;
                                    6: data = 8'b000_01110;
                                    7: data = 8'b000_00000;
                                    8: data = 8'b000_00000;
                                endcase
                                rs = 1;
                                send = 1;
                                index = index + 1;
                            end
                            else begin
                                index = 0;
                                next_state = MAKE_IMAGE2;
                            end
                        end
                    end
                end
                MAKE_IMAGE2: begin
                    if(busy)
                        send = 0;
                    else if(!send) begin
                        if(!index) begin
                            data = 8'h48;
                            index = 1;
                            rs = 0;
                            send = 1;
                        end
                        else begin
                            if(index < 9) begin
                                case(index)
                                    1: data = 8'b000_00000;
                                    2: data = 8'b000_01110;
                                    3: data = 8'b000_10001;
                                    4: data = 8'b000_10001;
                                    5: data = 8'b000_10001;
                                    6: data = 8'b000_01110;
                                    7: data = 8'b000_00000;
                                    8: data = 8'b000_00000;
                                endcase
                                rs = 1;
                                send = 1;
                                index = index + 1;
                            end
                            else begin
                                index = 0;
                                next_state = MAKE_IMAGE3;
                            end
                        end
                    end
                end
                MAKE_IMAGE3: begin
                    if(busy)
                        send = 0;
                    else if(!send) begin
                        if(!index) begin
                            data = 8'h50;
                            rs = 0;
                            send = 1;
                            index = 1;
                        end
                        else begin
                            if(index < 9) begin
                                case(index)
                                    1: data = 8'b000_00000;
                                    2: data = 8'b000_00100;
                                    3: data = 8'b000_01110;
                                    4: data = 8'b000_01110;
                                    5: data = 8'b000_01110;
                                    6: data = 8'b000_11111;
                                    7: data = 8'b000_00100;
                                    8: data = 8'b000_00000;
                                endcase
                                rs = 1;
                                send = 1;
                                index = index + 1;
                            end
                            else begin
                                index = 0;
                                next_state = CURSOR_MOVE2;
                            end
                        end
                    end
                end
                SEND_DATA1: begin
                    if(busy)
                        send = 0;
                    else if(!send) begin
                        if(index < 15) begin
                            rs = 1;
                            data = data_buffer1[index];
                            send = 1;
                            index = index + 1;
                        end
                        else begin
                            index = 0;
                            next_state = CURSOR_MOVE1;
                        end
                    end
                end
                CURSOR_MOVE1: begin
                    if(busy)
                        send = 0;
                    else if(!send) begin
                        rs = 0;
                        data = 8'hC0;
                        send = 1;
                        next_state = SEND_DATA2;
                    end
                end
                SEND_DATA2: begin
                    if(busy)
                        send = 0;
                    else if(!send) begin
                        if(index < 14) begin
                            rs = 1;
                            data = data_buffer2[index];
                            send = 1;
                            index = index + 1;
                        end
                        else begin
                            index = 0;
                            next_state = CURSOR_MOVE2;
                        end
                    end
                end
                CURSOR_MOVE2: begin
                    if(busy)
                        send = 0;
                    else if(!send) begin
                        rs = 0;
                        data = 8'h80;
                        send = 1;
                        next_state = IDLE;
                    end
                end
                SET_BLINK_CURSOR: begin
                    if(busy)
                        send = 0;
                    else if(!send) begin
                        rs = 0;
                        case(cursor_pos)
                            1 : data = 8'h81;
                            2 : data = 8'h84;
                            3 : data = 8'h87;
                            4 : data = 8'hC3;
                            5 : data = 8'hC6;
                            6 : data = 8'hC9;
                        endcase
                        send = 1;
                        next_state = BLINK;
                    end
                end
                BLINK: begin
                    if(busy)
                        send = 0;
                    else if(!send) begin
                        rs = 1;
                        data = " ";
                        send = 1;
                        next_state = CURSOR_MOVE2;
                    end
                end
            endcase
        end
    end

endmodule

module i2c_lcd(
    input clk, reset,
    input [7:0] send_buffer,
    input send, rs,
    output reg busy,
    output sda, scl
    );
    
    reg [7:0] data;
    reg comm_start;
    i2c single_byte(
        .clk(clk), .reset(reset),
        .data(data), .comm_start(comm_start), .sda(sda), .scl(scl)
    );
    
    wire send_pedge;
    pedge_detector ed(.clk(clk), .reset(reset), .cp(send), .pedge(send_pedge));
    
    reg [2:0] state, next_state;
    parameter IDLE                      = 0,
              /* 4-byte 전송 */
              SEND_HIGH_NIBBLE_DISABLE  = 1,
              SEND_HIGH_NIBBLE_ENABLE   = 2,
              SEND_LOW_NIBBLE_DISABLE   = 3,
              SEND_LOW_NIBBLE_ENABLE    = 4,
              /* 전송 종료 */
              SEND_DISABLE              = 5;
    
    always @(negedge clk, posedge reset) begin
        if(reset) state = IDLE;
        else state = next_state;
    end
    
    // make 200us delay
    parameter DELAY_FREQ = 5000;
    parameter DELAY = `CLOCK_FREQ / DELAY_FREQ;

    reg [$clog2(DELAY)-1 : 0] count;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            next_state = IDLE;
            busy = 0;
            count = 0;
            data = 0;
            comm_start = 0;
        end
        else begin
            case(state)
                IDLE: begin
                    if(send_pedge) begin
                        count = 0;
                        busy = 1;
                        next_state = SEND_HIGH_NIBBLE_DISABLE;
                    end
                end
                SEND_HIGH_NIBBLE_DISABLE: begin
                    // Backlight, enable, read/write
                    // 3'b100 - > backlight on, disable, write
                    if(count < DELAY - 1) begin // 200us
                        count = count + 1;
                        data = {send_buffer[7:4], 3'b100, rs};
                        comm_start = 1;
                    end
                    else begin
                        count = 0;
                        comm_start = 0;
                        next_state = SEND_HIGH_NIBBLE_ENABLE;
                    end
                end
                SEND_HIGH_NIBBLE_ENABLE: begin
                    // Backlight on, enable, write
                    if(count < DELAY - 1) begin
                        count = count + 1;
                        data = {send_buffer[7:4], 3'b110, rs};
                        comm_start = 1;
                    end
                    else begin
                        count = 0;
                        comm_start = 0;
                        next_state = SEND_LOW_NIBBLE_DISABLE;
                    end
                end
                SEND_LOW_NIBBLE_DISABLE: begin
                    if(count < DELAY - 1) begin
                        count = count + 1;
                        data = {send_buffer[3:0], 3'b100, rs};
                        comm_start = 1;
                    end
                    else begin
                        count = 0;
                        comm_start = 0;
                        next_state = SEND_LOW_NIBBLE_ENABLE;
                    end
                end
                SEND_LOW_NIBBLE_ENABLE: begin
                    if(count < DELAY - 1) begin
                        count = count + 1;
                        data = {send_buffer[3:0], 3'b110, rs};
                        comm_start = 1;
                    end
                    else begin
                        count = 0;
                        comm_start = 0;
                        next_state = SEND_DISABLE;
                    end
                end
                SEND_DISABLE: begin
                    if(count < DELAY - 1) begin
                        count = count + 1;
                        data = {send_buffer[3:0], 3'b100, rs};
                        comm_start = 1;
                    end
                    else begin
                        count = 0;
                        comm_start = 0;
                        busy = 0;
                        next_state = IDLE;
                    end
                end
            endcase
        end
    end
    
endmodule

module i2c(
    input clk, reset,
    input [7:0] data,
    input comm_start,
    output reg sda, scl
    );
    
    // consider I2C modules's address as 0'h27
    // r/w = 0 (write mode only)
    wire [7:0] addr_rw = 8'b010_0111_0;
    
    /* Generate 100kHz scl clock */
    parameter SCL_FREQ = 100_000;
    parameter PRESCALER = `CLOCK_FREQ / SCL_FREQ;
    
    reg [$clog2(PRESCALER)-1 : 0] count;
    reg enable;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            count <= 0;
            scl <= 1;
        end
        // 데이터를 보낼 때만 enable을 true로 하여 클럭 생성
        else if(enable) begin
            if(count < PRESCALER - 1) begin
                count <= count + 1;
                // 5us동안 high
                if(count < PRESCALER/2 - 1)
                    scl <= 1;
                // 5us동안 low
                else
                    scl <= 0;
            end
            else
                count <= 0;
        end
        else begin
            count <= 0;
            scl <= 1;
        end
    end
    
    // comm_start의 rising edge에서 start 신호 전송?
    wire comm_start_pedge;
    pedge_detector edge_start(
        .clk(clk), .reset(reset), .cp(comm_start), .pedge(comm_start_pedge) 
    );
    
    // scl의 상승 엣지에서 데이터 읽기
    // scl의 하강 엣지에서 데이터 변경 허용
    wire scl_pedge, scl_nedge;
    pedge_detector pedge_scl(
        .clk(clk), .reset(reset), .cp(scl), .pedge(scl_pedge)
    );
    nedge_detector nedge_scl(.clk(clk), .reset(reset), .cp(scl), .nedge(scl_nedge));
    
    /* State Machine code */
    reg [2:0] state, next_state;
    parameter IDLE          = 0,
              SEND_START    = 1,
              SEND_ADDR     = 2,
              READ_ACK      = 3,
              SEND_DATA     = 4,
              FINISH        = 5,
              SEND_STOP     = 6;
    
    always @(negedge clk, posedge reset) begin
        if(reset)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    /* Main code */
    reg [2:0] i;
    reg stop_flag;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            next_state <= IDLE;
            enable <= 0;
            sda <= 1;
            i <= 7;
            stop_flag <= 0;
        end
        else begin
            // state가 변하는 것은 high(rising edge 이후) 상태에서
            case(state)
                IDLE: begin
                    enable <= 0;
                    sda <= 1;
                    if(comm_start_pedge)
                        next_state <= SEND_START;
                end
                SEND_START: begin
                    // send start bit to slave
                    enable <= 1;
                    sda <= 0;
                    next_state <= SEND_ADDR;
                end
                SEND_ADDR: begin
                    if(scl_nedge) begin
                        sda <= addr_rw[i];
                    end
                    else if(scl_pedge) begin
                        if(i == 0) begin
                            i <= 7;
                            next_state <= READ_ACK;
                        end
                        else
                            i <= i - 1;
                    end
                end
                READ_ACK: begin
                    if(scl_nedge)
                        sda <= 'bz;
                    else if(scl_pedge) begin
                        if(stop_flag) begin
                            stop_flag <= 0;
                            next_state <= FINISH;
                        end
                        else begin
                            stop_flag <= 1;
                            next_state <= SEND_DATA;
                        end
                    end
                end
                SEND_DATA: begin
                    if(scl_nedge) begin
                        sda <= data[i];
                    end
                    else if(scl_pedge) begin
                        if(i == 0) begin
                            i <= 7;
                            next_state <= READ_ACK;
                        end
                        else
                            i <= i - 1;
                    end
                end
                FINISH: begin
                    if(scl_nedge) begin
                        sda <= 0;
                    end
                    else if(scl_pedge)
                        next_state = SEND_STOP;
                end
                SEND_STOP: begin
                    if(count > PRESCALER/4) begin
                        enable <= 0;
                        sda <= 1;
                        next_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
endmodule
