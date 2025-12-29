module dsp_adder (
    input wire clk,             // Clock input
    input wire rst,             // Reset input (active high)
    input wire [47:0] A_in,     // First operand (48 bits)
    input wire [47:0] B_in,     // Second operand (48 bits)
    input wire carry_in,        // Carry-in input (1 bit)
    output wire [47:0] P_out,   // Sum output (48 bits)
    output wire carry_out       // Carry-out output (1 bit)
);
    // Internal signals
    wire [29:0] A_wire;
    wire [17:0] B_wire;
    wire [47:0] C_wire;
    wire [47:0] P_wire;
    wire [3:0] ALUMODE_wire;
    wire [6:0] OPMODE_wire;
    wire [2:0] CARRYINSEL_wire;
    wire CARRYIN_wire;
    wire [3:0] CARRYOUT_wire;

    // Assign input operands to DSP48E1 inputs
    // The DSP48E1 has specific input widths; we need to split the 48-bit inputs accordingly
    assign A_wire = A_in[47:18];         // Upper 30 bits of A_in
    assign B_wire = A_in[17:0];          // Lower 18 bits of A_in (used for B input)
    assign C_wire = B_in;                // Full 48-bit B_in connected to C port
    assign CARRYIN_wire = carry_in;

    // Configure ALUMODE, OPMODE, and CARRYINSEL for addition
    assign ALUMODE_wire = 4'b0000;       // ALU performs (A + B) + C + carry-in
    assign OPMODE_wire = 7'b0001111;     // Select A:B, and C inputs for addition (Mux X = A:B, Mux Y = C)
    assign CARRYINSEL_wire = 3'b000;     // Select CARRYIN input

    // Instantiate the DSP48E1 block
    DSP48E1 #(
        // Feature Control Attributes
        .A_INPUT("DIRECT"),          // Use A port directly
        .B_INPUT("DIRECT"),          // Use B port directly
        .USE_DPORT("FALSE"),         // Do not use D port
        .USE_MULT("NONE"),           // Disable multiplier
        .USE_SIMD("ONE48"),          // 48-bit mode
        // Pattern Detector Attributes: Not used in this configuration
        .AUTORESET_PATDET("NO_RESET"),
        .MASK(48'h3FFFFFFFFFFF),
        .PATTERN(48'h000000000000),
        .SEL_MASK("MASK"),
        .SEL_PATTERN("PATTERN"),
        .USE_PATTERN_DETECT("NO_PATDET"),
        // Register Control Attributes: No pipeline registers used
        .ACASCREG(0),
        .ALUMODEREG(0),
        .AREG(0),
        .BCASCREG(0),
        .BREG(0),
        .CARRYINREG(0),
        .CARRYINSELREG(0),
        .CREG(0),
        .MREG(0),
        .OPMODEREG(0),
        .PREG(0)
    ) DSP48E1_inst (
        // Cascade outputs: Not used
        .ACOUT(),
        .BCOUT(),
        .CARRYCASCOUT(),
        .MULTSIGNOUT(),
        .PCOUT(),
        // Control outputs: Not used
        .OVERFLOW(),
        .PATTERNBDETECT(),
        .PATTERNDETECT(),
        .UNDERFLOW(),
        // Data outputs
        .CARRYOUT(CARRYOUT_wire),    // 4-bit carry-out output
        .P(P_wire),                  // 48-bit primary output
        // Cascade inputs: Not used
        .ACIN(30'b0),
        .BCIN(18'b0),
        .CARRYCASCIN(1'b0),
        .MULTSIGNIN(1'b0),
        .PCIN(48'b0),
        // Control inputs
        .ALUMODE(ALUMODE_wire),
        .CARRYINSEL(CARRYINSEL_wire),
        .CLK(clk),
        .INMODE(5'b00000),

        .OPMODE(OPMODE_wire),
        // Data inputs
        .A(A_wire),         // Extend A_wire to 48 bits by adding zeros
        .B(B_wire),                  // B input
        .C(C_wire),                  // C input
        .CARRYIN(CARRYIN_wire),      // Carry-in input
        .D(25'b0),                   // D port not used
        // Reset/Clock Enable inputs: Tie low (no resets or clock enables used)
        .CEA1(1'b0),
        .CEA2(1'b0),
        .CEAD(1'b0),
        .CEALUMODE(1'b0),
        .CEB1(1'b0),
        .CEB2(1'b0),
        .CEC(1'b0),
        .CECARRYIN(1'b0),
        .CECTRL(1'b0),
        .CED(1'b0),
        .CEINMODE(1'b0),
        .CEM(1'b0),
        .CEP(1'b0),
        .RSTA(rst),
        .RSTALLCARRYIN(rst),
        .RSTALUMODE(rst),
        .RSTB(rst),
        .RSTC(rst),
        .RSTCTRL(rst),
        .RSTD(rst),
        .RSTINMODE(rst),
        .RSTM(rst),
        .RSTP(rst)
    );

    // Assign the output
    assign P_out = P_wire;
    assign carry_out = CARRYOUT_wire[3];  // Use the most significant carry-out bit

endmodule