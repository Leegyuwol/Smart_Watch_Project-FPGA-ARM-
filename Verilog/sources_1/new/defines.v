`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/20 09:21:21
// Design Name: 
// Module Name: DEFINES
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

/* If your device's frequency is not 100MHz, please change this value to match the system frequency */
`define CLOCK_FREQ 100_000_000

/* You can modify this value to change the order in which the modes switch */
`define WATCH       0
`define STOP_WATCH  1
`define TIMER       2
`define ALARM       3

/* You can modify this value to change the order in which the cursor moves */
`define YEAR        5
`define MONTH       4
`define DAY         3
`define HOUR        2
`define MIN         1
`define SEC         0

/* You don't have to modify this value */
`define CUS_HOUR    1
`define CUS_MIN     2
`define CUS_SEC     3
`define CUS_YEAR    4
`define CUS_MONTH   5
`define CUS_DAY     6