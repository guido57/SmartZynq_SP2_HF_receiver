module adc_switch_capture_bd #(parameter AW=12)(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk128 CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk128, FREQ_HZ 128000000" *) input wire clk128,
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 bus_clk CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME bus_clk, FREQ_HZ 100000000" *) input wire bus_clk,
 input wire locked,stream_open,rden,source_external,
 input wire signed [13:0] simulated_sample,external_sample,
 input wire simulated_valid,external_valid,
 output wire simulator_run,active_external,
 output reg [31:0] data,
 output wire empty,eof
);
 assign simulator_run=op2 && locked;
 localparam N=1<<AW;
 (* ASYNC_REG="TRUE" *) reg op1=0,op2=0;
 (* ASYNC_REG="TRUE" *) reg source_meta=0,source_sync=0;
 reg frame_external=0;
 always @(posedge clk128)begin
  source_meta<=source_external;source_sync<=source_meta;
  if(!op2)frame_external<=source_sync;
 end
 assign active_external=frame_external;
 wire signed [13:0] capture_sample=frame_external ? external_sample : simulated_sample;
 wire capture_valid=frame_external ? external_valid : simulated_valid;
 (* ram_style="block" *) reg[31:0] memory[0:N-1];
 reg[AW-1:0] wrptr=0;
 reg[7:0] settle=0;
 reg done_capture=0;
 always @(posedge clk128)begin
  op1<=stream_open;op2<=op1;
  if(!op2 || !locked)begin wrptr<=0;settle<=0;done_capture<=0;end
  else if(!done_capture)begin
   if(settle!=255)settle<=settle+1'b1;
   else if(capture_valid)begin
    memory[wrptr]<={{(16-AW){1'b0}},wrptr,{2{capture_sample[13]}},capture_sample};
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
