# Create the ADC simulator project in this directory.
set root [file normalize [file join [file dirname [info script]] ../../..]]
set work "$root/vivado/projects/adc_simulator/project"
source "$root/scripts/create_adc_block_design.tcl"
