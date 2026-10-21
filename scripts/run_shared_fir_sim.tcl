set root [file normalize [file join [file dirname [info script]] ..]]
set vectors "$root/build/shared_fir_vectors"
puts [exec python3 "$root/scripts/generate_fir_vectors.py" $vectors "$root/rtl/ddc/ddc_fir_sharp_64k.mem"]
create_project -force shared_fir_sim "$root/build/shared_fir_sim" -part xc7z020clg484-1
add_files "$root/rtl/ddc/shared_fir_decimator.sv"
add_files "$root/rtl/ddc/ddc_fir_sharp_64k.mem"
foreach file [glob "$vectors/*.mem"] {add_files -fileset sim_1 $file}
add_files -fileset sim_1 "$root/sim/tb_shared_fir.sv"
set_property top tb_shared_fir [get_filesets sim_1]
set_property xsim.simulate.runtime {0 ns} [get_filesets sim_1]
launch_simulation
run all
if {[get_value -radix unsigned /tb_shared_fir/test_passed] ne "1"} {error "Shared FIR regression failed"}
close_sim
