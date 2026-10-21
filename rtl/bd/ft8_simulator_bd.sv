module ft8_simulator_bd(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk128 CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk128, FREQ_HZ 128000000" *) input wire clk128,
 input wire run,
 output wire signed [13:0] sample,
 output wire valid
);
 wire clka,clkb;
 wire signed [13:0] sa,sb,adc,ca,cb;
 wire oa,ob,va,vb,active_source;
 assign sample=ca;
 assign valid=va;
 ad9248_clock_gen clocks(clk128,clka,clkb);
 ft8_virtual_rf_core source(.clk128(clk128),.start_ft8(run),
 .stop_ft8(!run),.rf_freq_khz(15'd1000),
 .ft8_symbols(237'h0ae10b50084c130e2cb28b99104cae10ba13850c341f79459959cb0ae10b),
 .sample_a(sa),.sample_b(sb),.source_active(active_source));
 ad9248_emulator emulator(clk128,clka,clkb,sa,sb,adc,oa,ob);
 adc_input frontend(.clk128(clk128),.select_virtual(1'b0),.adc_data(adc),
 .adc_otra(oa),.adc_otrb(ob),.virtual_data(14'sd0),.virtual_otra(1'b0),.virtual_otrb(1'b0),
 .clka(),.clkb(),.ddc_sample_a(ca),.ddc_sample_b(cb),.ddc_valid_a(va),.ddc_valid_b(vb),.otra(),.otrb());
endmodule
