set root [file normalize [file join [file dirname [info script]] ../../..]]
open_project "$root/vivado/projects/board_test/project/verilog/vivado/xillydemo.xpr"
open_bd_design [get_files *vivado_system.bd]
regenerate_bd_layout
