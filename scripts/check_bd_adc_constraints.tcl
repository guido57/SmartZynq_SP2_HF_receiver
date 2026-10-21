# Guard checks run in normal Tcl, not the restricted XDC command language.
set c [get_pins -hierarchical -filter {NAME =~ *ADC_clock_output*clock_forward/C}]
if {[llength $c]!=1} {error "Expected one ADC forwarded-clock register, found [llength $c]"}
set sync [get_pins -hierarchical -filter {NAME =~ *ADC_switch_and_capture*op1_reg/D || NAME =~ *ADC_switch_and_capture*ready1_reg/D || NAME =~ *ADC_switch_and_capture*source_meta_reg/D || NAME =~ *External_ADC_input*frontend/toggle_meta_reg/D}]
if {[llength $sync]!=4} {error "Expected four ADC control synchronizers, found [llength $sync]"}
set src [get_cells -hierarchical -filter {NAME =~ *External_ADC_input*frontend/held_data_reg* || NAME =~ *External_ADC_input*frontend/held_overflow_reg}]
set dst [get_cells -hierarchical -filter {NAME =~ *External_ADC_input*frontend/sample_reg* || NAME =~ *External_ADC_input*frontend/overflow_reg}]
if {[llength $src]<14 || [llength $dst]<14} {error "ADC bundled-data endpoints are missing"}
if {[llength [get_clocks adc_clka_forwarded]]!=1} {error "ADC forwarded clock constraint missing"}
puts "PASS: ADC clock, four control synchronizers and 14-bit bundled-data paths found."
