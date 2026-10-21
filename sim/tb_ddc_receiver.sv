`timescale 1ns/1ps
module tb_ddc_receiver;
 reg test_passed=0;
 reg clk128=0,bus_clk=0,clk64=0;
 always #3.90625 clk128=~clk128;
 always #5 bus_clk=~bus_clk;
 always @(negedge clk128) clk64<=~clk64;
 reg locked=0,stream_open=0,rden=0,config_toggle=0;
 reg [97:0] cfg={48'd4398046511104,48'd4398046511104,2'b00};
 wire [47:0] sim_phase;
 wire run,external_active;
 wire signed [13:0] sim_data,ext_data;
 wire sim_valid,ext_valid;
 wire [31:0] data;wire empty,eof;
 reg [13:0] adc_data=14'h2000;
 always @(posedge clk64) if(locked) #3 adc_data<=adc_data+1'b1;
 external_adc64_bd frontend(clk128,clk64,locked,adc_data,1'b0,ext_data,ext_valid);
 tunable_simulator_bd simulator(clk128,run,sim_phase,sim_data,sim_valid);
 ddc_receiver_bd #(.AW(5),.SETTLE_IQ(64)) dut(clk128,bus_clk,locked,stream_open,rden,config_toggle,cfg,sim_data,ext_data,sim_valid,ext_valid,run,external_active,sim_phase,data,empty,eof);
 wire signed [23:0] ref_i,ref_q;
 wire ref_valid;
 reg signed [23:0] expected_i,expected_q;
 integer reference_count=0,matched_count=0;
 reference_ddc reference_path(.clk128(clk128),.sample_in(dut.selected_sample),
  .sample_valid(dut.selected_valid),.phase_increment_in(dut.config_active[49:2]),
  .i_out(ref_i),.q_out(ref_q),.output_valid(ref_valid));
 always @(posedge clk128) begin
  #2;
  if(reference_path.cic3_valid)begin
   expected_i=reference_path.cic_i;expected_q=reference_path.cic_q;
   reference_count=reference_count+1;
  end
  if(dut.ddc.core.cic_valid)begin
   if(dut.ddc.core.cic_i!=={{8{expected_i[23]}},expected_i} || dut.ddc.core.cic_q!=={{8{expected_q[23]}},expected_q})
    $fatal(1,"Mixer/CIC differs from original reference");
   matched_count=matched_count+1;
  end
  if(dut.ddc.core.fir_overrun)$fatal(1,"Shared FIR overload");
 end
 function [47:0] inc(input integer hz);
  reg [95:0] n;
  begin n=96'd281474976710656*hz+32000000;inc=n/64000000;end
 endfunction
 task config_set(input bit ext,input bit iq,input integer tune,input integer sim);
  begin
   @(negedge bus_clk);cfg={inc(sim),inc(tune),iq,ext};config_toggle=~config_toggle;
   repeat(20)@(negedge bus_clk);
  end
 endtask
 task read_word(output reg [31:0] value);
  begin
   while(empty)@(negedge bus_clk);
   rden=1;@(posedge bus_clk);#1 value=data;
   @(negedge bus_clk);rden=0;
   repeat(2)@(negedge bus_clk); // exercise backpressure
  end
 endtask
 reg [31:0] word_i,word_q;integer k;
 real old_i,old_q,iv,qv,power_sum,cross_sum,dot_sum,angle;
 task check_iq(input integer direction);
  begin
   stream_open=1;old_i=0;old_q=0;power_sum=0;cross_sum=0;dot_sum=0;
   for(k=0;k<32;k=k+1)begin
    read_word(word_i);read_word(word_q);
    iv=$signed(word_i);qv=$signed(word_q);
    if(word_i[31:24]!={8{word_i[23]}} || word_q[31:24]!={8{word_q[23]}})$fatal(1,"Bad IQ sign extension");
    power_sum=power_sum+iv*iv+qv*qv;
    if(k>0)begin cross_sum=cross_sum+old_i*qv-old_q*iv;dot_sum=dot_sum+old_i*iv+old_q*qv;end
    old_i=iv;old_q=qv;
   end
   if(!eof)$fatal(1,"Missing IQ EOF");
   angle=$atan2(cross_sum,dot_sum);
   if($sqrt(power_sum/32)<2500 || $sqrt(power_sum/32)>5000)$fatal(1,"Unexpected DDC amplitude %f",$sqrt(power_sum/32));
   if(angle*direction<0.70 || angle*direction>0.87)$fatal(1,"Expected signed 1 kHz rotation, angle=%f",angle);
   $display("PASS IQ offset direction=%d angle=%f amplitude=%f",direction,angle,$sqrt(power_sum/32));
   stream_open=0;repeat(30)@(negedge bus_clk);
  end
 endtask
 // Verify external FIFO preserves every sample and cadence over many wraps.
 reg signed [13:0] expected[0:2047];integer wp=0,rp=0,last_cycle=0,cycles=0;
 always @(posedge clk64) if(locked && !frontend.wr_busy && !frontend.full && wp<2048)begin
  expected[wp]=$signed({~frontend.input_register[13],frontend.input_register[12:0]});wp=wp+1;
 end
 always @(posedge clk128)begin
  #1;cycles=cycles+1;
  if(ext_valid && rp<2048)begin
   if(ext_data!==expected[rp])$fatal(1,"ADC64 lost/reordered sample %d got %d expected %d",rp,ext_data,expected[rp]);
   if(rp>4 && cycles-last_cycle!=2)$fatal(1,"ADC64 valid cadence is not 64 MS/s");
   last_cycle=cycles;rp=rp+1;
  end
 end
 initial begin
  if(inc(1000000)!==48'd4398046511104)$fatal(1,"Testbench phase conversion overflow");
  #100 locked=1;
  config_set(1,0,1000000,1000000);
  stream_open=1;
  for(k=0;k<32;k=k+1)begin
   read_word(word_i);
   if(word_i[31:16]!=k)$fatal(1,"Raw index mismatch");
   if(k>0 && $signed(word_i[15:0])!=$signed(word_q[15:0])+1)$fatal(1,"External ADC raw discontinuity");
   word_q=word_i;
   // Mid-frame change must be deferred until close.
   if(k==8)begin cfg={inc(1001000),inc(1000000),2'b10};config_toggle=~config_toggle;end
  end
  if(!eof)$fatal(1,"Missing raw EOF");
  stream_open=0;repeat(30)@(negedge bus_clk);
  check_iq(1);
  config_set(0,1,1002000,1001000);check_iq(-1);
  config_set(0,1,1002000,1003000);check_iq(1);
  config_set(0,1,1000000,1005000);
  stream_open=1;power_sum=0;
  for(k=0;k<32;k=k+1)begin
   read_word(word_i);read_word(word_q);iv=$signed(word_i);qv=$signed(word_q);
   power_sum=power_sum+iv*iv+qv*qv;
  end
  if($sqrt(power_sum/32)>3.0)$fatal(1,"5 kHz alias rejection insufficient, RMS=%f",$sqrt(power_sum/32));
  $display("PASS 5 kHz alias rejected: output RMS=%f versus ~3800 at 1 kHz",$sqrt(power_sum/32));
  stream_open=0;
  if(matched_count<100)$fatal(1,"Insufficient reference DDC comparisons");
  $display("PASS: %d mixer/CIC outputs equal original core bit-for-bit",matched_count);
  if(rp<2048)$fatal(1,"ADC FIFO coverage incomplete");
  $display("PASS: ADC64 CDC/cadence, raw/index/EOF, frozen frame controls, DDC +/- tuning and simulator frequency changes");test_passed=1;#1;$finish;
 end
 initial begin #75000000;$fatal(1,"Simulation timeout");end
endmodule
