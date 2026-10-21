`timescale 1ns/1ps
module tb_ssb_audio_stream;
 reg clk128=0,bus_clk=0;always #3.90625 clk128=~clk128;always #5 bus_clk=~bus_clk;
 reg locked=0,audio_valid=0,lsb_mode=0,stream_open=0,rden=0;
 reg signed[23:0] usb_audio=0,lsb_audio=0;
 wire[7:0] data;wire empty,overflow;
 reg test_passed=0,drain=0;
 ssb_audio_stream_bd dut(.*);
 reg[15:0] expected[0:8191];integer wp=0,bp=0,bc=0;
 integer signed v,pcm;reg[7:0] want;
 always @(posedge clk128)if(audio_valid && dut.sopen_sync && !dut.full && !dut.wr_busy)begin
  v=lsb_mode?$signed(lsb_audio):$signed(usb_audio);
  if(v>4095)pcm=32767;else if(v< -4096)pcm=-32768;else pcm=v*8;
  expected[wp]=pcm;wp=wp+1;
 end
 always @(negedge bus_clk)begin bc=bc+1;if(drain)rden=(bc%7!=0 && bc%13!=0);end
 always @(posedge bus_clk)if(rden && !empty)begin
  if(bp/2>=wp)$fatal(1,"Audio produced an unexpected byte");
  want=(bp%2)?expected[bp/2][15:8]:expected[bp/2][7:0];
  #1;if(data!==want)$fatal(1,"PCM byte order/data mismatch byte=%d got=%h want=%h",bp,data,want);
  bp=bp+1;
 end
 function signed[23:0] pattern(input integer n);
  case(n%8)
   0:pattern=-5000;1:pattern=-4096;2:pattern=-123;3:pattern=0;
   4:pattern=4095;5:pattern=5000;6:pattern=-1;7:pattern=258;
  endcase
 endfunction
 task send(input integer count,input integer gap);
  integer j;
  begin
   for(j=0;j<count;j=j+1)begin
    @(negedge clk128);audio_valid=1;usb_audio=pattern(j);lsb_audio=-pattern(j);
    @(negedge clk128);audio_valid=0;repeat(gap)@(negedge clk128);
   end
  end
 endtask
 task closed;
  begin
   @(negedge bus_clk);stream_open=0;drain=0;rden=0;
   repeat(30)@(negedge clk128);wp=0;bp=0;
  end
 endtask
 task opened;
  begin stream_open=1;repeat(30)@(negedge clk128);
   while(dut.wr_busy!==1'b0 || dut.rd_busy!==1'b0)@(negedge clk128);
  end
 endtask
 initial begin
  #100;locked=1;opened();drain=1;send(2000,38);
  $display("STREAM1 wp=%d bp=%d wr_busy=%b rd_busy=%b empty=%b",wp,bp,dut.wr_busy,dut.rd_busy,empty);wait(bp==4000);if(overflow)$fatal(1,"Overflow with a fast reader");closed();
  // Close after the low byte; the next open must not leak the old high byte.
  opened();send(4,38);@(negedge bus_clk);rden=1;
  @(posedge bus_clk);#2;@(negedge bus_clk);rden=0;
  if(bp!=1)$fatal(1,"Half-word close test did not read one byte");closed();
  lsb_mode=1;opened();drain=1;send(20,38);$display("STREAM2 wp=%d bp=%d",wp,bp);wait(bp==40);
  if(overflow)$fatal(1,"Unexpected LSB stream overflow");closed();
  opened();send(1200,2);repeat(10)@(negedge clk128);
  if(!overflow)$fatal(1,"FIFO overflow was not reported");closed();
  if(overflow)$fatal(1,"Overflow did not clear on stream close");
  $display("PASS: PCM16 clipping, USB/LSB selection, little-endian bytes, async FIFO wrap/backpressure, reopen after half word, overflow flag");
  test_passed=1;#1;$finish;
 end
 initial begin #5000000;$fatal(1,"Audio stream test timeout wp=%d bp=%d empty=%b wr_busy=%b rd_busy=%b",wp,bp,empty,dut.wr_busy,dut.rd_busy);end
endmodule
