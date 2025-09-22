`timescale 1ns/1ps

module tb_cdc_sync_2ff;

  logic clock;
  logic arst_n;
  logic din;
  logic dout;

  // Clock generator
  initial clock = 0;
  always #5 clock = ~clock;  // 100 MHz

  // DUT
  cdc_sync_2ff dut (
    .clock   (clock),
    .arst_n  (arst_n),
    .din     (din),
    .dout    (dout)
  );

  // Stimulus
  initial begin
    arst_n = 0; din = 0;
    #17 arst_n = 1;

    repeat (20) begin
      #($urandom_range(2,10)) din = $urandom_range(0,1);
      if ($urandom_range(0,99) < 10) begin
        arst_n = 0; #3; arst_n = 1;
      end
    end

    #50;
    $display("Simulation finished.");
    $finish;
  end

  // Monitor
  initial begin
    $monitor("[%0t] clock=%0b arst_n=%0b din=%0b dout=%0b", $time, clock, arst_n, din, dout);
  end

endmodule
