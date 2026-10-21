// Continuous mono PCM16. One FPGA audio sample -> low byte then high byte.
// read32 snapshots remain independent. Opening the stream flushes stale data.
module ssb_audio_stream_bd(
 input wire clk128,bus_clk,locked,
 input wire audio_valid,lsb_mode,
 input wire signed [23:0] usb_audio,lsb_audio,
 input wire stream_open,rden,
 output reg [7:0] data=0,
 output wire empty,
 output reg overflow=0
);
 (* ASYNC_REG="TRUE" *) reg sopen_meta=0,sopen_sync=0;
 always @(posedge clk128)begin sopen_meta<=stream_open;sopen_sync<=sopen_meta;end
 wire reset_fifo=!locked || !sopen_sync;
 wire signed [23:0] selected=lsb_mode?lsb_audio:usb_audio;
 // Fixed gain of eight; full-scale RF is about -0.6 dBFS after CIC scaling.
 wire signed [15:0] pcm=(selected>4095)?16'sh7fff:
                         (selected< -4096)?16'sh8000:{selected[12:0],3'b0};
 wire [15:0] fifo_data;
 wire full,fifo_empty,wr_busy,rd_busy;
 reg high_byte=0;
 assign empty=!stream_open || rd_busy || fifo_empty;
 wire pop=rden && !empty && high_byte;
 always @(posedge clk128)begin
  if(!sopen_sync)overflow<=0;
  else if(audio_valid && full && !wr_busy)overflow<=1;
 end
 xpm_fifo_async #(.FIFO_MEMORY_TYPE("block"),.FIFO_WRITE_DEPTH(1024),
 .WRITE_DATA_WIDTH(16),.READ_DATA_WIDTH(16),.READ_MODE("fwft"),.FIFO_READ_LATENCY(0),
 .CDC_SYNC_STAGES(2),.DOUT_RESET_VALUE("0"),.ECC_MODE("no_ecc"),.USE_ADV_FEATURES("0000"),
 .WR_DATA_COUNT_WIDTH(11),.RD_DATA_COUNT_WIDTH(11)) samples(
 .rst(reset_fifo),.wr_clk(clk128),.wr_en(audio_valid && sopen_sync && !full && !wr_busy),
 .din(pcm),.full(full),.wr_rst_busy(wr_busy),.rd_clk(bus_clk),.rd_en(pop),
 .dout(fifo_data),.empty(fifo_empty),.rd_rst_busy(rd_busy),
 .sleep(1'b0),.injectsbiterr(1'b0),.injectdbiterr(1'b0));
 always @(posedge bus_clk)begin
  if(!stream_open || rd_busy)high_byte<=0;
  else if(rden && !empty)begin
   data<=high_byte?fifo_data[15:8]:fifo_data[7:0];high_byte<=~high_byte;
  end
 end
endmodule
