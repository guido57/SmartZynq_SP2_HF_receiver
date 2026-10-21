# One-command GUI entry point, using the current receiver project if open.
set root [file normalize [file join [file dirname [info script]] ..]]
if {[current_project -quiet] eq ""} {open_project "$root/build/bd_ddc_build/xillydemo.xpr"}
source "$root/scripts/setup_ddc_simulation.tcl"
launch_simulation -simset sim_1 -mode behavioral
source "$root/scripts/ddc_receiver_waves.tcl"
run all
if {[get_value -radix unsigned /tb_ddc_receiver/test_passed] ne "1"} {error "DDC receiver testbench failed; inspect simulator messages"}
file mkdir "$root/build"
save_wave_config "$root/build/ddc_receiver.wcfg"
if {[llength [get_files -quiet "$root/build/ddc_receiver.wcfg"]]==0} {add_files -fileset sim_1 -norecurse "$root/build/ddc_receiver.wcfg"}
puts "PASS: receiver simulation complete. Waveform stays open; DDC output is under tb_ddc_receiver/dut."
