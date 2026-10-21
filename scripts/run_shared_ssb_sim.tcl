set root [file normalize [file join [file dirname [info script]] ..]]
set vectors "$root/build/shared_ssb_vectors"
puts [exec python3 "$root/scripts/generate_ssb_vectors.py" $vectors "$root/rtl/ddc/ssb_hilbert_8k.mem"]
create_project -force shared_ssb_sim "$root/build/shared_ssb_sim" -part xc7z020clg484-1
add_files "$root/rtl/ddc/shared_ssb_demod.sv"
add_files "$root/rtl/ddc/ssb_hilbert_8k.mem"
foreach file [glob "$vectors/*.mem"] {add_files -fileset sim_1 $file}
add_files -fileset sim_1 "$root/sim/tb_shared_ssb.sv"
set_property top tb_shared_ssb [get_filesets sim_1]
set_property xsim.simulate.runtime {0 ns} [get_filesets sim_1]
launch_simulation
run all
if {[get_value -radix unsigned /tb_shared_ssb/test_passed] ne "1"} {error "Shared FIR regression failed"}
close_sim
