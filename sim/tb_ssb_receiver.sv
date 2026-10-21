`timescale 1ns/1ps
module tb_ssb_receiver;
 reg clk128=0,bus_clk=0;
 always #3.90625 clk128=~clk128;
 always #5 bus_clk=~bus_clk;
 reg locked=0,stream_open=0,rden=0,config_toggle=0;
 reg [99:0] receiver_config={2'b00,48'd4398046511104,48'd4398046511104,2'b00};
 reg signed[13:0] sample=0;reg sample_valid=0;
 real rf=1001000.0;integer sample_index=0;
 always @(negedge clk128)begin
  sample_valid=~sample_valid;
  if(sample_valid)begin sample=$rtoi(8000.0*$sin(6.283185307179586*rf*sample_index/64000000.0));sample_index=sample_index+1;end
 end
 wire simulator_run,active_external;wire[47:0] simulator_phase;
 wire[31:0] data;wire empty,eof;
 reg test_passed=0;
 ssb_receiver_bd #(.AW(4)) dut(.clk128(clk128),.bus_clk(bus_clk),.locked(locked),
 .stream_open(stream_open),.rden(rden),.config_toggle(config_toggle),.receiver_config(receiver_config),
 .simulated_sample(sample),.external_sample(sample),.simulated_valid(sample_valid),.external_valid(sample_valid),
 .simulator_run(simulator_run),.active_external(active_external),.simulator_phase(simulator_phase),.data(data),.empty(empty),.eof(eof));
 function [47:0] inc(input integer hz);
  reg[95:0] n;begin n=96'd281474976710656*hz+32000000;inc=n/64000000;end
 endfunction
 task config_set(input[1:0] mode,input integer hz);
  begin
   @(negedge bus_clk);rf=hz;receiver_config={mode,inc(hz),inc(1000000),(|mode),1'b0};config_toggle=~config_toggle;
   repeat(30)@(negedge bus_clk);
  end
 endtask
 task word_read(output reg[31:0] value);
  begin
   while(empty)@(negedge bus_clk);
   rden=1;@(posedge bus_clk);#1;value=data;
   @(negedge bus_clk);rden=0;repeat(2)@(negedge bus_clk);
  end
 endtask
 integer k;reg[31:0] word;real sumsq,v,rms;
 task audio_check(input[1:0] mode,input integer hz,input bit wanted,input bit midframe);
  begin
   config_set(mode,hz);stream_open=1;sumsq=0;
   for(k=0;k<16;k=k+1)begin
    word_read(word);
    if(word[31:24]!={8{word[23]}})$fatal(1,"Invalid mono audio sign extension");
    v=$signed(word);sumsq=sumsq+v*v;
    if(midframe && k==4)begin
     receiver_config[99:98]=3;config_toggle=~config_toggle;
    end
   end
   if(!eof)$fatal(1,"Mono audio EOF/word count mismatch");
   rms=$sqrt(sumsq/16);
   if(wanted && (rms<2000 || rms>3500))$fatal(1,"Wanted SSB audio missing: mode=%d RMS=%f",mode,rms);
   if(!wanted && rms>2.5)$fatal(1,"Wrong sideband leaks: mode=%d RMS=%f",mode,rms);
   $display("PASS RF SSB mode=%d RF=%d wanted=%d audio RMS=%f",mode,hz,wanted,rms);
   stream_open=0;repeat(30)@(negedge bus_clk);
   if(midframe && dut.source_control.config_active[99:98]!=3)$fatal(1,"Deferred SSB mode commit failed");
  end
 endtask
 always @(posedge clk128)if(dut.ssb_overrun || dut.ddc.core.fir_overrun)$fatal(1,"DSP engine overload");
 initial begin
  #100;locked=1;
  audio_check(2,1001000,1,1);
  audio_check(2,999000,0,0);
  audio_check(3,999000,1,0);
  audio_check(3,1001000,0,0);
  config_set(0,1001000);stream_open=1;
  for(k=0;k<16;k=k+1)begin word_read(word);if(word[31:16]!=k)$fatal(1,"Raw capture index changed");end
  if(!eof)$fatal(1,"Raw EOF mismatch");stream_open=0;repeat(30)@(negedge bus_clk);
  config_set(1,1001000);stream_open=1;
  for(k=0;k<32;k=k+1)begin word_read(word);if(word[31:24]!={8{word[23]}})$fatal(1,"IQ sign extension changed");end
  if(!eof)$fatal(1,"IQ EOF/count mismatch");
  $display("PASS: RF-to-USB/LSB, sign convention, mono stream, raw/IQ compatibility, deferred controls");
  test_passed=1;#1;$finish;
 end
 initial begin #200000000;$fatal(1,"RF receiver test timeout");end
endmodule
