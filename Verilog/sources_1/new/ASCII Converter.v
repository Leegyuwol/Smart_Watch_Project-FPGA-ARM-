`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/17 21:01:59
// Design Name: 
// Module Name: ASCII Converter
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


module ascii_convert_time(
    input [23:0] value,
    output [47:0] ascii_value
);

    assign ascii_value[7:0]     = value[3:0]    + 48;
    assign ascii_value[15:8]    = value[7:4]    + 48;
    assign ascii_value[23:16]   = value[11:8]   + 48;
    assign ascii_value[31:24]   = value[15:12]  + 48;
    assign ascii_value[39:32]   = value[19:16]  + 48;
    assign ascii_value[47:40]   = value[23:20]  + 48;

endmodule

module ascii_convert_date(
    input [31:0] value,
    output [63:0] ascii_value
);

    assign ascii_value[7:0]     = value[3:0]    + 48;
    assign ascii_value[15:8]    = value[7:4]    + 48;
    assign ascii_value[23:16]   = value[11:8]   + 48;
    assign ascii_value[31:24]   = value[15:12]  + 48;
    assign ascii_value[39:32]   = value[19:16]  + 48;
    assign ascii_value[47:40]   = value[23:20]  + 48;
    assign ascii_value[55:48]   = value[27:24]  + 48;
    assign ascii_value[63:56]   = value[31:28]  + 48;

endmodule

module ascii_convert_sw(
    input [19:0] value,
    output [39:0] ascii_value
);

    assign ascii_value[7:0]     = value[3:0]    + 48;
    assign ascii_value[15:8]    = value[7:4]    + 48;
    assign ascii_value[23:16]   = value[11:8]   + 48;
    assign ascii_value[31:24]   = value[15:12]  + 48;
    assign ascii_value[39:32]   = value[19:16]  + 48;

endmodule

module ascii_convert_timer(
    input [15:0] value,
    output [31:0] ascii_value
);

    assign ascii_value[7:0]     = value[3:0]    + 48;
    assign ascii_value[15:8]    = value[7:4]    + 48;
    assign ascii_value[23:16]   = value[11:8]   + 48;
    assign ascii_value[31:24]   = value[15:12]  + 48;

endmodule

module weekday_converter(
    input [3:0] weekday,
    output reg [23:0] ascii_weekday
);
    parameter SUN = 0, MON = 1, TUE = 2, WED = 3, THU = 4, FRI = 5, SAT = 6;
    always @(*) begin
        case(weekday)
            SUN: begin
                ascii_weekday[7:0]  = "S";
                ascii_weekday[15:8] = "U";
                ascii_weekday[23:16]= "N";
            end
            MON: begin
                ascii_weekday[7:0]  = "M";
                ascii_weekday[15:8] = "O";
                ascii_weekday[23:16]= "N";
            end
            TUE: begin
                ascii_weekday[7:0]  = "T";
                ascii_weekday[15:8] = "U";
                ascii_weekday[23:16]= "E";
            end
            WED: begin
                ascii_weekday[7:0]  = "W";
                ascii_weekday[15:8] = "E";
                ascii_weekday[23:16]= "D";
            end
            THU: begin
                ascii_weekday[7:0]  = "T";
                ascii_weekday[15:8] = "H";
                ascii_weekday[23:16]= "U";
            end
            FRI: begin
                ascii_weekday[7:0]  = "F";
                ascii_weekday[15:8] = "R";
                ascii_weekday[23:16]= "I";
            end
            SAT: begin
                ascii_weekday[7:0]  = "S";
                ascii_weekday[15:8] = "A";
                ascii_weekday[23:16]= "T";
            end
            default: begin
                ascii_weekday[7:0]  = "M";
                ascii_weekday[15:8] = "O";
                ascii_weekday[23:16]= "N";
            end
        endcase
    end
endmodule