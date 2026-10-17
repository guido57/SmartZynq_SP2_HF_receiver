`timescale 1ns/1ps
module tb_counter;
reg clk=0, opened=0, rden=0;
wire empty; wire [31:0] data;
always #5 clk=~clk;
counter_stream dut(clk,opened,rden,empty,data);
integer i;
task read_word;
input [31:0] expected;
begin
 @(negedge clk);rden=1;
 @(posedge clk);#1;
 if (data !== expected) $fatal(1,"Expected %d, got %d",expected,data);
 @(negedge clk);rden=0;
end
endtask
initial begin
 repeat(3) @(negedge clk);
 if (!empty) $fatal(1,"Closed stream must be empty");
 opened=1;
 for(i=0;i<100;i=i+1) begin
 read_word(i);repeat(i%4) @(negedge clk);
 end
 opened=0;repeat(3) @(negedge clk);opened=1;
 read_word(0);read_word(1);
 @(negedge clk);dut.next_word=32'hffffffff;
 read_word(32'hffffffff);read_word(0);
 $display("PASS: counter sequence, pauses, reopen, wraparound");$finish;
end
initial begin #100000;$fatal(1,"Timeout");end
endmodule
