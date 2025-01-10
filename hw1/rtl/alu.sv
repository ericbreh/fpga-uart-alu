
module alu
  import config_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,
    input  logic rxd_i,
    output logic txd_o
);

  wire ready;
  wire valid;
  logic [7:0] data;

  uart_tx uart_tx (
      .clk(clk_i),
      .rst(!rst_ni),
      .s_axis_tdata(data),
      .s_axis_tvalid(valid),
      .s_axis_tready(ready),
      .txd(txd_o),
      .busy(),
      .prescale(65)
  );

  uart_rx uart_rx (
      .clk(clk_i),
      .rst(!rst_ni),
      .m_axis_tdata(data),
      .m_axis_tvalid(valid),
      .m_axis_tready(ready),
      .rxd(rxd_i),
      .busy(),
      .overrun_error(),
      .frame_error(),
      .prescale(65)
  );


endmodule
