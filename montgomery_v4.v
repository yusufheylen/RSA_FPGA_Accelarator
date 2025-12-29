`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2024 05:42:20 PM
// Design Name: 
// Module Name: montgomery_v3
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


module montgomery_v4(
  input           clk,
  input           resetn,
  input           start,
  input  [1024:0] in_a,                 // in pratice we would have 1026b with a[1025]=0 !!!
  input  [1024:0] in_b,
  input  [1023:0] in_m,
  output [1024:0] result,
  output          done
    );

  // Student tasks:
  // 1. Instantiate an Adder
  // 2. Use the Adder to implement the Montgomery multiplier in hardware.
  // 3. Use tb_montgomery.v to simulate your design.

  // Dear Students: This always block was added to ensure the tool doesn't
  // trim away the montgomery module. Feel free to remove this block.

//  reg [1023:0] r_result;
//  always @(posedge(clk))
//    r_result <= {1024{1'b1}};


//   assign done = 1;

/////////////////////////////////////////////////////
    
    //--------Internal constants--------
    localparam STATE_IDLE       = 4'b0000;
    localparam STATE_START_3B   = 4'b0001;
    localparam STATE_CALC_3B    = 4'b0010;
    localparam STATE_START_3M   = 4'b0011;
    localparam STATE_CALC_3M    = 4'b0100;
   
    localparam STATE_CSA        = 4'b0101;
    localparam STATE_START_RES = 4'b0110;
    localparam STATE_CALC_RES  = 4'b0111;
//    localparam STATE_START_RES2 = 4'b1000;
//    localparam STATE_CALC_RES2  = 4'b1001;
    localparam STATE_DONE       = 4'b1010;
    localparam STATE_RESET      = 4'b1011;
    reg reset_sig;
    
    assign resetn_in = reset_sig & resetn;
    
//    0 | 0 | 0 
//    0 | 1 | 0
//    1 | 0 | 0
//    1 | 1 | 1
    
    //--------Internal variables--------
    reg [3:0]   state;              // adjust the [9, 0] depending on the number of states that I have !!
    reg [3:0]   nextState;
    
    
    //--------Data Path --------
    reg             MUX_A_sel;
    reg [1024:0]    MUX_A_in0;
    reg [1024:0]    MUX_A_in1;
    reg [1024:0]    MUX_A_out;

    reg [1:0]       MUX_adder_1_sel;
    reg [1026:0]    MUX_adder_1_in0;
    reg [1026:0]    MUX_adder_1_in1;
    reg [1026:0]    MUX_adder_1_in2;
    reg [1026:0]    MUX_adder_1_in3;
    reg [1026:0]    MUX_adder_1_out;
    
    reg [1:0]       MUX_adder_2_sel;
    reg [1026:0]    MUX_adder_2_in0;
    reg [1026:0]    MUX_adder_2_in1;
    reg [1026:0]    MUX_adder_2_in2;
    reg [1026:0]    MUX_adder_2_in3;
    reg [1026:0]    MUX_adder_2_out;


    reg             ADDER_resetn;
    reg             ADDER_start;
    reg             ADDER_sub;
    reg             ADDER_carry_input_sel;
    reg             ADDER_carry_input;
    wire [1026:0]   ADDER_sum_out;         // TODO: REG SIZE
    wire            ADDER_carry_out;
    wire            ADDER_done;
    
    reg             regADDER_carry_out_en;
    reg             regADDER_carry_out;
    
    wire [1025:0]   output_csa_C;
    wire [1024:0]   output_csa_S;
    wire            output_csa_carry;
//    wire [1024:0]   output_csa_a;

    wire [1025:0]   out_C_a;
    wire [1024:0]   out_S_a;
    wire            carry_out_a;

 
    //--------Registers - Datapath--------
    reg [1024:0]    regA;
    reg             regA_en;

    reg [1024:0]    regB;
    reg             regB_en;

    reg [1023:0]    regM;
    reg             regM_en;
    
    reg [1026:0]    reg3B;
    reg             reg3B_en;
    
    reg [1025:0]    reg3M;
    reg             reg3M_en;
    
    reg [1026:0]    regkB_a;
    reg             regkB_a_en;
    reg [1026:0]    regkB_b;
    reg             regkB_b_en;
    
    reg [1025:0]    regC;   
    reg             regC_en;
    
    reg [1024:0]    regS;
    reg             regS_en;

    reg             regCarry;
    reg             regCarry_en;
    
    reg [1024:0]    regResult;
    reg             regResult_en;
    


    //--------Registers - FSM--------
    reg [7:0]       CSA_loopCounter;  // there are 512 steps in the iteration ==> 9 bits         // TODO: REG SIZE
    reg             regCSA_loopCounter_en;


    // --- INIT regB and regM ---
    
    always @(posedge clk) begin
        if (~resetn_in)
            regB <= 1025'b0;
        else if (regB_en)
            regB <= in_b;
    end
    
    always @(posedge clk) begin
        if (~resetn_in)
            regM <= 1024'b0;
        else if (regM_en)
            regM <= in_m;
    end
    
    
    // --- regA - MUX  --- 
    always @(*) begin
        MUX_A_in0 = in_a;
        MUX_A_in1 = {4'b0, regA[1024:4]};                       // NOTE THAT THE 4'b0 would be 2'b0 if we had only ONE loop cycle per clk cycle
        MUX_A_out = MUX_A_sel ? MUX_A_in1 : MUX_A_in0;
    end
    always @(posedge clk) begin
        if (~resetn_in)        regA <= 1025'b0;
        else if (regA_en)   regA <= MUX_A_out;
    end
    
    
    // --- regkB - MUX ---
    reg [1:0]   sel_mux_kB_a;
    reg [1026:0] MUX_kB_OUT_a;
    reg [1:0]   sel_mux_kB_b;
    reg [1026:0] MUX_kB_OUT_b;
    always @(*) begin
        sel_mux_kB_a = regA[1:0];
        case (sel_mux_kB_a)
            2'b00 : MUX_kB_OUT_a = 1027'b0;
            2'b01 : MUX_kB_OUT_a = {2'b0, in_b};
            2'b10 : MUX_kB_OUT_a = {1'b0, in_b, 1'b0};
            2'b11 : MUX_kB_OUT_a = reg3B;
        endcase
        
        sel_mux_kB_b = regA[3:2];
        case (sel_mux_kB_b)
            2'b00 : MUX_kB_OUT_b = 1027'b0;
            2'b01 : MUX_kB_OUT_b = {2'b0, in_b};
            2'b10 : MUX_kB_OUT_b = {1'b0, in_b, 1'b0};
            2'b11 : MUX_kB_OUT_b = reg3B;
        endcase
    end


    always @(posedge clk) begin
        if (~resetn_in) begin
            regkB_a <= 1027'b0;
            regkB_b <= 1027'b0;
        end
        else  begin
            if (regkB_a_en)  regkB_a <= MUX_kB_OUT_a;
            if (regkB_b_en)  regkB_b <= MUX_kB_OUT_b;
        end
    end


    mp_adder_v1 #(.INPUT_WIDTH(1027)) ADDER (               // TODO: CHECK ADDER WIDTH                  
        .clk(clk),
        .resetn(ADDER_resetn),
        .start(ADDER_start),
        .subtract(ADDER_sub),
        .carry_input(ADDER_carry_input),
        .in_a(MUX_adder_1_out),
        .in_b(MUX_adder_2_out),
        .result({ADDER_carry_out, ADDER_sum_out}),      
        .done(ADDER_done)
    );
    
    always @(posedge clk) begin
        if(~resetn_in) 
            regADDER_carry_out <= 1'b0;
        else if (regADDER_carry_out_en) regADDER_carry_out <= ~ADDER_carry_out;     // if Cout = 1, then RES1 >= M, so send RES2
    end 

    // --- ADDER  --- 
    always @(*) begin   // right now we assume 1026b -> 1027b adder
        ADDER_carry_input = ADDER_carry_input_sel ? regCarry : 1'b0;        // if sel=1 -> pass regCarry
    
        MUX_adder_1_in0 = {1'b0, regB, 1'b0};     // regB<<1
        MUX_adder_1_in1 = {2'b0, regM, 1'b0};     // regM<<1
//        MUX_adder_1_in2 = {1'b0, regC};
        MUX_adder_1_in2 = {1'b0, out_C_a};
        MUX_adder_1_in3 = 1027'b0;              // CAN BE ANYTHING
        
        case (MUX_adder_1_sel)
            2'b00 : MUX_adder_1_out = MUX_adder_1_in0;
            2'b01 : MUX_adder_1_out = MUX_adder_1_in1;
            2'b10 : MUX_adder_1_out = MUX_adder_1_in2;
            2'b11 : MUX_adder_1_out = MUX_adder_1_in3; //   CHECK
        endcase
        
        
        
        MUX_adder_2_in0 = {2'b0, regB};
        MUX_adder_2_in1 = {3'b0, regM};
//        MUX_adder_2_in2 = {2'b0, regS};
        MUX_adder_2_in2 = {2'b0, out_S_a};
        MUX_adder_2_in3 = 1027'b0;
        
        case (MUX_adder_2_sel)
            2'b00 : MUX_adder_2_out = MUX_adder_2_in0;
            2'b01 : MUX_adder_2_out = MUX_adder_2_in1;
            2'b10 : MUX_adder_2_out = MUX_adder_2_in2;
            2'b11 : MUX_adder_2_out = MUX_adder_2_in3;   //CHECK
        endcase
    end


    always @(posedge clk) begin
//        {ADDER_carry_out, ADDER_sum_out} = TBA;
        
        if (~resetn_in) begin      
            reg3B <= 1027'b0;
            reg3M <= 1026'b0;
        end
        else if (reg3B_en)  reg3B <= ADDER_sum_out[1025:0];             
        else if (reg3M_en)  reg3M <= ADDER_sum_out[1025:0];
    end
    

    // --- regRESULT --- 
    
    always @(posedge clk) begin
        if (~resetn_in) regResult <= 1025'b0;
        else if (regResult_en) regResult <= ADDER_sum_out[1024:0];
    end
    assign result = regResult;



    // --- CSA  ---
    CSA_block_v4 CSA (
      .in_C(regC),
      .in_S(regS),
      .carry_in(regCarry),
      .in_m(regM),
      .in_3m(reg3M),
      .in_kB_current_a(regkB_a),
      .in_kB_current_b(regkB_b),
      .out_C(output_csa_C),
      .out_S(output_csa_S),
      .carry_out(output_csa_carry),
      
      .out_C_a(out_C_a),
      .out_S_a(out_S_a),
      .carry_out_a(carry_out_a)
    );
           
    always @(*) begin
    end
    
always @(posedge clk) begin
    if (~resetn_in) begin
        regC <= 1026'b0;
        regS <= 1025'b0;
        regCarry <= 1'b0;
    end
    else begin                                  
        if (regC_en)        regC <= output_csa_C;
        if (regS_en)        regS <= output_csa_S;
        if (regCarry_en)    regCarry <= output_csa_carry;
    end
end


    // This is the state logic for the DATAPATH
always @(*) begin
    case (state)
        STATE_IDLE: begin
            regC_en <= 1'b0;
            regS_en <= 1'b0;
            regCarry_en <= 1'b0;
            
            reset_sig <= 1'b1;
            
            regCSA_loopCounter_en <= 1'b0; 
            
            reg3B_en <= 1'b0;
            reg3M_en <= 1'b0;

            regA_en <= 1'b1;
            MUX_A_sel <= 1'b0;             
            
            regB_en <= 1'b1;
            regM_en <= 1'b1;

            regkB_a_en <= 1'b0;
            regkB_b_en <= 1'b0;

            regResult_en <= 1'b0;
            regADDER_carry_out_en <= 1'b0;
            
            MUX_adder_1_sel <= 2'b00;
            MUX_adder_2_sel <= 2'b00;
            
            ADDER_start  <= 1'b0;
            ADDER_resetn <= 1'b0;
            ADDER_sub    <= 1'b0;
            ADDER_carry_input_sel <= 1'b0;             


        end

        STATE_START_3B: begin
            // we calculate 3B (COMB)
            // reg3B <= {1'b0, regB} + {regB, 1'b0};

            regC_en <= 1'b0;
            regS_en <= 1'b0;
            regCarry_en <= 1'b0;
            
            reset_sig <= 1'b1;

            
            regCSA_loopCounter_en <= 1'b0; 
            
            reg3B_en <= 1'b1;
            reg3M_en <= 1'b0;

            regA_en <= 1'b0;
            MUX_A_sel <= 1'b0;             // 0: in_a   |   1: regA>>2
            
            regB_en <= 1'b0;
            regM_en <= 1'b0;

            regkB_a_en <= 1'b0;
            regkB_b_en <= 1'b0;

            regResult_en <= 1'b0;
            regADDER_carry_out_en <= 1'b0;

            MUX_adder_1_sel <= 2'b00;
            MUX_adder_2_sel <= 2'b00;
            
            ADDER_start <= 1'b1;
            ADDER_resetn <= 1'b1;
            ADDER_sub <= 1'b0;
            ADDER_carry_input_sel <= 1'b0;             

        end
        STATE_CALC_3B: begin
            // we calculate 3B (COMB)
            // reg3B <= {1'b0, regB} + {regB, 1'b0};

            regC_en <= 1'b0;
            regS_en <= 1'b0;
            regCarry_en <= 1'b0;

            reset_sig <= 1'b1;

            regADDER_carry_out_en <= 1'b0;

            regCSA_loopCounter_en <= 1'b0; 
            
            reg3B_en <= 1'b1;
            reg3M_en <= 1'b0;

            regA_en <= 1'b0;
            MUX_A_sel <= 1'b0;             // 0: in_a   |   1: regA>>2
            
            regB_en <= 1'b0;
            regM_en <= 1'b0;

            regkB_a_en <= 1'b0;
            regkB_b_en <= 1'b0;

            regResult_en <= 1'b0;
            
            MUX_adder_1_sel <= 2'b00;
            MUX_adder_2_sel <= 2'b00;
            
            ADDER_start <= 1'b0;
            ADDER_resetn <= 1'b1;
            ADDER_sub <= 1'b0;
            ADDER_carry_input_sel <= 1'b0;             

        end

        STATE_START_3M: begin
            // we LOAD the data for 3M (COMB)
            regC_en <= 1'b0;
            regS_en <= 1'b0;
            regCarry_en <= 1'b0;
            
            reset_sig <= 1'b1;
            
            regADDER_carry_out_en <= 1'b0;
            
            regCSA_loopCounter_en <= 1'b0; 
            
            reg3B_en <= 1'b0;
            reg3M_en <= 1'b1;

            regA_en <= 1'b1;
            MUX_A_sel <= 1'b1;             // 0: in_a   |   1: regA>>2
            
            regB_en <= 1'b0;
            regM_en <= 1'b0;
            
            regkB_a_en <= 1'b1;
            regkB_b_en <= 1'b1;
            
            regResult_en <= 1'b0;
            
            MUX_adder_1_sel <= 2'b01;
            MUX_adder_2_sel <= 2'b01;
            
            ADDER_start <= 1'b1;
            ADDER_resetn <= 1'b1;
            ADDER_sub <= 1'b0;
            ADDER_carry_input_sel <= 1'b0;             
            
            // TODO: 
            // - choose the right kB block before going into STATE_3        
            // regkB <= {}
        end
        
        STATE_CALC_3M: begin
            // we CALCULATE 3M (COMB)
            regC_en <= 1'b0;
            regS_en <= 1'b0;
            regCarry_en <= 1'b0;

            reset_sig <= 1'b1;


            regADDER_carry_out_en <= 1'b0;  
            regCSA_loopCounter_en <= 1'b0; 
            
            reg3B_en <= 1'b0;
            reg3M_en <= 1'b1;

            regA_en <= 1'b0;
            MUX_A_sel <= 1'b0;             // 0: in_a   |   1: regA>>2
            
            regB_en <= 1'b0;
            regM_en <= 1'b0;

            regkB_a_en <= 1'b0;
            regkB_b_en <= 1'b0;

            regResult_en <= 1'b0;
            
            MUX_adder_1_sel <= 2'b01;
            MUX_adder_2_sel <= 2'b01;
            
            ADDER_start <= 1'b0;
            ADDER_resetn <= 1'b1;
            ADDER_sub <= 1'b0;
            ADDER_carry_input_sel <= 1'b0;             
            
            // TODO: 
            // - choose the right kB block before going into CSA        
            // regkB <= {}
        end
        STATE_CSA: begin
            // TODO:
            //  - kB al een stap eerder klaar zetten in REG, (mux uitsparen)

            regC_en <= 1'b1;
            regS_en <= 1'b1;
            regCarry_en <= 1'b1;

            reset_sig <= 1'b1;

            regADDER_carry_out_en <= 1'b0;                
            regCSA_loopCounter_en <= 1'b1; 
            
            reg3B_en <= 1'b0;
            reg3M_en <= 1'b0;

            regA_en <= 1'b1;
            MUX_A_sel <= 1'b1;             // 0: in_a   |   1: regA>>2
            
            regB_en <= 1'b0;
            regM_en <= 1'b0;

            regkB_a_en <= 1'b1;
            regkB_b_en <= 1'b1;

            regResult_en <= 1'b0;
            
            MUX_adder_1_sel <= 2'b10;
            MUX_adder_2_sel <= 2'b10;
           
            ADDER_start <= 1'b0;
            ADDER_resetn <= 1'b1;
            ADDER_sub <= 1'b0;
            ADDER_carry_input_sel <= 1'b0;             
                    
            
        end
        
        STATE_START_RES: begin
            // we LOAD res1 <- C+S+carry (COMB)
            //regRes1 <= {regC, 1'b0} + {1'b0, regS} + regCarry;
      
            regC_en <= 1'b0;
            regS_en <= 1'b0;
            regCarry_en <= 1'b0;
            
            reset_sig <= 1'b1;            
            
            regADDER_carry_out_en <= 1'b0;
            regCSA_loopCounter_en <= 1'b0; 
            
            reg3B_en <= 1'b0;
            reg3M_en <= 1'b0;

            regA_en <= 1'b0;
            MUX_A_sel <= 1'b0;             // 0: in_a   |   1: regA>>2
            
            regB_en <= 1'b0;
            regM_en <= 1'b0;

            regkB_a_en <= 1'b0;
            regkB_b_en <= 1'b0;
            
            regResult_en <= 1'b0;
            
            MUX_adder_1_sel <= 2'b10;
            MUX_adder_2_sel <= 2'b10;
           
            ADDER_start <= 1'b1;
            ADDER_resetn <= 1'b1;
            ADDER_sub <= 1'b0;
            ADDER_carry_input_sel <= 1'b1;                  
                    
        end
        
        STATE_CALC_RES: begin
            // we calculate res1 <- C+S+carry (COMB)
            //regRes1 <= {regC, 1'b0} + {1'b0, regS} + regCarry;
            regC_en <= 1'b0;
            regS_en <= 1'b0;
            regCarry_en <= 1'b0;

            reset_sig <= 1'b1;
            
            regADDER_carry_out_en <= 1'b0;
            regCSA_loopCounter_en <= 1'b0; 
            
            reg3B_en <= 1'b0;
            reg3M_en <= 1'b0;

            regA_en <= 1'b0;
            MUX_A_sel <= 1'b0;                          // 0: in_a   |   1: regA>>2
            
            regB_en <= 1'b0;
            regM_en <= 1'b0;

            regkB_a_en <= 1'b0;
            regkB_b_en <= 1'b0;
            
            regResult_en <= 1'b1;               // WE CHANGED THIS
            
            MUX_adder_1_sel <= 2'b10;
            MUX_adder_2_sel <= 2'b10;
           
            ADDER_start <= 1'b0;
            ADDER_resetn <= 1'b1;
            ADDER_sub <= 1'b0;
            ADDER_carry_input_sel <= 1'b1;                  
                    
        end
                    

        STATE_DONE: begin
            regC_en <= 1'b0;
            regS_en <= 1'b0;
            regCarry_en <= 1'b0;

            reset_sig <= 1'b1;
            
            regADDER_carry_out_en <= 1'b0;
            regCSA_loopCounter_en <= 1'b0; 

            reg3B_en <= 1'b0;
            reg3M_en <= 1'b0;

            regA_en <= 1'b0;
            MUX_A_sel <= 1'b0;             // 0: in_a   |   1: regA>>2
            
            regB_en <= 1'b0;
            regM_en <= 1'b0;

            regkB_a_en <= 1'b0;
            regkB_b_en <= 1'b0;
            
//            regRes1_en <= 1'b0;
//            regRes2_en <= 1'b1;
            regResult_en <= 1'b1;
            
            MUX_adder_1_sel <= 2'b11;
            MUX_adder_2_sel <= 2'b11;
            
            ADDER_start <= 1'b0;
            ADDER_resetn <= 1'b1;
            ADDER_sub <= 1'b0;
            ADDER_carry_input_sel <= 1'b0;             
        end

        STATE_RESET: begin

            regC_en <= 1'b0;
            regS_en <= 1'b0;
            regCarry_en <= 1'b0;

            reset_sig <= 1'b0;
            
            regADDER_carry_out_en <= 1'b0;
            regCSA_loopCounter_en <= 1'b0; 

            reg3B_en <= 1'b0;
            reg3M_en <= 1'b0;

            regA_en <= 1'b0;
            MUX_A_sel <= 1'b0;             // 0: in_a   |   1: regA>>2
            
            regB_en <= 1'b0;
            regM_en <= 1'b0;

            regkB_a_en <= 1'b0;
            regkB_b_en <= 1'b0;
            
//            regRes1_en <= 1'b0;
//            regRes2_en <= 1'b0;
            regResult_en <= 1'b0;
            
            MUX_adder_1_sel <= 2'b00;
            MUX_adder_2_sel <= 2'b00;
            
            ADDER_start <= 1'b0;
            ADDER_resetn <= 1'b0;
            ADDER_sub <= 1'b0;
            ADDER_carry_input_sel <= 1'b0;             
                   
        end
        default : begin
            regC_en <= 1'b0;
            regS_en <= 1'b0;
            regCarry_en <= 1'b0;
            
            reset_sig <= 1'b0;
            
            regADDER_carry_out_en <= 1'b0;
            regCSA_loopCounter_en <= 1'b0; 
            
            MUX_adder_1_sel <= 2'b00;
            MUX_adder_2_sel <= 2'b00;
            
            reg3B_en <= 1'b0;
            reg3M_en <= 1'b0;

            regA_en <= 1'b0;
            MUX_A_sel <= 1'b0;             // 0: in_a   |   1: regA>>2
            
            regB_en <= 1'b0;
            regM_en <= 1'b0;

            regkB_a_en <= 1'b0;
            regkB_b_en <= 1'b0;
            
//            regRes1_en <= 1'b0;
//            regRes2_en <= 1'b0;
            regResult_en <= 1'b0;
            
            
            ADDER_resetn <= 1'b0;
            ADDER_sub <= 1'b0;
            ADDER_carry_input_sel <= 1'b0;             
            ADDER_start  <= 1'b0;

        end
         
    endcase
end
    
// This is the SEQUENTIAL logic
always @(posedge clk) begin
    if(~resetn) state <= STATE_IDLE;
    else state <= nextState; 
end


// Next state logic
always @(*) begin
    case (state)
        STATE_IDLE: begin
           if (start) 
              nextState <= STATE_START_3B;
           else 
              nextState <= state;
        end
        STATE_START_3B: begin
            nextState <= STATE_CALC_3B;
        end
        STATE_CALC_3B: begin
            if (ADDER_done)  
                nextState <= STATE_START_3M;
            else  
                nextState <= state;
        end
        STATE_START_3M: begin
            nextState <= STATE_CALC_3M;
        end
        STATE_CALC_3M: begin
            if (ADDER_done)  
                nextState <= STATE_CSA;
            else  
                nextState <= state;
        end
        STATE_CSA: begin
            if (CSA_loopCounter != 8'b11111111) 
                nextState <= state;
            else 
                nextState <= STATE_START_RES;
        end            
        STATE_START_RES: begin
            nextState <= STATE_CALC_RES;
        end
        STATE_CALC_RES: begin
            if (ADDER_done)  
                nextState <= STATE_DONE;
            else  
                nextState <= state;
        end               
        STATE_DONE: begin
            nextState <= STATE_RESET;
        end
        STATE_RESET: begin
            nextState <= STATE_IDLE;
        end    
        default : begin
            nextState <= STATE_IDLE;
        end
    endcase     
end

always @(posedge clk) begin
    if(~resetn_in)
        CSA_loopCounter <= 8'b0;
    else if (regCSA_loopCounter_en) 
        CSA_loopCounter <= CSA_loopCounter + 1'b1; 
end

reg regDone;
always @(posedge clk)
begin
    if(~resetn) regDone <= 1'd0;
    else        regDone <= ( state == STATE_DONE ) ? 1'b1 : 1'b0;
end

assign done = regDone;



       

endmodule
