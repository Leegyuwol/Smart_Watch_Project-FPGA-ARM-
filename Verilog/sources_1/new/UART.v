`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/24 13:21:59
// Design Name: 
// Module Name: Uart
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
`define BAUD_RATE 9600
`define BAUD_DIV `CLOCK_FREQ / `BAUD_RATE

module sync_send(
    input clk, reset,
    input btn_sync,
    input [55:0] data_buffer,
    output tx
    );

    reg [7:0] data_in;
    reg send;
    wire busy;
    uart_tx test(
        .clk(clk), .reset(reset), .data_in(data_in), .send(send), .tx(tx), .busy(busy)
    );
    
    reg [1:0] state, next_state;
    parameter IDLE = 0;
    parameter SEND = 1;
    parameter WAIT = 2;
    always @(negedge clk, posedge reset) begin
        if(reset) state <= IDLE;
        else state <= next_state;
    end
    
    reg [2:0] i;
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            next_state = IDLE;
            data_in = 0;
            send = 0;
            i = 0;
        end
        else begin
            case(state)
                IDLE: begin
                    send = 0;
                    if(btn_sync) begin
                        i = 0;
                        next_state = SEND;
                    end
                end
                SEND: begin
                    if(!busy) begin
                        case(i)
                            6: data_in = data_buffer[55:48];
                            5: data_in = data_buffer[47:40];
                            4: data_in = data_buffer[39:32];
                            3: data_in = data_buffer[31:24];
                            2: data_in = data_buffer[23:16];
                            1: data_in = data_buffer[15:8];
                            0: data_in = data_buffer[7:0];
                        endcase
                        send = 1;
                        next_state = WAIT;
                    end
                end
                WAIT: begin
                    send = 0;
                    if(busy) begin
                        next_state = WAIT;
                    end
                    else if(i < 6) begin
                        i = i + 1;
                        next_state = SEND;
                    end
                    else begin
                        next_state = IDLE;
                    end
                end
            endcase
        end
    end
    
endmodule

module sync_receive(
    input clk, reset,
    input rx,
    output [55:0] received_value,
    output reg rx_done
);

    wire [7:0] data_out;
    wire valid;
    uart_rx reception(
        .clk(clk), .reset(reset), .rx(rx),
        .data_out(data_out), .valid(valid)
    );
    
    parameter N = 7;
    reg [7:0] data_buffer [0:N-1];
    reg [4:0] index;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            for(index = 0; index < N; index = index + 1)
                data_buffer[index] = 0;
            index = 0;
            rx_done = 0;
        end
        else if(valid) begin
            data_buffer[index] = data_out;
            index = index + 1;
            if(index > N-1) begin
                index = 0;
                rx_done = 1;
            end
        end
        else
            rx_done = 0;
    end
    
    wire [7:0] year;
    assign year = 10 * data_buffer[0][7:4] + data_buffer[0][3:0];
    
    assign received_value = {
        data_buffer[6], data_buffer[5], data_buffer[4], data_buffer[3],
        data_buffer[2], data_buffer[1], year
    };

endmodule

/* parity bit: 없음, stop bit: 1비트 */
module uart_tx(
    input clk, reset,
    input [7:0] data_in,
    input send,
    output reg tx,  // uart transmission port
    output reg busy
    );
    
    reg [$clog2(`BAUD_DIV)-1 : 0] count;
    reg [3:0] bit_index;
    reg [9:0] tx_shift;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            count = 0;
            bit_index = 0;
            tx_shift = 0;   // idle
            tx = 1;         // start bit가 0이므로, 1로 초기화
            busy = 0;
        end
        /* 전송 시작 */
        else if(send) begin
            count = 0;
            bit_index = 0;
            tx_shift = {1'b1, data_in, 1'b0};
            busy = 1;
        end
        /* 전송 */
        else if(busy) begin
            if(count < `BAUD_DIV - 1)
                count = count + 1;
            else begin
                count = 0;
                tx = tx_shift[0];
                tx_shift = {1'b1, tx_shift[9:1]};
                if(bit_index < 10)
                    bit_index = bit_index + 1;
                else
                    busy = 0;
            end
        end
    end
endmodule

module uart_rx(
    input clk, reset,
    input rx,  // uart reception port
    output reg [7:0] data_out,
    output reg valid
    );
    
    reg [$clog2(`BAUD_DIV)-1 : 0] count;
    reg [3:0] bit_index;
    reg [9:0] rx_shift;
    reg busy;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            count = 0;
            bit_index = 0;
            rx_shift = 0;
            valid = 0;
            busy = 0;
            data_out = 0;
        end
        else if(!busy && !rx)
            busy = 1;
        else if(busy) begin
            if(count < `BAUD_DIV - 1)
                count = count + 1;
            else begin
                count = 0;
                rx_shift = {rx, rx_shift[9:1]};
                bit_index = bit_index + 1;
                if(bit_index > 8) begin
                    bit_index = 0;
                    busy = 0;
                    valid = 1;
                    data_out = rx_shift[8:1];
                end
            end
        end
        else
            valid = 0;
    end
    
endmodule