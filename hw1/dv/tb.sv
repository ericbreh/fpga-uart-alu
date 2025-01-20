module tb;
  import config_pkg::*;
  import dv_pkg::*;
  ;
  alu_runner runner ();

  task automatic test_echo(input string message);
    logic [7:0] data[];
    logic [7:0] received[256];
    logic [15:0] packet_len;
    logic [7:0] header[4];
    int msg_len;

    // Convert string to byte array
    msg_len = message.len();
    data = new[msg_len];
    foreach (message[i]) begin
      data[i] = message[i];
    end

    // Calculate packet length (header + data)
    packet_len = 16'd4 + 16'(msg_len);

    $display("Message: %s", message);

    // Set up header
    header[0] = OPCODE_ECHO;
    header[1] = 8'h00;
    header[2] = packet_len[7:0];
    header[3] = packet_len[15:8];

    // Send header bytes
    foreach (header[i]) begin
      runner.send(header[i]);
      // $display("Sent header: %h", header[i]);
    end

    // For data section, send one byte and receive it back immediately
    for (int i = 0; i < msg_len; i++) begin
      runner.send(data[i]);
      // $display("Sent data: %h", data[i]);
      runner.receive(received[i]);
      // $display("Received: %h", received[i]);

      if (received[i] !== data[i]) begin
        $display("FAIL - Mismatch at position %0d: expected %h, got %h", i, data[i], received[i]);
        return;
      end
    end
    $display("PASS");
  endtask

  task automatic send_packet(input logic [7:0] opcode, input logic [15:0] len,
                             input logic [7:0] data[]);
    logic [7:0] header[4];
    header[0] = opcode;
    header[1] = 8'h00;  // Reserved
    header[2] = len[7:0];
    header[3] = len[15:8];

    // Send header
    foreach (header[i]) begin
      runner.send(header[i]);
      $display("Sent: %h", header[i]);
    end

    // Send data
    foreach (data[i]) begin
      runner.send(data[i]);
      $display("Sent: %h", data[i]);
    end
  endtask

  task automatic receive_result(output logic [31:0] result);
    logic [7:0] bytes[4];
    foreach (bytes[i]) begin
      runner.receive(bytes[i]);
    end
    result = {bytes[0], bytes[1], bytes[2], bytes[3]};
  endtask

  task automatic test_math(input logic [7:0] opcode, input logic [31:0] operands[],
                           input logic [31:0] expected);
    logic [7:0] data[];
    logic [31:0] result;
    logic [15:0] packet_len;

    // Convert 32-bit operands to byte array
    data = new[operands.size() * 4];
    foreach (operands[i]) begin
      data[i*4+0] = operands[i][31:24];
      data[i*4+1] = operands[i][23:16];
      data[i*4+2] = operands[i][15:8];
      data[i*4+3] = operands[i][7:0];
    end

    // Calculate packet length
    packet_len = 16'd4 + 16'(data.size());

    $display("Operands: %p", operands);
    $display("Expected: %0d (0x%0h)", $signed(expected), expected);

    send_packet(opcode, packet_len, data);
    receive_result(result);

    $display("Received: %0d (0x%0h)", $signed(result), result);

    if (result !== expected) begin
      $display("FAIL");
    end else begin
      $display("PASS");
    end
  endtask

  initial begin
    $dumpfile("dump.fst");
    $dumpvars;

    runner.reset();

    // Test ECHO
    // test_echo(1);
    test_echo("Hello, World!");

    // Test ADD
    test_math(OPCODE_ADD, '{32'h1, 32'h2}, 32'h3);
    // test_math(OPCODE_ADD, '{32'hFFFFFFFF, 32'h1}, 32'h0);
    // test_math(OPCODE_ADD, '{32'h1, 32'h2, 32'h3}, 32'h6);

    // // Test MUL
    // test_math(OPCODE_MUL, '{32'h2, 32'h3}, 32'h6);
    // test_math(OPCODE_MUL, '{32'hFFFFFFFF, 32'h2}, 32'hFFFFFFFE);
    // test_math(OPCODE_MUL, '{32'h2, 32'h3, 32'h4}, 32'h18);

    // // Test DIV
    // test_math(OPCODE_DIV, '{32'h6, 32'h2}, 32'h3);
    // test_math(OPCODE_DIV, '{32'hFFFFFFFC, 32'h2}, 32'hFFFFFFFE);
    // test_math(OPCODE_DIV, '{32'h7, 32'h2}, 32'h3);

    $finish;
  end
endmodule
