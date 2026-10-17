set root [file normalize [file join [file dirname [info script]] ..]]
create_project -force virtual_adc_sim "$root/build/virtual_adc_sim" -part xc7z020clg484-1
add_files "$root/rtl/virtual_adc_snapshot.sv"
foreach n {ft8_virtual_rf_core.sv ad9248_emulator.sv ad9248_clock_gen.sv adc_input.sv sine_lut.mem} {add_files "$root/rtl/adc_simulator/$n"}
add_files -fileset sim_1 "$root/sim/tb_virtual_adc.sv"
set_property top tb_virtual_adc [get_filesets sim_1]
launch_simulation
run all
close_sim
