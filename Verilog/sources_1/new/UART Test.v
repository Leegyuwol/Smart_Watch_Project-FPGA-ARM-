`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/25 12:02:17
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

module tb_uart_echo ();
    
    reg clk, reset;
    reg RsRx;
    wire RsTx;
    
    test_uart_echo_string DUT (
        clk, reset,
        RsRx,
        RsTx
    );
    
    // system clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // reset signal generation
    initial begin
        reset = 0;
        reset = 1;
        #10 reset =0;
    end
    
    // module input initialization
    initial begin
        RsRx = 1;
    end
    
    // uart clock only for reference
    reg uart_clock;
    initial begin
        uart_clock = 0;
        forever #104160 uart_clock = ~uart_clock;
    end
    
    // test bench main routine
    reg [7:0] sample_string [0:11] = "Hello World\n";
    integer byte_index, bit_index;
    initial begin
        byte_index = 0;
        bit_index = 0;
        #1000;
        for (byte_index=0; byte_index<12; byte_index=byte_index+1) begin
            RsRx = 0; #104160;  //; Start bit 
            
            for (bit_index=0; bit_index<8; bit_index=bit_index+1) begin
                RsRx = sample_string[byte_index][bit_index];
                #104160;
            end
            RsRx = 1; #104160;  // Stop bit
//            #200000;
        end
        #1000;
        $finish;
    end

endmodule

module test_uart_tx(
    input clk, reset,
    input [55:0] data_buffer,
    output RsTx
);

    reg [7:0] data_in;
    reg send;
    wire busy;
    uart_tx test(
        .clk(clk), .reset(reset), .data_in(data_in), .send(send), .tx(RsTx), .busy(busy)
    );
    
    reg [2:0] state, next_state;
    parameter IDLE = 3'b001;
    parameter SEND = 3'b010;
    parameter WAIT = 3'b100;
    always @(negedge clk, posedge reset) begin
        if(reset) state <= IDLE;
        else state <= next_state;
    end
    
    wire clk_div;
    clock_divider #(1_000_000_00) triggering(
        clk, reset, clk_div
    );
    
    reg [2:0] i;
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            next_state <= IDLE;
            data_in <= 0;
            send <= 0;
            i <= 0;
        end
        else begin
            case(state)
                IDLE: begin
                    send <= 0;
                    if(clk_div) begin
                        i <= 0;
                        next_state <= SEND;
                    end
                end
                SEND: begin
                    if(!busy) begin
                        case(i)
                            6: data_in <= data_buffer[55:48];
                            5: data_in <= data_buffer[47:40];
                            4: data_in <= data_buffer[39:32];
                            3: data_in <= data_buffer[31:24];
                            2: data_in <= data_buffer[23:16];
                            1: data_in <= data_buffer[15:8];
                            0: data_in <= data_buffer[7:0];
                        endcase
                        send <= 1;
                        next_state <= WAIT;
                    end
                end
                WAIT: begin
                    send <= 0;
                    if(busy) begin
                        next_state <= WAIT;
                    end
                    else if(i < 6) begin
                        i <= i + 1;
                        next_state <= SEND;
                    end else begin
                        next_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
endmodule

module test_uart_echo(
    input clk, reset,
    input RsRx,
    output RsTx
    );
    
    reg [7:0] data_in;
    reg send;
    wire busy;
    uart_tx echo(
        .clk(clk), .reset(reset), .data_in(data_in), .send(send),
        .tx(RsTx), .busy(busy)
    );
    
    wire [7:0] data_out;
    wire valid;
    uart_rx reception(
        .clk(clk), .reset(reset), .rx(RsRx),
        .data_out(data_out), .valid(valid)
    );
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            data_in = 0;
            send = 0;
        end
        else if(valid && !busy) begin
            data_in = data_out;
            send = 1;
        end
        else
            send = 0;
    end
    
endmodule

module test_uart_echo_string(
    input clk, reset,
    input RsRx,
    output RsTx
);

    reg [7:0] data_in;
    reg send;
    wire busy;
    uart_tx test(
        .clk(clk), .reset(reset), .data_in(data_in), .send(send), .tx(RsTx), .busy(busy)
    );
    
    wire [7:0] data_out;
    wire valid;
    uart_rx reception(
        .clk(clk), .reset(reset), .rx(RsRx),
        .data_out(data_out), .valid(valid)
    );
    
    reg [1:0] state, next_state;
    parameter IDLE = 0;
    parameter RX = 1;
    parameter TX = 2;
    always @(negedge clk, posedge reset) begin
        if(reset) state = RX;
        else state = next_state;
    end
    
    reg [7:0] data_buffer [0:11];
    
    reg [3:0] index;
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            next_state = RX;
            data_in = 0;
            send = 0;
            for(index = 0; index < 12; index = index + 1)
                data_buffer[index] = 0;
            index = 0;
        end
        else begin
            case(state)
                IDLE: begin
                    send = 0;
                    if(!busy)
                        next_state = RX;
                end
                RX: begin
                    if(valid) begin
                        data_buffer[index] = data_out;
                        index = index + 1;
                        if(index > 11) begin
                            index = 0;
                            next_state = TX;
                        end
                    end
                end
                TX: begin
                    if(busy)
                        send = 0;
                    // 그냥 else로 하면 busy가 0이 됨과 동시에 send가 1(엣지)가 된다
                    // busy가 0이 되고 그 다음 클럭에 send가 1이 되도록 조건문 추가
                    else if(!send) begin
                        data_in = data_buffer[index];
                        send = 1;
                        index = index + 1;
                        if(index > 11) begin
                            index = 0;
                            next_state = IDLE;
                        end
                    end
                end
            endcase
        end
    end
    
endmodule
