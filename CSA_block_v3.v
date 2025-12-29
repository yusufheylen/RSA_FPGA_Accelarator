`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2024 05:28:35 PM
// Design Name: MARC MOOONEN
// Module Name: CSA_block_v3
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


module CSA_block_v3(
  input  wire [1024:0] in_C,
  input  wire [1023:0] in_S,
  input  wire carry_in,
  input  wire [1023:0] in_m,
  input  wire [1025:0] in_3m,
  input  wire [1025:0] in_kB_current_a,
  input  wire [1025:0] in_kB_current_b,
  
  output reg [1024:0] out_C,
  output reg [1023:0] out_S,
  output reg carry_out
  
//  output reg [1025:1] C_inter_1,
//  output reg [1025:0] S_inter_1

  
);
    reg [1:0] sel_mux_k_next_a;
    reg [1025:0] MUX_kB_OUT_NEXT_a;
    
    reg [1025:1] C_inter_1_a;
    reg [1025:0] S_inter_1_a;
    
    
    reg [1:0] sel_mux_q_a;
    reg [1025:0] MUX_qM_OUT_a;
    
    reg [1026:1] C_inter_2_a;
    reg [1025:1] S_inter_2_a;
    
    reg [1:0] C10_a;
    reg [1:0] M10;

    reg [1024:0] out_C_a;
    reg [1023:0] out_S_a;
    reg carry_out_a;


    // ITERATION TWO
    reg [1:0] sel_mux_k_next_b;
    reg [1025:0] MUX_kB_OUT_NEXT_b;
    
    reg [1025:1] C_inter_1_b;
    reg [1025:0] S_inter_1_b;
    
    
    reg [1:0] sel_mux_q_b;
    reg [1025:0] MUX_qM_OUT_b;
    
    reg [1026:1] C_inter_2_b;
    reg [1025:1] S_inter_2_b;
    
    reg [1:0] C10_b;

    always @(*) begin

  
    // RUN THE FIRST ITERATION
          
        // add kb to cs
        S_inter_1_a = {in_kB_current_a[1025], in_kB_current_a[1024] ^ in_C[1024], in_kB_current_a[1023:0] ^ in_C[1023:0] ^ in_S[1023:0]};
        C_inter_1_a = {in_kB_current_a[1024] & in_C[1024], ((in_C[1023:0]^in_S[1023:0])&in_kB_current_a[1023:0]) | (in_C[1023:0]&in_S[1023:0])};
        
 
        C10_a = {( (S_inter_1_a[1] ^ C_inter_1_a[1]) ^ (S_inter_1_a[0] & carry_in) ), S_inter_1_a[0] ^ carry_in};
        M10 = in_m[1:0];


        if ( ( (C10_a == 2'b01) && (M10 == 2'b01) ) || ( (C10_a == 2'b11) && (M10 == 2'b11) ) ) begin
            sel_mux_q_a = 2'b11;
        end
        else if ( ( (C10_a == 2'b10) && (M10 == 2'b01) ) || ( (C10_a == 2'b10) && (M10 == 2'b11) ) ) begin
            sel_mux_q_a = 2'b10;
        end
        else if ( ( (C10_a == 2'b11) && (M10 == 2'b01) ) || ( (C10_a == 2'b01) && (M10 == 2'b11) ) ) begin
            sel_mux_q_a = 2'b01;
        end
        else begin
            sel_mux_q_a = 2'b00;
        end


        
        case (sel_mux_q_a)    
            2'b00 : MUX_qM_OUT_a = 1026'b0;
            2'b01 : MUX_qM_OUT_a = {2'b0, in_m};
            2'b10 : MUX_qM_OUT_a = {1'b0, in_m, 1'b0};
            2'b11 : MUX_qM_OUT_a = in_3m;
        endcase



//        S_inter_2 = {S_inter_1[1025:1]^C_inter_1[1025:1]^MUX_qM_OUT[1025:1], S_inter_1[0]^carry_in^MUX_qM_OUT[0]};

        S_inter_2_a = {S_inter_1_a[1025:1]^C_inter_1_a[1025:1]^MUX_qM_OUT_a[1025:1]};       // NOTE: a bit at the 2^0 value SHOULD be ZERO always here, so we don't need it
        
        C_inter_2_a = {((C_inter_1_a[1025:1]^S_inter_1_a[1025:1])&MUX_qM_OUT_a[1025:1]) | (C_inter_1_a[1025:1]&S_inter_1_a[1025:1]), 
                     ((carry_in^S_inter_1_a[0])&MUX_qM_OUT_a[0]) | (carry_in&S_inter_1_a[0])};


        carry_out_a = S_inter_2_a[1] & C_inter_2_a[1];
        out_S_a = S_inter_2_a[1025:2];      // shifting by not passing last two LSB
        out_C_a = C_inter_2_a[1026:2];


    // RUN THE SECOND ITERATION
        
        // add kb to cs
        S_inter_1_b = {in_kB_current_b[1025], in_kB_current_b[1024] ^ out_C_a[1024], in_kB_current_b[1023:0] ^ out_C_a[1023:0] ^ out_S_a[1023:0]};
        C_inter_1_b = {in_kB_current_b[1024] & out_C_a[1024], ((out_C_a[1023:0]^out_S_a[1023:0])&in_kB_current_b[1023:0]) | (out_C_a[1023:0]&out_S_a[1023:0])};
        
 
        C10_b = {( (S_inter_1_b[1] ^ C_inter_1_b[1]) ^ (S_inter_1_b[0] & carry_out_a) ), S_inter_1_b[0] ^ carry_out_a};
//        M10 = in_m[1:0];


        if ( ( (C10_b == 2'b01) && (M10 == 2'b01) ) || ( (C10_b == 2'b11) && (M10 == 2'b11) ) ) begin
            sel_mux_q_b = 2'b11;
        end
        else if ( ( (C10_b == 2'b10) && (M10 == 2'b01) ) || ( (C10_b == 2'b10) && (M10 == 2'b11) ) ) begin
            sel_mux_q_b = 2'b10;
        end
        else if ( ( (C10_b == 2'b11) && (M10 == 2'b01) ) || ( (C10_b == 2'b01) && (M10 == 2'b11) ) ) begin
            sel_mux_q_b = 2'b01;
        end
        else begin
            sel_mux_q_b = 2'b00;
        end


        
        case (sel_mux_q_b)    
            2'b00 : MUX_qM_OUT_b = 1026'b0;
            2'b01 : MUX_qM_OUT_b = {2'b0, in_m};
            2'b10 : MUX_qM_OUT_b = {1'b0, in_m, 1'b0};
            2'b11 : MUX_qM_OUT_b = in_3m;
        endcase



//        S_inter_2 = {S_inter_1[1025:1]^C_inter_1[1025:1]^MUX_qM_OUT[1025:1], S_inter_1[0]^carry_in^MUX_qM_OUT[0]};

        S_inter_2_b = {S_inter_1_b[1025:1]^C_inter_1_b[1025:1]^MUX_qM_OUT_b[1025:1]};       // NOTE: a bit at the 2^0 value SHOULD be ZERO always here, so we don't need it
        
        C_inter_2_b = {((C_inter_1_b[1025:1]^S_inter_1_b[1025:1])&MUX_qM_OUT_b[1025:1]) | (C_inter_1_b[1025:1]&S_inter_1_b[1025:1]), 
                     ((carry_out_a^S_inter_1_b[0])&MUX_qM_OUT_b[0]) | (carry_out_a&S_inter_1_b[0])};




        // Shift by two bits and save carry_out
        carry_out = S_inter_2_b[1] & C_inter_2_b[1];
        out_S = S_inter_2_b[1025:2];      // shifting by not passing last two LSB
        out_C = C_inter_2_b[1026:2];



    end
    
endmodule