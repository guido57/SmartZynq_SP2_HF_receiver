# Create and validate the hierarchical ADC block design. NO synthesis/implementation.
set root [file normalize [file join [file dirname [info script]] ..]]
if {![info exists work]} {set work "$root/build/bd_adc"}
if {[file exists $work]} {error "build/bd_adc already exists; open its project instead of overwriting it"}
file mkdir "$root/build"
file copy "$root/vendor/xillinux-eval-SmartZynq-SP2-1.0b" $work
file copy -force "$root/rtl/bd/xillydemo_bd_top.v" "$work/verilog/src/xillydemo.v"
source "$work/verilog/xillydemo-vivado.tcl"
remove_files [get_files -all *fifo_32x512.xci]
foreach f {xillybus_endpoints_bd.sv ft8_simulator_bd.sv external_adc_bd.sv adc_switch_capture_bd.sv adc_clock_output_bd.sv} {
 add_files -norecurse "$root/rtl/bd/$f"
}
add_files -norecurse "$root/rtl/adc_external_frontend.sv"
foreach f {ft8_virtual_rf_core.sv ad9248_emulator.sv ad9248_clock_gen.sv adc_input.sv sine_lut.mem} {
 add_files -norecurse "$root/rtl/adc_simulator/$f"
}
set_property source_mgmt_mode All [current_project]
update_compile_order -fileset sources_1
open_bd_design [get_files *vivado_system.bd]
# Replace an external port by an internal module connection, retaining its nets.
proc internalize_pin {port target} {
 set obj [get_bd_ports $port]
 set names {}
 foreach pin [get_bd_pins -of_objects [get_bd_nets -of_objects $obj]] {lappend names [format %s $pin]}
 puts "Internalizing $port -> $target via $names"
 delete_bd_objs $obj
 foreach name $names {connect_bd_net [get_bd_pins $target] [get_bd_pins $name]}
}
proc internalize_bus {port target} {
 set obj [get_bd_intf_ports $port]
 set pins [get_bd_intf_pins -of_objects [get_bd_intf_nets -of_objects $obj]]
 delete_bd_objs $obj
 connect_bd_intf_net [get_bd_intf_pins $target] {*}$pins
}
create_bd_cell -type module -reference xillybus_endpoints_bd endpoints
create_bd_cell -type module -reference ft8_simulator_bd FT8_simulator
create_bd_cell -type module -reference external_adc_bd External_ADC_input
create_bd_cell -type module -reference adc_switch_capture_bd ADC_switch_and_capture
create_bd_cell -type module -reference adc_clock_output_bd ADC_clock_output
create_bd_cell -type ip -vlnv [lindex [get_ipdefs -all xilinx.com:ip:clk_wiz:*] end] adc_clocks
set_property -dict [list CONFIG.PRIM_IN_FREQ {100.000} CONFIG.PRIM_SOURCE {Global_buffer} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {128.000} CONFIG.USE_RESET {false} CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {8.000}] [get_bd_cells adc_clocks]
internalize_bus xillybus_M_AXI endpoints/M_AXI_ACP
internalize_bus xillybus_S_AXI endpoints/S_AXI
internalize_pin xillybus_bus_clk endpoints/bus_clk
internalize_pin xillybus_bus_rst_n endpoints/bus_rst_n
internalize_pin xillybus_host_interrupt endpoints/host_interrupt
foreach signal {user_addr user_clk user_irq user_rd_data user_rden user_wr_data user_wren user_wstrb} {
 internalize_pin $signal endpoints/$signal
}
connect_bd_net [get_bd_pins endpoints/bus_clk] [get_bd_pins adc_clocks/clk_in1] [get_bd_pins ADC_switch_and_capture/bus_clk]
connect_bd_net [get_bd_pins adc_clocks/clk_out1] [get_bd_pins FT8_simulator/clk128] [get_bd_pins External_ADC_input/clk128] [get_bd_pins ADC_switch_and_capture/clk128]
connect_bd_net [get_bd_pins adc_clocks/clk_out2] [get_bd_pins External_ADC_input/clk_adc] [get_bd_pins ADC_clock_output/clk_adc]
connect_bd_net [get_bd_pins adc_clocks/locked] [get_bd_pins External_ADC_input/locked] [get_bd_pins ADC_switch_and_capture/locked] [get_bd_pins ADC_clock_output/locked]
connect_bd_net [get_bd_pins endpoints/adc_source_external] [get_bd_pins ADC_switch_and_capture/source_external]
foreach {endpoint capture} {user_r_read_32_open stream_open user_r_read_32_rden rden user_r_read_32_data data user_r_read_32_empty empty user_r_read_32_eof eof} {
 connect_bd_net [get_bd_pins endpoints/$endpoint] [get_bd_pins ADC_switch_and_capture/$capture]
}
connect_bd_net [get_bd_pins ADC_switch_and_capture/simulator_run] [get_bd_pins FT8_simulator/run]
connect_bd_net [get_bd_pins FT8_simulator/sample] [get_bd_pins ADC_switch_and_capture/simulated_sample]
connect_bd_net [get_bd_pins FT8_simulator/valid] [get_bd_pins ADC_switch_and_capture/simulated_valid]
connect_bd_net [get_bd_pins External_ADC_input/sample] [get_bd_pins ADC_switch_and_capture/external_sample]
connect_bd_net [get_bd_pins External_ADC_input/valid] [get_bd_pins ADC_switch_and_capture/external_valid]
create_bd_port -dir I -from 13 -to 0 adc_data
create_bd_port -dir I adc_otra
create_bd_port -dir O adc_clka
create_bd_port -dir O adc_clkb
create_bd_port -dir O -from 3 -to 0 GPIO_LED
foreach {port pin} {adc_data External_ADC_input/adc_data adc_otra External_ADC_input/adc_otra adc_clka ADC_clock_output/clka adc_clkb ADC_clock_output/clkb GPIO_LED endpoints/GPIO_LED} {
 connect_bd_net [get_bd_ports $port] [get_bd_pins $pin]
}
# Original CPU register offsets remain at 0x50000000, 0x50001000, 0x50002000.
# The core's AXI ports replace the previously exported AXI ports.
assign_bd_address -offset 0x00000000 -range 4G -target_address_space [get_bd_addr_spaces endpoints/M_AXI_ACP] [get_bd_addr_segs xillybus_ip_0/xillybus_M_AXI/reg0]
set cfg_segments [get_bd_addr_segs -of_objects [get_bd_intf_pins endpoints/S_AXI]]
puts "Core register segments: $cfg_segments"
if {[llength $cfg_segments] != 1} {error "Expected one core register segment; available: [get_bd_addr_segs]"}
assign_bd_address -offset 0x00000000 -range 64K -target_address_space [get_bd_addr_spaces xillybus_ip_0/xillybus_S_AXI] $cfg_segments
group_bd_cells Xillybus [get_bd_cells {endpoints xillybus_ip_0 xillybus_lite_0}]
group_bd_cells PS_system [get_bd_cells {processing_system7_0 processing_system7_0_axi_periph rst_processing_system7_0_100M xillyvga_0 xlconcat_0 gmii_to_rgmii_0 util_vector_logic_0 adc_clocks}]
validate_bd_design
regenerate_bd_layout
save_bd_design
file mkdir "$root/build/bd_adc_diagrams"
# Diagram image export is done by open_adc_block_design.tcl in GUI mode.
write_bd_tcl -force "$root/build/bd_adc_diagrams/vivado_system.tcl"
# Keep design sources available for inspection; do not generate or launch runs.
update_compile_order -fileset sources_1
puts "READY: $work/verilog/vivado/xillydemo.xpr"
puts "No synthesis or implementation was run."
