module icebreaker (
    input  wire CLK,      // 12MHz clock input
    input  wire BTN_N,    // Reset button
    input  wire RX,       // UART RX
    output wire TX        // UART TX
);

    wire clk_12 = CLK;
    wire clk_40.5;

    // PLL instance for 60MHz clock
    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'd0),
        .DIVF(7'd53),
        .DIVQ(3'd4),
        .FILTER_RANGE(3'd1)
    ) pll (
        .LOCK(),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .PACKAGEPIN(CLK),
        .PLLOUTCORE(clk_40.5),
    );

    // ALU instance
    alu alu (
        .clk_i   (clk_40.5),
        .rst_ni  (BTN_N),
        .rxd_i   (RX),
        .txd_o   (TX)
    );

endmodule
