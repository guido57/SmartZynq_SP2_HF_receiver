// Finite raw or I/Q snapshot. I and Q occupy separate signed 32-bit words.
module ssb_snapshot_bd #(parameter AW=12,parameter SETTLE_IQ=64,parameter SETTLE_AUDIO=192)(
 input wire clk128,bus_clk,locked,stream_open,capture_open,iq_mode,rden,
 input wire signed [13:0] selected_sample,
 input wire selected_valid,
 input wire signed [23:0] ddc_i,ddc_q,
 input wire ddc_valid,
 input wire audio_enable,lsb_mode,audio_valid,pair_mode,
 input wire signed [23:0] usb_audio,lsb_audio,
 output wire [31:0] data,
 output wire empty,eof
);
 localparam N=1<<AW;
 (* ram_style="block" *) reg [31:0] memory_i[0:N-1];
 (* ram_style="block" *) reg [31:0] memory_q[0:N-1];
 reg [AW-1:0] wrptr=0;
 reg [15:0] settle=0;
 reg done_capture=0;
 always @(posedge clk128) begin
  if(!capture_open || !locked) begin wrptr<=0;settle<=0;done_capture<=0;end
  else if(!done_capture) begin
   if(iq_mode ? (audio_enable?audio_valid:ddc_valid) : selected_valid) begin
    // Discard filter transients after a source/frequency change. Also handles
    // the DDC's initial startup; 64 IQ samples exceed the FIR settling time.
    if(settle<(iq_mode?(audio_enable?SETTLE_AUDIO:SETTLE_IQ):256)) settle<=settle+1'b1;
    else begin
     if(audio_enable)begin
      if(lsb_mode)memory_i[wrptr]<={{8{lsb_audio[23]}},lsb_audio};
      else memory_i[wrptr]<={{8{usb_audio[23]}},usb_audio};
     end else if(iq_mode) begin
      memory_i[wrptr]<={{8{ddc_i[23]}},ddc_i};
      memory_q[wrptr]<={{8{ddc_q[23]}},ddc_q};
     end else memory_i[wrptr]<={{(16-AW){1'b0}},wrptr,{2{selected_sample[13]}},selected_sample};
     if(wrptr==N-1)done_capture<=1;else wrptr<=wrptr+1'b1;
    end
   end
  end
 end
 (* ASYNC_REG="TRUE" *) reg ready1=0,ready2=0;
 reg armed=0;
 reg [AW+1:0] rdptr=0;
 // Mode is bundled with ready: it settles long before capture completes.
 reg bus_iq=0;
 (* ASYNC_REG="TRUE" *) reg pair_meta=0,pair_sync=0;
 wire [AW+1:0] words=bus_iq?(N*2):N;
 wire [AW-1:0] read_address=bus_iq?rdptr[AW:1]:rdptr[AW-1:0];
 reg [31:0] read_i,read_q;
 reg select_q=0;
 assign data=select_q?read_q:read_i;
 assign empty=!stream_open || !armed || !ready2 || rdptr==words;
 assign eof=armed && ready2 && rdptr==words;
 always @(posedge bus_clk) begin
  ready1<=done_capture;ready2<=ready1;
  pair_meta<=pair_mode;pair_sync<=pair_meta;
  if(!ready2)bus_iq<=pair_sync;
  if(!stream_open)begin rdptr<=0;armed<=0;end
  else begin
   if(!ready2)armed<=1;
   if(rden && !empty)begin
    read_i<=memory_i[read_address];
    read_q<=memory_q[read_address];
    select_q<=bus_iq && rdptr[0];
    rdptr<=rdptr+1'b1;
   end
  end
 end
endmodule
