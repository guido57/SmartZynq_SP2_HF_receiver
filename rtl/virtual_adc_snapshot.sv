// Finite channel-A snapshot from the existing 64 MS/s ADC emulator.
module virtual_adc_snapshot #(parameter AW=12)(
 input wire clk128, bus_clk, locked, stream_open, rden,
 output reg [31:0] data,
 output wire empty,eof
);
 localparam N=1<<AW;
 (* ASYNC_REG="TRUE" *) reg op1=0,op2=0;
 wire clka,clkb;wire signed[13:0] sa,sb,adc,ca,cb;
 wire oa,ob,va,vb,active_source;
 ad9248_clock_gen clocks(clk128,clka,clkb);
 ft8_virtual_rf_core source(.clk128(clk128),.start_ft8(op2 && locked),
 .stop_ft8(!op2 || !locked),.rf_freq_khz(15'd1000),.ft8_symbols(237'b0),
 .sample_a(sa),.sample_b(sb),.source_active(active_source));
 ad9248_emulator emulator(clk128,clka,clkb,sa,sb,adc,oa,ob);
 adc_input frontend(.clk128(clk128),.select_virtual(1'b0),.adc_data(adc),
 .adc_otra(oa),.adc_otrb(ob),.virtual_data(14'sd0),.virtual_otra(1'b0),.virtual_otrb(1'b0),
 .clka(),.clkb(),.ddc_sample_a(ca),.ddc_sample_b(cb),.ddc_valid_a(va),.ddc_valid_b(vb),.otra(),.otrb());
 (* ram_style="block" *) reg[31:0] memory[0:N-1];
 reg[AW-1:0] wrptr=0;
 reg[7:0] settle=0;
 reg done_capture=0;
 always @(posedge clk128)begin
  op1<=stream_open;op2<=op1;
  if(!op2 || !locked)begin wrptr<=0;settle<=0;done_capture<=0;end
  else if(!done_capture)begin
   if(settle!=255)settle<=settle+1'b1;
   else if(va)begin
    memory[wrptr]<={{(16-AW){1'b0}},wrptr,{2{ca[13]}},ca};
    if(wrptr==N-1)done_capture<=1;
    else wrptr<=wrptr+1'b1;
   end
  end
 end
 (* ASYNC_REG="TRUE" *)reg ready1=0,ready2=0;
 reg armed=0;reg[AW:0] rdptr=0;
 assign empty=!stream_open || !armed || !ready2 || rdptr==N;
 assign eof=armed && ready2 && rdptr==N;
 always @(posedge bus_clk)begin
  ready1<=done_capture;ready2<=ready1;
  if(!stream_open)begin rdptr<=0;armed<=0;end
  else begin
   if(!ready2)armed<=1;
   if(rden && !empty)begin data<=memory[rdptr[AW-1:0]];rdptr<=rdptr+1'b1;end
  end
 end
endmodule
