

`include "cdc_reset_sync.sv"
`include "cdc_reset_sync_assert.sv"

`timescale 1ns/1ps
module tb_cdc_reset_sync;
    localparam int STAGES = 2;

    logic clk = 0, arst_n = 0;
    wire srst_n;
    always #5 clk = ~clk; // 100 MHz clock

    //DUT
    cdc_reset_sync #(.STAGES(STAGES)) dut (.clk(clk), .arst_n(arst_n), .srst_n(srst_n));
    cdc_reset_sync_assert #(.STAGES(STAGES)) chk (.clk(clk), .arst_n(arst_n), .srst_n(srst_n));

    initial begin
        $display("time arst_n srst_n");
        $monitor("%4t   %b      %b", $time, arst_n, srst_n);

        //Release reset off phase to see sync ripple
        #17 arst_n = 1;

        repeat(10) begin
            #(50 + {$urandom_range(0, 100)}) arst_n = 0; //async assert
            #(12 + {$urandom_range(5, 20)}) arst_n = 1;  //misaligned de-assert
        end

        #100 $finish;
    end

   initial begin
     $dumpfile("waves.vcd");
     $dumpvars(0, tb_cdc_reset_sync);
   end

endmodule