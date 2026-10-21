// Complete Xillybus endpoint logic moved from the board top.
module xillybus_ssb_endpoints_bd(
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 bus_clk CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME bus_clk, FREQ_HZ 100000000, ASSOCIATED_BUSIF S_AXI:M_AXI_ACP, ASSOCIATED_RESET bus_rst_n" *)
 input wire bus_clk,
 (* X_INTERFACE_INFO="xilinx.com:signal:reset:1.0 bus_rst_n RST", X_INTERFACE_PARAMETER="XIL_INTERFACENAME bus_rst_n, POLARITY ACTIVE_LOW" *)
 input wire bus_rst_n,
 (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME S_AXI, PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 32, ID_WIDTH 0, FREQ_HZ 100000000" *)
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
 input wire [31:0] S_AXI_AWADDR,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
 input wire S_AXI_AWVALID,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
 input wire [31:0] S_AXI_WDATA,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
 input wire [3:0] S_AXI_WSTRB,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
 input wire S_AXI_WVALID,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
 input wire S_AXI_BREADY,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
 input wire [31:0] S_AXI_ARADDR,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
 input wire S_AXI_ARVALID,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
 input wire S_AXI_RREADY,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP ARREADY" *)
 input wire M_AXI_ACP_ARREADY,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP RVALID" *)
 input wire M_AXI_ACP_RVALID,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP RDATA" *)
 input wire [63:0] M_AXI_ACP_RDATA,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP RRESP" *)
 input wire [1:0] M_AXI_ACP_RRESP,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP RLAST" *)
 input wire M_AXI_ACP_RLAST,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP AWREADY" *)
 input wire M_AXI_ACP_AWREADY,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP WREADY" *)
 input wire M_AXI_ACP_WREADY,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP BVALID" *)
 input wire M_AXI_ACP_BVALID,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP BRESP" *)
 input wire [1:0] M_AXI_ACP_BRESP,
 input wire [31:0] user_r_read_32_data,
 input wire user_r_read_32_empty,
 input wire user_r_read_32_eof,
 input wire [7:0] audio_data,
 input wire audio_empty,audio_overflow,
 output wire audio_rden,
 output reg audio_open=0,
 output wire [3:0] GPIO_LED,
 output wire quiesce,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
 output wire S_AXI_ARREADY,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
 output wire [31:0] S_AXI_RDATA,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
 output wire [1:0] S_AXI_RRESP,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
 output wire S_AXI_RVALID,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
 output wire S_AXI_WREADY,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
 output wire [1:0] S_AXI_BRESP,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
 output wire S_AXI_BVALID,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
 output wire S_AXI_AWREADY,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP ARVALID" *)
 output wire M_AXI_ACP_ARVALID,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP ARADDR" *)
 output wire [31:0] M_AXI_ACP_ARADDR,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP ARLEN" *)
 output wire [3:0] M_AXI_ACP_ARLEN,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP ARSIZE" *)
 output wire [2:0] M_AXI_ACP_ARSIZE,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP ARBURST" *)
 output wire [1:0] M_AXI_ACP_ARBURST,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP ARPROT" *)
 output wire [2:0] M_AXI_ACP_ARPROT,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP ARCACHE" *)
 output wire [3:0] M_AXI_ACP_ARCACHE,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP RREADY" *)
 output wire M_AXI_ACP_RREADY,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP AWVALID" *)
 output wire M_AXI_ACP_AWVALID,
 (* X_INTERFACE_PARAMETER="XIL_INTERFACENAME M_AXI_ACP, PROTOCOL AXI3, DATA_WIDTH 64, ADDR_WIDTH 32, ID_WIDTH 0, FREQ_HZ 100000000" *)
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP AWADDR" *)
 output wire [31:0] M_AXI_ACP_AWADDR,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP AWLEN" *)
 output wire [3:0] M_AXI_ACP_AWLEN,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP AWSIZE" *)
 output wire [2:0] M_AXI_ACP_AWSIZE,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP AWBURST" *)
 output wire [1:0] M_AXI_ACP_AWBURST,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP AWPROT" *)
 output wire [2:0] M_AXI_ACP_AWPROT,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP AWCACHE" *)
 output wire [3:0] M_AXI_ACP_AWCACHE,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP WVALID" *)
 output wire M_AXI_ACP_WVALID,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP WDATA" *)
 output wire [63:0] M_AXI_ACP_WDATA,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP WSTRB" *)
 output wire [7:0] M_AXI_ACP_WSTRB,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP WLAST" *)
 output wire M_AXI_ACP_WLAST,
 (* X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 M_AXI_ACP BREADY" *)
 output wire M_AXI_ACP_BREADY,
 output wire host_interrupt,
 output wire user_r_read_32_rden,
 output wire user_r_read_32_open,
 output reg [99:0] receiver_config={2'b00,48'd4398046511104,48'd4398046511104,2'b00},
 output reg config_toggle=0,
 output reg [236:0] ft8_symbols=237'h0ae10b50084c130e2cb28b99104cae10ba13850c341f79459959cb0ae10b,
 output reg ft8_commit=0,
 input wire ft8_ack,
 (* X_INTERFACE_INFO="xilinx.com:signal:clock:1.0 user_clk CLK", X_INTERFACE_PARAMETER="XIL_INTERFACENAME user_clk, FREQ_HZ 100000000" *) input wire user_clk,
 input wire user_wren,
 input wire [3:0] user_wstrb,
 input wire user_rden,
 input wire [31:0] user_wr_data,
 input wire [31:0] user_addr,
 output reg [31:0] user_rd_data,
 output wire user_irq
);
 (* ASYNC_REG="TRUE" *) reg audio_overflow_meta=0,audio_overflow_sync=0;
 always @(posedge bus_clk)begin
  audio_overflow_meta<=audio_overflow;audio_overflow_sync<=audio_overflow_meta;
 end
 wire [7:0] loop_data;
 wire loop_empty,loop_full;
 always @(posedge bus_clk)audio_open<=user_r_read_8_open && receiver_config[99];
 assign audio_rden=user_r_read_8_rden && receiver_config[99];
 assign user_r_read_8_data=receiver_config[99]?audio_data:loop_data;
 assign user_r_read_8_empty=receiver_config[99]?audio_empty:loop_empty;
 assign user_w_write_8_full=receiver_config[99]?1'b0:loop_full;
 wire user_w_write_32_full;
 wire [7:0] user_r_read_8_data;
 wire user_r_read_8_empty;
 wire user_r_read_8_eof;
 wire user_w_write_8_full;
 wire [7:0] user_r_mem_8_data;
 wire user_r_mem_8_empty;
 wire user_r_mem_8_eof;
 wire user_w_mem_8_full;
 wire user_w_write_32_wren;
 wire [31:0] user_w_write_32_data;
 wire user_w_write_32_open;
 wire user_r_read_8_rden;
 wire user_r_read_8_open;
 wire user_w_write_8_wren;
 wire [7:0] user_w_write_8_data;
 wire user_w_write_8_open;
 wire user_r_mem_8_rden;
 wire user_r_mem_8_open;
 wire user_w_mem_8_wren;
 wire [7:0] user_w_mem_8_data;
 wire user_w_mem_8_open;
 wire [4:0] user_mem_8_addr;
 wire user_mem_8_addr_update;
 xillybus core(
 .bus_clk(bus_clk),
 .bus_rst_n(bus_rst_n),
 .S_AXI_AWADDR(S_AXI_AWADDR),
 .S_AXI_AWVALID(S_AXI_AWVALID),
 .S_AXI_WDATA(S_AXI_WDATA),
 .S_AXI_WSTRB(S_AXI_WSTRB),
 .S_AXI_WVALID(S_AXI_WVALID),
 .S_AXI_BREADY(S_AXI_BREADY),
 .S_AXI_ARADDR(S_AXI_ARADDR),
 .S_AXI_ARVALID(S_AXI_ARVALID),
 .S_AXI_RREADY(S_AXI_RREADY),
 .M_AXI_ACP_ARREADY(M_AXI_ACP_ARREADY),
 .M_AXI_ACP_RVALID(M_AXI_ACP_RVALID),
 .M_AXI_ACP_RDATA(M_AXI_ACP_RDATA),
 .M_AXI_ACP_RRESP(M_AXI_ACP_RRESP),
 .M_AXI_ACP_RLAST(M_AXI_ACP_RLAST),
 .M_AXI_ACP_AWREADY(M_AXI_ACP_AWREADY),
 .M_AXI_ACP_WREADY(M_AXI_ACP_WREADY),
 .M_AXI_ACP_BVALID(M_AXI_ACP_BVALID),
 .M_AXI_ACP_BRESP(M_AXI_ACP_BRESP),
 .user_r_read_32_data(user_r_read_32_data),
 .user_r_read_32_empty(user_r_read_32_empty),
 .user_r_read_32_eof(user_r_read_32_eof),
 .user_w_write_32_full(user_w_write_32_full),
 .user_r_read_8_data(user_r_read_8_data),
 .user_r_read_8_empty(user_r_read_8_empty),
 .user_r_read_8_eof(user_r_read_8_eof),
 .user_w_write_8_full(user_w_write_8_full),
 .user_r_mem_8_data(user_r_mem_8_data),
 .user_r_mem_8_empty(user_r_mem_8_empty),
 .user_r_mem_8_eof(user_r_mem_8_eof),
 .user_w_mem_8_full(user_w_mem_8_full),
 .GPIO_LED(GPIO_LED),
 .quiesce(quiesce),
 .S_AXI_ARREADY(S_AXI_ARREADY),
 .S_AXI_RDATA(S_AXI_RDATA),
 .S_AXI_RRESP(S_AXI_RRESP),
 .S_AXI_RVALID(S_AXI_RVALID),
 .S_AXI_WREADY(S_AXI_WREADY),
 .S_AXI_BRESP(S_AXI_BRESP),
 .S_AXI_BVALID(S_AXI_BVALID),
 .S_AXI_AWREADY(S_AXI_AWREADY),
 .M_AXI_ACP_ARVALID(M_AXI_ACP_ARVALID),
 .M_AXI_ACP_ARADDR(M_AXI_ACP_ARADDR),
 .M_AXI_ACP_ARLEN(M_AXI_ACP_ARLEN),
 .M_AXI_ACP_ARSIZE(M_AXI_ACP_ARSIZE),
 .M_AXI_ACP_ARBURST(M_AXI_ACP_ARBURST),
 .M_AXI_ACP_ARPROT(M_AXI_ACP_ARPROT),
 .M_AXI_ACP_ARCACHE(M_AXI_ACP_ARCACHE),
 .M_AXI_ACP_RREADY(M_AXI_ACP_RREADY),
 .M_AXI_ACP_AWVALID(M_AXI_ACP_AWVALID),
 .M_AXI_ACP_AWADDR(M_AXI_ACP_AWADDR),
 .M_AXI_ACP_AWLEN(M_AXI_ACP_AWLEN),
 .M_AXI_ACP_AWSIZE(M_AXI_ACP_AWSIZE),
 .M_AXI_ACP_AWBURST(M_AXI_ACP_AWBURST),
 .M_AXI_ACP_AWPROT(M_AXI_ACP_AWPROT),
 .M_AXI_ACP_AWCACHE(M_AXI_ACP_AWCACHE),
 .M_AXI_ACP_WVALID(M_AXI_ACP_WVALID),
 .M_AXI_ACP_WDATA(M_AXI_ACP_WDATA),
 .M_AXI_ACP_WSTRB(M_AXI_ACP_WSTRB),
 .M_AXI_ACP_WLAST(M_AXI_ACP_WLAST),
 .M_AXI_ACP_BREADY(M_AXI_ACP_BREADY),
 .host_interrupt(host_interrupt),
 .user_r_read_32_rden(user_r_read_32_rden),
 .user_r_read_32_open(user_r_read_32_open),
 .user_w_write_32_wren(user_w_write_32_wren),
 .user_w_write_32_data(user_w_write_32_data),
 .user_w_write_32_open(user_w_write_32_open),
 .user_r_read_8_rden(user_r_read_8_rden),
 .user_r_read_8_open(user_r_read_8_open),
 .user_w_write_8_wren(user_w_write_8_wren),
 .user_w_write_8_data(user_w_write_8_data),
 .user_w_write_8_open(user_w_write_8_open),
 .user_r_mem_8_rden(user_r_mem_8_rden),
 .user_r_mem_8_open(user_r_mem_8_open),
 .user_w_mem_8_wren(user_w_mem_8_wren),
 .user_w_mem_8_data(user_w_mem_8_data),
 .user_w_mem_8_open(user_w_mem_8_open),
 .user_mem_8_addr(user_mem_8_addr),
 .user_mem_8_addr_update(user_mem_8_addr_update)
 );
 assign user_w_write_32_full=1'b0;
   fifo_8x2048 fifo_8
     (
      .clk(bus_clk),
      .srst(!user_w_write_8_open && !user_r_read_8_open),
      .din(user_w_write_8_data),
      .wr_en(user_w_write_8_wren && !receiver_config[99]),
      .rd_en(user_r_read_8_rden && !receiver_config[99]),
      .dout(loop_data),
      .full(loop_full),
      .empty(loop_empty)
      );

   assign  user_r_read_8_eof = 0;

   /*
    * PART 4
    * ======
    *
    * Example code for seekable stream
    */

   reg [239:0] ft8_shadow=240'h0ae10b50084c130e2cb28b99104cae10ba13850c341f79459959cb0ae10b;
   reg [4:0] ft8_index=0;
   (* ASYNC_REG="TRUE" *) reg ft8_ack_meta=0,ft8_ack_sync=0;
   always @(posedge bus_clk) begin
    ft8_ack_meta<=ft8_ack;ft8_ack_sync<=ft8_ack_meta;
   end
   reg [7:0] demoarray[0:31];
   reg [7:0] mem_8_data_reg;

   assign user_r_mem_8_data = mem_8_data_reg;


   // Shadow bytes are committed atomically by writing byte 2. Byte 3 is a
   // read-only protocol marker; frequencies are little-endian phase increments.
   reg [1:0] shadow_flags=0;
   reg [1:0] shadow_mode=0;
   reg [47:0] shadow_tune=48'd4398046511104;
   reg [47:0] shadow_sim=48'd4398046511104;
   always @(posedge bus_clk) begin
    if(user_w_mem_8_wren) begin
     demoarray[user_mem_8_addr]<=user_w_mem_8_data;
     case(user_mem_8_addr)
      17: ft8_index<=user_w_mem_8_data[4:0];
      18: if(ft8_index<30) ft8_shadow[ft8_index*8 +: 8]<=user_w_mem_8_data;
      19: if(ft8_ack_sync==ft8_commit) begin
       ft8_symbols<=ft8_shadow[236:0];ft8_commit<=~ft8_commit;
      end
      0: shadow_flags[0]<=user_w_mem_8_data[0];
      1: shadow_mode<=user_w_mem_8_data[1:0];
      2: begin receiver_config<={shadow_mode,shadow_sim,shadow_tune,(|shadow_mode),shadow_flags[0]};config_toggle<=~config_toggle;end
      default: begin
       if(user_mem_8_addr>=4 && user_mem_8_addr<10)
        shadow_tune[(user_mem_8_addr-4)*8 +: 8]<=user_w_mem_8_data;
       if(user_mem_8_addr>=10 && user_mem_8_addr<16)
        shadow_sim[(user_mem_8_addr-10)*8 +: 8]<=user_w_mem_8_data;
      end
     endcase
    end
    if(user_r_mem_8_rden) begin
     case(user_mem_8_addr)
      0:mem_8_data_reg<={7'b0,receiver_config[0]};
      1:mem_8_data_reg<={6'b0,receiver_config[99:98]};
      2:mem_8_data_reg<={7'b0,config_toggle};
      3:mem_8_data_reg<=8'hd3;
      17:mem_8_data_reg<={3'b0,ft8_index};
      18:mem_8_data_reg<=ft8_index<30 ? ft8_shadow[ft8_index*8 +: 8] : 8'b0;
      19:mem_8_data_reg<={6'b0,ft8_ack_sync,ft8_commit};
      20:mem_8_data_reg<=8'hf8;
      16:mem_8_data_reg<={7'b0,audio_overflow_sync};
      default:begin
       if(user_mem_8_addr>=4 && user_mem_8_addr<16)
        mem_8_data_reg<=receiver_config[2+(user_mem_8_addr-4)*8 +: 8];
       else mem_8_data_reg<=demoarray[user_mem_8_addr];
      end
     endcase
    end
   end

   assign  user_r_mem_8_empty = 0;
   assign  user_r_mem_8_eof = 0;
   assign  user_w_mem_8_full = 0;

   /*
    * PART 5
    * ======
    *
    * Example code for Xillybus Lite
    */









   reg [7:0] litearray0[0:31];
   reg [7:0] litearray1[0:31];
   reg [7:0] litearray2[0:31];
   reg [7:0] litearray3[0:31];

   assign      user_irq = 0; // No interrupts for now

   always @(posedge user_clk)
     begin
	if (user_wstrb[0])
	  litearray0[user_addr[6:2]] <= user_wr_data[7:0];

	if (user_wstrb[1])
	  litearray1[user_addr[6:2]] <= user_wr_data[15:8];

	if (user_wstrb[2])
	  litearray2[user_addr[6:2]] <= user_wr_data[23:16];

	if (user_wstrb[3])
	  litearray3[user_addr[6:2]] <= user_wr_data[31:24];

	if (user_rden)
	  user_rd_data <= { litearray3[user_addr[6:2]],
			    litearray2[user_addr[6:2]],
			    litearray1[user_addr[6:2]],
			    litearray0[user_addr[6:2]] };
     end


endmodule
