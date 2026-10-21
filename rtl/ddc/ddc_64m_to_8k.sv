// Single-channel composition. For eight channels instantiate eight frontends
// and ONE shared_fir_decimator(CHANNELS=8), tagging their 64 ksample/s inputs.
module ddc_64m_to_8k #(
 parameter integer FIR_DECIMATION=8,parameter integer FIR_TAPS=255
)(
 input wire clk128,
 input wire signed [13:0] sample_in,
 input wire sample_valid,
`ifdef DDC_PHASE_INCREMENT_INPUT
 input wire [47:0] phase_increment_in,
`else
 input wire [24:0] vfo_hz,
`endif
 output wire signed [23:0] i_out,q_out,
 output wire output_valid
);
 wire signed [31:0] cic_i,cic_q;
 wire cic_valid,fir_overrun;
 ddc_64m_to_64k frontend(.clk128(clk128),.sample_in(sample_in),.sample_valid(sample_valid),
`ifdef DDC_PHASE_INCREMENT_INPUT
 .phase_increment_in(phase_increment_in),
`else
 .vfo_hz(vfo_hz),
`endif
 .i_out(cic_i),.q_out(cic_q),.output_valid(cic_valid));
 shared_fir_decimator #(.CHANNELS(1),.TAPS(FIR_TAPS),.DECIMATION(FIR_DECIMATION)) filter(
 .clk(clk128),.in_valid(cic_valid),.in_channel(1'b0),.in_i(cic_i),.in_q(cic_q),
 .out_valid(output_valid),.out_channel(),.out_i(i_out),.out_q(q_out),.overrun(fir_overrun));
endmodule
