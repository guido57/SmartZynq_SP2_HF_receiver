`timescale 1ns/1ps
module tb_virtual_adc;
reg clk=0,busclk=0,opened=0,rden=0;wire empty,eof;wire[31:0]data;
always #3.90625 clk=~clk;
always #5 busclk=~busclk;
virtual_adc_snapshot #(.AW(8)) dut(clk,busclk,1'b1,opened,rden,data,empty,eof);
integer i;reg signed[15:0] samples[0:255];integer lo,hi;
task capture;
begin
 @(negedge busclk);opened=1;wait(!empty);lo=8192;hi=-8192;
 for(i=0;i<256;i=i+1)begin
 @(negedge busclk);rden=1;
 @(posedge busclk);#1;
 if(data[31:16]!==i)$fatal(1,"index mismatch");
 samples[i]=$signed(data[15:0]);
 if(i>=64 && samples[i]!==samples[i-64])$fatal(1,"sine period mismatch");
 if(samples[i]<lo)lo=samples[i];if(samples[i]>hi)hi=samples[i];
 @(negedge busclk);rden=0;repeat(i%3)@(negedge busclk);
 end
 if(lo>=0||hi<=0)$fatal(1,"not a bipolar sine");
 if(!eof||!empty)$fatal(1,"EOF missing");
 opened=0;repeat(20)@(negedge busclk);
end
endtask
initial begin repeat(10)@(negedge busclk);capture;capture;$display("PASS: reused ADC emulator, 1 MHz sine, index, pauses, EOF, reopen");$finish;end
initial begin #200000;$fatal(1,"timeout");end
endmodule
