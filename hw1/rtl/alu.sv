
module alu
  import config_pkg::*;
(
    input logic clk_i,
    input logic rst_ni,
    input logic [7:0] data_i,
    input logic ready_i,
    input logic valid_i,
    output logic ready_o,
    output logic valid_o,
    output logic [7:0] data_o
);

  wire uart;

  uart_tx uart_tx (
      .clk(clk_i),
      .rst(!rst_ni),
      .s_axis_tdata(data_i),
      .s_axis_tvalid(valid_i),
      .s_axis_tready(ready_o),
      .txd(uart),
      .busy(),
      .prescale(1)
  );

  uart_rx uart_rx (
      .clk(clk_i),
      .rst(!rst_ni),
      .m_axis_tdata(data_o),
      .m_axis_tvalid(valid_o),
      .m_axis_tready(ready_i),
      .rxd(uart),
      .busy(),
      .overrun_error(),
      .frame_error(),
      .prescale(1)
  );


endmodule
