// Assertions for cdc_sync_2ff.sv
module cdc_sync_2ff_assert #(int STAGES = 2) (
    input logic clock, //destination clock domain
    input logic arst_n, //asynchronous reset, active low
    input logic din, //data input from source clock domain
    input logic dout //data output to destination clock domain
);

//dout must never be X/Z after reset is deasserted
//This is a basic check to ensure that the synchronizer is functioning correctly.
//The assertion only checks dout when reset (arst_n) is deasserted (high).
property p_no_unknown_dout;
    @(posedge clock) disable iff(!arst_n) !$isunknown(dout);
endproperty
a_no_unknown_dout: assert property (p_no_unknown_dout);

//Once din holds a stable value for STAGES clock cycles, dout must reflect that value
//This Window allows exactly STAGES clock cycles latency for the change to propagate through
//the synchronizer from stability point onwards.
property p_dout_follows_din_after_stages;
    @(posedge clock) disable iff(!arst_n) 
    $stable(din) [*STAGES] |-> (dout == din);
endproperty

a_dout_follows_din_after_stages: assert property (p_dout_follows_din_after_stages);

//When din toggles, dout must change within [STAGES:STAGES+1] clock cycles 
//the +1 wiggle room is to account for edge alignment around the sampling clock edge
property p_latency_bounds;
    @(posedge clock) disable iff(!arst_n)
    (din != $past(din)) |-> ##[STAGES : STAGES+1] (dout == din);
endproperty
a_latency_bounds: assert property (p_latency_bounds);

//Simple coverage: observe both directions and reset release
covergroup cg@(posedge clock);
    coverpoint din {
        bins to1 = (1 => 1);
        bins to0 = (0 => 0);
    }
    coverpoint dout {
        bins to1 = (1 => 1);
        bins to0 = (0 => 0);
    }

    //cross to ensure we have seen din->dout propagation
    cross din, dout;
endgroup

cg cov = new();

endmodule