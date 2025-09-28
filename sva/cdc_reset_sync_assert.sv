

//------------------------------------------------------------------------------
// Assertions for cdc_reset_sync
//------------------------------------------------------------------------------
module cdc_reset_sync_assert #(
    parameter int STAGES = 2; //MUST BE >= 2
)(
    input logic clk;
    input logic arst_n;  //async, active-low
    input logic srst_n; //synced, active-low 
);

// 1) Asynchronous assertion: srst_n must drop immediately when arst_n drops
property p_async_assert_immediate;
    @(negedge arst_n) disable iff ($time == 0)!srst_n;
endproperty
a_async_assert_immediate: assert property (p_async_assert_immediate)
 else $error("srst_n not asserted immediately with arst_n");

// 2) Deassert latency: srst_n must only rise within [STAGES : STAGES+1] cycles of clk
property p_deassert_exact_latency;
    @(posedge clk) $rose(arst_n) |-> ##[STAGES : STAGES + 1] $rose(srst_n);
endproperty
a_deassert_exact_latency: assert property (p_deassert_exact_latency)
 else $error("srst_n did not deassert within allowed latency window");

// 3) Hold low until release: srst_n stays low for STAGES-1 cycles after release starts
property p_hold_low_until_release;
    @(posedge clk) disable iff (!arst_n)
    $rose(arst_n) |-> (!srst_n) [*(STAGES - 1)];
endproperty
a_hold_low_until_release: assert property (p_hold_low_until_release)
    else $error("srst_n did not hold low for required cycles after arst_n release");

// 4) No unknowns after release
property p_no_unknown_after_release;
    @(posedge clk) disable iff (!arst_n)
    $rose(srst_n) |-> !$isunknown(srst_n);
endproperty
a_no_unknown_after_release: assert property (p_no_unknown_after_release)
    else $error("srst_n is unknown after release");

// 5) Coverage: see a deassert transition
covergroup cg_reset @(posedge clk);
    cp_release: coverpoint srst_n { bins deassert = (0 => 1);}
endgroup
cg_reset cg = new();

endmodule