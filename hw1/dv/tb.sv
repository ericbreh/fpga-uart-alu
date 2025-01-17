module tb;
  alu_runner runner ();

  localparam OPCODE_ADD32 = 8'hAD;

  // Helper tasks
  task automatic send_packet(input logic [7:0] opcode, input logic [15:0] len,
                             input logic [31:0] data[]);
    logic [7:0] header[4];
    header[0] = opcode;
    header[1] = 8'h00;
    header[2] = len[7:0];
    header[3] = len[15:8];

    // Send header
    foreach (header[i]) begin
      runner.send(header[i]);
    end

    // Send data
    foreach (data[i]) begin
      runner.send(data[i][31:24]);
      runner.send(data[i][23:16]);
      runner.send(data[i][15:8]);
      runner.send(data[i][7:0]);
    end
  endtask

  task automatic receive_result(output logic [31:0] result);
    logic [7:0] bytes[4];
    foreach (bytes[i]) begin
      runner.receive(bytes[i]);
    end
    result = {bytes[0], bytes[1], bytes[2], bytes[3]};
  endtask

  task automatic test_add32(input logic [31:0] operands[], input string test_name);
    logic [31:0] result;
    logic [31:0] expected;
    logic [15:0] packet_len;

    // Calculate packet length (header + data)
    packet_len = 4 + (operands.size() * 4);

    // Calculate expected result
    expected   = '0;
    foreach (operands[i]) begin
      expected = expected + operands[i];
    end

    $display("\nTest case: %s", test_name);
    $display("Operands: %p", operands);
    $display("Expected: %0d (0x%0h)", $signed(expected), expected);

    send_packet(OPCODE_ADD32, packet_len, operands);
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

    // Basic positive numbers
    test_add32('{32'h1, 32'h2}, "Basic positive");
    test_add32('{32'h64, 32'hC8}, "Larger positive");

    // Byte ordering test
    test_add32('{32'h12345678, 32'h9ABCDEF0}, "Byte ordering");

    // Sign handling
    test_add32('{32'h7FFFFFFF, 32'h1}, "Max positive + 1");
    test_add32('{32'hFFFFFFFF, 32'h1}, "-1 + 1");

    // Overflow tests
    test_add32('{32'h80000000, 32'h80000000}, "Double MIN");
    test_add32('{32'hFFFFFFFF, 32'hFFFFFFFF}, "-1 + -1");

    // Multiple numbers
    test_add32('{32'h11111111, 32'h22222222, 32'h33333333}, "Three numbers");

    // Negative numbers
    test_add32('{32'hFFFFFFFF, 32'h00000001}, "-1 + 1");
    test_add32('{32'h80000000, 32'h00000000}, "MIN + 0");
    test_add32('{32'h80000000, 32'hFFFFFFFF}, "MIN + -1");

    // Edge cases
    test_add32('{32'h7FFFFFFF, 32'h80000000}, "MAX + MIN");

    $finish;
  end
endmodule
