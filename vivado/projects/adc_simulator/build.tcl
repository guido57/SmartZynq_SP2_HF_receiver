set root [file normalize [file join [file dirname [info script]] ../../..]]
open_project "$root/vivado/projects/adc_simulator/project/verilog/vivado/xillydemo.xpr"
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
puts "BITSTREAM: [get_property DIRECTORY [get_runs impl_1]]/xillydemo.bit"
