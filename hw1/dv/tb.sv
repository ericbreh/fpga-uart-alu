module tb;
  alu_runner runner ();
  logic [7:0] sending;
  logic [7:0] received;

  // Add these debug prints in your test_pattern task
  task test_pattern(input logic [7:0] pattern);
    sending = pattern;
    $display("\nSending: %d, 0x%h, %b", sending, sending, sending);
    runner.send(sending);
    runner.receive(received);
    $display("Received: %d, 0x%h, %b", received, received, received);
  endtask

  initial begin
    $dumpfile("dump.fst");
    $dumpvars;

    runner.reset();

    test_pattern(85);  // Alternating
    test_pattern(0);  // All zeros
    test_pattern(255);  // All ones
    test_pattern(1);  // Single bit

    // // Walking zeros pattern
    // test_pattern(8'hFE);  // 1111_1110
    // test_pattern(8'hFD);  // 1111_1101
    // test_pattern(8'hFB);  // 1111_1011
    // test_pattern(8'hF7);  // 1111_0111

    // // Walking 1 pattern
    // test_pattern(8'h01);  // 0000_0001
    // test_pattern(8'h02);  // 0000_0010
    // test_pattern(8'h04);  // 0000_0100
    // test_pattern(8'h08);  // 0000_1000


    $finish;
  end
endmodule
