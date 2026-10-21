set root [file normalize [file join [file dirname [info script]] ../../..]]
set project "$root/vivado/projects/hf_ssb_receiver/project/verilog/vivado/xillydemo.xpr"
set work "$root/vivado/projects/hf_ssb_receiver/project/verilog/vivado"
open_project $project
add_files -fileset constrs_1 "$root/constraints/bd_ddc.xdc"
add_files -fileset constrs_1 "$root/constraints/ssb.xdc"
update_compile_order -fileset sources_1
if {[llength [get_runs impl_1]] && [get_property STATUS [get_runs impl_1]] ne "Not started"} {reset_run impl_1}
if {[llength [get_runs vga_fifo_synth_1]] && [get_property STATUS [get_runs vga_fifo_synth_1]] ne "Not started"} {reset_run vga_fifo_synth_1}
set vga [get_ips vga_fifo]
if {[get_property IS_LOCKED $vga]} {upgrade_ip $vga}
set vga_xci [get_files -all -filter {NAME =~ *vga_fifo.xci}]
set_property GENERATE_SYNTH_CHECKPOINT true $vga_xci
generate_target all $vga_xci
create_ip_run $vga_xci
launch_runs vga_fifo_synth_1 -jobs 2
wait_on_run vga_fifo_synth_1
if {[get_property PROGRESS [get_runs vga_fifo_synth_1]] ne "100%"} {error "VGA FIFO synthesis failed"}
set_property STEPS.OPT_DESIGN.TCL.PRE "$root/vivado/projects/hf_ssb_receiver/link_vga_fifo.tcl" [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
puts "BITSTREAM: [get_property DIRECTORY [get_runs impl_1]]/xillydemo.bit"
