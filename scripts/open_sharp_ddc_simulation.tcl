set root [file normalize [file join [file dirname [info script]] ..]]
set target "$root/build/bd_ddc_sharp/verilog/vivado/xillydemo.xpr"
if {[current_project -quiet] eq ""} {open_project $target}
if {[file normalize [get_property DIRECTORY [current_project]]] ne [file dirname $target]} {error "Open $target before running this script"}
source "$root/scripts/open_ddc_simulation.tcl"
