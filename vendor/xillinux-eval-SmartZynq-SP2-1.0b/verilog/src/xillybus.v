`timescale 1ns / 10ps

module xillybus(GPIO_LED, quiesce, bus_clk, bus_rst_n, S_AXI_AWADDR,
  S_AXI_AWVALID, S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WVALID, S_AXI_BREADY,
  S_AXI_ARADDR, S_AXI_ARVALID, S_AXI_RREADY, S_AXI_ARREADY, S_AXI_RDATA,
  S_AXI_RRESP, S_AXI_RVALID, S_AXI_WREADY, S_AXI_BRESP, S_AXI_BVALID,
  S_AXI_AWREADY, M_AXI_ACP_ARREADY, M_AXI_ACP_ARVALID, M_AXI_ACP_ARADDR,
  M_AXI_ACP_ARLEN, M_AXI_ACP_ARSIZE, M_AXI_ACP_ARBURST, M_AXI_ACP_ARPROT,
  M_AXI_ACP_ARCACHE, M_AXI_ACP_RREADY, M_AXI_ACP_RVALID, M_AXI_ACP_RDATA,
  M_AXI_ACP_RRESP, M_AXI_ACP_RLAST, M_AXI_ACP_AWREADY, M_AXI_ACP_AWVALID,
  M_AXI_ACP_AWADDR, M_AXI_ACP_AWLEN, M_AXI_ACP_AWSIZE, M_AXI_ACP_AWBURST,
  M_AXI_ACP_AWPROT, M_AXI_ACP_AWCACHE, M_AXI_ACP_WREADY, M_AXI_ACP_WVALID,
  M_AXI_ACP_WDATA, M_AXI_ACP_WSTRB, M_AXI_ACP_WLAST, M_AXI_ACP_BREADY,
  M_AXI_ACP_BVALID, M_AXI_ACP_BRESP, host_interrupt, user_r_read_32_rden,
  user_r_read_32_data, user_r_read_32_empty, user_r_read_32_eof,
  user_r_read_32_open, user_w_write_32_wren, user_w_write_32_data,
  user_w_write_32_full, user_w_write_32_open, user_r_read_8_rden,
  user_r_read_8_data, user_r_read_8_empty, user_r_read_8_eof,
  user_r_read_8_open, user_w_write_8_wren, user_w_write_8_data,
  user_w_write_8_full, user_w_write_8_open, user_r_mem_8_rden,
  user_r_mem_8_data, user_r_mem_8_empty, user_r_mem_8_eof, user_r_mem_8_open,
  user_w_mem_8_wren, user_w_mem_8_data, user_w_mem_8_full, user_w_mem_8_open,
  user_mem_8_addr, user_mem_8_addr_update);

  input  bus_clk;
  input  bus_rst_n;
  input [31:0] S_AXI_AWADDR;
  input  S_AXI_AWVALID;
  input [31:0] S_AXI_WDATA;
  input [3:0] S_AXI_WSTRB;
  input  S_AXI_WVALID;
  input  S_AXI_BREADY;
  input [31:0] S_AXI_ARADDR;
  input  S_AXI_ARVALID;
  input  S_AXI_RREADY;
  input  M_AXI_ACP_ARREADY;
  input  M_AXI_ACP_RVALID;
  input [63:0] M_AXI_ACP_RDATA;
  input [1:0] M_AXI_ACP_RRESP;
  input  M_AXI_ACP_RLAST;
  input  M_AXI_ACP_AWREADY;
  input  M_AXI_ACP_WREADY;
  input  M_AXI_ACP_BVALID;
  input [1:0] M_AXI_ACP_BRESP;
  input [31:0] user_r_read_32_data;
  input  user_r_read_32_empty;
  input  user_r_read_32_eof;
  input  user_w_write_32_full;
  input [7:0] user_r_read_8_data;
  input  user_r_read_8_empty;
  input  user_r_read_8_eof;
  input  user_w_write_8_full;
  input [7:0] user_r_mem_8_data;
  input  user_r_mem_8_empty;
  input  user_r_mem_8_eof;
  input  user_w_mem_8_full;
  output [3:0] GPIO_LED;
  output  quiesce;
  output  S_AXI_ARREADY;
  output [31:0] S_AXI_RDATA;
  output [1:0] S_AXI_RRESP;
  output  S_AXI_RVALID;
  output  S_AXI_WREADY;
  output [1:0] S_AXI_BRESP;
  output  S_AXI_BVALID;
  output  S_AXI_AWREADY;
  output  M_AXI_ACP_ARVALID;
  output [31:0] M_AXI_ACP_ARADDR;
  output [3:0] M_AXI_ACP_ARLEN;
  output [2:0] M_AXI_ACP_ARSIZE;
  output [1:0] M_AXI_ACP_ARBURST;
  output [2:0] M_AXI_ACP_ARPROT;
  output [3:0] M_AXI_ACP_ARCACHE;
  output  M_AXI_ACP_RREADY;
  output  M_AXI_ACP_AWVALID;
  output [31:0] M_AXI_ACP_AWADDR;
  output [3:0] M_AXI_ACP_AWLEN;
  output [2:0] M_AXI_ACP_AWSIZE;
  output [1:0] M_AXI_ACP_AWBURST;
  output [2:0] M_AXI_ACP_AWPROT;
  output [3:0] M_AXI_ACP_AWCACHE;
  output  M_AXI_ACP_WVALID;
  output [63:0] M_AXI_ACP_WDATA;
  output [7:0] M_AXI_ACP_WSTRB;
  output  M_AXI_ACP_WLAST;
  output  M_AXI_ACP_BREADY;
  output  host_interrupt;
  output  user_r_read_32_rden;
  output  user_r_read_32_open;
  output  user_w_write_32_wren;
  output [31:0] user_w_write_32_data;
  output  user_w_write_32_open;
  output  user_r_read_8_rden;
  output  user_r_read_8_open;
  output  user_w_write_8_wren;
  output [7:0] user_w_write_8_data;
  output  user_w_write_8_open;
  output  user_r_mem_8_rden;
  output  user_r_mem_8_open;
  output  user_w_mem_8_wren;
  output [7:0] user_w_mem_8_data;
  output  user_w_mem_8_open;
  output [4:0] user_mem_8_addr;
  output  user_mem_8_addr_update;

  xillybus_core  xillybus_core_ins(.S_AXI_WVALID_w(S_AXI_WVALID),
    .S_AXI_BREADY_w(S_AXI_BREADY), .S_AXI_ARADDR_w(S_AXI_ARADDR),
    .S_AXI_ARVALID_w(S_AXI_ARVALID), .S_AXI_RREADY_w(S_AXI_RREADY),
    .S_AXI_ARREADY_w(S_AXI_ARREADY), .S_AXI_RDATA_w(S_AXI_RDATA),
    .S_AXI_RRESP_w(S_AXI_RRESP), .S_AXI_RVALID_w(S_AXI_RVALID),
    .S_AXI_WREADY_w(S_AXI_WREADY), .GPIO_LED_w(GPIO_LED),
    .S_AXI_BRESP_w(S_AXI_BRESP), .S_AXI_BVALID_w(S_AXI_BVALID),
    .S_AXI_AWREADY_w(S_AXI_AWREADY), .M_AXI_ACP_ARREADY_w(M_AXI_ACP_ARREADY),
    .M_AXI_ACP_ARVALID_w(M_AXI_ACP_ARVALID), .M_AXI_ACP_ARADDR_w(M_AXI_ACP_ARADDR),
    .M_AXI_ACP_ARLEN_w(M_AXI_ACP_ARLEN), .M_AXI_ACP_ARSIZE_w(M_AXI_ACP_ARSIZE),
    .M_AXI_ACP_ARBURST_w(M_AXI_ACP_ARBURST), .M_AXI_ACP_ARPROT_w(M_AXI_ACP_ARPROT),
    .quiesce_w(quiesce), .M_AXI_ACP_ARCACHE_w(M_AXI_ACP_ARCACHE),
    .M_AXI_ACP_RREADY_w(M_AXI_ACP_RREADY), .M_AXI_ACP_RVALID_w(M_AXI_ACP_RVALID),
    .M_AXI_ACP_RDATA_w(M_AXI_ACP_RDATA), .M_AXI_ACP_RRESP_w(M_AXI_ACP_RRESP),
    .M_AXI_ACP_RLAST_w(M_AXI_ACP_RLAST), .M_AXI_ACP_AWREADY_w(M_AXI_ACP_AWREADY),
    .M_AXI_ACP_AWVALID_w(M_AXI_ACP_AWVALID), .M_AXI_ACP_AWADDR_w(M_AXI_ACP_AWADDR),
    .M_AXI_ACP_AWLEN_w(M_AXI_ACP_AWLEN), .bus_clk_w(bus_clk),
    .M_AXI_ACP_AWSIZE_w(M_AXI_ACP_AWSIZE), .M_AXI_ACP_AWBURST_w(M_AXI_ACP_AWBURST),
    .M_AXI_ACP_AWPROT_w(M_AXI_ACP_AWPROT), .M_AXI_ACP_AWCACHE_w(M_AXI_ACP_AWCACHE),
    .M_AXI_ACP_WREADY_w(M_AXI_ACP_WREADY), .M_AXI_ACP_WVALID_w(M_AXI_ACP_WVALID),
    .M_AXI_ACP_WDATA_w(M_AXI_ACP_WDATA), .M_AXI_ACP_WSTRB_w(M_AXI_ACP_WSTRB),
    .M_AXI_ACP_WLAST_w(M_AXI_ACP_WLAST), .M_AXI_ACP_BREADY_w(M_AXI_ACP_BREADY),
    .bus_rst_n_w(bus_rst_n), .M_AXI_ACP_BVALID_w(M_AXI_ACP_BVALID),
    .user_r_read_32_rden_w(user_r_read_32_rden), .user_r_read_32_data_w(user_r_read_32_data),
    .user_r_read_32_empty_w(user_r_read_32_empty),
    .user_r_read_32_eof_w(user_r_read_32_eof), .user_r_read_32_open_w(user_r_read_32_open),
    .M_AXI_ACP_BRESP_w(M_AXI_ACP_BRESP), .host_interrupt_w(host_interrupt),
    .user_w_write_32_wren_w(user_w_write_32_wren),
    .user_w_write_32_data_w(user_w_write_32_data),
    .user_w_write_32_full_w(user_w_write_32_full),
    .user_w_write_32_open_w(user_w_write_32_open),
    .S_AXI_AWADDR_w(S_AXI_AWADDR), .user_r_read_8_rden_w(user_r_read_8_rden),
    .user_r_read_8_data_w(user_r_read_8_data), .user_r_read_8_empty_w(user_r_read_8_empty),
    .user_r_read_8_eof_w(user_r_read_8_eof), .user_r_read_8_open_w(user_r_read_8_open),
    .user_w_write_8_wren_w(user_w_write_8_wren), .user_w_write_8_data_w(user_w_write_8_data),
    .user_w_write_8_full_w(user_w_write_8_full), .user_w_write_8_open_w(user_w_write_8_open),
    .S_AXI_AWVALID_w(S_AXI_AWVALID), .user_r_mem_8_rden_w(user_r_mem_8_rden),
    .user_r_mem_8_data_w(user_r_mem_8_data), .user_r_mem_8_empty_w(user_r_mem_8_empty),
    .user_r_mem_8_eof_w(user_r_mem_8_eof), .user_r_mem_8_open_w(user_r_mem_8_open),
    .S_AXI_WDATA_w(S_AXI_WDATA), .user_w_mem_8_wren_w(user_w_mem_8_wren),
    .user_w_mem_8_data_w(user_w_mem_8_data), .user_w_mem_8_full_w(user_w_mem_8_full),
    .user_w_mem_8_open_w(user_w_mem_8_open), .user_mem_8_addr_w(user_mem_8_addr),
    .user_mem_8_addr_update_w(user_mem_8_addr_update),
    .S_AXI_WSTRB_w(S_AXI_WSTRB));

endmodule
