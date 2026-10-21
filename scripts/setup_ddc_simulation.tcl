# Source in the open bd_ddc_build project. Only simulation settings are changed.
set root [file normalize [file join [file dirname [info script]] ..]]
if {[current_project -quiet] eq ""} {error "Open build/bd_ddc_build/xillydemo.xpr first"}
if {[llength [get_files -all -quiet *ddc_receiver_bd.sv]]==0} {error "The current project has no ddc_receiver_bd source"}
foreach name {tb_ddc_receiver.sv reference_ddc.sv} {
 set path "$root/sim/$name"
 if {[llength [get_files -quiet $path]]==0} {add_files -fileset sim_1 -norecurse $path}
}
foreach name {adc_source_control_bd.sv adc_snapshot_bd.sv ddc_core_bd.sv} {
 set path "$root/rtl/bd/$name"
 if {[llength [get_files -all -quiet *$name]]==0} {add_files -norecurse $path}
}
foreach name {ddc_64m_to_64k.sv shared_fir_decimator.sv ddc_fir_sharp_64k.mem} {
 set path "$root/rtl/ddc/$name"
 if {[llength [get_files -all -quiet *$name]]==0} {add_files -norecurse $path}
}
set sim [get_filesets sim_1]
set defines [get_property verilog_define $sim]
if {[lsearch -exact $defines DDC_PHASE_INCREMENT_INPUT]<0} {lappend defines DDC_PHASE_INCREMENT_INPUT}
set_property verilog_define $defines $sim
set_property top tb_ddc_receiver $sim
set_property top_auto_set false $sim
set_property xsim.simulate.runtime {0 ns} $sim
update_compile_order -fileset sim_1
puts "Simulation top: tb_ddc_receiver (dut is the same receiver RTL, with a 32-pair test snapshot)"
puts "Synthesis top and hardware sources are unchanged."
