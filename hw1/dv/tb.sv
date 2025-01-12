module tb;
  alu_runner runner ();
  logic [7:0] sending;
  logic [7:0] received;

  // Add these debug prints in your test_pattern task
  task test_pattern(input logic [7:0] pattern);
    sending = pattern;
    $display("\nTest Pattern: 0x%h", pattern);
    $display("Before send: %b", sending);  // Verify data before send
    runner.send(sending);
    $display("After send: %b", sending);  // Check if data changed during send
    runner.receive(received);
    $display("Raw received: %h", received);  // See raw hex value
  endtask

  initial begin
    $dumpfile("dump.fst");
    $dumpvars;

    runner.reset();

    // test_pattern(8'h55);  // Alternating
    // test_pattern(8'h00);  // All zeros
    // test_pattern(8'hFF);  // All ones
    // test_pattern(8'h01);  // Single bit

    // // Walking zeros pattern
    // test_pattern(8'hFE);  // 1111_1110
    // test_pattern(8'hFD);  // 1111_1101
    // test_pattern(8'hFB);  // 1111_1011
    // test_pattern(8'hF7);  // 1111_0111

    // Walking 1 pattern
    test_pattern(8'h01);  // 0000_0001
    test_pattern(8'h02);  // 0000_0010
    test_pattern(8'h04);  // 0000_0100
    test_pattern(8'h08);  // 0000_1000


    $finish;
  end
endmodule
