`timescale 1ns / 1ps

module mpadder(
  input  wire          clk,
  input  wire          resetn,
  input  wire          start,
  input  wire          subtract,
  input  wire [1026:0] in_a,
  input  wire [1026:0] in_b,
  output reg  [1027:0] result,
  output wire          done    
  );
  
  // Parameters
  parameter SEGMENT_WIDTH = 1027; // Adjustable: Set width of adder segment, to experiment -> BEST FOUND 160 | Try 171 gives 1026 then only add last standard
  parameter NUM_SEGMENTS = (1027 + SEGMENT_WIDTH - 1) / SEGMENT_WIDTH; // remove - 1 if not using factor of 1026 version
    
  // Internal signals 
  wire [NUM_SEGMENTS:0] carry_segment; // Carry between the segments 
  wire [1026:0]         sum;           // Output sum     

// Input Register A 
reg           regA_en;
reg  [1026:0] regA_out;
always @(posedge clk)
begin
    if(~resetn)         regA_out <= 1027'd0;
    else if (regA_en)   regA_out <= in_a;
end

// Subtraction MUX for B
wire [1026:0] muxB_out;
assign muxB_out = (subtract == 0) ? in_b : ~in_b;

// Input Register B
reg           regB_en;
reg  [1026:0] regB_out;
always @(posedge clk)
begin
    if(~resetn)         regB_out <= 1027'd0;
    else if (regB_en)   regB_out <= muxB_out;
end

// Input Register for Carry in (for subtraction)
reg          regCarryIn_en;
reg          carry_in;
always @(posedge clk)
begin
    if(~resetn)               carry_in <= 1'd0;
    else if (regCarryIn_en)   carry_in <= subtract;
end

//set the starting carry value for each segment
assign carry_segment[0] = carry_in;

// Create segmented adders
generate 
    genvar segment;
    for (segment = 0; segment < NUM_SEGMENTS; segment = segment + 1) begin : add_segment_loop //NB: FOR GENERIC GO TO NUM_SEGMENTs + 1
    
        // DEPRECIATED: Using 171 -> Known last segment is 1 bit
        //Last width is different
        localparam ADDER_WIDTH = (segment == NUM_SEGMENTS -1) ? 1027 - SEGMENT_WIDTH * segment : SEGMENT_WIDTH; 
        
        //localparam ADDER_WIDTH = SEGMENT_WIDTH;
        
//        // Segment adder inputs / outputs
        wire [ADDER_WIDTH-1:0] A_seg;
        wire [ADDER_WIDTH-1:0] B_seg;
        wire [ADDER_WIDTH-1:0] sum_seg; //output of segment 
        //wire                   carry_out_seg;
                

         
//        //Select the correct portion of the inputs
        assign A_seg = regA_out[SEGMENT_WIDTH * segment + ADDER_WIDTH - 1 : SEGMENT_WIDTH * segment]; // eg from [31:0] for s = 0, [63:32] for s=1 etc...
        assign B_seg = regB_out[SEGMENT_WIDTH * segment + ADDER_WIDTH - 1 : SEGMENT_WIDTH * segment];
        //
        
        // Segment adder inputs / outputs
        
        wire [SEGMENT_WIDTH-1:0] A_seg;
        wire [SEGMENT_WIDTH-1:0] B_seg;
        wire [SEGMENT_WIDTH-1:0] sum_seg; //output of segment 
                
         
        //Select the correct portion of the inputs
        assign A_seg = regA_out[SEGMENT_WIDTH * (segment + 1) - 1 : SEGMENT_WIDTH * segment]; // eg from [31:0] for s = 0, [63:32] for s=1 etc...
        assign B_seg = regB_out[SEGMENT_WIDTH * (segment + 1) - 1 : SEGMENT_WIDTH * segment];
        
        
        // DEPRECIATED
        // Version 1: Standard chunk adder | Works but too slow!
        adder_segment #(.WIDTH(ADDER_WIDTH)) adder_s (
            .a(A_seg),
            .b(B_seg),
            .carry_in(carry_segment[segment]), 
            .sum(sum_seg),
            .carry_out(carry_out_seg) 
        );
        assign carry_segment[segment + 1]= carry_out_seg;
         
        // Version 2; Carry Look-ahead logic -> WORKS BUT ALSO TOO SLOW
        
        // Generate Propagate for entire chunk
        /*
        wire G_Group;
        wire P_Group;
        
        // Get G, P for each chunk
        compute_GP_seg #(.WIDTH(ADDER_WIDTH)) gp_seg_s (
            .P(A_seg ^ B_seg),
            .G(A_seg & B_seg),
            .P_Group(P_Group),
            .G_Group(G_Group)
        );
        
        assign carry_segment[segment+1] = G_Group | ( P_Group & carry_segment[segment] ); 
        */
            

        // Version 3: Parrallel Prefix Adder (Brent-Kung):
//        bk_adder #(.WIDTH(SEGMENT_WIDTH)) bk_seg_s (
//            .A_seg(A_seg),
//            .B_seg(B_seg),
//            .carry_in( carry_segment[segment] ),
//            .sum(sum_seg),
//            .carry_out(carry_segment[segment + 1])
//        );

        
        //Assign the correct output of each block and the carry (for the next block)
        assign sum[SEGMENT_WIDTH * (segment + 1) - 1 : SEGMENT_WIDTH * segment] = sum_seg; 
        
    end
endgenerate    
//wire carry_out_last;
//wire sum_1027; 



//Version 4: Add last bit (1027)
//assign {carry_out_last, sum_1027} = (regA_out[1026] + regB_out[1026] + carry_segment[NUM_SEGMENTS]);

//Final bit register & mux | Carry Out Mux
wire muxCarry_out;
//assign muxCarry_out = (subtract == 0) ? carry_out_last : ~carry_out_last; 

assign muxCarry_out = (subtract == 0) ? carry_segment[NUM_SEGMENTS] : ~carry_segment[NUM_SEGMENTS];

//assign the output 
reg regResult_en;
always @(posedge clk) begin
    if (~resetn) result <= 1028'd0;
   //else if (regResult_en) result <= {muxCarry_out, sum_1027, sum};
    else if (regResult_en) result <= {muxCarry_out, sum};

end

// FSM States:
reg [1:0] state, nextstate;
localparam      IDLE = 1'b0,
                DONE = 1'b1;

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
            end

            // DONE state:
            DONE: begin
                regA_en         <= 1'b0;
                regB_en         <= 1'b0;
                regCarryIn_en   <= 1'b0;
                regResult_en    <= 1'b1;
            end

            default: begin
                regA_en        <= 1'b0;
                regB_en        <= 1'b0;
                regCarryIn_en  <= 1'b0;
                regResult_en   <= 1'b0;
            end

        endcase
    end

    // Describe next_state logic
    always @(*)
    begin
        case(state)
            IDLE: begin
                if(start)
                    nextstate <= DONE;
                else
                    nextstate <= IDLE;
            end
            DONE      : nextstate <= IDLE;
            default: nextstate <= IDLE;
        endcase
    end

    reg regDone;
    always @(posedge clk)
    begin
        if(~resetn) regDone <= 1'd0;
        else        regDone <= (state==DONE) ? 1'b1 : 1'b0;
    end

    assign done = regDone;

endmodule