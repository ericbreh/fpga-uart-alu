module tb;
  alu_runner runner();
  logic [7:0] sending;
  logic [7:0] received;

  initial begin
    // Initialize
    runner.reset();

    sending = 17;
    $display("Sending data: %d", sending);
    runner.send(sending);
    runner.receive(received);
    $display("Received data: %d", received);

    sending = 10;
    $display("Sending data: %d", sending);
    runner.send(sending);
    runner.receive(received);
    $display("Received data: %d", received);

    sending = 6;
    $display("Sending data: %d", sending);
    runner.send(sending);
    runner.receive(received);
    $display("Received data: %d", received);

    sending = 64;
    $display("Sending data: %d", sending);
    runner.send(sending);
    runner.receive(received);
    $display("Received data: %d", received);

    $finish();
  end
endmodule
