# Read the working routed checkpoint; no synthesis or implementation.
set root [file normalize [file join [file dirname [info script]] ..]]
set output "$root/build/resource_measurement"
file mkdir $output
open_checkpoint "$root/build/bd_ddc_build/xillydemo.runs/impl_1/xillydemo_routed.dcp"
report_utilization -file "$output/total.rpt"
report_utilization -hierarchical -hierarchical_depth 8 -file "$output/hierarchy.rpt"
report_timing_summary -file "$output/timing.rpt"
