# New review project; preserve the working implementation and bitstreams.
set root [file normalize [file join [file dirname [info script]] ..]]
set work "$root/build/bd_ddc_split_review"
source "$root/scripts/create_ddc_block_design.tcl"
regenerate_bd_layout -hierarchy [get_bd_cells DDC_receiver]
save_bd_design
puts "Open DDC_receiver to see ADC_source_switch, DDC, and Snapshot_buffer."
