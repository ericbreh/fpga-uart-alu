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

  state_t state_q, state_d;
  logic [15:0] pkt_length_q, pkt_length_d;
  logic [15:0] byte_count_q, byte_count_d;

  logic tx_ready_o, tx_valid_i;
  logic rx_ready_i, rx_valid_o;
  logic [DATA_WIDTH-1:0] rx_data_o, tx_data_i;

  logic [7:0] opcode_q, opcode_d;

  logic [31:0] accumulator_q, accumulator_d;
  logic [31:0] current_number_q, current_number_d;
  logic [1:0] number_byte_count_q, number_byte_count_d;
  logic [1:0] tx_byte_count_q, tx_byte_count_d;

  // Add multiplier control signals
  logic mul_v_i, mul_ready_and_o, mul_v_o, mul_yumi_i;
  logic [31:0] mul_result_o;

  // State signals for mul
  logic mul_v_q, mul_v_d;
  logic mul_yumi_q, mul_yumi_d;

  bsg_imul_iterative #(
      .width_p(32)
  ) multiplier (
      .clk_i(clk_i),
      .reset_i(!rst_ni),
      .v_i(mul_v_i),
      .ready_and_o(mul_ready_and_o),
      .opA_i(current_number_q),
      .signed_opA_i(1'b1),
      .opB_i(accumulator_q),
      .signed_opB_i(1'b1),
      .gets_high_part_i(1'b0),
      .v_o(mul_v_o),
      .result_o(mul_result_o),
      .yumi_i(mul_yumi_i)
  );

  uart_rx #(
      .DATA_WIDTH(DATA_WIDTH)
  ) uart_rx (
      .clk(clk_i),
      .rst(!rst_ni),
      .m_axis_tdata(rx_data_o),
      .m_axis_tvalid(rx_valid_o),
      .m_axis_tready(rx_ready_i),
      .prescale(33),
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
      .s_axis_tdata(tx_data_i),
      .s_axis_tvalid(tx_valid_i),
      .s_axis_tready(tx_ready_o),
      .prescale(33),
      .txd(txd_o),
      .busy()
  );

  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q <= IDLE;
      pkt_length_q <= '0;
      byte_count_q <= '0;
      opcode_q <= '0;
      accumulator_q <= '0;
      current_number_q <= '0;
      number_byte_count_q <= '0;
      tx_byte_count_q <= '0;
      mul_v_q <= 1'b0;
      mul_yumi_q <= 1'b0;
    end else begin
      state_q <= state_d;
      pkt_length_q <= pkt_length_d;
      byte_count_q <= byte_count_d;
      opcode_q <= opcode_d;
      accumulator_q <= accumulator_d;
      current_number_q <= current_number_d;
      number_byte_count_q <= number_byte_count_d;
      tx_byte_count_q <= tx_byte_count_d;
      mul_v_q <= mul_v_d;
      mul_yumi_q <= mul_yumi_d;
    end
  end

  always_comb begin
    state_d = state_q;
    pkt_length_d = pkt_length_q;
    byte_count_d = byte_count_q;
    opcode_d = opcode_q;
    accumulator_d = accumulator_q;
    current_number_d = current_number_q;
    number_byte_count_d = number_byte_count_q;
    tx_byte_count_d = tx_byte_count_q;
    tx_valid_i = '0;
    tx_data_i = '0;
    mul_v_d = 1'b0;
    mul_yumi_d = 1'b0;

    case (state_q)
      IDLE: begin
        if (rx_valid_o) state_d = RX_OPCODE;
      end

      RX_OPCODE: begin
        if (rx_valid_o) begin
          opcode_d = rx_data_o;
          state_d  = RX_RESERVED;
        end
      end

      RX_RESERVED: begin
        if (rx_valid_o) state_d = RX_LENGTH_LSB;
      end

      RX_LENGTH_LSB: begin
        if (rx_valid_o) begin
          state_d = RX_LENGTH_MSB;
          pkt_length_d[7:0] = rx_data_o;
        end
      end

      RX_LENGTH_MSB: begin
        if (rx_valid_o) begin
          case (opcode_q)
            OPCODE_ECHO: state_d = ECHO;
            OPCODE_ADD:  state_d = ADD;
            OPCODE_MUL: begin
              state_d = MUL;
            end
            // OPCODE_DIV:  state_d = DIV;
            default:     state_d = IDLE;
          endcase
          pkt_length_d[15:8] = rx_data_o;
          // set default values
          byte_count_d = '0;
          accumulator_d = '0;
          current_number_d = '0;
          number_byte_count_d = '0;
          tx_byte_count_d = '0;
        end
      end

      ECHO: begin
        tx_valid_i = rx_valid_o;
        tx_data_i  = rx_data_o;

        if (rx_valid_o && rx_ready_i) begin
          byte_count_d = byte_count_q + 1;
        end
        if (byte_count_q == pkt_length_q - 4) state_d = IDLE;
      end

      ADD: begin
        if (rx_valid_o && rx_ready_i) begin
          byte_count_d = byte_count_q + 1;

          // Build 32-bit number
          current_number_d = (current_number_q << 8) | {24'b0, rx_data_o};
          number_byte_count_d = number_byte_count_q + 1;

          // When we have a complete number
          if (number_byte_count_q == 2'd3) begin
            number_byte_count_d = '0;
            // Add the number to the accumulator
            accumulator_d = accumulator_q + ((current_number_q << 8) | {24'b0, rx_data_o});
            current_number_d = '0;
          end
        end
        if (byte_count_q == pkt_length_q - 4) state_d = TRANSMIT;
        tx_byte_count_d = '0;
      end

      MUL: begin
        if (rx_valid_o && rx_ready_i) begin
          byte_count_d = byte_count_q + 1;

          // Build 32-bit number
          current_number_d = (current_number_q << 8) | {24'b0, rx_data_o};
          number_byte_count_d = number_byte_count_q + 1;

          // When we have a complete number
          if (number_byte_count_q == 2'd3) begin
            number_byte_count_d = '0;

            if (mul_ready_and_o) begin
              if (accumulator_q == 0) begin
                // First number, just store it
                accumulator_d = current_number_d;
              end else begin
                mul_v_d = 1'b1;
                // Wait for multiplication result
                state_d = MUL_WAIT;
              end
              current_number_d = '0;
            end
          end
        end
        if (byte_count_q == pkt_length_q - 4) state_d = TRANSMIT;
      end

      // Add new state for multiplication
      MUL_WAIT: begin
        mul_yumi_d = 1'b1;
        if (mul_v_o) begin
          accumulator_d = mul_result_o;
          state_d = MUL;
        end
      end

      TRANSMIT: begin
        tx_valid_i = 1'b1;
        case (tx_byte_count_q)
          0: tx_data_i = accumulator_q[31:24];
          1: tx_data_i = accumulator_q[23:16];
          2: tx_data_i = accumulator_q[15:8];
          3: tx_data_i = accumulator_q[7:0];
        endcase

        if (tx_ready_o) begin
          if (tx_byte_count_q == 2'd3) begin
            tx_byte_count_d = '0;
            state_d = IDLE;
          end else begin
            tx_byte_count_d = tx_byte_count_q + 1;
          end
        end
      end

      default: begin
        state_d = IDLE;
      end
    endcase
  end

  assign rx_ready_i = (state_q != IDLE) && (state_q == ECHO ? tx_ready_o : 1'b1);
  assign mul_v_i = mul_v_q;
  assign mul_yumi_i = mul_yumi_q;

endmodule
