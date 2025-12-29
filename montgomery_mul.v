`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2024 05:39:54 PM
// Design Name: 
// Module Name: montgomery_mul
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


module montgomery_mul(
    input           clk,
    input           resetn,
    
    input [1023:0]  A,
    input [1023:0]  B,
    input [1023:0]  M,
    
    output [1023:0]  result,
    output           done
    );
    
    reg [1023:0]    regA;
    reg [1023:0]    regB;
    reg [1023:0]    regM;
    
    reg [1025:0]    reg3B;
    reg [1025:0]    reg3M;
    
    reg [1024:0]    regC;
    reg [1023:0]    regS;
    reg             carry;
    
    
    reg [8:0]       i_counter;          // i_MAX = 511 --> 9 bits
    reg             currentState;              // TODO: the state needs X bits
    reg             nextState;              // TODO: the state needs X bits
    
    
//    localparam STATE_initial = 0'b0000,
//               STATE_0       = 0'b0001,
//               STATE_1       = 0'b0011,
//               STATE_2       = 0'b0010,
//               STATE_3       = 0'b0110,
//               STATE_4       = 0'b0111;
//                // TBA
    
    
    
    // DataPath (combinational)
    always @(*) begin
        /*
        To Do:
            - instantiate adder (WITH sub/add option)
            - connect the MUX's to the adder
            - comparator & output stuff
            
            - connect the CSA stuff
        */
        
        
        
    end
    
    
    
    // Update all the registers (clocked)
    always @(posedge clk) begin
        nextState <= currentState;
        
//        case (currentState)
//             STATE_initial : begin
//            end
//        endcase

    end
    
    
    
    // FSM (combinational)
    always @(*) begin
    end
    
    
    
endmodule




module adder_TBA(
    input           clk,
    input [1026:0]  x_in,
    input [1026:0]  y_in,
    input           c_in,
    input           add_sub,        // add_sub==1 ? (do addition) : (do subtraction)
    
    output [1026:0] z_out,
    output          c_out
    );
endmodule