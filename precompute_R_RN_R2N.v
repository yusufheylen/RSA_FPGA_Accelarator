`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2024 03:06:38 PM
// Design Name: 
// Module Name: precompute_R_RN_R2N
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


module precompute_RM_R2M(
//    reg R_old,                    ! just KNOW that we need to INCREASE the nb of steps in the CSA block to (R*4)
    input               clk,
    input               resetn,
    input               start,
    input [1023:0]      RM_old,
    input [1023:0]      R2M_old,
    input [1023:0]      M,
    output [1023:0]     RM_new,
    output [1023:0]     R2M_new,
    output [4:0]        state_out,
    output              done
    );
    
    //--------Internal variables--------
    //--------Data Path --------
    reg [1:0]       MUX_reg_input_sel;
    reg [1023:0]    MUX_reg_input_in_RES;
    reg [1023:0]    MUX_reg_input_in_2RM;
    reg [1023:0]    MUX_reg_input_in_input_RM;
    reg [1024:0]    MUX_reg_input_in_input_R2M;          // CAN BE ANYTHING !!
    reg [1023:0]    MUX_reg_input_out;


    reg [1:0]       MUX_sub_sel;
    reg [1023:0]    MUX_sub_in_RM;
    reg [1023:0]    MUX_sub_in_R2M;
    reg [1023:0]    MUX_sub_out;
    
    
    reg             SUB_resetn;
    reg             SUB_start;
    wire [1023:0]    SUB_out_sum;
    wire             SUB_out_carry;
    wire            SUB_done;

    //--------Registers - Datapath--------
    reg [1023:0]        regRM;                 // CHECK THESE if problems with intermediate number of bits
    reg                 regRM_en;
    
    reg [1023:0]        regR2M;
    reg                 regR2M_en;
    
    reg [1023:0]        regM;
    reg                 regM_en; 

    //--------Registers - FSM--------
    
    
    
    //-------- MUX_input --------
    always @(*) begin
        MUX_reg_input_in_RES = SUB_out_sum;
        MUX_reg_input_in_2RM = {MUX_sub_out[1022:0], 1'b0};
        MUX_reg_input_in_input_RM = RM_old;
        MUX_reg_input_in_input_R2M = R2M_old;
    end


    always @(*) begin
        case (MUX_reg_input_sel)
            2'b00 : MUX_reg_input_out = MUX_reg_input_in_RES;
            2'b01 : MUX_reg_input_out = MUX_reg_input_in_2RM;
            2'b10 : MUX_reg_input_out = MUX_reg_input_in_input_RM;
            2'b11 : MUX_reg_input_out = MUX_reg_input_in_input_R2M;
        endcase
    end
    
    //-------- MUX_sub --------
    always @(*) begin
        MUX_sub_in_R2M = regR2M;
        MUX_sub_in_RM = regRM;
    end

    always @(*) begin
        MUX_sub_out = MUX_sub_sel ? MUX_sub_in_R2M : MUX_sub_in_RM;         // 1 : 0
    end
    
    //-------- REGS (RM, R2M, and M) --------
    always @(posedge clk) begin
        if (~resetn)        regRM <= 1024'b0;
        else if (regRM_en)   regRM <= MUX_reg_input_out;
    end
    
    always @(posedge clk) begin
        if (~resetn)        regR2M <= 1024'b0;
        else if (regR2M_en)   regR2M <= MUX_reg_input_out;
    end
    
    always @(posedge clk) begin
        if (~resetn)        regM <= 1024'b0;
        else if (regM_en)   regM <= M;
    end

    
    //-------- SUB --------
    mp_adder_v1 #(.INPUT_WIDTH(1025)) ADDER (       // double check the SUB width                           
        .clk(clk),
        .resetn(SUB_resetn),
        .start(SUB_start),
        .subtract(1'b1),
        .carry_input(1'b0),
        .in_a({MUX_sub_out[1023:0], 1'b0}),
        .in_b({1'b0,regM[1023:0]}),
        .result({SUB_out_carry, SUB_out_sum}),
        .done(SUB_done)
    );

    //-------- FSM --------
    
// FSM States:
reg [3:0] state, nextstate;
localparam      LOAD_RM          = 3'b000,
                START_FIRST_SUB  = 3'b001,
                FIRST_SUB        = 3'b010,
                DONE_FIRST_SUB   = 3'b011,
                START_SECOND_SUB = 3'b100,
                SECOND_SUB       = 3'b101,
                DONE_SECOND_SUB  = 3'b110,
                DONE             = 3'b111;

always @(posedge clk) begin
    if(~resetn)	state <= LOAD_RM;
    else state <= nextstate;
end
    always @(*) begin
        // Default values
        regRM_en            = 1'b0;
        regR2M_en           = 1'b0;  
        regM_en             = 1'b0;
        SUB_start           = 1'b0;
        MUX_sub_sel         = 1'b0;    
        MUX_reg_input_sel   = 2'b00;
        SUB_resetn          = 1'b1;    
        case(state)

            // Idle state; Here the FSM waits for the start signal
            // Enable input registers to fetch the inputs and when start is received
            LOAD_RM: begin
                regRM_en            = 1'b1;
                regM_en             = 1'b1;
                MUX_reg_input_sel   = 2'b10;
                SUB_resetn          = 1'b0;
            end
            START_FIRST_SUB: begin
                SUB_start           = 1'b1;
                MUX_reg_input_sel   = 2'b10;
            end 
            FIRST_SUB: begin 
                MUX_reg_input_sel   = 2'b10;
            end
            DONE_FIRST_SUB: begin
                regRM_en            = 1'b1;  // Update
                MUX_reg_input_sel   = {1'b0, SUB_out_carry}; // NB: IS THIS OKAY!!?? (for 2RM)
                SUB_resetn          = 1'b0;
            end
            START_SECOND_SUB: begin
                SUB_start           = 1'b1;
                MUX_reg_input_sel   = {1'b0, SUB_out_carry};
            end
            SECOND_SUB: begin 
                SUB_start           = 1'b1;
                MUX_reg_input_sel   = {1'b0, SUB_out_carry};
            end
            DONE_SECOND_SUB: begin
                regRM_en            = 1'b1;  // Update
                MUX_reg_input_sel   = {1'b0, SUB_out_carry}; // NB: IS THIS OKAY!!?? (for 2RM)
            end 
            // DONE state:
            DONE: begin
                SUB_resetn          = 1'b0;
            end
            default: begin
                //do nothing
            end
        endcase
    end

    // Describe next_state logic
    always @(*) begin
        case(state)
            LOAD_RM: begin
                if(start)
                    nextstate <= START_FIRST_SUB;
                else
                    nextstate <= LOAD_RM;
            end
            START_FIRST_SUB: begin
                nextstate <= FIRST_SUB;
            end
            FIRST_SUB: begin 
                if(SUB_done)
                    nextstate <= DONE_FIRST_SUB;
                else
                    nextstate <= FIRST_SUB;
            end
            DONE_FIRST_SUB: begin
                nextstate <= START_SECOND_SUB;
            end
            START_SECOND_SUB: begin
                nextstate <= SECOND_SUB;
            end
            SECOND_SUB: begin 
                if(SUB_done)
                    nextstate <= DONE_SECOND_SUB;
                else
                    nextstate <= SECOND_SUB;
            end
            DONE_SECOND_SUB: begin
                nextstate <= DONE;
            end 
            // DONE state:
            DONE: begin
                nextstate <= LOAD_RM;
            end
            default: begin
                nextstate <= LOAD_RM;
            end
        endcase
    end 

    reg regDone;
    always @(posedge clk)
    begin
        if(~resetn) regDone <= 1'd0;
        else        regDone <= (state==DONE) ? 1'b1 : 1'b0;
    end
    
    assign RM_new = regRM;
    assign done = regDone;

endmodule
