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

  state_t state_d, state_q, future_state_d, future_state_q;

  logic rx_ready_i, rx_valid_o, tx_ready_o, tx_valid_i;
  logic [DATA_WIDTH-1:0] tx_data_i, rx_data_o;

  logic [15:0] pkt_length_d, pkt_length_q;
  // logic [1:0] bit_num_d, bit_num_q;

  uart #(
      .DATA_WIDTH(DATA_WIDTH)
  ) uart (
      .clk(clk_i),
      .rst(!rst_ni),
      .m_axis_tdata(rx_data_o),
      .m_axis_tready(rx_ready_i),
      .m_axis_tvalid(rx_valid_o),
      .prescale(33),
      .rxd(rxd_i),
      .txd(txd_o),
      .s_axis_tdata(tx_data_i),
      .s_axis_tready(tx_ready_o),
      .s_axis_tvalid(tx_valid_i),
      .tx_busy(),
      .rx_busy(),
      .rx_overrun_error(),
      .rx_frame_error()
  );

  // logic imul_ready_i, imul_valid_o, imul_ready_o, imul_valid_i, imul_rst_ni;
  // logic [4*DATA_WIDTH-1:0] imul_res_o;
  // bsg_imul_iterative #(
  //     .width_p(4 * DATA_WIDTH)
  // ) bsg_imul_iterative (
  //     .clk_i(clk_i),
  //     .reset_i(!rst_ni || !imul_rst_ni),
  //     .v_i(imul_valid_i),
  //     .ready_and_o(imul_ready_o),

  //     .opA_i(accum_q),
  //     .signed_opA_i(1),

  //     .opB_i(operand_q),
  //     .signed_opB_i(1),

  //     .gets_high_part_i(0),

  //     .v_o(imul_valid_o),
  //     .result_o(imul_res_o),
  //     .yumi_i(imul_ready_i)  // ready_i
  // );


  // logic [4*DATA_WIDTH -1:0] accum_d, accum_q, operand_d, operand_q;


  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      state_q <= RX_OPCODE;
      future_state_q <= RX_OPCODE;
      pkt_length_q <= 0;
      // bit_num_q <= 0;
      // accum_q <= 0;
      // operand_q <= 0;
    end else begin
      state_q <= state_d;
      future_state_q <= future_state_d;
      pkt_length_q <= pkt_length_d;
      // bit_num_q <= bit_num_d;
      // accum_q <= accum_d;
      // operand_q <= operand_d;
    end
  end

  always_comb begin
    state_d = state_q;
    future_state_d = future_state_q;
    pkt_length_d = pkt_length_q;
    // bit_num_d = bit_num_q;
    // accum_d = accum_q;
    // operand_d = operand_q;
    //ready to recive data by defualt
    rx_ready_i = 1;
    tx_valid_i = 0;
    tx_data_i = 0;

    // //multiplier
    // imul_ready_i = 0;
    // imul_valid_i = 0;
    // imul_rst_ni = 1;

    unique case (state_q)
      RX_OPCODE: begin
        if (rx_valid_o) begin
          case (rx_data_o)
            OPCODE_ECHO: future_state_d = ECHO;
            // OPCODE_ADD:  future_state_d = ADD;
            // OPCODE_MUL:  future_state_d = MUL;
            // OPCODE_DIV:  future_state_d = DIV;
            default:     future_state_d = RX_OPCODE;
          endcase
          state_d = RX_RESERVED;
        end
      end

      RX_RESERVED: begin
        if (rx_valid_o) state_d = RX_LENGTH_LSB;
      end

      RX_LENGTH_LSB: begin
        if (rx_valid_o) begin
          pkt_length_d[DATA_WIDTH-1:0] = rx_data_o;
          state_d = RX_LENGTH_MSB;
        end
      end

      RX_LENGTH_MSB: begin
        if (rx_valid_o) begin
          pkt_length_d[2*DATA_WIDTH-1:DATA_WIDTH] = rx_data_o;
          state_d = future_state_q;
        end
        // bit_num_d = 0;
        accum_d   = 0;
        operand_d = 0;
      end

      ECHO: begin
        rx_ready_i = 0;
        if (rx_valid_o && tx_ready_o) begin
          rx_ready_i = 1;
          tx_data_i = rx_data_o;
          tx_valid_i = 1;
          pkt_length_d = pkt_length_q - 1;
        end
        if (pkt_length_q == 'd4) begin
          // bit_num_d = 0;
          state_d = RX_OPCODE;
        end
      end

      // GET_INITIAL_OPERAND: begin
      //   // Wait for data
      //   if (rx_valid_o) begin
      //     // Change counters
      //     bit_num_d = bit_num_q + 1;
      //     pkt_length_d = pkt_length_q - 1;
      //     // Get next data after 4 bytes
      //     if (bit_num_q == 'd3) begin
      //       bit_num_d = 0;
      //       state_d   = GET_OPERAND;
      //     end
      //     // Bail out if we have all the data
      //     if (pkt_length_q == 'd4) begin
      //       bit_num_d = 0;
      //       state_d   = TRANSMIT;
      //     end
      //     // Load data in
      //     accum_d[bit_num_q*8+:8] = rx_data_o;
      //   end
      // end

      // GET_OPERAND: begin
      //   //this is weird but might need?
      //   imul_rst_ni = 0;

      //   if (rx_valid_o) begin
      //     bit_num_d = bit_num_q + 1;
      //     pkt_length_d = pkt_length_q - 1;
      //     // Go to operation after 4 bytes
      //     if (bit_num_q == 'd3) begin
      //       bit_num_d = 0;
      //       state_d   = future_state_q;
      //     end else if (pkt_length_q == 'd4) begin
      //       // Go to transmit if all data is received
      //       bit_num_d = 0;
      //       state_d   = TRANSMIT;
      //     end
      //     // Load data in
      //     operand_d[bit_num_q*8+:8] = rx_data_o;
      //   end
      // end

      // ADD: begin
      //   // Don't get more data
      //   rx_ready_i = 0;
      //   // Probably don't need this
      //   bit_num_d = 0;
      //   // Add the two operands
      //   accum_d = accum_q + operand_q;
      //   // Transition
      //   if (pkt_length_q == 'd4) begin
      //     //if all data is recived then transmit
      //     state_d = TRANSMIT;
      //   end else begin
      //     state_d = GET_OPERAND;
      //   end
      // end

      // MUL: begin
      //   // Don't get more data from reciver
      //   rx_ready_i   = 0;
      //   // ready for data from multiplier
      //   imul_ready_i = 1;
      //   // imul_valid_i = 1;
      //   if (imul_ready_o && bit_num_q == 'd0) begin
      //     // state_d = TRANSMIT;
      //     bit_num_d = bit_num_q + 1;
      //     imul_valid_i = 1;
      //   end
      //   // For this to work we assume that bit_num_q is 0 when entering
      //   // if (bit_num_q == 'd0) begin
      //   //   // This is kinda jank. need a way to set valid high for one cycle
      //   //   bit_num_d = bit_num_q + 1;
      //   //   imul_valid_i = 1;
      //   //   // state_d   = TRANSMIT;
      //   // end

      //   // // if(imul_valid_o) begin
      //   // // end
      //   // // Already said we are ready so now we wait for data to come back
      //   if (imul_valid_o) begin
      //     accum_d = imul_res_o;
      //     if (pkt_length_q == 'd4) begin
      //       // If all data is recived then transmit. Counter is messed up so
      //       // it should be reset for next stage.
      //       bit_num_d = 0;
      //       state_d   = TRANSMIT;
      //     end else begin
      //       // Need to reset counter.
      //       bit_num_d = 0;
      //       state_d   = GET_OPERAND;
      //     end
      //   end
      // end

      // TRANSMIT: begin
      //   rx_ready_i = 0;
      //   if (tx_ready_o) begin
      //     if (bit_num_q == 'd3) begin
      //       bit_num_d = 0;
      //       state_d   = RX_OPCODE;
      //     end
      //     tx_data_i  = accum_q[bit_num_q*8+:8];
      //     tx_valid_i = 1;
      //     bit_num_d  = bit_num_q + 1;
      //   end
      // end
    endcase
  end
endmodule
