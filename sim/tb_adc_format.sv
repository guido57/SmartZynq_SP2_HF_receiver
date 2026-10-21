`timescale 1ns/1ps
module tb_adc_format;
 reg clk128=0,clk_adc=0,locked=0;
 reg [13:0] data=0;
 wire signed [13:0] sample;
 wire valid,overflow;
 always #3.90625 clk128=~clk128;
 always #62.5 clk_adc=~clk_adc;
 adc_external_frontend dut(.clk128(clk128),.clk_adc(clk_adc),.locked(locked),
  .adc_data(data),.adc_otra(1'b0),.sample(sample),.valid(valid),.overflow(overflow));
 task check(input [13:0] code,input integer expected);
 begin
  @(posedge clk_adc);#7;data=code;locked=1;
  @(posedge valid);#1;
  if($signed(sample)!==expected)$fatal(1,"code %h expected %0d got %0d",code,expected,$signed(sample));
 end
 endtask
 initial begin
  repeat(3)@(posedge clk_adc);
  check(14'h0000,-8192);check(14'h0001,-8191);check(14'h1fff,-1);
  check(14'h2000,0);check(14'h2001,1);check(14'h3fff,8191);
  $display("PASS: external offset-binary boundaries, midpoint and signed conversion");$finish;
 end
 initial begin #10000;$fatal(1,"timeout");end
endmodule
