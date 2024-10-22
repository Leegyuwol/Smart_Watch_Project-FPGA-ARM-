`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/19 09:34:09
// Design Name: 
// Module Name: Test
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


module tb_edge_detector();

    reg clk, reset, cp;
    wire pedge;
    edge_detector_p uur(
        clk, reset, cp, pedge
    );
    
    always #5 clk = ~clk;
    always #100 cp = ~cp;
    
    initial begin
        reset = 1;
        clk = 0;
        cp = 0;
        #10
        
        reset = 0;
        #1000
        
        $finish;
    end
    
endmodule

module test_btn_nedge(
    input clk, reset, btn,
    output led
);
    
    wire btn_nedge;
    short_button_nedge Button(
        clk, reset, btn, btn_nedge
    );
    
    t_flip_flop LED(
        .clk(clk), .reset(reset),
        .t(btn_nedge), .q(led)
    );
    
endmodule

module test_btn_pedge(
    input clk, reset, btn,
    output reg [15:0] led
);
    
    wire btn_pedge;
    long_short_button_pedge Button(
        clk, reset, btn, btn_pedge
    );
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            led = 0;
        end
        else if(btn_pedge) begin
            if(led != 16'hffff) begin
                led = (led << 1) | 1'b1;
            end
            else begin
                led = 16'h0000;
            end
        end
    end
    
endmodule

module generator_1ms(
    input clk, reset,
    output clk_div
);

    reg enable = 1;
    wire source;
    
    clock_divider #(100) test1(
        .clk(clk), .reset(reset), .enable(enable),
        .clk_div(source)
    );
    
    source_divider #(1000) test2(
        clk, reset, enable, source,
        clk_div
    );

endmodule

module tb_generator_1ms();

    reg clk, reset;
    wire clk_div;

    generator_1ms uut(
        clk, reset, clk_div
    );

    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        reset = 1;
        #10
        reset = 0;

        // 시뮬레이션이 충분히 길게 실행되도록 시간 증가
        #10_000_000 
        
        $finish;
    end

    initial begin
        // clk_div의 변화를 모니터링하기 위해 $monitor 사용
        $monitor("Time: %0t | clk_div: %b", $time, clk_div);
    end

endmodule

module tb_bcd_counter();

    reg clk, reset;
    wire source;
    wire [2:0] bcd10;
    wire [3:0] bcd1;
    
    // 1us edge
    clock_divider #(100) tb(
        .clk(clk), .reset(reset), .clk_div(source) 
    );
    
    bcd_counter uur(
        clk, reset, source, bcd10, bcd1
    );
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 0;
        reset = 1;
        #10
        reset = 0;
        
        #1000_000
        $finish;
    end

endmodule

module test_i2c(
    input clk, reset,
    input [1:0] btn,
    output sda, scl
);
    
    reg comm_start;
    reg [7:0] data;
    i2c test(
        .clk(clk), .reset(reset),
        .data(data), .comm_start(comm_start), .sda(sda), .scl(scl)
    );
    
    wire [1:0] btn_nedge;
    short_button_nedge button1(.clk(clk), .reset(reset), .btn(btn[0]), .btn_nedge(btn_nedge[0]));
    short_button_nedge button2(.clk(clk), .reset(reset), .btn(btn[1]), .btn_nedge(btn_nedge[1]));
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            data = 0;
            comm_start = 0;
        end
        /* LCD backlight off */
        else if(btn_nedge[0]) begin
            data = 0;
            comm_start = 1;
        end
        /* LCD backlight on */
        else if(btn_nedge[1]) begin
            data = 8'b0000_1000;
            comm_start = 1;
        end
        else comm_start = 0;
    end
    
endmodule

module test_i2c_lcd(
    input clk, reset,
    input [2:0] btn,
    output sda, scl
);
    
    reg [7:0] data;
    reg send;
    reg rs;
    wire busy;
    reg init_flag;
    i2c_lcd test(
        .clk(clk), .reset(reset),
        .send_buffer(data), .send(send), .rs(rs), .busy(busy), .sda(sda), .scl(scl)
    );
    
    wire [2:0] btn_nedge;
    short_button_nedge button0(.clk(clk), .reset(reset), .btn(btn[0]), .btn_nedge(btn_nedge[0]));
    short_button_nedge button1(.clk(clk), .reset(reset), .btn(btn[1]), .btn_nedge(btn_nedge[1]));
    short_button_nedge button2(.clk(clk), .reset(reset), .btn(btn[2]), .btn_nedge(btn_nedge[2]));
    
    reg [4:0] state, next_state;
    parameter IDLE          = 5'b00001;
    parameter INIT          = 5'b00010;
    parameter SEND_DATA     = 5'b00100;
    parameter CURSOR_MOVE   = 5'b01000;
    parameter SEND_COMMAND  = 5'b10000;
    
    always @(negedge clk, posedge reset) begin
        if(reset) state = IDLE;
        else state = next_state;
    end
    
    integer count;
    reg [6:0] cnt_data;
    reg command;
    reg [7:0] hello_world [0:10]; // Array to store "Hello World"
    
    initial begin
        hello_world[0] = "H";
        hello_world[1] = "e";
        hello_world[2] = "l";
        hello_world[3] = "l";
        hello_world[4] = "o";
        hello_world[5] = " ";
        hello_world[6] = "W";
        hello_world[7] = "o";
        hello_world[8] = "r";
        hello_world[9] = "l";
        hello_world[10] = "d";
    end
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            next_state <= IDLE;
            init_flag <= 0;
            data <= 0;
            send <= 0;
            rs <= 0;
            count <= 0;
            cnt_data <= 0;
            command <= 0;
        end
        else begin
            case(state)
                IDLE: begin
                    if(init_flag) begin
                        if(btn_nedge[0])
                            next_state <= SEND_DATA;
                        else if(btn_nedge[1]) begin
                            command <= 0;
                            next_state <= SEND_COMMAND;
                        end
                        else if(btn_nedge[2]) begin
                            command <= 1;
                            next_state <= SEND_COMMAND;
                        end
                    end
                    else begin
                        if(count < 40_000_00)
                            count <= count + 1;
                        else begin
                            count <= 0;
                            next_state <= INIT;
                        end
                    end
                end
                INIT: begin
                    if(busy) begin
                        send <= 0;
                        if(cnt_data > 5) begin
                            cnt_data <= 0;
                            next_state <= IDLE;
                            init_flag <= 1;
                        end
                    end
                    else if(!send) begin
                        case(cnt_data)
                            0: data <= 8'h33;    // send 0011, 0011
                            1: data <= 8'h32;    // send 0011, 0010
                            2: data <= 8'h28;    // N = 1, F = 0
                            3: data <= 8'h0C;    // send 0000, 1100
                            4: data <= 8'h01;    // send 0000, 0001
                            5: data <= 8'h06;    // I/D = 1, S = 0
                        endcase
                        send <= 1;
                        cnt_data <= cnt_data + 1;
                    end
                end
                SEND_DATA: begin
                    if(busy) begin
                        send <= 0;
                    end
                    else if(!send) begin
                        if(cnt_data < 11) begin
                            rs <= 1;
                            data <= hello_world[cnt_data];
                            send <= 1;
                            cnt_data <= cnt_data + 1;
                        end
                        else begin
                            cnt_data <= 0;
                            next_state <= CURSOR_MOVE;
                        end
                    end
                end
                CURSOR_MOVE: begin
                    if(busy) begin
                        send <= 0;
                        next_state <= IDLE;
                    end
                    else begin
                        rs <= 0;
                        data <= 8'h80;
                        send <= 1;
                    end
                end
                SEND_COMMAND: begin
                    /* Scroll to Left */
                    if(command == 0) begin
                        if(busy) begin
                            send <= 0;
                            command <= 0;
                            next_state <= IDLE;
                        end
                        else begin
                            rs <= 0;
                            data <= 8'h1C;
                            send <= 1;
                        end
                    end
                    /* Scroll to Right */
                    else if(command == 1) begin
                        if(busy) begin
                            send <= 0;
                            command <= 0;
                            next_state <= IDLE;
                        end
                        else begin
                            rs <= 0;
                            data <= 8'h18;
                            send <= 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule

module tb_day_of_week;

    reg clk;
    reg reset;
    reg [3:0] day10, day1;
    reg [3:0] month10, month1;
    reg [11:0] year;
    wire [3:0] weekday;

    // Instantiate the day_of_week module
    day_of_week dut (
        .clk(clk),
        .reset(reset),
        .day10(day10),
        .day1(day1),
        .month10(month10),
        .month1(month1),
        .year(year),
        .weekday(weekday)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        day10 = 0;
        day1 = 1;
        month10 = 0;
        month1 = 1;
        year = 2024;
        
        // Release reset
        #10;
        reset = 0;
        
        // Test case 1: January 1, 2024 (should be Monday)
        #10;
        day10 = 0; day1 = 1;
        month10 = 0; month1 = 1;
        year = 2024;
        
        #10;
        month1 = month1 + 1;
        #10;
        month1 = month1 + 1;
        #10;
        month1 = month1 + 1;
        #10;
        month1 = month1 + 1;
        #10;
        month1 = month1 + 1;
        #10;
        month1 = month1 + 1;
        #10;
        month1 = month1 + 1;
        #10;
        month1 = month1 + 1;
        #10;
        month10 = 1; month1 = 0;

        $finish;
    end
endmodule