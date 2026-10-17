set root [file normalize [file join [file dirname [info script]] ..]]
if {[file exists "$root/build/counter"]} {error "build/counter exists; open its project or move it aside"}
file mkdir "$root/build"
file copy "$root/vendor/xillinux-eval-SmartZynq-SP2-1.0b" "$root/build/counter"
set top "$root/build/counter/verilog/src/xillydemo.v"
set f [open $top r]; set text [read $f]; close $f
set start [string first "   // 32-bit loopback" $text]
set end [string first "   assign  user_r_read_32_eof = 0;" $text $start]
if {$start < 0 || $end < 0} {error "Cannot find reference 32-bit loopback"}
set replacement {   // PL-generated counter replaces the 32-bit FIFO loopback.
   counter_stream counter_ins (
       .clk(bus_clk), .stream_open(user_r_read_32_open),
       .rden(user_r_read_32_rden), .empty(user_r_read_32_empty),
       .data(user_r_read_32_data)
   );
   // The 32-bit write endpoint is unused; reject writes with backpressure.
   assign user_w_write_32_full = 1'b1;

}
set text [string replace $text $start [expr {$end-1}] $replacement]
set f [open $top w]; puts -nonewline $f $text; close $f
source "$root/build/counter/verilog/xillydemo-vivado.tcl"
remove_files [get_files -all *fifo_32x512.xci]
add_files -norecurse "$root/rtl/counter_stream.v"
update_compile_order -fileset sources_1
