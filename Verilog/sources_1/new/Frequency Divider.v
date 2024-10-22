`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/03 12:13:20
// Design Name: 
// Module Name: Frequency Divider
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


module clock_divider #(parameter N = 100)(
    input clk, reset,
    output reg clk_div
    );
    
    reg [$clog2(N) - 1 : 0] count;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            clk_div = 0;
            count = 0;
        end
        else begin
            if(count < N-1) begin
                count = count + 1;
                clk_div = 0;
            end
            else begin
                count = 0;
                clk_div = 1;
            end
        end
    end
endmodule

module clock_divider_clear_enable #(parameter N = 100)(
    input clk, reset, clear, enable,
    output reg clk_div
    );
    
    reg [$clog2(N) - 1 : 0] count;
    always @(posedge clk, posedge reset) begin
        if(reset || clear) begin
            clk_div = 0;
            count = 0;
        end
        else if(enable) begin
            if(count < N-1) begin
                count = count + 1;
                clk_div = 0;
            end
            else begin
                count = 0;
                clk_div = 1;
            end
        end
    end
endmodule

module source_divider #(parameter N = 1000)(
    input clk, reset, source,
    output reg clk_div
);

    reg [$clog2(N) - 1 : 0] count;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            count = 0;
            clk_div = 0;
        end
        else if(source) begin
            if(count < N-1) begin
                count = count + 1;
            end
            else begin
                count = 0;
                clk_div = 1;
            end
        end
        else clk_div = 0;
    end

endmodule

module source_divider_clear_enable #(parameter N = 1000)(
    input clk, reset, clear, enable, source,
    output reg clk_div
);

    reg [$clog2(N) - 1 : 0] count;
    always @(posedge clk, posedge reset) begin
        if(reset || clear) begin
            count = 0;
            clk_div = 0;
        end
        else if(source && enable) begin
            if(count < N-1) begin
                count = count + 1;
            end
            else begin
                count = 0;
                clk_div = 1;
            end
        end
        else clk_div = 0;
    end

endmodule
