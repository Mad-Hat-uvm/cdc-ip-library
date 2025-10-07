`timescale 1ns/1ps
`include "cdc_pulse_sync.sv"
`include "cdc_pulse_sync_assert.sv"

//------------------------------------------------------------------------------
// Smoke Testbench for CDC Pulse Synchronizer
//------------------------------------------------------------------------------
// Purpose:
//   - Drives two unrelated clocks
//   - Generates random single-cycle pulses in source domain (only when !s_busy)
//   - Applies async resets to both domains
//   - Scoreboard checks that number of accepted pulses == number of dest pulses
//   - Integrates SVA checks for no loss / duplication / one-cycle width
//------------------------------------------------------------------------------

module tb_cdc_pulse_sync;

    localparam int STAGES = 2;
    localparam int SIM_TIME = 3000;

//-----------------------------------------
//Clock generation (unrelated frequencies)
//-----------------------------------------
    logic s_clk = 0;
    logic d_clk = 0;
    always #4 s_clk = ~s_clk; //Source clk 125MHz
    always #7 d_clk = ~d_clk;  // ~Dest clk 71.4MHz

//-----------------------------------------
//Async resets
//-----------------------------------------
    logic s_arst_n = 0, d_arst_n = 0;

    initial begin
        #15 s_arst_n = 1; //Release source reset at 15ns
        #21 d_arst_n = 1; //Release dest reset at 36ns
        
        //occasional async re-assertion to stress CDC paths
        repeat (2) begin
            #(200 + {$urandom_range(0, 200)}) s_arst_n = 0;
            #(20 +  {$urandom_range(0, 40)}) s_arst_n = 1;
            #(150 + {$urandom_range(0, 120)}) d_arst_n = 0;
            #(30 +  {$urandom_range(0, 40)}) d_arst_n = 1;
        end
    end

//-----------------------------------------
// DUT I/O 
//-----------------------------------------
  logic s_pulse_in;
  wire s_busy;
  wire d_pulse_out;

//-----------------------------------------
// Instantiation DUT
//-----------------------------------------
  cdc_pulse_sync #(.STAGES(STAGES)) dut (
    .s_clk(s_clk),
    .s_arst_n(s_arst_n),
    .s_pulse_in(s_pulse_in),
    .s_busy(s_busy),
    .d_clk(d_clk),
    .d_arst_n(d_arst_n),
    .d_arst_n(d_arst_n),
    .d_pulse_out(d_pulse_out)
  );

//-----------------------------------------
// Assertions
//-----------------------------------------
  cdc_pulse_sync_assert #(.STAGES(STAGES)) assert_inst (
    .s_clk(s_clk),
    .s_arst_n(s_arst_n),
    .s_pulse_in(s_pulse_in),
    .s_busy(s_busy),
    .d_clk(d_clk),
    .d_arst_n(d_arst_n),
    .d_pulse_out(d_pulse_out)
  );

  // ----------------------------------------
  //Stimulus
  // ----------------------------------------
  int src_accepted, dst_pulses;

  //generate random pulses on source domain only when !busy
  always @(posedge s_clk or negedge !s_arst_n) begin
    if(!s_arst_n) begin s_pulse_in <= 1'b0;
                        src_accepted <= 0;
    end else begin
        if(!s_busy && {$urandom_range(0, 9) < 3}) begin
            s_pulse_in <= 1'b1;
        else
            s_pulse_in <= 1'b0;

        if(s_pulse_in && !s_busy)
            src_accepted++;
    end
           
  end
end
  //destination pulse counter
  always @(posedge d_clk or negedge d_arst_n) begin
    if(!d_arst_n) dst_pulses <= 0;
    else if(d_pulse_out) dst_pulses++;
  end

//-------------------------------------------------------------------------
// Simple monitor
//-------------------------------------------------------------------------
  initial begin
    $display(" time | s_arst_n d_arst_n | s_busy s_pulse_in | d_pulse_out | src_acc dst_pulses");
    forever begin
      @(posedge s_clk);
      $display("%5t |     %0b        %0b   |   %0b       %0b   |     %0b      |   %0d        %0d",
               $time, s_arst_n, d_arst_n, s_busy, s_pulse_in, d_pulse_out, src_accepted, dst_pulses);
    end
  end

//-------------------------------------------------------------------------
// End -of - test Scoreboard
//-------------------------------------------------------------------------
  initial begin
    #(SIM_TIME);
    if(dst_pulses != src_accepted)
        $display("[WARN] Counts differ: src= %0d dst = $0d (check busy protocol)", src_accepted, dst_pulses);
    else
        $display("[PASS] All source accepted pulses received in dest. Counts match = %0d", src_accepted);
  end

endmodule
