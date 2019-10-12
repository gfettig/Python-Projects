`timescale 1ns / 1ps

//This module takes two 32 bit values, and returns the difference squared 20ns after x & y are given
module ArithPE(
    input [31:0] x,
    input [31:0] y,
    output [31:0] z
    );
    
    wire [31:0] diff;
    
    assign diff = x - y;
    
    assign z = diff * diff;
endmodule