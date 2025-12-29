module bk_adder #(parameter WIDTH = 64) (
    input  [WIDTH-1:0] A_seg,
    input  [WIDTH-1:0] B_seg,
    input              carry_in,
    output [WIDTH-1:0] sum,
    output             carry_out
);
    // Compute the number of levels needed
    localparam LEVELS = $clog2(WIDTH);
    localparam TOTAL_WIDTH = 1 << LEVELS;  // Next power of two

    // Extend A_seg and B_seg to TOTAL_WIDTH by padding with zeros | Redundance re-area -> select good widths
    wire [TOTAL_WIDTH-1:0] A_ext = {{(TOTAL_WIDTH-WIDTH){1'b0}}, A_seg};
    wire [TOTAL_WIDTH-1:0] B_ext = {{(TOTAL_WIDTH-WIDTH){1'b0}}, B_seg};

    // Per-bit propagate and generate signals
    wire [TOTAL_WIDTH-1:0] G_0 = A_ext & B_ext;
    wire [TOTAL_WIDTH-1:0] P_0 = A_ext ^ B_ext;

    // Arrays to hold the group generate and propagate signals
    wire [TOTAL_WIDTH-1:0] G [0:LEVELS];
    wire [TOTAL_WIDTH-1:0] P [0:LEVELS];

    // Initialize level 0
    assign G[0] = G_0;
    assign P[0] = P_0;

    genvar i, j;
    generate
        // Up-sweep: Build the tree
        for (i = 1; i <= LEVELS; i = i + 1) begin : up_sweep
            for (j = 0; j < TOTAL_WIDTH; j = j + 1) begin : up_sweep_bits
                if (j >= (1 << (i - 1))) begin
                    assign G[i][j] = G[i-1][j] | (P[i-1][j] & G[i-1][j - (1 << (i - 1))]);
                    assign P[i][j] = P[i-1][j] & P[i-1][j - (1 << (i - 1))];
                end else begin
                    assign G[i][j] = G[i-1][j];
                    assign P[i][j] = P[i-1][j];
                end
            end
        end

        // Compute cumulative generate and propagate signals for each bit
        wire [TOTAL_WIDTH-1:0] G_total;
        wire [TOTAL_WIDTH-1:0] P_total;

        for (j = 0; j < TOTAL_WIDTH; j = j + 1) begin : compute_cumulative_GP
            if (j == 0) begin
                // For the first bit, cumulative G and P are just G[0][0] and P[0][0]
                assign G_total[j] = G[0][j];
                assign P_total[j] = P[0][j];
            end else begin
                // Cumulative G and P from bits 0 to j
                assign G_total[j] = G[LEVELS][j];
                assign P_total[j] = P[LEVELS][j];
            end
        end

        // Compute carries
        wire [TOTAL_WIDTH:0] C;
        assign C[0] = carry_in;

        for (j = 0; j < TOTAL_WIDTH; j = j + 1) begin : compute_carries
            assign C[j+1] = G_total[j] | (P_total[j] & carry_in);
        end
    endgenerate

    // Compute sum bits
    assign sum = P_0[WIDTH-1:0] ^ C[WIDTH-1:0];

    // Carry-out from the chunk
    assign carry_out = C[WIDTH];

endmodule



