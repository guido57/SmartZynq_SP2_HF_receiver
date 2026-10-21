# Run the split receiver components with driven clocks and sample stimulus.
set root [file normalize [file join [file dirname [info script]] ..]]
set target [file normalize "$root/build/bd_ddc_split_review/verilog/vivado/xillydemo.xpr"]
if {[current_project -quiet] eq ""} {
 open_project $target
} elseif {[file normalize [get_property DIRECTORY [current_project]]] ne [file dirname $target]} {
 error "Open $target first, then source this script."
}
source "$root/scripts/open_ddc_simulation.tcl"
