set root [file normalize [file join [file dirname [info script]] ..]]
create_project -force bd_adc_sim "$root/build/bd_adc_sim" -part xc7z020clg484-1
add_files [list "$root/rtl/selectable_adc_snapshot.sv" "$root/rtl/adc_external_frontend.sv"]
foreach f {ft8_simulator_bd.sv external_adc_bd.sv adc_switch_capture_bd.sv} {add_files "$root/rtl/bd/$f"}
foreach f {ft8_virtual_rf_core.sv ad9248_emulator.sv ad9248_clock_gen.sv adc_input.sv sine_lut.mem} {add_files "$root/rtl/adc_simulator/$f"}
add_files -fileset sim_1 "$root/sim/tb_bd_adc_equivalence.sv"
set_property top tb_bd_adc_equivalence [get_filesets sim_1]
launch_simulation
run all
close_sim
