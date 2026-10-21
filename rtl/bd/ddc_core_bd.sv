// Stable block-design ports; the core's optional phase port is enabled by
// the project-wide DDC_PHASE_INCREMENT_INPUT synthesis definition.
module ddc_core_bd(
 input wire clk128,
 input wire signed [13:0] sample_in,
 input wire sample_valid,
 input wire [47:0] phase_increment_in,
 output wire signed [23:0] i_out,q_out,
 output wire output_valid
);
 ddc_64m_to_8k core(.*);
endmodule
