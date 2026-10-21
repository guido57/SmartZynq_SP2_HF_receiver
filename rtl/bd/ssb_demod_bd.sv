module ssb_demod_bd(
 input wire clk128,in_valid,
 input wire signed [23:0] in_i,in_q,
 output wire signed [23:0] usb_audio,lsb_audio,
 output wire out_valid,overrun
);
 shared_ssb_demod #(.CHANNELS(1)) core(.clk(clk128),.in_channel(1'b0),.out_channel(),.*);
endmodule
