module b14_dump;

  reg [1023:0] vcd_name;

  initial begin
    if (!$value$plusargs("VCD=%s", vcd_name)) begin
      $display("ERROR: +VCD=<output.vcd> is required.");
      $finish;
    end

    $dumpfile(vcd_name);

    // top testbench を明示
    $dumpvars(0, b14_test);
  end

endmodule
