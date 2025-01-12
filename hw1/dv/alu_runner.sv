module alu_runner;
  logic clk_i;
  logic rst_ni;
  logic rxd_i;
  logic txd_o;

  localparam realtime ClockPeriod = 5ms;

  initial begin
    clk_i = 0;
    forever begin
      #(ClockPeriod / 2);
      clk_i = !clk_i;
    end
  end

  alu dut (
      .clk_i,
      .rst_ni,
      .rxd_i,
      .txd_o
  );

  task reset();
    rst_ni = 0;
    rxd_i  = 1;
    repeat (5) @(posedge clk_i);
    rst_ni = 1;
    repeat (5) @(posedge clk_i);
  endtask

  logic [7:0] test_tx_data;
  logic test_tx_valid;
  logic test_tx_ready;

  logic [7:0] test_rx_data;
  logic test_rx_valid;
  logic test_rx_ready;

  uart_tx test_tx (
      .clk(clk_i),
      .rst(!rst_ni),
      .s_axis_tdata(test_tx_data),
      .s_axis_tvalid(test_tx_valid),
      .s_axis_tready(test_tx_ready),
      .txd(rxd_i),
      .busy(),
      .prescale(65)
  );

  uart_rx test_rx (
      .clk(clk_i),
      .rst(!rst_ni),
      .m_axis_tdata(test_rx_data),
      .m_axis_tvalid(test_rx_valid),
      .m_axis_tready(test_rx_ready),
      .rxd(txd_o),
      .busy(),
      .overrun_error(),
      .frame_error(),
      .prescale(65)
  );

  task send(input logic [7:0] data);
    test_tx_data  = data;
    test_tx_valid = 1;
    wait (test_tx_ready);
    @(posedge clk_i);
    test_tx_valid = 0;
  endtask

  task receive(output logic [7:0] data);
    test_rx_ready = 1;
    @(posedge clk_i);
    wait (test_rx_valid);
    @(posedge clk_i);
    data = test_rx_data;
    @(posedge clk_i);
    test_rx_ready = 0;
  endtask

endmodule
