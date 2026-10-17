# The inherited vendor XDC maps J6[] to Bank 33 with LVCMOS33.
# Hardware requirement: J6 VADJ and ADC digital output supply must be compatible.
# ADC D0..D13 = J6/20,19,22,21,24,23,26,25,28,27,30,29,32,31.
# OTRA = J6/34; CLKA = J6/33; CLKB = J6/18 (held low).
create_generated_clock -name adc_clka_forwarded -source [get_pins adc_clock_output/C] -divide_by 1 [get_ports {J6[32]}]
# Provisional lab timing budget including clock-out, PCB/cable and ADC delay.
# Verify against the actual board/cable before raising the physical sample rate.
set adc_data_ports [get_ports {J6[18] J6[19] J6[20] J6[21] J6[22] J6[23] J6[24] J6[25] J6[26] J6[27] J6[28] J6[29] J6[30] J6[31] J6[33]}]
set_input_delay -clock adc_clka_forwarded -max 25.0 $adc_data_ports
set_input_delay -clock adc_clka_forwarded -min 0.0 $adc_data_ports
# Control synchronizers. Data bundle remains stable for 125 ns; transfer is
# recognized after the two-flop toggle synchronizer, then copied at 128 MHz.
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *capture_ins/op1_reg/D || NAME =~ *capture_ins/ready1_reg/D || NAME =~ *capture_ins/source_meta_reg/D || NAME =~ *physical_input/toggle_meta_reg/D}]
# Bound the stable bundled-data path rather than blanket-false-pathing it.
set_max_delay -datapath_only 15.0 -from [get_cells -hierarchical -filter {NAME =~ *physical_input/held_data_reg* || NAME =~ *physical_input/held_overflow_reg}] -to [get_cells -hierarchical -filter {NAME =~ *physical_input/sample_reg* || NAME =~ *physical_input/overflow_reg}]
