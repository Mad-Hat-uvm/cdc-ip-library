//Simple interface for the Synchronizer DUT
interface sync_if #(int STAGES = 2) (input logic clock);
    logic arst_n; //asynchronous reset, active low
    logic din;    //data input from source clock domain
    logic dout;  //data output to destination clock domain

    modport dut(input clock, input arst_n, input din, output dout);
    modport tb(input clock, output arst_n, output din, input dout);

endinterface