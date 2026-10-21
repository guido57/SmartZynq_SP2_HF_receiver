# Build a self-contained snapshot, allowing the reviewed diagram to stay open.
set root [file normalize [file join [file dirname [info script]] ..]]
set reviewed "$root/build/bd_ddc_sharp/verilog/vivado/xillydemo.xpr"
set work "$root/build/bd_ddc_sharp_build"
if {[file exists $work]} {error "build/bd_ddc_sharp_build already exists; reopen it rather than overwrite a build"}
open_project -read_only $reviewed
save_project_as -exclude_run_results xillydemo $work
close_project
open_project "$work/xillydemo.xpr"
# Import remote source files into this snapshot before generating IP outputs.
import_files -norecurse [get_files -of_objects [get_filesets sources_1] -filter {IS_GENERATED == 0}]
# Reload imported BD metadata before regenerating nested module references.
close_project
open_project "$work/xillydemo.xpr"
set_property source_mgmt_mode All [current_project]
add_files -fileset constrs_1 "$root/constraints/bd_ddc.xdc"
set bd [get_files *vivado_system.bd]
open_bd_design $bd
validate_bd_design
save_bd_design
# The board top instantiates vivado_system directly; generation supplies its HDL.
# Refresh module references after importing their RTL into the snapshot.
# Vivado otherwise misses generation for module cells nested in a hierarchy.
set module_refs [get_ips -filter {IPDEF =~ xilinx.com:module_ref:*}]
if {[llength $module_refs]==0} {error "No module-reference IP objects found"}
update_module_reference $module_refs
validate_bd_design
save_bd_design
reset_target all $bd
generate_target all $bd
set module_wrappers [get_files -all -quiet *vivado_system_ADC_source_switch_0.sv]
if {[llength $module_wrappers]==0} {error "Missing generated ADC source module wrapper"}
# The VGA FIFO is instantiated inside a vendor EDIF netlist, so explicitly
# synthesize its IP; dependency discovery through a module reference misses it.
set vga [get_ips vga_fifo]
if {[get_property IS_LOCKED $vga]} {upgrade_ip $vga}
set vga_xci [get_files -all -filter {NAME =~ *vga_fifo.xci}]
set_property GENERATE_SYNTH_CHECKPOINT true $vga_xci
generate_target all $vga_xci
create_ip_run $vga_xci
launch_runs vga_fifo_synth_1 -jobs 2
wait_on_run vga_fifo_synth_1
if {[get_property PROGRESS [get_runs vga_fifo_synth_1]] ne "100%"} {error "VGA FIFO synthesis failed"}
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Synthesis failed"}
open_run synth_1
source "$root/scripts/check_bd_ddc_constraints.tcl"
set_property STEPS.OPT_DESIGN.TCL.PRE "$root/scripts/link_sharp_ddc_vga_fifo.tcl" [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
open_run impl_1
source "$root/scripts/check_bd_ddc_constraints.tcl"
report_utilization -file "$root/build/bd_ddc_sharp_utilization.rpt"
report_utilization -hierarchical -hierarchical_depth 8 -file "$root/build/bd_ddc_sharp_hierarchy.rpt"
report_timing_summary -file "$root/build/bd_ddc_sharp_timing.rpt"
report_cdc -file "$root/build/bd_ddc_sharp_cdc.rpt"
report_drc -file "$root/build/bd_ddc_sharp_drc.rpt"
report_io -file "$root/build/bd_ddc_sharp_io.rpt"
set setup [get_timing_paths -delay_type max -max_paths 1]
set hold [get_timing_paths -delay_type min -max_paths 1]
if {[get_property SLACK $setup]<0 || [get_property SLACK $hold]<0} {error "Timing violations: do not deploy this build"}
set bitfile [file join [get_property DIRECTORY [get_runs impl_1]] xillydemo.bit]
file copy -force $bitfile "$root/build/bd_ddc_sharp.bit"
puts [exec python3 "$root/scripts/shorten_bit_header.py" $bitfile "$root/build/bd_ddc_sharp-legacy.bit"]
puts "READY: $root/build/bd_ddc_sharp.bit (JTAG), $root/build/bd_ddc_sharp-legacy.bit (SD)"
