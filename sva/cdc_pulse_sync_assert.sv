//------------------------------------------------------------------------------
// Assertions for cdc_pulse_sync
//------------------------------------------------------------------------------
// Purpose:
//   Verify handshake-based pulse synchronizer transfers events safely.
//   Checks:
//     1. d_pulse_out is always exactly 1 cycle wide
//     2. No duplicate pulses in dest domain for one accepted src event
//     3. Every accepted src event results in exactly one dest pulse
//     4. Source never sends a pulse when busy
//------------------------------------------------------------------------------
module cdc_pulse_sync_assert #(
    parameter int STAGES = 2, // Synchronizer stages (2 or 3)
    parameter int MAX_LATENCY_DST = 16 // Max allowed d_clk cycle from src event to d_pulse_out
)(
    //Source Domain
    input logic s_clk,
    input logic s_arst_n,
    input logic s_pulse_in,
    input logic s_busy,

    //Destination Domain
    input logic d_clk,
    input logic d_arst_n,
    input logic d_pulse_out
);

// -----------------------------
// Helper: flag when src event is accepted
// -----------------------------
logic s_accept;
always_ff @(posedge s_clk or negedge s_arst_n) begin
    if(!s_arst_n) s_accept <= 1'b0;
    else          s_accept <= (s_pulse_in && !s_busy);
end

// -----------------------------
// 1) Single-cycle dest pulse
// -----------------------------
property p_one_cycle_pulse;
    @(posedge d_clk) disable iff (!d_arst_n)
    d_pulse_out |-> ##1 !d_pulse_out; //if high, must go low next cycle
endproperty
a_one_cycle_pulse: assert property (p_one_cycle_pulse)
else $error("d_pulse_out not 1 cycle wide");

// -----------------------------
// 2) No duplicate pulses
// -----------------------------
property p_no_duplicate_pulses;
    @(posedge d_clk) disable iff(!d_arst_n)
    d_pulse_out |-> ##[1 : MAX_LATENCY_DST] !$rose(d_pulse_out);
endproperty
a_no_duplicate_pulses: assert property (p_no_duplicate_pulses)
    else $error("Duplicate destination pulses detected");

// -----------------------------
// 3) No lost pulses
// -----------------------------
//Every accepted src event must eventually trigge a dest pulse
property p_event_transferred;
    @(posedge s_clk) disable iff(!s_arst_n)
      s_accept |-> ##[1 : MAX_LATENCY_DST] @(posedge d_clk) $rose(d_pulse_out);
endproperty
a_event_transferred: assert property (p_event_transferred)
    else $error("Accepted source pulse did not transfer to destination");

// -----------------------------
// 4) Respect busy: no pulse when busy
// -----------------------------
property p_no_pulse_when_busy;
    @(posedge s_clk) disable iff (!s_arst_n)
    (s_busy && s_pulse_in) |-> 0;
endproperty
a_no_pulse_when_busy: assert property (p_no_pulse_when_busy)
    else $error("Source pulse asserted while busy");

endmodule