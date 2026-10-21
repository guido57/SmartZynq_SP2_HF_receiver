# The FIFO is only referenced inside the legacy VGA EDIF. Link its generated
# implementation explicitly; Vivado's project dependency scanner misses it.
set root [file normalize [file join [file dirname [info script]] ..]]
set cells [get_cells -hierarchical -filter {REF_NAME == vga_fifo && IS_BLACKBOX}]
if {[llength $cells]!=1} {error "Expected one unresolved vendor VGA FIFO, found [llength $cells]"}
read_checkpoint -cell $cells "$root/build/bd_adc_build/xillydemo.runs/vga_fifo_synth_1/vga_fifo.dcp"
puts "PASS: linked vendor VGA FIFO checkpoint into $cells"
