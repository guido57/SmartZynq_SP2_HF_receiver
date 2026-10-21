// One finite snapshot per open: raw indexed ADC words or alternating signed
// 32-bit I,Q words. DDC always runs, independently of slow GUI frame drawing.
module ssb_receiver_bd #(parameter AW=12, parameter SETTLE_IQ=64, parameter SETTLE_AUDIO=192)(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk128 CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk128, FREQ_HZ 128000000" *) input wire clk128,
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 bus_clk CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME bus_clk, FREQ_HZ 100000000" *) input wire bus_clk,
 input wire locked,stream_open,rden,config_toggle,
 input wire [99:0] receiver_config,
 input wire signed [13:0] simulated_sample,external_sample,
 input wire simulated_valid,external_valid,
 output wire simulator_run,active_external,
 output wire [47:0] simulator_phase,
 output wire [31:0] data,
 output wire empty,eof
);
 // Compatibility wrapper for standalone receiver regression.
 wire capture_open,iq_mode,selected_valid,ddc_valid,audio_enable,lsb_mode,audio_valid,ssb_overrun,pair_mode;
 wire signed [23:0] usb_audio,lsb_audio;
 wire signed [13:0] selected_sample;
 wire signed [23:0] ddc_i,ddc_q;
 wire [47:0] tune_phase;
 wire [99:0] config_active={audio_enable,lsb_mode,simulator_phase,tune_phase,iq_mode,active_external};
 adc_source_control_ssb_bd source_control(.*);
 ddc_core_bd ddc(.clk128(clk128),.sample_in(selected_sample),
  .sample_valid(selected_valid),.phase_increment_in(tune_phase),
  .i_out(ddc_i),.q_out(ddc_q),.output_valid(ddc_valid));
 ssb_demod_bd demod(.clk128(clk128),.in_valid(ddc_valid),.in_i(ddc_i),.in_q(ddc_q),
 .usb_audio(usb_audio),.lsb_audio(lsb_audio),.out_valid(audio_valid),.overrun(ssb_overrun));
 ssb_snapshot_bd #(.AW(AW),.SETTLE_IQ(SETTLE_IQ),.SETTLE_AUDIO(SETTLE_AUDIO)) snapshot(.*);
endmodule
