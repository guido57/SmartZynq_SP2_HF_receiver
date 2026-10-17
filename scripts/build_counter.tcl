source [file join [file dirname [info script]] prepare_counter.tcl]
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Synthesis failed"}
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
puts "Counter bitstream: $root/build/counter/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit"
