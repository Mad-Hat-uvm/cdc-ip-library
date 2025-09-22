module cdc_sync_2ff #(
    parameter int STAGES = 2  //Number of flip flop stages (minimum 2)
    )(
        input logic clock,  //destination clock domain
        input logic arst_n, //asynchronous reset, active low
        input logic din,    //data input from source clock domain
        output logic dout   //data output to destination clock domain
    );

    //synchronizer shift register
   (* ASYNC_REG = "TRUE" *) logic sync_reg0, sync_reg1;

always_ff @(posedge clock or negedge arst_n) begin
  if (!arst_n) begin
    sync_reg0 <= 1'b0;
    sync_reg1 <= 1'b0;
  end else begin
    sync_reg0 <= din;
    sync_reg1 <= sync_reg0;
  end
end

assign dout = sync_reg1;

endmodule
