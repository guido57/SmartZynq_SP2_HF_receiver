module ft8_upload_tb;
 reg clk=0;always #5 clk=~clk;
 reg run=0,commit=0;
 reg [236:0] tones=0;
 wire ack;wire signed [13:0] sample;wire valid;
 tunable_simulator_bd dut(.clk128(clk),.run(run),.ft8_symbols(tones),.ft8_commit(commit),.ft8_ack(ack),.phase_increment(48'd4398046511104),.sample(sample),.valid(valid));
 initial begin
 repeat(5) @(negedge clk);run=1;
 repeat(8) @(negedge clk);
 tones=237'h123456789;commit=1;
 repeat(10) @(negedge clk);
 if(!ack || dut.source.symbols_latched!==tones) $fatal(1,"First upload/restart failed");
 tones=237'h7777654321;commit=0;
 repeat(10) @(negedge clk);
 if(ack || dut.source.symbols_latched!==tones) $fatal(1,"Second upload/restart failed");
 $display("PASS: asynchronous commit synchronization, acknowledgement and two message restarts");$finish;
 end
endmodule
