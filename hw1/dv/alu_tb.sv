
module alu_tb
  import config_pkg::*;
  import dv_pkg::*;
;

  alu_runner alu_runner ();

  always begin
    $dumpfile("dump.fst");
    $dumpvars;
    $display("Begin simulation.");
    $urandom(100);
    $timeformat(-3, 3, "ms", 0);

    alu_runner.reset();

    repeat (4) begin
      alu_runner.wait_for_on();
      alu_runner.wait_for_off();
    end

    $display("End simulation.");
    $finish;
  end

endmodule
