module external_adc_bd(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk128 CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk128, FREQ_HZ 128000000" *) input wire clk128,
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk_adc CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk_adc, FREQ_HZ 8000000" *) input wire clk_adc,
 input wire locked,
 input wire [13:0] adc_data,
 input wire adc_otra,
 output wire signed [13:0] sample,
 output wire valid
);
 adc_external_frontend frontend(.clk128(clk128),.clk_adc(clk_adc),.locked(locked),
 .adc_data(adc_data),.adc_otra(adc_otra),.sample(sample),.valid(valid),.overflow());
endmodule
