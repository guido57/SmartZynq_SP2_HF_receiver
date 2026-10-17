set root [file normalize [file join [file dirname [info script]] ..]]
if {[file exists "$root/build/physical_adc"]} {error "build/physical_adc exists; open its project or move it aside"}
file mkdir "$root/build"
file copy "$root/vendor/xillinux-eval-SmartZynq-SP2-1.0b" "$root/build/physical_adc"
set top "$root/build/physical_adc/verilog/src/xillydemo.v"
set f [open $top r]; set text [read $f]; close $f
set start [string first "   // 32-bit loopback" $text]
set end [string first "   assign  user_r_read_32_eof = 0;" $text $start]
if {$start < 0 || $end < 0} {error "Cannot find reference 32-bit loopback"}
set replacement {   wire virtual_clk128, physical_clk8, virtual_locked;
   reg adc_source_external = 1'b0;
   virtual_adc_clk clock_ins(.clk_in1(bus_clk),.clk_out1(virtual_clk128),.clk_out2(physical_clk8),.locked(virtual_locked));
   // J6 clock A uses an output DDR register; clock B stays inactive.
   ODDR #(.DDR_CLK_EDGE("SAME_EDGE"),.INIT(1'b0),.SRTYPE("SYNC")) adc_clock_output
      (.C(physical_clk8),.CE(1'b1),.D1(1'b1),.D2(1'b0),
       .R(!virtual_locked),.S(1'b0),.Q(J6[32]));
   assign J6[17] = 1'b0;
   wire signed [13:0] physical_adc_data = {
      J6[30],J6[31],J6[28],J6[29],J6[26],J6[27],J6[24],
      J6[25],J6[22],J6[23],J6[20],J6[21],J6[18],J6[19]};
   selectable_adc_snapshot capture_ins(.clk128(virtual_clk128),.bus_clk(bus_clk),
      .clk_adc(physical_clk8),.source_external(adc_source_external),
      .adc_data(physical_adc_data),.adc_otra(J6[33]),.active_external(),
      .locked(virtual_locked),.stream_open(user_r_read_32_open),.rden(user_r_read_32_rden),
      .data(user_r_read_32_data),.empty(user_r_read_32_empty),.eof(user_r_read_32_eof));
   // Unused write endpoint accepts and discards incoming words.
   assign user_w_write_32_full = 1'b0;

}
set text [string replace $text $start [expr {$end+[string length "   assign  user_r_read_32_eof = 0;"]-1}] $replacement]
# Offset zero of the seekable byte endpoint controls the source; other bytes
# retain their demo RAM behavior. Changes take effect on the next capture.
set text [string map [list {   // A simple inferred RAM} {
   always @(posedge bus_clk)
     if (user_w_mem_8_wren && user_mem_8_addr == 0)
       adc_source_external <= user_w_mem_8_data[0];
   // A simple inferred RAM
} {mem_8_data_reg <= demoarray[user_mem_8_addr];} {
         mem_8_data_reg <= (user_mem_8_addr == 0) ?
                           {7'b0, adc_source_external} : demoarray[user_mem_8_addr];
}] $text]
set f [open $top w]; puts -nonewline $f $text; close $f
source "$root/build/physical_adc/verilog/xillydemo-vivado.tcl"
remove_files [get_files -all *fifo_32x512.xci]
add_files -norecurse "$root/rtl/selectable_adc_snapshot.sv"
add_files -norecurse "$root/rtl/adc_external_frontend.sv"
foreach n {ft8_virtual_rf_core.sv ad9248_emulator.sv ad9248_clock_gen.sv adc_input.sv sine_lut.mem} {
 add_files -norecurse "$root/rtl/adc_simulator/$n"
}
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name virtual_adc_clk
set_property -dict [list CONFIG.PRIM_IN_FREQ {100.000} CONFIG.PRIM_SOURCE {Global_buffer} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {128.000} CONFIG.USE_RESET {false} CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {8.000}] [get_ips virtual_adc_clk]
generate_target all [get_ips virtual_adc_clk]
add_files -fileset constrs_1 "$root/constraints/physical_adc.xdc"
update_compile_order -fileset sources_1
