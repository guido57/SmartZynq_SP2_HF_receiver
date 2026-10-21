set root [file normalize [file join [file dirname [info script]] ../../..]]
open_project "$root/vivado/projects/hf_ssb_receiver/project/verilog/vivado/xillydemo.xpr"
open_bd_design [get_files *vivado_system.bd]
update_compile_order -fileset sources_1
update_module_reference -verbose [get_ips -all -filter {IPDEF =~ *module_ref*xillybus_ssb_endpoints_bd* || IPDEF =~ *module_ref*tunable_simulator_bd*}]
foreach name {ft8_symbols ft8_commit ft8_ack} {
 if {![llength [get_bd_nets -of_objects [get_bd_pins FT8_simulator/$name]]]} {
 connect_bd_net [get_bd_pins Xillybus/endpoints/$name] [get_bd_pins FT8_simulator/$name]
 }
}
validate_bd_design
save_bd_design
generate_target all [get_files *vivado_system.bd]
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Synthesis failed"}
close_project
source "$root/vivado/projects/hf_ssb_receiver/build.tcl"
