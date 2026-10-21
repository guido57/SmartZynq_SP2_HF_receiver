# Timing constraints for the hierarchical BD version; same 8 MS/s lab budget.
set forwarded_c [get_pins -hierarchical -filter {NAME =~ *ADC_clock_output*clock_forward/C}]
create_generated_clock -name adc_clka_forwarded -source $forwarded_c -divide_by 1 [get_ports {J6[32]}]
set adc_data_ports [get_ports {J6[18] J6[19] J6[20] J6[21] J6[22] J6[23] J6[24] J6[25] J6[26] J6[27] J6[28] J6[29] J6[30] J6[31] J6[33]}]
set_input_delay -clock adc_clka_forwarded -max 25.0 $adc_data_ports
set_input_delay -clock adc_clka_forwarded -min 0.0 $adc_data_ports
set synchronizers [get_pins -hierarchical -filter {NAME =~ *ADC_switch_and_capture*op1_reg/D || NAME =~ *ADC_switch_and_capture*ready1_reg/D || NAME =~ *ADC_switch_and_capture*source_meta_reg/D || NAME =~ *External_ADC_input*frontend/toggle_meta_reg/D}]
set_false_path -to $synchronizers
set bundle_from [get_cells -hierarchical -filter {NAME =~ *External_ADC_input*frontend/held_data_reg* || NAME =~ *External_ADC_input*frontend/held_overflow_reg}]
set bundle_to [get_cells -hierarchical -filter {NAME =~ *External_ADC_input*frontend/sample_reg* || NAME =~ *External_ADC_input*frontend/overflow_reg}]
set_max_delay -datapath_only 15.0 -from $bundle_from -to $bundle_to
