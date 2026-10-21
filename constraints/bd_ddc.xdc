# AD9248-65: 2..6 ns output delay; provisional 0..3 ns combined
# outbound clock/return data PCB+cable delay. Capture next rising edge.
set forwarded_c [get_pins -hierarchical -filter {NAME =~ *ADC_clock_output*clock_forward/C}]
create_generated_clock -name adc_clka_forwarded -source $forwarded_c -divide_by 1 [get_ports {J6[32]}]
set adc_data_ports [get_ports {J6[18] J6[19] J6[20] J6[21] J6[22] J6[23] J6[24] J6[25] J6[26] J6[27] J6[28] J6[29] J6[30] J6[31] J6[33]}]
set_input_delay -clock adc_clka_forwarded -max 9.0 $adc_data_ports
set_input_delay -clock adc_clka_forwarded -min 2.0 $adc_data_ports
set control_sync [get_pins -hierarchical -filter {NAME =~ *DDC_receiver*op1_reg/D || NAME =~ *DDC_receiver*ready1_reg/D || NAME =~ *DDC_receiver*cfg_meta_reg/D}]
set_false_path -to $control_sync
# Committed configuration bank is stable before the synchronized toggle is
# acted on (minimum two clk128 periods). Bound that bundled-data path.
set config_source [get_cells -hierarchical -filter {NAME =~ *Xillybus*endpoints*receiver_config_reg*}]
set config_target [get_cells -hierarchical -filter {NAME =~ *DDC_receiver*config_active_reg*}]
set_max_delay -datapath_only 15.0 -from $config_source -to $config_target
# Readout mode is stable for an entire capture before ready enables reading.
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *DDC_receiver*bus_iq_reg/D}]
