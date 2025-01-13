module icebreaker (
    input  wire CLK,      // 12MHz clock input
    input  wire BTN_N,    // Reset button
    input  wire RX,       // UART RX
    output wire TX        // UART TX
);

    wire clk_12 = CLK;
    wire clk_60;

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
        .BYPASS(1'b0),
        .PACKAGEPIN(CLK),
        .PLLOUTCORE(clk_60),
    );

    // ALU instance
    alu alu (
        .clk_i   (clk_60),
        .rst_ni  (BTN_N),
        .rxd_i   (RX),
        .txd_o   (TX)
    );

endmodule
