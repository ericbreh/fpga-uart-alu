module alu
  import config_pkg::*;
#(
    parameter DATA_WIDTH = 8
) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic rxd_i,
    output logic txd_o
);

  // State and control signals
  state_t state_q, state_d;
  logic [15:0] pkt_length_q, pkt_length_d;
  logic [15:0] byte_count_q, byte_count_d;

  logic tx_ready_o, tx_valid_i;
  logic rx_ready_o, rx_valid_i;
  logic [DATA_WIDTH-1:0] rx_data_i, tx_data_o;

  uart_rx #(
      .DATA_WIDTH(DATA_WIDTH)
  ) uart_rx (
      .clk(clk_i),
      .rst(!rst_ni),
      .m_axis_tdata(rx_data_i),
      .m_axis_tready(rx_ready_o),
      .m_axis_tvalid(rx_valid_i),
      .prescale(44),
      .rxd(rxd_i),
      .busy(),
      .frame_error(),
      .overrun_error()
  );

  uart_tx #(
      .DATA_WIDTH(DATA_WIDTH)
  ) uart_tx (
      .clk(clk_i),
      .rst(!rst_ni),
      .s_axis_tdata(tx_data_o),
      .s_axis_tready(tx_ready_o),
      .s_axis_tvalid(tx_valid_i),
      .prescale(44),
      .txd(txd_o),
      .busy()
  );

  // State machine sequential logic
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q <= IDLE;
      pkt_length_q <= '0;
      byte_count_q <= '0;
    end else begin
      state_q <= state_d;
      pkt_length_q <= pkt_length_d;
      byte_count_q <= byte_count_d;
    end
  end

  // State machine combinational logic
  always_comb begin
    state_d = state_q;
    pkt_length_d = pkt_length_q;
    byte_count_d = byte_count_q;

    case (state_q)
      IDLE: begin
        if (rx_valid_i) state_d = RX_OPCODE;
      end

      RX_OPCODE: begin
        if (rx_valid_i && rx_data_i == 8'hEC) state_d = RX_RESERVED;
      end

      RX_RESERVED: begin
        if (rx_valid_i) state_d = RX_LENGTH_LSB;
      end

      RX_LENGTH_LSB: begin
        if (rx_valid_i) begin
          state_d = RX_LENGTH_MSB;
          pkt_length_d[7:0] = rx_data_i;
        end
      end

      RX_LENGTH_MSB: begin
        if (rx_valid_i) begin
          state_d = RX_DATA;
          pkt_length_d[15:8] = rx_data_i;
          byte_count_d = '0;
        end
      end

      RX_DATA: begin
        if (rx_valid_i && rx_ready_o) begin
          byte_count_d = byte_count_q + 1;
        end
        if (byte_count_q == pkt_length_q - 4)  // Header size is 4 bytes
          state_d = IDLE;
      end
    endcase
  end

  // TX data handling just echo back
  assign tx_valid_i = (state_q == RX_DATA) && rx_valid_i;
  assign tx_data_o  = rx_data_i;
  assign rx_ready_o = (state_q != IDLE) && (state_q == RX_DATA ? tx_ready_o : 1'b1);

endmodule
