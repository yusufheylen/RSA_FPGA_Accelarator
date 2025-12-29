`timescale 1ns / 1ps

//Adder of set width for a segment, implements the FPGA's default (optimal) adder 
module adder_segment #(parameter WIDTH = 32) (
    input  [WIDTH-1:0]  a,
    input  [WIDTH-1:0]  b,
    input               carry_in,
    output [WIDTH-1:0]  sum,
    output              carry_out
  );
  
  assign {carry_out, sum} = a + b + carry_in;
  
  //assign sum = a + b + carry_in;

endmodule

