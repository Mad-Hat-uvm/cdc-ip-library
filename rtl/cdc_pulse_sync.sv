//------------------------------------------------------------------------------
// CDC Pulse Synchronizer (Handshake-based)
//------------------------------------------------------------------------------
// Purpose:
//   Safely transfer a 1-cycle pulse from source clock domain (s_clk) to
//   destination clock domain (d_clk) with no loss or duplication.
//
// Method:
//   - Source: latch 'req' when a pulse arrives (if not busy), hold until ack.
//   - Dest  : synchronize 'req', edge-detect to generate 1-cycle 'd_pulse_out'.
//             Drive 'ack' back as a level (mirror of synchronized req).
//   - Source: synchronize 'ack' and clear 'req' when ack observed.
//   - s_busy = s_req ^ s_ack_sync prevents accepting a new pulse mid-flight.
//
// Notes:
//   - Requires the source to respect s_busy: only assert s_pulse_in when !s_busy.
//   - STAGES controls 2-FF (or 3-FF) synchronizer depth for both directions.
//------------------------------------------------------------------------------
module cdc_pulse_sync #(
    parameter int STAGES = 2  // Synchronizer stages (2 or 3)
) (
    // Source domain signals
    input logic s_clk,
    input logic s_arst_n,    // Asynchronous reset, active low(for source domain)
    input logic s_pulse_in,  // 1-cycle pulse in source domain
    output logic s_busy,     // High when transfer in-flight (source domain)

    //Destination domain signals
    input logic d_clk,
    input logic d_arst_n,    // Asynchronous reset, active low(for destination domain)
    output logic d_pulse_out // 1-cycle pulse in destination domain
);

  // ----------------------
  // Source domain: req/ack
  // ----------------------
    logic s_req;             // Source held request level
    logic s_ack_sync;        // Synchronized ack from dest domain

    //Busy high while req and ack disagree (classic handshake busy)
    assign s_busy = s_req ^ s_ack_sync;

    //Latch request when s_pulse_in arrives (if not busy); clear when ack sync seen
    always_ff @(posedge s_clk or negedge s_arst_n) begin
        if (!s_arst_n)
            s_req <= 1'b0;
         else begin
            if(!s_busy && s_pulse_in) 
                s_req <= 1'b1;   // Set req when pulse arrives and not busy
            else if(s_ack_sync) 
                s_req <= 1'b0;   // Clear req when ack seen
            end
        end
    // -----------------------------
    // Synchronize req into dest side
    // -----------------------------   
    (*ASYNC_REG = "TRUE"*) logic [STAGES - 1 : 0] s_req_sync;
    always_ff @(posedge d_clk or negedge d_arst_n) begin
        if(!d_arst_n) begin
            d_req_sync <= '0;
        end
        else begin
            s_req_sync <= {s_req_sync[STAGES-2 : 0], s_req};
        end
        end

        logic d_req; //Synchronized req in dest domain
        assign d_req = s_req_sync[STAGES - 1];
        
        //Edge-detect rising edge to generate a single-cycle pulse in dest domain
        logic d_req_q;
        always_ff @(posedge d_clk or negedge d_arst_n) begin
            if(!d_arst_n) begin
                d_req_q <= 1'b0;
            end
            else begin
                d_req_q <= d_req;
            end
        end
        assign d_pulse_out = d_req & ~d_req_q; // Pulse when req rises
     

    // -----------------------------
   // Drive ack level back to source
   // -----------------------------
   // Ack mirrors the synchronized request level (holds while req is asserted)
    logic d_ack;
    always_ff @(posedge d_clk or negedge d_arst_n) begin
        if(!d_arst_n) d_ack <= 1'b0;
        else          d_ack <= d_req;
    end

     // Synchronize ack back into source domain
     (*ASYNC_REG = "TRUE"*) logic [STATES - 1 : 0] s_ack_sync_chain;
     always_ff @(posedge s_clk or negedge s_arst_n) begin
        if(!s_arst_n) s_ack_sync_chain <= 0;
        else          s_ack_sync_chain <= {s_ack_sync_chain[STAGES - 2 : 0], d_ack};
     end

     assign s_ack_sync = s_ack_sync_chain[STAGES - 1];

    endmodule