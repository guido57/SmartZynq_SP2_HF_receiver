module ft8_tb;
 reg clk=0;always #5 clk=~clk;
 reg start=0,stop=1;
 reg [236:0] tones=0;
 wire signed [13:0] a,b;wire active;
 ft8_virtual_rf_tunable #(.SYMBOL_SAMPLES(4),.SLOT_SAMPLES(320)) dut(clk,start,stop,48'd4398046511104,tones,a,b,active);
 integer n;
 initial begin
 tones=237'h0ae10b50084c130e2cb28b99104cae10ba13850c341f79459959cb0ae10b;
 repeat(2) @(negedge clk);stop=0;start=1;
 @(negedge clk);start=0;
 for(n=0;n<79;n=n+1) begin
 if(!active || dut.symbol_index!=n || dut.current_tone!==tones[n*3 +: 3]) $fatal(1,"Symbol mismatch %d",n);
 repeat(8) @(negedge clk);
 end
 if(active) $fatal(1,"Frame did not end after 79 symbols");
 repeat(8) @(negedge clk);
 if(!active || dut.symbol_index!=0) $fatal(1,"15-second slot did not restart");
 $display("PASS: 79 symbols, frame end, silent gap and slot repeat");$finish;
 end
endmodule
