module icebreaker (
    input  wire CLK,      // 12MHz clock input
    input  wire BTN_N,    // Reset button
    input  wire RX,       // UART RX
    output wire TX        // UART TX
);

    wire clk_12 = CLK;
    wire clk_30.5;

    // https://www.desmos.com/calculator/tbvv5cego6
    // icepll -i 12 -o 30.5

    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'd0),
        .DIVF(7'd80),
        .DIVQ(3'd5),
        .FILTER_RANGE(3'd1)
    ) pll (
        .LOCK(),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .PACKAGEPIN(CLK),
        .PLLOUTGLOBAL(clk_30.5),
    );

    // ALU instance
    alu alu (
        .clk_i   (clk_30.5),
        .rst_ni  (BTN_N),
        .rxd_i   (RX),
        .txd_o   (TX)
    );

endmodule
