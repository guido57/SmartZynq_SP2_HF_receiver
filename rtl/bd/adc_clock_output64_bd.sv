module adc_clock_output64_bd(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk_adc CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk_adc, FREQ_HZ 64000000" *) input wire clk_adc,
 input wire locked,
 output wire clka,clkb
);
 ODDR #(.DDR_CLK_EDGE("SAME_EDGE"),.INIT(1'b0),.SRTYPE("SYNC")) clock_forward
 (.C(clk_adc),.CE(1'b1),.D1(1'b1),.D2(1'b0),.R(!locked),.S(1'b0),.Q(clka));
 assign clkb=1'b0;
endmodule
