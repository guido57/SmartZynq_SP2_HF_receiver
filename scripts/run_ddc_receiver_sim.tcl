set root [file normalize [file join [file dirname [info script]] ..]]
create_project -force ddc_receiver_sim "$root/build/ddc_receiver_sim" -part xc7z020clg484-1
set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY XPM_FIFO} [current_project]
set_property verilog_define {DDC_PHASE_INCREMENT_INPUT} [get_filesets sources_1]
set_property verilog_define {DDC_PHASE_INCREMENT_INPUT} [get_filesets sim_1]
foreach f {ddc_receiver_bd.sv adc_source_control_bd.sv adc_snapshot_bd.sv ddc_core_bd.sv external_adc64_bd.sv tunable_simulator_bd.sv} {add_files "$root/rtl/bd/$f"}
foreach f {ddc_64m_to_8k.sv ddc_64m_to_64k.sv shared_fir_decimator.sv ddc_fir_sharp_64k.mem ddc_fir_64k.mem ft8_virtual_rf_tunable.sv} {add_files "$root/rtl/ddc/$f"}
foreach f {ad9248_emulator.sv ad9248_clock_gen.sv adc_input.sv sine_lut.mem} {add_files "$root/rtl/adc_simulator/$f"}
add_files -fileset sim_1 "$root/sim/tb_ddc_receiver.sv"
add_files -fileset sim_1 "$root/sim/reference_ddc.sv"
set_property top tb_ddc_receiver [get_filesets sim_1]
set_property xsim.simulate.runtime {0 ns} [get_filesets sim_1]
launch_simulation
run all
if {[get_value -radix unsigned /tb_ddc_receiver/test_passed] ne "1"} {error "DDC receiver regression failed"}
close_sim
