module tunable_simulator_bd(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk128 CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk128, FREQ_HZ 128000000" *) input wire clk128,
 input wire run,
 input wire [236:0] ft8_symbols,
 input wire ft8_commit,
 output reg ft8_ack=0,
 input wire [47:0] phase_increment,
 output wire signed [13:0] sample,
 output wire valid
);
 (* ASYNC_REG="TRUE" *) reg commit_meta=0,commit_sync=0;
 reg [236:0] active_symbols=237'h0ae10b50084c130e2cb28b99104cae10ba13850c341f79459959cb0ae10b;
 reg [1:0] restart_count=0;
 always @(posedge clk128) begin
  commit_meta<=ft8_commit;commit_sync<=commit_meta;
  if(commit_sync!=ft8_ack) begin
   active_symbols<=ft8_symbols;restart_count<=2;ft8_ack<=commit_sync;
  end else if(restart_count!=0) restart_count<=restart_count-1'b1;
 end
 wire clka,clkb;
 wire signed [13:0] sa,sb,adc,ca,cb;
 wire oa,ob,va,vb,active_source;
 assign sample=ca;
 assign valid=va;
 ad9248_clock_gen clocks(clk128,clka,clkb);
 ft8_virtual_rf_tunable source(.clk128(clk128),.start_ft8(run),
 .stop_ft8(!run || restart_count!=0),.phase_increment_in(phase_increment),
 .ft8_symbols(active_symbols),
 .sample_a(sa),.sample_b(sb),.source_active(active_source));
 ad9248_emulator emulator(clk128,clka,clkb,sa,sb,adc,oa,ob);
 adc_input frontend(.clk128(clk128),.select_virtual(1'b0),.adc_data(adc),
 .adc_otra(oa),.adc_otrb(ob),.virtual_data(14'sd0),.virtual_otra(1'b0),.virtual_otrb(1'b0),
 .clka(),.clkb(),.ddc_sample_a(ca),.ddc_sample_b(cb),.ddc_valid_a(va),.ddc_valid_b(vb),.otra(),.otrb());
endmodule
