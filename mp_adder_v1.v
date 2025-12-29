`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2024 05:03:38 PM
// Design Name: 
// Module Name: mp_adder_v1
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


module mp_adder_v1 #(parameter INPUT_WIDTH = 1027)  (
  input  wire          clk,
  input  wire          resetn,
  input  wire          start,
  input  wire          subtract,
  input  wire          carry_input, //fix also for generic carry in
  input  wire [INPUT_WIDTH-1:0] in_a,
  input  wire [INPUT_WIDTH-1:0] in_b,
  output reg  [INPUT_WIDTH:0] result,
  output wire          done    
  );
  
  // Parameters
  localparam SEGMENT_WIDTH = 48; // fixed for DSP48E
  
  localparam CYCLES = 8; 
  localparam NUM_SEGMENTS = ( (INPUT_WIDTH+1) / (SEGMENT_WIDTH*CYCLES) ) + 1 ;
  localparam DSP_ADDER_WIDTH = NUM_SEGMENTS * SEGMENT_WIDTH;   
  localparam TOTAL_WIDTH = DSP_ADDER_WIDTH * CYCLES;
    
  localparam    IDLE = 2'b00,
                UNDF =  2'b01,
                CALC = 2'b10,
                DONE  = 2'b11;
  
    
  // Internal signals 
  wire [NUM_SEGMENTS:0]           carry_segment; // Carry between the segments 
  wire [DSP_ADDER_WIDTH-1:0]        partial_sum;           // Output sum     

/**
 * Mux for register A
 * Either loads input or loads the remaining pieces to still be added  
**/
wire [TOTAL_WIDTH-1:0] muxA;
assign muxA = (state == IDLE) ? {{(TOTAL_WIDTH - INPUT_WIDTH){1'b0}}, in_a} : regA_out >> DSP_ADDER_WIDTH; // {{(DSP_ADDER_WIDTH){1'b0}}, regA_out[TOTAL_WIDTH-1:DSP_ADDER_WIDTH]};  //

// Input Register A 
reg                     regA_en;
reg  [TOTAL_WIDTH-1:0] regA_out;
always @(posedge clk)
begin
    if(~resetn)         regA_out <= {(TOTAL_WIDTH){1'b0}};
    else if (regA_en)   regA_out <= muxA; 
end

// Subtraction MUX for B
reg [TOTAL_WIDTH-1:0] muxB;
always @(*) begin
    if (state == IDLE) begin
        if (subtract) 
            muxB = {{(TOTAL_WIDTH - INPUT_WIDTH){1'b0}} ,~in_b}; 
        else 
            muxB = {{(TOTAL_WIDTH - INPUT_WIDTH){1'b0}} , in_b};
    end
    else begin
        muxB = regB_out >> DSP_ADDER_WIDTH;// {{(DSP_ADDER_WIDTH){1'b0}}, regB_out[TOTAL_WIDTH-1:DSP_ADDER_WIDTH]};
    end
end

// Input Register B
reg                     regB_en;
reg  [TOTAL_WIDTH-1:0] regB_out;
always @(posedge clk)
begin
    if(~resetn)         regB_out <= {(TOTAL_WIDTH){1'b0}};
    else if (regB_en)   regB_out <= muxB;
end

/**
 * Carry in register
 * On load set to subtract 
 * On calculation set to carry_out of the last segment 
**/
reg          regCarryIn_en;
reg               carry_in;
always @(posedge clk)
begin
    if(~resetn)               carry_in <= 1'd0;
//    else if (state == IDLE)   carry_in <= subtract | carry_in;
    else if (state == IDLE)   carry_in <= subtract | carry_input;
    else carry_in <= carry_segment[NUM_SEGMENTS];
end

//set the starting carry value for each segment
assign carry_segment[0] = carry_in; // TODO: CHECK

// Create segmented adders
generate 
    genvar segment;
    for (segment = 0; segment < NUM_SEGMENTS; segment = segment + 1) begin : add_segment_loop 
    
        
        localparam ADDER_WIDTH = SEGMENT_WIDTH;
        
       // Segment adder inputs / outputs
        wire [ADDER_WIDTH-1:0] A_seg;
        wire [ADDER_WIDTH-1:0] B_seg;
        wire [ADDER_WIDTH-1:0] sum_seg; //output of segment 
        wire                   carry_out_seg;
                

         
//        //Select the correct portion of the inputs
        assign A_seg = regA_out[SEGMENT_WIDTH * segment + ADDER_WIDTH - 1 : SEGMENT_WIDTH * segment]; // eg from [31:0] for s = 0, [63:32] for s=1 etc...
        assign B_seg = regB_out[SEGMENT_WIDTH * segment + ADDER_WIDTH - 1 : SEGMENT_WIDTH * segment];
        
   
        // versie 5: DSP Adder
        dsp_adder dsp_slice_s (
            .clk(clk),
            .rst(~resetn),
            .A_in(A_seg),
            .B_in(B_seg),
            .carry_in(carry_segment[segment]), 
            .P_out(sum_seg),
            .carry_out(carry_out_seg) 
        );
        assign carry_segment[segment + 1]= carry_out_seg;
     
        //Assign the correct output of each block and the carry (for the next block)
        assign partial_sum[SEGMENT_WIDTH * (segment + 1) - 1 : SEGMENT_WIDTH * segment] = sum_seg; 
        
    end
endgenerate    

//Save the partial sum in the correct location: 
reg sum_en;
reg [TOTAL_WIDTH-1:0] sum; 
always @(posedge clk) begin
    if (~resetn) sum <= {(TOTAL_WIDTH){1'b0}};
    else if (sum_en) sum <= {partial_sum, sum[TOTAL_WIDTH-1:DSP_ADDER_WIDTH]}; 
end

reg regResult_en;
always @(posedge clk) begin
    if (~resetn) result <= {(INPUT_WIDTH+1){1'b0}};
    else if (regResult_en) result <= { sum[1027] ^ subtract , sum[1026:0] };
end


// FSM States:
reg [1:0] state, nextstate;

reg [3:0] count; 
always @(posedge  clk) begin
    if(state == CALC)
        count <= count + 1'b1;        
    else 
        count <= 4'b0;
end 

always @(posedge clk) begin
    if(~resetn)	state <= IDLE;
    else state <= nextstate;
end

always @(*)
    begin
        case(state)

            // Idle state; Here the FSM waits for the start signal
            // Enable input registers to fetch the inputs A and B when start is received
            IDLE: begin
                regA_en         <= 1'b1;
                regB_en         <= 1'b1;
                regCarryIn_en   <= 1'b1;
                regResult_en    <= 1'b0;
                sum_en          <= 1'b1;
            end 
            
            CALC: begin 
                regA_en         <= 1'b1;
                regB_en         <= 1'b1;
                regCarryIn_en   <= 1'b1;
                regResult_en    <= 1'b1;     
                sum_en          <= 1'b1;
   
            end
            // DONE state:
            DONE: begin
                regA_en         <= 1'b1;
                regB_en         <= 1'b1;
                regCarryIn_en   <= 1'b1;
                sum_en          <= 1'b1;
                regResult_en    <= 1'b1;

            end
            UNDF: begin
                regA_en        <= 1'b0;
                regB_en        <= 1'b0;
                regCarryIn_en  <= 1'b0;
                regResult_en   <= 1'b0;
                sum_en         <= 1'b0;

            end
            default: begin
                regA_en        <= 1'b0;
                regB_en        <= 1'b0;
                regCarryIn_en  <= 1'b0;
                regResult_en   <= 1'b0;
                sum_en         <= 1'b0;

            end
        endcase
    end

    // Describe next_state logic
always @(*)
    begin
        case(state)
            IDLE: begin
                if(start)
                    nextstate <= CALC;
                else
                    nextstate <= IDLE;
            end

            CALC: begin
                if (count < CYCLES-1)
                    nextstate <= CALC;
                else 
                    nextstate <= DONE;
            end 
            DONE      : nextstate <= IDLE;
            UNDF      : nextstate <= IDLE;
            default: nextstate <= IDLE;
        endcase
    end

    reg regDone;
    always @(posedge clk)
    begin
        if(~resetn) regDone <= 1'd0;
        else        regDone <= ( state == DONE  ) ? 1'b1 : 1'b0;
    end

    assign done = regDone;

endmodule