// Shared 24x18 Hilbert MAC, matched I delay and USB/LSB phasing.
// 128 MHz clock; up to eight channel-tagged 8 ksample/s I/Q streams.
// Each channel has independent history, startup/decimation count and job pointer.
module shared_ssb_demod #(
 parameter integer CHANNELS=8,
 parameter integer TAPS=127,
 parameter integer DECIMATION=1,
 parameter integer RING_AW=8,
 parameter COEFF_FILE="ssb_hilbert_8k.mem",
 parameter integer CH_BITS=(CHANNELS>1?$clog2(CHANNELS):1)
)(
 input wire clk,
 input wire in_valid,
 input wire [CH_BITS-1:0] in_channel,
 input wire signed [23:0] in_i,in_q,
 output reg out_valid=0,
 output reg [CH_BITS-1:0] out_channel=0,
 output reg signed [23:0] usb_audio=0,lsb_audio=0,
 output reg overrun=0
);
 localparam RING_SIZE=1<<RING_AW;
 localparam TAP_BITS=(TAPS>1?$clog2(TAPS):1);
 localparam COUNT_BITS=(DECIMATION>1?$clog2(DECIMATION):1);
 (* ram_style="block" *) reg signed [23:0] history_i[0:CHANNELS*RING_SIZE-1];
 (* ram_style="block" *) reg signed [23:0] history_q[0:CHANNELS*RING_SIZE-1];
 (* rom_style="block" *) reg signed [17:0] coefficients[0:TAPS-1];
 reg [RING_AW-1:0] wrptr[0:CHANNELS-1];
 reg [TAP_BITS:0] filled[0:CHANNELS-1];
 reg [COUNT_BITS-1:0] decimation_count[0:CHANNELS-1];
 reg [CHANNELS-1:0] pending=0;
 reg [RING_AW-1:0] pending_base[0:CHANNELS-1];
 reg [CH_BITS-1:0] active_channel=0;
 reg [RING_AW-1:0] base=0;
 reg [TAP_BITS-1:0] tap=0;
 reg [3:0] state=0;
 reg signed [23:0] ram_i,ram_q;
 reg signed [23:0] operand=0;
 reg signed [17:0] coefficient=0;
 reg signed [41:0] product=0;
 reg signed [57:0] acc_q=0;
 reg signed [23:0] delayed_i=0;
 wire signed [57:0] delayed_ext={{34{delayed_i[23]}},delayed_i};
 wire signed [57:0] hilbert_q=acc_q >>> 17;
 wire [RING_AW-1:0] read_slot=base-tap;
 wire [CH_BITS+RING_AW-1:0] read_address={active_channel,read_slot};
 wire [CH_BITS+RING_AW-1:0] write_address={in_channel,wrptr[in_channel]};
 integer chosen,c;
 always @* begin
  chosen=-1;
  for(integer n=0;n<CHANNELS;n=n+1) if(pending[n] && chosen<0)chosen=n;
 end
 initial begin
  if(CHANNELS<1 || CHANNELS>8 || TAPS+DECIMATION>=RING_SIZE)
   $error("Unsupported FIR parameters/history guard");
  $readmemh(COEFF_FILE,coefficients);
  for(c=0;c<CHANNELS;c=c+1)begin
   wrptr[c]=0;filled[c]=0;decimation_count[c]=0;pending_base[c]=0;
  end
 end
 function automatic signed [23:0] saturate24(input signed [57:0] v);
  if(v>58'sd8388607)saturate24=24'sh7fffff;
  else if(v< -58'sd8388608)saturate24=24'sh800000;
  else saturate24=v[23:0];
 endfunction
 // Dedicated synchronous memory outputs preserve BRAM inference. Sharing the
 // operand register directly between two RAMs would force distributed RAM.
 always @(posedge clk)begin
  ram_i<=history_i[read_address];ram_q<=history_q[read_address];
  coefficient<=coefficients[tap];
  if(in_valid && in_channel<CHANNELS)begin
   history_i[write_address]<=in_i;history_q[write_address]<=in_q;
  end
 end
 always @(posedge clk)begin
  out_valid<=0;
  // A single multiply expression is shared between the two component phases.
  if(state==3)product<=operand*coefficient;
  case(state)
   0:if(chosen>=0)begin
    active_channel<=chosen; base<=pending_base[chosen];pending[chosen]<=0;
    tap<=0;acc_q<=0;state<=1;
   end
   1:state<=2;
   2:begin
    operand<=ram_q;
    if(tap==(TAPS-1)/2)delayed_i<=ram_i;
    state<=3;
   end
   3:state<=4;
   4:begin
    acc_q<=acc_q+{{16{product[41]}},product};
    if(tap==TAPS-1)state<=5;
    else begin tap<=tap+1'b1;state<=1;end
   end
   5:begin
    // H has -j response at positive frequency: USB=I-H(Q), LSB=I+H(Q).
    // Divide by two to preserve the I/Q envelope's amplitude.
    usb_audio<=saturate24((delayed_ext-hilbert_q) >>> 1);
    lsb_audio<=saturate24((delayed_ext+hilbert_q) >>> 1);
    out_channel<=active_channel;out_valid<=1;state<=0;
   end
   default:state<=0;
  endcase
  if(in_valid)begin
   if(in_channel>=CHANNELS)overrun<=1;
   else begin
    wrptr[in_channel]<=wrptr[in_channel]+1'b1;
    // Do not read unwritten history: first result uses a fully filled window.
    if(filled[in_channel]<TAPS)begin
     filled[in_channel]<=filled[in_channel]+1'b1;decimation_count[in_channel]<=0;
    end else if(decimation_count[in_channel]==DECIMATION-1)begin
     decimation_count[in_channel]<=0;
     // Sticky fault: the caller must never silently use an overloaded stream.
     if(pending[in_channel])overrun<=1;
     pending[in_channel]<=1;pending_base[in_channel]<=wrptr[in_channel];
    end else decimation_count[in_channel]<=decimation_count[in_channel]+1'b1;
   end
  end
 end
endmodule
