
module tb
  import config_pkg::*;
  import dv_pkg::*;
;

  logic       clk_i;
  logic       rst_ni = 0;

  logic [7:0] data_i;
  logic       ready_i = 0;
  logic       valid_i = 0;
  logic       ready_o;
  logic       valid_o;
  logic [7:0] data_o;

  initial begin
    clk_i = 0;
    forever begin
      #1ns;
      clk_i = !clk_i;
    end
  end

  alu alu (.*);

  initial begin
    repeat (1000) @(posedge clk_i);
    $display("Timed out");
    $fatal;
  end

  logic in_handshake = 0;
  logic alu_handshake = 0;
  logic [7:0] result;

  task automatic run(logic [7:0] a, logic [7:0] expected);

    $display("Sending %0d", a);

    valid_i <= 1;
    in_handshake <= ready_o;
    ready_i <= 0;
    alu_handshake <= 0;

    data_i <= a;
    @(posedge clk_i);
    while (!in_handshake) begin
      @(posedge clk_i);
      in_handshake <= (ready_o && valid_i);
    end

    valid_i <= 0;
    in_handshake <= 0;
    ready_i <= 1;
    alu_handshake <= valid_o;

    result <= data_o;
    data_i <= 0;
    @(posedge clk_i);
    while (!alu_handshake) begin
      alu_handshake <= (ready_i && valid_o);
      result <= data_o;
      @(posedge clk_i);
    end

    valid_i <= 0;
    in_handshake <= 0;
    ready_i <= 0;
    alu_handshake <= 0;

    assert (expected == result)
    else $error("Expected %0d, Received %0d", expected, result);
    $display("Produced %0d", result);
  endtask


  always begin
    $dumpfile("dump.fst");
    $dumpvars;
    $urandom(100);

    rst_ni <= 0;
    @(posedge clk_i);
    rst_ni <= 1;

    run(2, 2);
    run(9, 9);
    run(170, 170);

    $finish;
  end

endmodule
