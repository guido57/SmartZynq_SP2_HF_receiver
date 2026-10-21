set root [file normalize [file join [file dirname [info script]] ..]]
set work "$root/build/bd_ddc_sharp"
source "$root/scripts/create_ddc_block_design.tcl"
regenerate_bd_layout -hierarchy [get_bd_cells DDC_receiver]
save_bd_design
puts "Sharp filter review project created. No synthesis or implementation."
