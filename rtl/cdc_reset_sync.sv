

//------------------------------------------------------------------------------
// Reset Synchronizer
//------------------------------------------------------------------------------
// Purpose:
//   Safely synchronize an asynchronous reset (active-low) into a given clock domain.
//
// Behavior:
//   - Assertion of reset is asynchronous (srst_n goes low immediately when arst_n falls).
//   - De-assertion of reset is synchronous (srst_n goes high only after STAGES clk edges).
//
// Parameters:
//   STAGES : Number of synchronization stages (>=2). Typically 2 is enough.
//            Larger values add latency but reduce metastability risk further.
//
// Notes:
//   - The output srst_n is still active-low (0 = in reset, 1 = released).
//   - Commonly used in every clock domain of an SoC to ensure resets release cleanly.
//   - The (* ASYNC_REG *) synthesis attribute guides tools to treat flops as synchronizer cells.
//
// Example timing:
//   arst_n ↓ : srst_n drops immediately (async assert).
//   arst_n ↑ : srst_n remains low for STAGES-1 cycles, then goes high at clk edge.
//
//------------------------------------------------------------------------------
module cdc_reset_sync #(
    parameter int STAGES = 2  //must be >= 2
)(
    input logic clk,
    input logic arst_n, //async in, active low
    output logic srst_n //synced out, active-low (0 = in reset)
);

//Synthesis-time check
initial if (STAGES < 2) $error("cdc_reset_sync: STAGES must be >= 2");

//Shift register chain
//   - Holds '0' when arst_n is low (async assert).
//   - Shifts in '1's once arst_n goes high (sync de-assert).
(* ASYNC_REG = "TRUE" *) logic [STAGES - 1 : 0] sync_ff;

always_ff@(posedge clk or negedge arst_n) begin
    if(!arst_n) begin
    //Asynchronous assertion: force the chain low
        sync_ff <= '0;
    end else begin
        //On each clock edge after arst_n = 1, shift in "1"
        //With STAGES = N, the synchronizer output (srst_n) stays low for N clock cycles after async
        //reset de-asserts, then finally goes high.
        //That’s why this trick is used: it gives you a programmable “pipeline” delay that safely 
        //re-times the reset release into the clock domain.
        sync_ff <= {sync_ff[STAGES - 2 : 0], 1'b1};
    end
end

// Output reset (active-low). Goes high only after STAGES cycles of clk.
assign srst_n = sync_ff[STAGES - 1];

endmodule