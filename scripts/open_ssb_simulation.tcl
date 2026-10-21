set root [file normalize [file join [file dirname [info script]] ..]]
set target "$root/build/bd_ssb/verilog/vivado/xillydemo.xpr"
if {[current_project -quiet] eq ""} {open_project $target}
if {[file normalize [get_property DIRECTORY [current_project]]] ne [file dirname $target]} {error "Open $target first"}
set path "$root/sim/tb_ssb_receiver.sv"
if {[llength [get_files -quiet $path]]==0} {add_files -fileset sim_1 $path}
set_property verilog_define {DDC_PHASE_INCREMENT_INPUT} [get_filesets sim_1]
set_property top tb_ssb_receiver [get_filesets sim_1]
set_property top_auto_set false [get_filesets sim_1]
set_property xsim.simulate.runtime {0 ns} [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral
create_wave_config
foreach name {ddc_i ddc_q usb_audio lsb_audio} {
 set w [add_wave -radix dec /tb_ssb_receiver/dut/$name]
 set_property HEIGHT 70 $w
}
foreach name {ddc_valid audio_valid audio_enable lsb_mode} {add_wave /tb_ssb_receiver/dut/$name}
foreach name {stream_open rden empty eof data test_passed} {add_wave /tb_ssb_receiver/$name}
run all
if {[get_value -radix unsigned /tb_ssb_receiver/test_passed] ne "1"} {error "SSB simulation failed"}
save_wave_config "$root/build/ssb_receiver.wcfg"
puts "PASS: USB/LSB receiver; select audio and I/Q waves, then Waveform Style > Analog."
