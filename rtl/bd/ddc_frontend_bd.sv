// Exposes the 64 ksample/s CIC output for a shared channel-filter engine.
module ddc_frontend_bd(
 input wire clk128,
 input wire signed [13:0] sample_in,
 input wire sample_valid,
 input wire [47:0] phase_increment_in,
 output wire signed [31:0] i_out,q_out,
 output wire output_valid
);
 ddc_64m_to_64k core(.*);
endmodule
