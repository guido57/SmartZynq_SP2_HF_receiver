set root [file normalize [file join [file dirname [info script]] ..]]
file mkdir "$root/build/counter_sim"
create_project -force counter_sim "$root/build/counter_sim" -part xc7z020clg484-1
add_files "$root/rtl/counter_stream.v"
add_files -fileset sim_1 "$root/sim/tb_counter.v"
set_property top tb_counter [get_filesets sim_1]
launch_simulation
run all
close_sim
