// One shared I/Q MAC; channel-tagged interface scales to eight frontends.
module shared_fir_bd #(
 parameter integer CHANNELS=1,
 parameter integer CH_BITS=(CHANNELS>1?$clog2(CHANNELS):1)
)(
 input wire clk128,
 input wire in_valid,
 input wire [CH_BITS-1:0] in_channel,
 input wire signed [31:0] in_i,in_q,
 output wire out_valid,
 output wire [CH_BITS-1:0] out_channel,
 output wire signed [23:0] out_i,out_q,
 output wire overrun
);
 shared_fir_decimator #(.CHANNELS(CHANNELS)) core(.clk(clk128),.*);
endmodule
