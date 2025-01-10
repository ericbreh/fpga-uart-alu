module icebreaker (
    input  wire CLK,      // 12MHz clock input
    input  wire BTN_N,    // Reset button
);

    // Internal signals
    logic [7:0] data_i, data_o;
    logic ready_i, ready_o;
    logic valid_i, valid_o;
    wire pll_clk;

    // PLL instance for 60MHz clock
    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'b0000),     // DIVR =  0
        .DIVF(7'b1001111),  // DIVF = 79
        .DIVQ(3'b100),      // DIVQ =  4
        .FILTER_RANGE(3'b001)
    ) pll (
        .LOCK(),
        .RESETB(1'b1),
        .BYPASS(1'b0)
        .PACKAGEPIN(CLK),
        .PLLOUTCORE(pll_clk),
    );

    // ALU instance
    alu alu (
        .clk_i   (pll_clk),
        .rst_ni  (BTN_N),
        .data_i  (data_i),
        .ready_i (ready_i),
        .valid_i (valid_i),
        .ready_o (ready_o),
        .valid_o (valid_o),
        .data_o  (data_o)
    );

endmodule
