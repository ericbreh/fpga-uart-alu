
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

  // state
  state_t state_d, state_q, future_state_d, future_state_q;
  logic is_echo_d, is_echo_q;

  // counter
  logic [1:0] byte_counter_d, byte_counter_q;

  logic [15:0] pkt_length_d, pkt_length_q;
  logic [4*DATA_WIDTH -1:0] accumulator_d, accumulator_q, current_number_d, current_number_q;

  // uart control signals
  logic rx_ready_i, rx_valid_o, tx_ready_o, tx_valid_i;
  logic [DATA_WIDTH-1:0] data_i, data_o;

  // multiplier control signals
  logic mul_ready_i, mul_valid_o, mul_ready_o, mul_valid_i;
  logic [4*DATA_WIDTH-1:0] mul_result_o;

  // divider control signals
  logic div_ready_i, div_valid_i, div_ready_o, div_valid_o;
  logic [4*DATA_WIDTH-1:0] div_result_o;

  // reset signal
  logic my_rst_ni;

  uart #(
      .DATA_WIDTH(DATA_WIDTH)
  ) uart (
      .clk(clk_i),
      .rst(!rst_ni),
      .m_axis_tdata(data_o),
      .m_axis_tready(rx_ready_i),
      .m_axis_tvalid(rx_valid_o),
      .prescale(33),
      .rxd(rxd_i),
      .txd(txd_o),
      .s_axis_tdata(data_i),
      .s_axis_tready(tx_ready_o),
      .s_axis_tvalid(tx_valid_i),
      .tx_busy(),
      .rx_busy(),
      .rx_overrun_error(),
      .rx_frame_error()
  );

  bsg_imul_iterative multiplier (
      .clk_i(clk_i),
      .reset_i(!rst_ni || !my_rst_ni),
      .v_i(mul_valid_i),
      .ready_and_o(mul_ready_o),
      .opA_i(accumulator_q),
      .signed_opA_i(1),
      .opB_i(current_number_q),
      .signed_opB_i(1),
      .gets_high_part_i(0),
      .v_o(mul_valid_o),
      .result_o(mul_result_o),
      .yumi_i(mul_ready_i)
  );

  bsg_idiv_iterative divider (
      .clk_i(clk_i),
      .reset_i(!rst_ni || !my_rst_ni),
      .v_i(div_valid_i),
      .ready_and_o(div_ready_o),
      .dividend_i(accumulator_q),
      .divisor_i(current_number_q),
      .signed_div_i(1),
      .v_o(div_valid_o),
      .quotient_o(div_result_o),
      .remainder_o(),
      .yumi_i(div_ready_i)
  );

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q <= OPCODE;
      future_state_q <= OPCODE;
      is_echo_q <= 0;
      byte_counter_q <= 0;
      pkt_length_q <= 0;
      accumulator_q <= 0;
      current_number_q <= 0;

    end else begin
      state_q <= state_d;
      future_state_q <= future_state_d;
      is_echo_q <= is_echo_d;
      byte_counter_q <= byte_counter_d;
      pkt_length_q <= pkt_length_d;
      accumulator_q <= accumulator_d;
      current_number_q <= current_number_d;
    end
  end

  always_comb begin
    state_d = state_q;
    future_state_d = future_state_q;
    is_echo_d = is_echo_q;
    byte_counter_d = byte_counter_q;
    pkt_length_d = pkt_length_q;
    accumulator_d = accumulator_q;
    current_number_d = current_number_q;

    // uart
    rx_ready_i = 1;
    tx_valid_i = 0;
    data_i = 0;

    // multiplier
    mul_ready_i = 0;
    mul_valid_i = 0;
    my_rst_ni = 1;

    unique case (state_q)

      OPCODE: begin
        is_echo_d = 0;
        if (rx_valid_o) begin
          // set future state and is_echo
          case (data_o)
            OPCODE_ECHO: begin
              future_state_d = ECHO;
              is_echo_d = 1;
            end
            OPCODE_ADD: future_state_d = ADD;
            OPCODE_MUL: future_state_d = MUL;
            OPCODE_DIV: future_state_d = DIV;
            default: future_state_d = OPCODE;
          endcase
          state_d = RESERVED;
        end
      end

      RESERVED: begin
        if (rx_valid_o) state_d = LENGTH_LSB;
      end

      LENGTH_LSB: begin
        if (rx_valid_o) begin
          pkt_length_d[DATA_WIDTH-1:0] = data_o;
          state_d = LENGTH_MSB;
        end
      end

      LENGTH_MSB: begin
        if (rx_valid_o) begin
          pkt_length_d[2*DATA_WIDTH-1:DATA_WIDTH] = data_o;
          state_d = (is_echo_q) ? ECHO : FIRST_NUMBER;

          byte_counter_d = 0;
          accumulator_d = 0;
          current_number_d = 0;
        end
      end

      ECHO: begin
        rx_ready_i = 0;
        if (rx_valid_o && tx_ready_o) begin
          rx_ready_i = 1;
          data_i = data_o;
          tx_valid_i = 1;
          pkt_length_d = pkt_length_q - 1;
        end
        if (pkt_length_q == 'd4) begin
          byte_counter_d = 0;
          state_d = OPCODE;
        end
      end

      FIRST_NUMBER: begin
        if (rx_valid_o) begin
          byte_counter_d = byte_counter_q + 1;
          pkt_length_d = pkt_length_q - 1;

          // load fisrt number straight into accumulator
          accumulator_d[byte_counter_q*8+:8] = data_o;

          // after 4 bytes
          if (byte_counter_q == 'd3) begin
            byte_counter_d = 0;
            state_d = RX_NUMBER;
          end
        end
      end

      RX_NUMBER: begin
        my_rst_ni = 0; // not sure why these need to be reset

        if (rx_valid_o) begin
          byte_counter_d = byte_counter_q + 1;
          pkt_length_d = pkt_length_q - 1;

          // load other numbers into current_number_d
          current_number_d[byte_counter_q*8+:8] = data_o;
          // Go to operation after 4 bytes
          if (byte_counter_q == 'd3) begin
            byte_counter_d = 0;
            state_d = future_state_q;
          end else if (pkt_length_q == 'd4) begin
            // all data is received
            byte_counter_d = 0;
            state_d = TRANSMIT;
          end
        end
      end

      ADD: begin
        rx_ready_i = 0;
        accumulator_d = accumulator_q + current_number_q;
        if (pkt_length_q == 'd4) begin
          state_d = TRANSMIT;
        end else begin
          state_d = RX_NUMBER;
        end
      end

      MUL: begin
        rx_ready_i  = 0;
        mul_ready_i = 1;
        // byte counter will be 0 on first time in this state, flash valid once
        if (mul_ready_o && byte_counter_q == 'd0) begin
          byte_counter_d = byte_counter_q + 1;
          mul_valid_i = 1;
        end
        // wait for data
        if (mul_valid_o) begin
          accumulator_d = mul_result_o;
          byte_counter_d = 0;
          // no more numbers
          if (pkt_length_q == 'd4) begin
            state_d = TRANSMIT;
            // get next number
          end else begin
            state_d = RX_NUMBER;
          end
        end
      end

      DIV: begin
        rx_ready_i  = 0;
        div_ready_i = 1;
        // byte counter will be 0 on first time in this state, flash valid once
        if (div_ready_o && byte_counter_q == 'd0) begin
          byte_counter_d = byte_counter_q + 1;
          div_valid_i = 1;
        end
        // wait for data
        if (div_valid_o) begin
          accumulator_d = div_result_o;
          byte_counter_d = 0;
          state_d = TRANSMIT;
        end
      end

      TRANSMIT: begin
        rx_ready_i = 0;
        if (tx_ready_o) begin
          if (byte_counter_q == 'd3) begin
            byte_counter_d = 0;
            state_d = OPCODE;
          end
          data_i = accumulator_q[byte_counter_q*8+:8];
          tx_valid_i = 1;
          byte_counter_d = byte_counter_q + 1;
        end
      end

    endcase
  end
endmodule
