# Xillydemo project generation script for Vivado 2018.3 and up

set partfile "[file normalize "$origin_dir/../select_part.tcl"]"

set thepart "xc7z020clg484-1"

set proj_name xillydemo
set proj_dir "[file normalize $origin_dir/vivado]"
set coreblock xillybus_bundled_0

# Create project
create_project $proj_name "$proj_dir/"

# Set project properties
set obj [get_projects $proj_name]
set_property "default_lib" "xil_defaultlib" $obj
set_property "part" $thepart $obj
set_property "simulator_language" "Mixed" $obj
set_property "source_mgmt_mode" "DisplayOnly" $obj
set_property target_language $proj_lang $obj

set_property "ip_repo_paths" "$essentials_dir/vivado-ip" [current_fileset]

update_ip_catalog

# Modify gmii_to_rgmii IP version number
set origfile "$essentials_dir/vivado_system/vivado_system.bd"
set tmpfile  "vivado_system.tmp"

if { [catch {open $origfile r} fi] } {
    send_msg_id setup-1 error "Failed to open $origfile"
    return -code error
}

if { [catch {open $tmpfile w} fo] } {
    send_msg_id setup-2 error "Failed to open temporary file $tmpfile for output"
    close $fi
    return -code error
}

while {[gets $fi line] != -1} {
   if { [regexp {xilinx.com:ip:gmii_to_rgmii:} $line]} {
      regexp {\d+(\.\d+)} [get_ipdefs *gmii_to_rgmii*] ver
      regsub -all {\d+(\.\d+)} $line $ver line
   }
   puts $fo $line
}
close $fo
close $fi

# Overwrite the original file
if { [catch { file rename -force $tmpfile $origfile } ] } {
    send_msg_id setup-3 error "Failed to overwrite $origfile. Please report this error unless you've made changes in file permissions"
    return -code error
}

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "edif_extra_search_paths" "[file normalize "$origin_dir/../cores"]" $obj
set_property "top" "xillydemo" $obj

# Add files to 'sources_1' fileset
set obj [get_filesets sources_1]

set files [list \
	       $origin_dir/src/xillydemo.$proj_suffix \
	       $origin_dir/src/xillybus.v \
	       $origin_dir/src/xillybus_core.v \
	       $essentials_dir/vga_fifo/vga_fifo.xci \
	       $essentials_dir/fifo_8x2048/fifo_8x2048.xci \
	       $essentials_dir/fifo_32x512/fifo_32x512.xci \
	       $essentials_dir/vivado_system/vivado_system.bd \
	      ]

add_files -norecurse -fileset $obj $files

set_msg_config -new_severity "INFO" -id {IP_Flow 19-3298} -string {{fifo_xillybus_}}

upgrade_ip [get_ips]

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Add files to 'constrs_1' fileset
set obj [get_filesets constrs_1]
add_files -fileset $obj -norecurse $essentials_dir/xillydemo.xdc

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets sim_1] ""]} {
  create_fileset -simset sim_1
}

# Add files to 'sim_1' fileset
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property "top" "unknown" $obj
set_property "xsim.simulate.runtime" "1000 ns" $obj
set_property "xsim.simulate.uut" "UUT" $obj

# Create 'synth_1' run (if not found)
if {[string equal [get_runs synth_1] ""]} {
  create_run -name synth_1 -part $thepart -flow {Vivado Synthesis 2013} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
}
set obj [get_runs synth_1]
set_property "part" $thepart $obj

# Create 'impl_1' run (if not found)
if {[string equal [get_runs impl_1] ""]} {
  create_run -name impl_1 -part $thepart -flow {Vivado Implementation 2013} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
}
set obj [get_runs impl_1]
set_property "part" $thepart $obj
set_property STEPS.ROUTE_DESIGN.TCL.POST "$essentials_dir/showstopper.tcl" $obj

# Calm down critical warnings for issues that are known to be OK
set_msg_config -new_severity "INFO" -id {PSU-1}
set_msg_config -new_severity "INFO" -id {PSU-2}
set_msg_config -new_severity "INFO" -id {PSU-3}
set_msg_config -new_severity "INFO" -id {PSU-4}
set_msg_config -new_severity "INFO" -id {IP_Flow 19-3432}
set_msg_config -new_severity "INFO" -id {BD 41-968} -string {{xillybus_S_AXI} }
set_msg_config -new_severity "INFO" -id {BD 41-678} -string {{xillybus_S_AXI/Reg} }
set_msg_config -new_severity "INFO" -id {BD 41-1356} -string {{xillybus_S_AXI/Reg} }
set_msg_config -new_severity "INFO" -id {BD 41-759} -string {{xlconcat_0/In} }
set_msg_config -new_severity "INFO" -id {BD 41-759} -string {{xlconcat_0/In} }

set_msg_config -new_severity "INFO" -id {BD 41-968} -string {{xillybus_M_AXI} }
set_msg_config -new_severity "INFO" -id {BD 41-967} -string {{xillybus_ip_0/xillybus_M_AXI} }
set_msg_config -new_severity "INFO" -id {BD 41-967} -string {{xillybus_ip_0/xillybus_S_AXI} }

# The processor's native pads are detached in the logic design to prevent
# Vivado from confusing itself. This causes a lot of critical warnings about
# meaningless contraints not being applied. So drop the warnings.
set_msg_config -new_severity "INFO" -id {Netlist 29-160} -string {{vivado_system_processing_system7} }

puts "INFO: Project created: $proj_name"

# Uncomment the two following lines for a full implementation
#launch_runs -jobs 8 impl_1 -to_step write_bitstream
#wait_on_run impl_1
