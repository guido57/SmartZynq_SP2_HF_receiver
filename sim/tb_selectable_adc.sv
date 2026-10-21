`timescale 1ns/1ps
module tb_selectable_adc;
reg clk=0,busclk=0,adcclk=0,opened=0,rden=0,source_external=0;
wire empty,eof,active_external;wire[31:0]data;
reg signed[13:0] physical_sample=-4000;
wire [13:0] physical_data=physical_sample ^ 14'h2000;
always #3.90625 clk=~clk;
always #5 busclk=~busclk;
always #62.5 adcclk=~adcclk;
always @(posedge adcclk) physical_sample <= #7 physical_sample+1;
selectable_adc_snapshot #(.AW(8)) dut(.clk128(clk),.clk_adc(adcclk),.bus_clk(busclk),
 .locked(1'b1),.stream_open(opened),.rden(rden),.source_external(source_external),
 .adc_data(physical_data),.adc_otra(1'b0),.active_external(active_external),
 .data(data),.empty(empty),.eof(eof));
integer i;reg signed[15:0] samples[0:255];integer lo,hi;
task capture(input integer external_mode,input integer switch_mid_frame);
begin
 source_external=external_mode;repeat(20)@(negedge busclk);
 opened=1;
 if(switch_mid_frame)begin
  repeat(100)@(negedge busclk);source_external=!external_mode;
 end
 wait(!empty);
 if(active_external!==external_mode[0])$fatal(1,"wrong latched source");
 lo=8192;hi=-8192;
 for(i=0;i<256;i=i+1)begin
  @(negedge busclk);rden=1;
  @(posedge busclk);#1;
  if(data[31:16]!==i)$fatal(1,"index mismatch");
  samples[i]=$signed(data[15:0]);
  if(external_mode && i>0 && samples[i]!==samples[i-1]+16'sd1)$fatal(1,"external ramp missing/mixed samples");
  if(!external_mode && i>=64 && samples[i]!==samples[i-64])$fatal(1,"simulated sine period mismatch");
  if(samples[i]<lo)lo=samples[i];if(samples[i]>hi)hi=samples[i];
  @(negedge busclk);rden=0;repeat(i%3)@(negedge busclk);
 end
 if(!external_mode && (lo>=0||hi<=0))$fatal(1,"not a bipolar sine");
 if(!eof||!empty)$fatal(1,"EOF missing");
 opened=0;repeat(20)@(negedge busclk);
end
endtask
initial begin
 repeat(10)@(negedge busclk);
 capture(0,0);capture(1,1);capture(0,1);capture(1,0);
 $display("PASS: simulator/external, signed ramp, source frozen per frame, pauses, EOF and reopen");$finish;
end
initial begin #200000;$fatal(1,"timeout");end
endmodule
