set root [file normalize [file join [file dirname [info script]] ..]]
create_project -force ssb_audio_stream_sim "$root/build/ssb_audio_stream_sim" -part xc7z020clg484-1
set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY XPM_FIFO} [current_project]
add_files "$root/rtl/bd/ssb_audio_stream_bd.sv"
add_files -fileset sim_1 "$root/sim/tb_ssb_audio_stream.sv"
set_property top tb_ssb_audio_stream [get_filesets sim_1]
set_property xsim.simulate.runtime {0 ns} [get_filesets sim_1]
launch_simulation
run all
if {[get_value -radix unsigned /tb_ssb_audio_stream/test_passed] ne "1"} {error "Continuous audio transport test failed"}
close_sim
