`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/17 21:03:58
// Design Name: 
// Module Name: Decimal Converter
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


module bin_to_dec(
    input [11:0] bin,
    output reg [15:0] bcd
    );

    reg [3:0] i;

    always @(bin) begin
        bcd = 0;
        // 12-bit 처리 위해 12번 반복
        for (i=0;i<12;i=i+1) begin
            // bcd 레지스터를 왼쪽으로 한 비트 시프트하고
            // 현재 이진 입력의 비트를 bcd의 최하위 비트에 추가
            bcd = {bcd[14:0], bin[11-i]};
            if(i < 11 && bcd[3:0] > 4) bcd[3:0] = bcd[3:0] + 3;
            if(i < 11 && bcd[7:4] > 4) bcd[7:4] = bcd[7:4] + 3;
            if(i < 11 && bcd[11:8] > 4) bcd[11:8] = bcd[11:8] + 3;
            if(i < 11 && bcd[15:12] > 4) bcd[15:12] = bcd[15:12] + 3;
        end
    end
endmodule

module bin_to_bcd2(
    input [6:0] bin,      // 7비트 바이너리 입력
    output reg [7:0] bcd  // 8비트 BCD 출력
    );

    reg [3:0] i; // 루프 카운터

    always @(bin) begin
        bcd = 0; // BCD를 0으로 초기화
        
        // 7-bit 처리 위해 7번 반복
        for (i = 0; i < 7; i = i + 1) begin
            // BCD 레지스터를 왼쪽으로 한 비트 시프트하고
            // 현재 이진 입력의 비트를 BCD의 최하위 비트에 추가
            bcd = {bcd[6:0], bin[6-i]};
            
            // 각 BCD 자리수에 대해 5 이상인 경우 +3 보정
            if (i < 6 && bcd[3:0] > 4) bcd[3:0] = bcd[3:0] + 3;
            if (i < 6 && bcd[7:4] > 4) bcd[7:4] = bcd[7:4] + 3;
        end
    end
endmodule