set root [file normalize [file join [file dirname [info script]] ..]]
create_project -force ssb_receiver_sim "$root/build/ssb_receiver_sim" -part xc7z020clg484-1
set_property verilog_define {DDC_PHASE_INCREMENT_INPUT} [get_filesets sources_1]
set_property verilog_define {DDC_PHASE_INCREMENT_INPUT} [get_filesets sim_1]
foreach f {ssb_receiver_bd.sv adc_source_control_ssb_bd.sv ssb_snapshot_bd.sv ddc_core_bd.sv ssb_demod_bd.sv} {add_files "$root/rtl/bd/$f"}
foreach f {ddc_64m_to_8k.sv ddc_64m_to_64k.sv shared_fir_decimator.sv ddc_fir_sharp_64k.mem shared_ssb_demod.sv ssb_hilbert_8k.mem} {add_files "$root/rtl/ddc/$f"}
add_files "$root/rtl/adc_simulator/sine_lut.mem"
add_files -fileset sim_1 "$root/sim/tb_ssb_receiver.sv"
set_property top tb_ssb_receiver [get_filesets sim_1]
set_property xsim.simulate.runtime {0 ns} [get_filesets sim_1]
launch_simulation
run all
if {[get_value -radix unsigned /tb_ssb_receiver/test_passed] ne "1"} {error "RF SSB regression failed"}
close_sim
