set root [file normalize [file join [file dirname [info script]] ..]]
set project "$root/build/physical_adc/verilog/vivado/xillydemo.xpr"
if {[file exists $project]} {
 # Keep a copy of the previous images before rebuilding this project.
 set backup "$root/build/physical_adc_previous"
 file mkdir $backup
 foreach item [list "$root/build/physical_adc-legacy.bit" "$root/build/physical_adc/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit"] {
  if {[file exists $item]} {file copy -force $item $backup}
 }
 open_project $project
 reset_run synth_1
} else {
 source [file join [file dirname [info script]] prepare_physical_adc.tcl]
}
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Synthesis failed"}
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
puts "Selectable ADC bitstream: $root/build/physical_adc/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit"

set bitfile "$root/build/physical_adc/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit"
exec python3 "$root/scripts/shorten_bit_header.py" $bitfile "$root/build/physical_adc-legacy.bit"
open_run impl_1
report_timing_summary -file "$root/build/physical_adc_timing.rpt"
report_cdc -file "$root/build/physical_adc_cdc.rpt"
report_drc -file "$root/build/physical_adc_drc.rpt"
