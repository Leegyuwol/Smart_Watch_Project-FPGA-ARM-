`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/03 20:29:11
// Design Name: 
// Module Name: edge_detector_p
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


module pedge_detector(
    input clk, reset, cp,
    output pedge
    );
    
    reg ff_master, ff_slave;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            ff_master = 0;
            ff_slave = 0;
        end
        else begin
            ff_slave = ff_master;
            ff_master = cp;
        end
    end
    
    assign pedge = (ff_master && !ff_slave)? 1 : 0;
    
endmodule

module nedge_detector(
    input clk, reset, cp,
    output nedge
    );
    
    reg ff_master, ff_slave;
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            ff_master = 0;
            ff_slave = 0;
        end
        else begin
            ff_slave = ff_master;
            ff_master = cp;
        end
    end
    
    assign nedge = (!ff_master && ff_slave)? 1 : 0;
    
endmodule