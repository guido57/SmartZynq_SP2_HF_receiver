# Source after launch_simulation, before running time, so all samples are logged.
set wave_config [create_wave_config]
current_wave_config $wave_config
set outputs [add_wave_group {DDC output - 8 ksample/s I/Q}]
foreach {path label color} {ddc_i I #00FF00 ddc_q Q #FFFF00} {
 set w [add_wave -into $outputs -radix dec -name $label -color $color /tb_ddc_receiver/dut/$path]
 set_property HEIGHT 70 $w
}
add_wave -into $outputs -name sample_valid /tb_ddc_receiver/dut/ddc_valid
set inputs [add_wave_group {DDC input - 64 MS/s}]
add_wave -into $inputs -radix dec -name ADC_sample /tb_ddc_receiver/dut/selected_sample
add_wave -into $inputs -name ADC_valid /tb_ddc_receiver/dut/selected_valid
add_wave -into $inputs -name external_source /tb_ddc_receiver/external_active
add_wave -into $inputs -radix hex -name committed_settings /tb_ddc_receiver/dut/config_active
set stream [add_wave_group {Snapshot readout - I then Q}]
foreach name {stream_open rden empty eof} {add_wave -into $stream /tb_ddc_receiver/$name}
add_wave -into $stream -radix dec /tb_ddc_receiver/data
add_wave -into $stream /tb_ddc_receiver/test_passed
# Keep the decimator stages available in the WDB without logging RAM arrays.
foreach stage {cic1 cic2 cic3} {
 foreach suffix {i q valid} {log_wave /tb_ddc_receiver/dut/ddc/core/frontend/${stage}_${suffix}}
}
puts "Waveform ready. For I/Q curves: select I and Q, right-click Waveform Style > Analog. Radix is already Signed Decimal."

add_wave -name FIR_overrun /tb_ddc_receiver/dut/ddc/core/fir_overrun
