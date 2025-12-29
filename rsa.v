module rsa (
    input  wire          clk,
    input  wire          resetn,
    output wire   [ 3:0] leds,

    // input registers                     // output registers
    input  wire   [31:0] rin0,             output wire   [31:0] rout0,
    input  wire   [31:0] rin1,             output wire   [31:0] rout1,
    input  wire   [31:0] rin2,             output wire   [31:0] rout2,
    input  wire   [31:0] rin3,             output wire   [31:0] rout3,
    input  wire   [31:0] rin4,             output wire   [31:0] rout4,
    input  wire   [31:0] rin5,             output wire   [31:0] rout5,
    input  wire   [31:0] rin6,             output wire   [31:0] rout6,
    input  wire   [31:0] rin7,             output wire   [31:0] rout7,

    // dma signals
    input  wire [1023:0] dma_rx_data,      output wire [1023:0] dma_tx_data,
    output wire [  31:0] dma_rx_address,   output wire [  31:0] dma_tx_address,
    output reg           dma_rx_start,     output reg           dma_tx_start,
    input  wire          dma_done,
    input  wire          dma_idle,
    input  wire          dma_error
  );
    //--------Internal constants--------

//--------Internal Wires--------
    
   // DMA wires
   
    //DMA input wires
    wire [31:0] command;  
    wire [31:0] message_address;
    wire [31:0] modulus_address;
    wire [31:0] exponant_address;
    wire [31:0] RN_address;
    wire [31:0] R2N_address;
    wire [31:0] exp_len; 
    
    assign command          = rin0;  // use rin0 as command
    assign message_address  = rin1;  // use rin1 as input  data address
    assign modulus_address  = rin2;  // r2 := message adddress 
    assign exponant_address = rin3;  // r3 := exp addr (both e and d) 
    assign RN_address       = rin4;  // r4 := RN address 
    assign R2N_address      = rin5;  // r5 := R2N address
    assign dma_tx_address   = rin6;  // use rin6 as output data address
    assign exp_len          = rin7;
    
    // DMA output wires 
    // Only one output register is used. It will the status of FPGA's execution.
    wire [31:0] status;
    assign rout0 = status; // use rout0 as status
    assign rout1 = 32'b0;  // r1 := n/a 
    assign rout2 = 32'b0;  // r2 := n/a
    assign rout3 = 32'b0;  // not used
    assign rout4 = 32'b0;  // not used
    assign rout5 = 32'b0;  // not used
    assign rout6 = 32'b0;  // not used
    assign rout7 = 32'b0;  // not used

    // In this example we have only one computation command.
    wire isCmdComp = (command == 32'd1);
    wire isCmdIdle = (command == 32'd0);
  
    // DP Wires
    wire exp_start;
    wire exp_done;
    reg [1023:0] resWire;
    reg [1023:0] r_data;

  
//--------Internal Registers--------
    // Defines
    reg [1023:0]    regMessage;
    reg             regMessage_en;
   
    reg [1023:0]    regModulus;
    reg             regModulus_en;
 
    reg [1023:0]    regExponant;
    reg             regExponant_en;
 
    reg [1023:0]    regRN;
    reg             regRN_en;
    
    reg [1023:0]    regR2N;
    reg             regR2N_en;
    
    reg [1023:0]    regResult;
    reg             regResult_en;
    
    // Instance
    always @(posedge clk) begin
    if (~resetn)
        regMessage <= 1024'b0;
    else if (regMessage_en)
        regMessage <= r_data;               
    end
    
    always @(posedge clk) begin
    if (~resetn)
        regModulus <= 1024'b0;
    else if (regModulus_en)
        regModulus <= r_data;               
    end
    
    always @(posedge clk) begin
    if (~resetn)
        regExponant <= 1024'b0;
    else if (regExponant_en)
        regExponant <= r_data;               
    end
    
    always @(posedge clk) begin
    if (~resetn)
        regRN <= 1024'b0;
    else if (regRN_en)
        regRN <= r_data;               
    end
    
    always @(posedge clk) begin
    if (~resetn)
        regR2N <= 1024'b0;
    else if (regRN_en)
        regR2N <= r_data;               
    end    
    
    always @(posedge clk) begin
    if (~resetn)
        regResult <= 1024'b0;
    else if (regResult_en)
        regR2N <= resWire;               
    end    
//--------Data Path --------
   
  exp_v4(
    .clk(clk),
    .resetn(resetn),
    .start(exp_start),
    .in_RM(regRN),             
    .in_R2M(regR2N),
    .in_E(regExponant),
    .in_E_ln(exp_len),         
    .in_M(regModulus),
    .in_X(regMessage),
    .result(resWire),
    .done(exp_done)
  );

  assign dma_tx_data = regResult;

    
//-------- Finite State Machine -------- \\ 
    // Define state machine's states
    localparam
        STATE_IDLE           = 4'd0 ,
        STATE_GET_DATA       = 4'd1 ,
        STATE_GET_DATA_WAIT  = 4'd2 ,
        STATE_GET_MOD        = 4'd3 ,
        STATE_GET_MOD_WAIT   = 4'd4 ,
        STATE_GET_EXP        = 4'd5 ,
        STATE_GET_EXP_WAIT   = 4'd6 ,
        STATE_GET_RN         = 4'd7 ,
        STATE_GET_RN_WAIT    = 4'd8 ,
        STATE_GET_R2N        = 4'd9 ,
        STATE_GET_R2N_WAIT   = 4'd10,
        STATE_COMPUTE        = 4'd11,
        STATE_TX             = 4'd12,
        STATE_TX_WAIT        = 4'd13,
        STATE_DONE           = 4'd14;

    // FSM wires
    reg [2:0] state = STATE_IDLE;
    reg [2:0] next_state;

  // FSM update logic
  always@(*) begin // should this be posedge?
    // defaults
     regMessage_en  = 1'b0;
     regModulus_en  = 1'b0;
     regExponant_en = 1'b0;
     regRN_en       = 1'b0;
     regR2N_en      = 1'b0;
     regResult_en   = 1'b0;
     
     // Updates on transition
     if (state == STATE_GET_DATA_WAIT && next_state == STATE_GET_MOD )
        regMessage_en - 1'b1;
     if (state == STATE_GET_MOD_WAIT  && next_state == STATE_GET_EXP )
        regModulus_en  = 1'b1;
     if (state == STATE_GET_EXP_WAIT  && next_state == STATE_GET_RN  )
        regExponant_en = 1'b1;
     if (state == STATE_GET_RN_WAIT   && next_state == STATE_GET_R2N )
        regRN_en       = 1'b1;
     if (state == STATE_GET_R2N_WAIT  && next_state == STATE_GET_COMPUTE)
        regR2N_en      = 1'b1;
  end

  // FSM Transition logic
  always@(*) begin
    // defaults
    next_state   <= STATE_IDLE;

    // state defined logic
    case (state)
      // Wait in IDLE state till a compute command
      STATE_IDLE: begin
        next_state <= (isCmdComp) ? STATE_GET_DATA : state;
      end

      // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_GET_DATA: begin
        next_state <= (~dma_idle) ? STATE_GET_DATA_WAIT : state;
      end

      // Wait the completion of dma.
      STATE_GET_DATA_WAIT : begin
        next_state <= (dma_done) ? STATE_GET_MOD : state;
      end
     // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_GET_MOD: begin
        next_state <= (~dma_idle) ? STATE_GET_MOD_WAIT : state;
      end

      // Wait the completion of dma.
      STATE_GET_MOD_WAIT : begin
        next_state <= (dma_done) ? STATE_GET_EXP : state;
      end
      
      // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_GET_EXP: begin
        next_state <= (~dma_idle) ? STATE_GET_EXP_WAIT : state;
      end
      
      // Wait the completion of dma.
      STATE_GET_EXP_WAIT : begin
        next_state <= (dma_done) ? STATE_GET_RN : state;
      end
      
      // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_GET_RN: begin
        next_state <= (~dma_idle) ? STATE_GET_RN_WAIT : state;
      end
      
      // Wait the completion of dma.
      STATE_GET_RN_WAIT : begin
        next_state <= (dma_done) ? STATE_GET_R2N : state;
      end
      
      STATE_GET_R2N: begin
        next_state <= (~dma_idle) ? STATE_GET_R2N_WAIT : state;
      end
      
      // Wait the completion of dma.
      STATE_GET_R2N_WAIT : begin
        next_state <= (dma_done) ? STATE_COMPUTE : state;
      end
      
      STATE_COMPUTE : begin
        next_state <= (exp_done) ? STATE_TX : STATE_COMPUTE;
      end
      
      // Wait, if dma is not idle. Otherwise, start dma operation and go to
      // next state to wait its completion.
      STATE_TX : begin
        next_state <= (~dma_idle) ? STATE_TX_WAIT : state;
      end

      // Wait the completion of dma.
      STATE_TX_WAIT : begin
        next_state <= (dma_done) ? STATE_DONE : state;
      end

      // The command register might still be set to compute state. Hence, if
      // we go back immediately to the IDLE state, another computation will
      // start. We might go into a deadlock. So stay in this state, till CPU
      // sets the command to idle. While FPGA is in this state, it will
      // indicate the state with the status register, so that the CPU will know
      // FPGA is done with computation and waiting for the idle command.
      STATE_DONE : begin
        next_state <= (isCmdIdle) ? STATE_IDLE : state;
      end
    endcase
  end

  // Signal pull/push data DMA  
  always@(posedge clk) begin
    dma_rx_start <= 1'b0;
    dma_tx_start <= 1'b0;
    case (state)
      STATE_GET_DATA: dma_rx_start <= 1'b1;
      STATE_GET_MOD:  dma_rx_start <= 1'b1;
      STATE_GET_EXP:  dma_rx_start <= 1'b1;
      STATE_GET_RN:   dma_rx_start <= 1'b1;
      STATE_GET_R2N:  dma_rx_start <= 1'b1;
  
      STATE_TX: dma_tx_start <= 1'b1;
    endcase
  end

  // Synchronous state transitions
  always@(posedge clk)
    state <= (~resetn) ? STATE_IDLE : next_state;

  // Pull DMA data
  always@(posedge clk)
    case (state)
      STATE_GET_DATA_WAIT: r_data <= (dma_done)  ? dma_rx_data : r_data;
      STATE_GET_MOD_WAIT : r_data <= (dma_done)  ? dma_rx_data : r_data;
      STATE_GET_EXP_WAIT : r_data <= (dma_done)  ? dma_rx_data : r_data;
      STATE_GET_RN_WAIT  : r_data <= (dma_done)  ? dma_rx_data : r_data;
      STATE_GET_R2N_WAIT : r_data <= (dma_done)  ? dma_rx_data : r_data;
    endcase
    

  // Status signals to the CPU
  wire isStateIdle = (state == STATE_IDLE);
  wire isStateDone = (state == STATE_DONE);
  assign status = {29'b0, dma_error, isStateIdle, isStateDone};

endmodule
