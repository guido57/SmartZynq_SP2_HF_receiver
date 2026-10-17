set root [file normalize [file join [file dirname [info script]] ..]]
if {[file exists "$root/build/reference"]} {error "build/reference already exists; move it aside before a fresh build"}
file mkdir "$root/build"
file copy -force "$root/vendor/xillinux-eval-SmartZynq-SP2-1.0b" "$root/build/reference"
source "$root/build/reference/verilog/xillydemo-vivado.tcl"
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Synthesis failed"}
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
puts "BITSTREAM: $root/build/reference/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit"
