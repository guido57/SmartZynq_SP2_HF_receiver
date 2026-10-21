`timescale 1ns/1ps
module tb_shared_ssb;
 localparam N=450,CHANNELS=8,OUTPUTS=323;
 reg clk=0;always #3.90625 clk=~clk;
 reg in_valid=0;reg [2:0] in_channel=0;
 reg signed [23:0] in_i=0,in_q=0;
 wire out_valid,overrun;wire[2:0] out_channel;
 wire signed [23:0] usb_audio,lsb_audio;
 reg test_passed=0;
 shared_ssb_demod dut(.*);
 reg signed [23:0] vector_i[0:N*CHANNELS-1],vector_q[0:N*CHANNELS-1];
 reg signed [23:0] expected_usb[0:CHANNELS*OUTPUTS-1],expected_lsb[0:CHANNELS*OUTPUTS-1];
 integer received[0:CHANNELS-1],last_job[0:CHANNELS-1],last_output[0:CHANNELS-1];
 integer accepted[0:CHANNELS-1];
 integer cycle=0,max_latency=0,outputs_total=0,idx,latency;
 // Independent overload test: deliberately violate the supported input cadence.
 reg overload_valid=0;
 wire overload_fault;
 shared_ssb_demod #(.CHANNELS(1)) overload_test(.clk(clk),.in_valid(overload_valid),
 .in_channel(1'b0),.in_i(24'sd1),.in_q(-24'sd1),.out_valid(),.out_channel(),.usb_audio(),.lsb_audio(),.overrun(overload_fault));
 always @(posedge clk)begin
  cycle=cycle+1;
  if(in_valid)begin
   if(accepted[in_channel]>=127)last_job[in_channel]=cycle;
   accepted[in_channel]=accepted[in_channel]+1;
  end
  #1;
  if(overrun)$fatal(1,"Eight-channel SSB overrun at supported cadence");
  if(out_valid)begin
   if(received[out_channel]>=OUTPUTS)$fatal(1,"Unexpected extra output channel %d",out_channel);
   idx=out_channel*OUTPUTS+received[out_channel];
   if(usb_audio!==expected_usb[idx] || lsb_audio!==expected_lsb[idx])
    $fatal(1,"SSB mismatch ch=%d frame=%d got %d,%d expected %d,%d",out_channel,received[out_channel],usb_audio,lsb_audio,expected_usb[idx],expected_lsb[idx]);
   latency=cycle-last_job[out_channel];if(latency>max_latency)max_latency=latency;
   if(latency>=16000)$fatal(1,"Missed eight-channel output deadline");
   if(received[out_channel]>0 && cycle-last_output[out_channel]!=16000)$fatal(1,"Output cadence mismatch");
   last_output[out_channel]=cycle;received[out_channel]=received[out_channel]+1;
   outputs_total=outputs_total+1;
  end
 end
 integer n,ch;
 initial begin
  for(ch=0;ch<CHANNELS;ch=ch+1)begin received[ch]=0;accepted[ch]=0;last_job[ch]=0;last_output[ch]=0;end
  $readmemh("input_i.mem",vector_i);$readmemh("input_q.mem",vector_q);
  $readmemh("expected_usb.mem",expected_usb);$readmemh("expected_lsb.mem",expected_lsb);
  for(n=0;n<N;n=n+1)begin
   for(ch=0;ch<CHANNELS;ch=ch+1)begin
    @(negedge clk);in_valid=1;in_channel=ch;
    in_i=vector_i[n*CHANNELS+ch];in_q=vector_q[n*CHANNELS+ch];
   end
   @(negedge clk);in_valid=0;
   repeat(15991)@(negedge clk);
  end
  repeat(16000)@(negedge clk);
  for(ch=0;ch<CHANNELS;ch=ch+1)if(received[ch]!=OUTPUTS)$fatal(1,"Missing outputs ch=%d count=%d",ch,received[ch]);
  overload_valid=1;repeat(1000)@(negedge clk);overload_valid=0;
  if(!overload_fault)$fatal(1,"Overload was not reported");
  $display("PASS: %d complex outputs match independent convolution across eight channels",outputs_total);
  $display("PASS: continuous 8k USB/LSB cadence, history wrap, signed arithmetic, saturation, channel isolation; max latency %d clocks",max_latency);
  $display("PASS: intentional overload raises sticky fault");
  test_passed=1;#1;$finish;
 end
 initial begin #65000000;$fatal(1,"Shared FIR test timeout");end
endmodule
