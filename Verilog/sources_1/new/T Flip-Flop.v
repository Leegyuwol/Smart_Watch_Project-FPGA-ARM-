`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/03 20:23:33
// Design Name: 
// Module Name: t_flip_flop
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


module t_flip_flop(
    input clk, reset, t,
    output reg q
    );
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            q = 0;
        end
        else if(t) begin
            q = ~q;
        end
    end
    
endmodule
