// Channel A only. Capture on the next rising edge (one full ADC period),
// then transfer complete samples through a supported asynchronous FIFO.
module external_adc64_bd(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk128 CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk128, FREQ_HZ 128000000" *) input wire clk128,
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 clk_adc CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME clk_adc, FREQ_HZ 64000000" *) input wire clk_adc,
 input wire locked, input wire [13:0] adc_data, input wire adc_otra,
 output reg signed [13:0] sample=0, output reg valid=0
);
 (* IOB="TRUE" *) reg [14:0] input_register=0;
 always @(posedge clk_adc) input_register<={adc_otra,adc_data};
 wire [14:0] fifo_data;
 wire full,empty,wr_busy,rd_busy;
 wire take=locked && !empty && !rd_busy;
 xpm_fifo_async #(.FIFO_MEMORY_TYPE("distributed"),.FIFO_WRITE_DEPTH(32),
  .WRITE_DATA_WIDTH(15),.READ_DATA_WIDTH(15),.READ_MODE("fwft"),
  .FIFO_READ_LATENCY(0),.CDC_SYNC_STAGES(2),.RELATED_CLOCKS(0),
  .WR_DATA_COUNT_WIDTH(6),.RD_DATA_COUNT_WIDTH(6),
  .PROG_FULL_THRESH(22),.PROG_EMPTY_THRESH(10),.USE_ADV_FEATURES("0000")) samples(
  .rst(!locked),.wr_clk(clk_adc),.wr_en(locked && !wr_busy && !full),
  .din({input_register[14],~input_register[13],input_register[12:0]}),.full(full),.wr_rst_busy(wr_busy),
  .rd_clk(clk128),.rd_en(take),.dout(fifo_data),.empty(empty),.rd_rst_busy(rd_busy),
  .sleep(1'b0),.injectsbiterr(1'b0),.injectdbiterr(1'b0));
 always @(posedge clk128) begin
  valid<=take;
  if(take) sample<=fifo_data[13:0];
 end
endmodule
