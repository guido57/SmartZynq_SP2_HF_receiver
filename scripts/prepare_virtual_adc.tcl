set root [file normalize [file join [file dirname [info script]] ..]]
if {[file exists "$root/build/virtual_adc"]} {error "build/virtual_adc exists; open its project or move it aside"}
file mkdir "$root/build"
file copy "$root/vendor/xillinux-eval-SmartZynq-SP2-1.0b" "$root/build/virtual_adc"
set top "$root/build/virtual_adc/verilog/src/xillydemo.v"
set f [open $top r]; set text [read $f]; close $f
set start [string first "   // 32-bit loopback" $text]
set end [string first "   assign  user_r_read_32_eof = 0;" $text $start]
if {$start < 0 || $end < 0} {error "Cannot find reference 32-bit loopback"}
set replacement {   wire virtual_clk128, virtual_locked;
   virtual_adc_clk clock_ins(.clk_in1(bus_clk),.clk_out1(virtual_clk128),.locked(virtual_locked));
   virtual_adc_snapshot capture_ins(.clk128(virtual_clk128),.bus_clk(bus_clk),
      .locked(virtual_locked),.stream_open(user_r_read_32_open),.rden(user_r_read_32_rden),
      .data(user_r_read_32_data),.empty(user_r_read_32_empty),.eof(user_r_read_32_eof));
   // Unused write endpoint accepts and discards incoming words.
   assign user_w_write_32_full = 1'b0;

}
set text [string replace $text $start [expr {$end+[string length "   assign  user_r_read_32_eof = 0;"]-1}] $replacement]
set f [open $top w]; puts -nonewline $f $text; close $f
source "$root/build/virtual_adc/verilog/xillydemo-vivado.tcl"
remove_files [get_files -all *fifo_32x512.xci]
add_files -norecurse "$root/rtl/virtual_adc_snapshot.sv"
foreach n {ft8_virtual_rf_core.sv ad9248_emulator.sv ad9248_clock_gen.sv adc_input.sv sine_lut.mem} {
 add_files -norecurse "$root/rtl/adc_simulator/$n"
}
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name virtual_adc_clk
set_property -dict [list CONFIG.PRIM_IN_FREQ {100.000} CONFIG.PRIM_SOURCE {Global_buffer} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {128.000} CONFIG.USE_RESET {false}] [get_ips virtual_adc_clk]
generate_target all [get_ips virtual_adc_clk]
add_files -fileset constrs_1 "$root/constraints/virtual_adc_cdc.xdc"
update_compile_order -fileset sources_1
