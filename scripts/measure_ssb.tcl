# Out-of-context synthesis/placement to measure the real eight-channel engine.
set root [file normalize [file join [file dirname [info script]] ..]]
set output "$root/build/ssb_resources"
file mkdir $output
create_project -in_memory -part xc7z020clg484-1
add_files "$root/rtl/ddc/shared_ssb_demod.sv"
add_files "$root/rtl/ddc/ssb_hilbert_8k.mem"
add_files "$root/sim/shared_ssb_timing_top.sv"
synth_design -top shared_ssb_timing_top -part xc7z020clg484-1 -mode out_of_context
create_clock -name clk128 -period 7.8125 [get_ports clk]
# Cut only external harness pin paths. All filter-to-boundary and internal
# register paths retain the actual 128 MHz setup and hold requirements.
set_false_path -from [get_ports {in_valid in_channel[*] in_i[*] in_q[*]}]
set_false_path -to [get_ports {out_valid out_channel[*] usb_audio[*] lsb_audio[*] overrun}]
report_utilization -cells [get_cells filter] -file "$output/utilization_synth.rpt"
opt_design
place_design
phys_opt_design
route_design
report_utilization -cells [get_cells filter] -file "$output/utilization_routed.rpt"
report_timing_summary -file "$output/timing_routed.rpt"
write_checkpoint -force "$output/shared_ssb_routed.dcp"
set setup [get_timing_paths -delay_type max -max_paths 1]
set hold [get_timing_paths -delay_type min -max_paths 1]
if {[get_property SLACK $setup]<0 || [get_property SLACK $hold]<0} {error "Shared FIR failed 128 MHz timing"}
puts "PASS: shared eight-channel FIR meets 128 MHz out-of-context timing"
