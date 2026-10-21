set c [get_pins -hierarchical -filter {NAME =~ *ADC_clock_output*clock_forward/C}]
if {[llength $c]!=1} {error "Missing ADC forwarded clock"}
set s [get_pins -hierarchical -filter {NAME =~ *DDC_receiver*op1_reg/D || NAME =~ *DDC_receiver*ready1_reg/D || NAME =~ *DDC_receiver*cfg_meta_reg/D}]
if {[llength $s]!=3} {error "Expected three receiver control CDCs"}
set clk [get_clocks adc_clka_forwarded]
if {[llength $clk]!=1 || abs([get_property PERIOD $clk]-15.625)>0.01} {error "ADC forwarded clock is not 64 MHz"}
puts "PASS: ADC 64 MHz clock and receiver CDC constraints found"
set source_cells [get_cells -hierarchical -filter {NAME =~ *Xillybus*endpoints*receiver_config_reg*}]
set target_cells [get_cells -hierarchical -filter {NAME =~ *DDC_receiver*config_active_reg*}]
if {[llength $source_cells]<90 || [llength $target_cells]<90} {error "Missing committed configuration bank CDC endpoints"}
if {[llength [get_pins -hierarchical -filter {NAME =~ *DDC_receiver*bus_iq_reg/D}]]!=1} {error "Missing stable frame-mode latch"}
