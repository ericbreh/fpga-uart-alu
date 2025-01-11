
module alu_runner;
  reg  CLK;
  reg  BTN_N = 0;
  logic RX;
  logic TX;

  initial begin
    CLK = 0;
    forever begin
      #41.666ns;  // 12MHz
      CLK = !CLK;
    end
  end

  logic pll_out;
  initial begin
    pll_out = 0;
    forever begin
      #8.333ns;  // 60MHz
      pll_out = !pll_out;
    end
  end
  assign icebreaker.pll.PLLOUTCORE = pll_out;

  icebreaker icebreaker (.*);

  task reset();
    BTN_N = 0;
    RX  = 1;
    repeat (5) @(posedge CLK);
    BTN_N = 1;
    repeat (5) @(posedge CLK);
  endtask

  logic [7:0] test_tx_data;
  logic test_tx_valid;
  logic test_tx_ready;

  logic [7:0] test_rx_data;
  logic test_rx_valid;
  logic test_rx_ready;

  uart_tx test_tx (
      .clk(CLK),
      .rst(!BTN_N),
      .s_axis_tdata(test_tx_data),
      .s_axis_tvalid(test_tx_valid),
      .s_axis_tready(test_tx_ready),
      .txd(RX),
      .busy(),
      .prescale(65)
  );

  uart_rx test_rx (
      .clk(CLK),
      .rst(!BTN_N),
      .m_axis_tdata(test_rx_data),
      .m_axis_tvalid(test_rx_valid),
      .m_axis_tready(test_rx_ready),
      .rxd(TX),
      .busy(),
      .overrun_error(),
      .frame_error(),
      .prescale(65)
  );

  task send(input logic [7:0] data);
    test_tx_data  = data;
    test_tx_valid = 1;
    wait (test_tx_ready);
    @(posedge CLK);
    test_tx_valid = 0;

    // wait (!test_tx_ready);
    // @(posedge clk_i);
  endtask

  task receive(output logic [7:0] data);
    test_rx_ready = 1;
    @(posedge CLK);
    wait (test_rx_valid);
    @(posedge CLK);
    data = test_rx_data;
    @(posedge CLK);
    test_rx_ready = 0;

    // wait (!test_rx_valid);
    // @(posedge CLK);
  endtask

endmodule
