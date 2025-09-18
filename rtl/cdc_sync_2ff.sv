module cdc_sync_2ff #(
    parameter int STAGES = 2  //Number of flip flop stages (minimum 2)
    )(
        input logic clock,  //destination clock domain
        input logic arst_n, //asynchronous reset, active low
        input logic din,    //data input from source clock domain
        output logic dout   //data output to destination clock domain
    );

    //synchronizer shift register
    (* ASYNC_REG = "TRUE" *) logic [STAGES - 1 : 0] sync_reg;

    //FF chain
    always_ff @(posedge clock or negedge arst_n) begin
        if (!arst_n)
         sync_reg <= '0;
        
        else
        sync_reg <= {[STAGES - 2 : 0], din};
    end

    assign dout = sync_reg[STAGES - 1];

endmodule
