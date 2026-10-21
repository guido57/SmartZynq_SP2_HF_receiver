set root [file normalize [file join [file dirname [info script]] ../../..]]
set cells [get_cells -hierarchical -filter {REF_NAME == vga_fifo && IS_BLACKBOX}]
if {[llength $cells] == 0} {puts "PASS: vendor VGA FIFO checkpoint already linked"; return}
if {[llength $cells] != 1} {error "Expected one unresolved vendor VGA FIFO, found [llength $cells]"}
set dcp "$root/vivado/projects/hf_ssb_receiver/project/verilog/vivado/xillydemo.runs/vga_fifo_synth_1/vga_fifo.dcp"
read_checkpoint -cell $cells $dcp
puts "PASS: linked vendor VGA FIFO checkpoint into $cells"
