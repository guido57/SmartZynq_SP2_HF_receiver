// Atomic configuration and ADC source selection, in the 128 MHz domain.
module adc_source_control_ssb_bd(
 input wire clk128,locked,stream_open,config_toggle,
 input wire [99:0] receiver_config,
 input wire signed [13:0] simulated_sample,external_sample,
 input wire simulated_valid,external_valid,
 output wire simulator_run,active_external,capture_open,iq_mode,audio_enable,lsb_mode,
 output reg pair_mode=0,
 output wire [47:0] simulator_phase,tune_phase,
 output wire signed [13:0] selected_sample,
 output wire selected_valid
);
 (* ASYNC_REG="TRUE" *) reg op1=0,op2=0;
 (* ASYNC_REG="TRUE" *) reg cfg_meta=0,cfg_sync=0;
 reg cfg_seen=0;
 reg [99:0] config_active={2'b00,48'd4398046511104,48'd4398046511104,2'b00};
 always @(posedge clk128)pair_mode<=config_active[99:98]==2'b01;
 always @(posedge clk128) begin
  op1<=stream_open;op2<=op1;cfg_meta<=config_toggle;cfg_sync<=cfg_meta;
  // Bus-side bank remains stable after commit. Apply between complete frames.
  if(!op2 && cfg_sync!=cfg_seen) begin
   config_active<=receiver_config;cfg_seen<=cfg_sync;
  end
 end
 assign active_external=config_active[0];
 assign iq_mode=config_active[1];
 assign audio_enable=config_active[99];
 assign lsb_mode=config_active[98];
 assign capture_open=op2;
 assign tune_phase=config_active[49:2];
 assign simulator_phase=config_active[97:50];
 assign simulator_run=locked;
 assign selected_sample=active_external?external_sample:simulated_sample;
 assign selected_valid=locked && (active_external?external_valid:simulated_valid);
endmodule
