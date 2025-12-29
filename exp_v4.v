`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/30/2024 12:24:15 PM
// Design Name: 
// Module Name: exp_v3
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


module exp_v4(
    input           clk,
    input           resetn,
    input           start,
    
    input [1023:0]  in_RM,          // RM = R mod M, thus 1024b
    input [1023:0]  in_R2M,
    input [1023:0]  in_E,
    input [9:0]     in_E_ln,         // Check this
    input [1023:0]  in_M,
    input [1023:0]  in_X,
    
    output [1023:0] result,
    output          done
    );

    //--------Internal constants--------

    //--------Internal variables--------
//    reg [3:0]   state;              // adjust the [9, 0] depending on the number of states that I have !!
//    reg [3:0]   nextState;

    //--------Data Path --------
    reg [1024:0]    MUX_A_in0;
    reg [1024:0]    MUX_A_in1;
    reg [1024:0]    MUX_A_out;
    reg             MUX_A_sel;
    
    reg [1024:0]    MUX_X_tilde_in0;
    reg [1024:0]    MUX_X_tilde_in1;
    reg [1024:0]    MUX_X_tilde_out;
    reg             MUX_X_tilde_sel;            // is this the same value as MUX_A_sel??

    
    reg [1024:0]    MUX_MM_A_value_in0;
    reg [1024:0]    MUX_MM_A_value_in1;
    reg [1024:0]    MUX_MM_A_value_out;
    reg             MUX_MM_A_value_sel;

    reg [1024:0]    MUX_MM_B_value_in0;
    reg [1024:0]    MUX_MM_B_value_in1;
    reg [1024:0]    MUX_MM_B_value_out;
    reg             MUX_MM_B_value_sel;

    
    reg             MM_start;
    wire [1024:0]   MM_result;
    wire            MM_done;
    

    //--------Registers - Datapath--------
    /*
    General note: MM inputs and output satisfy < 2M, hence they are at most 1025b
    
    regA; 1025b
    regX_tilde; 1025b
    regM; 1024b
    regX; 1024b
    regE; 1024b
    regE_ln; 10b        (TO BE SEEN)
    */
    
    
    reg [1024:0]    regA;                       // check the size of this value !!
    reg             regA_en;
    
    reg [1024:0]    regX_tilde;
    reg             regX_tilde_en;
    
//    reg [1023:0]    regM;
//    reg             regM_en;
    
    reg [1023:0]    regX;
    reg             regX_en;
    
//    reg [1023:0]    regE;
//    reg             regE_en;
    
    
    
//    reg [9:0]       regE_ln;
//    reg             regE_ln_en;

    reg regEi_en;
    reg [9:0]       regEi; 

    //--------Registers - FSM--------
//    reg select_X_tilde_Init;
    reg resetX_tilde;

    //----------------DATAPATH----------------
    //-------- INIT regM, regX --------
//    always @(posedge clk) begin
//        if (~resetn)
//            regM <= 1024'b0;
//        else if (regM_en)
//            regM <= in_M;
//    end

    always @(posedge clk) begin
        if (~resetn)
            regX <= 1'b0;
        else if (regX_en)
            regX <= in_X;               // we can implement the MM(A,1) here
    end


    //-------- INIT regE, regEi --------
//    always @(posedge clk) begin
//        if (~resetn)
//            regE <= 1024'b0;
//        else if (regE_en)
//            regE <= in_E;
//    end
    
    always @(posedge clk) begin
        if (~resetn)
            regEi <= 10'b0;
        else if (regEi_en)
            regEi <= regEi + 1 ;
    end
    
//    always @(posedge clk) begin
//        if (~resetn)
//            regE_ln <= 10'b0;
//        else if (regE_ln_en)
//            regE_ln <= in_E_ln;
//    end


    //-------- MUX regA --------
    always @(*) begin
        MUX_A_in0 = {1'b0, in_RM};
        MUX_A_in1 = MM_result;
        MUX_A_out = MUX_A_sel ? MUX_A_in1 : MUX_A_in0;
    end

    always @(posedge clk) begin
        if (~resetn)
            regA <= 1025'b0;
        else if (regA_en)
            regA <= MUX_A_out;              // note that RM is moved into regA and R2M into regX_tilde
    end

    //-------- MUX regX_tilde --------
    always @(*) begin
        MUX_X_tilde_in0 = {1'b0, in_R2M};
        MUX_X_tilde_in1 = MM_result;
        MUX_X_tilde_out = MUX_X_tilde_sel ? MUX_X_tilde_in1 : MUX_X_tilde_in0;
    end


    always @(posedge clk) begin
        if (~resetn)
            regX_tilde <= 1025'b0;
        else if(resetX_tilde)
            regX_tilde <= 1'b1;
        else if (regX_tilde_en)
            regX_tilde <= MUX_X_tilde_out;
    end



        
    //-------- MUX MM_A_value & MM_B_value --------
    always @(*) begin
        MUX_MM_A_value_in0 = {1'b0, regX};
        MUX_MM_A_value_in1 = regA;
        MUX_MM_A_value_out = MUX_MM_A_value_sel ? MUX_MM_A_value_in1 : MUX_MM_A_value_in0;
    end
    
    always @(*) begin
        MUX_MM_B_value_in0 = regX_tilde;
        MUX_MM_B_value_in1 = regA;
        MUX_MM_B_value_out = MUX_MM_B_value_sel ? MUX_MM_B_value_in1 : MUX_MM_B_value_in0;
    end   


    //-------- MM--------             (TODO: REMOVE THE INTERNAL RESET ==> RESET EXTERNALLY ISNTEAD)
    

    montgomery_v4 MM ( 
        .clk(clk),
        .resetn(resetn),
        .start(MM_start),
        .in_a(MUX_MM_A_value_out),
        .in_b(MUX_MM_B_value_out),
        .in_m(in_M),
        .result(MM_result),      
        .done(MM_done)
    );    


    

    //-------- FSM... --------
    
    
        // FSM States:
    reg [3:0] state, nextstate;
    localparam  IDLE               = 4'b0000,
                START_X_TILDE_INIT = 4'b0001,
                CALC_X_TILDE_INIT  = 4'b0010,
                DONE_X_TILDE_INIT  = 4'b0011,    //? NEEDED????
                START_MONT_MUL_AA  = 4'b0100,
                CALC_MONT_MUL_AA   = 4'b0101,
                DONE_MONT_MUL_AA   = 4'b0110,
                START_MONT_MUL_AX  = 4'b0111,
                CALC_MONT_MUL_AX   = 4'b1000,
                DONE_MONT_MUL_AX   = 4'b1001,
                START_A_1          = 4'b1010,    //? NEEDED????
                CALC_A_1           = 4'b1011,
                DONE_A_1           = 4'b1100,   //? NEEDED????
                DONE               = 4'b1101;

    always @(posedge clk) begin
        if(~resetn)	state <= IDLE;
        else state <= nextstate;
    end
    
    always @(*) begin
        // Default values
        MUX_A_sel           = 1'b1; // Select MM output for regA
        MUX_X_tilde_sel     = 1'b1; // Select MM output for regX_tilde
        MUX_MM_A_value_sel  = 1'b1; // Select regA as a_input for MM
        MUX_MM_B_value_sel  = 1'b1; // Select regA as a_input for MM
        resetX_tilde        = 1'b0; // DON'T RESET regX 
        MM_start            = 1'b0;
        regX_en             = 1'b0;
        regA_en             = 1'b0;
        regX_tilde_en       = 1'b0;
//        regE_en             = 1'b0;
        regEi_en            = 1'b0;
        
        case(state)     
            // Idle state; Wait for start signal and load values into regs 
            IDLE : begin
                MUX_A_sel       = 1'b0; // Load RM
                regA_en         = 1'b1;
                regX_en         = 1'b1; // Load x
                MUX_X_tilde_sel = 1'b0; // Load R2M
                regX_tilde_en   = 1'b1;
                
//                regE_en         = 1'b1;
            end
            START_X_TILDE_INIT : begin
                MM_start           = 1'b1;
                MUX_MM_A_value_sel = 1'b0;  // X
                MUX_MM_B_value_sel = 1'b0;  // X_tilde (R2M)
            end
            CALC_X_TILDE_INIT : begin
                MUX_MM_A_value_sel = 1'b0;  // X
                MUX_MM_B_value_sel = 1'b0;  // X_tilde (R2M)
            end
            DONE_X_TILDE_INIT : begin // Needed? 
                //regX_tilde_en = 1'b1;       // Update -> Mont(x, R2M)
            end
            START_MONT_MUL_AA : begin 
                MM_start   = 1'b1;
            end
            CALC_MONT_MUL_AA : begin
                // wait
            end
            DONE_MONT_MUL_AA : begin // Needed? 
            end
            START_MONT_MUL_AX : begin 
                MM_start   = 1'b1;
                MUX_MM_B_value_sel = 1'b0;  // X_tilde
            end
            CALC_MONT_MUL_AX : begin
                // wait
                MUX_MM_B_value_sel = 1'b0;  // X_tilde
            end
            DONE_MONT_MUL_AX : begin // Needed? 
//                regA_en       = 1'b1;       // Update 
//                regEi_en      = 1'b1;       // Count++                                                          ???
            end
            START_A_1 : begin 
                MM_start           = 1'b1;
                MUX_MM_B_value_sel = 1'b0; // X_tilde=1
            end
            CALC_A_1 : begin
                // wait
                MUX_MM_B_value_sel = 1'b0; // X_tilde=1
            end
            DONE_A_1 : begin // Needed? 
            end
            // DONE state:
            DONE : begin // Needed? 
                // ?
            end
            default: begin
                //do nothing
            end
        endcase
    end
    
    // Haxx: 
    always @(*) begin
        if (state==CALC_X_TILDE_INIT && nextstate == DONE_X_TILDE_INIT)
            regX_tilde_en = 1'b1;       // Update -> Mont(x, R2M)
            
        if ( (state==CALC_MONT_MUL_AA || state==CALC_MONT_MUL_AX ||state==CALC_A_1) && (nextstate == DONE_MONT_MUL_AA || nextstate == DONE_MONT_MUL_AX || nextstate == DONE_A_1) )
            regA_en = 1'b1;       // Update -> Mont(x, R2M)
        if ( (state == DONE_MONT_MUL_AA || state == DONE_MONT_MUL_AX) && (nextstate == START_MONT_MUL_AA) )
            regEi_en      = 1'b1;       // Count++                                                          ???
        if ( (state == DONE_MONT_MUL_AA || state == DONE_MONT_MUL_AX) && (nextstate == START_A_1) )
            resetX_tilde = 1'b1;
    end
   
   
    
    // Describe next_state logic
    always @(*) begin
        case(state)
            IDLE : begin
                if(start)
                    nextstate <= START_X_TILDE_INIT; //LOAD;
                else
                    nextstate <= IDLE;
            end
            START_X_TILDE_INIT : begin
                nextstate <= CALC_X_TILDE_INIT;
            end
            CALC_X_TILDE_INIT : begin 
                if(MM_done)
                    nextstate <= DONE_X_TILDE_INIT;
                else
                    nextstate <= CALC_X_TILDE_INIT;
            end
            DONE_X_TILDE_INIT : begin
                nextstate <= START_MONT_MUL_AA;
            end
            START_MONT_MUL_AA : begin
                nextstate <= CALC_MONT_MUL_AA;
            end
            CALC_MONT_MUL_AA : begin
                if(MM_done)
                    nextstate <= DONE_MONT_MUL_AA;
                else
                    nextstate <= CALC_MONT_MUL_AA;
            end
            DONE_MONT_MUL_AA: begin 
                if (regEi < in_E_ln) begin
                    if (in_E[regEi] == 1'b1)
                        nextstate <= START_MONT_MUL_AX;             // MM(A,X) needs to be done ONLY if e_i == 1
                    else begin
                        nextstate <= START_MONT_MUL_AA;
                    end
                end else 
                    nextstate <= START_A_1;           
            end
            START_MONT_MUL_AX : begin
                nextstate <= CALC_MONT_MUL_AX;
            end
            CALC_MONT_MUL_AX : begin
                if(MM_done)
                    nextstate <= DONE_MONT_MUL_AX;
                else
                    nextstate <= CALC_MONT_MUL_AX;
            end
            DONE_MONT_MUL_AX: begin 
                if (regEi < in_E_ln) begin
                    nextstate <= START_MONT_MUL_AA;    
                end else 
                    nextstate <= START_A_1;           
            end
            START_A_1 : begin
                nextstate <= CALC_A_1;
            end 
            CALC_A_1 : begin
                if (MM_done)
                    nextstate = DONE_A_1;
                else 
                    nextstate = CALC_A_1;
            end
            DONE_A_1 : begin 
                nextstate = DONE;
            end
            // DONE state:
            DONE: begin
                nextstate <= IDLE;
            end
            default: begin
                nextstate <= IDLE;
            end
        endcase
    end 


    reg regDone;
    always @(posedge clk)
    begin
        if(~resetn) regDone <= 1'd0;
        else        regDone <= (state==DONE) ? 1'b1 : 1'b0;
    end
    
    assign result = regA[1023:0];       //  we only save the 1024LSB bits !! (not 1025b)
    assign done = regDone;


    

endmodule