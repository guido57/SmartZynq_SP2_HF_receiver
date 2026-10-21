# Create the complete HF SSB receiver project in this directory.
set root [file normalize [file join [file dirname [info script]] ../../..]]
set work "$root/vivado/projects/hf_ssb_receiver/project"
source "$root/scripts/create_ssb_block_design.tcl"
