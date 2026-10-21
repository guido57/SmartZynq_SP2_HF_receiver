set root [file normalize [file join [file dirname [info script]] ..]]
open_project "$root/build/bd_ddc/verilog/vivado/xillydemo.xpr"
open_bd_design [get_files *vivado_system.bd]
regenerate_bd_layout

file mkdir "$root/build/bd_ddc_diagrams"
write_bd_layout -force -format svg -orientation portrait "$root/build/bd_ddc_diagrams/overview.svg"
write_bd_layout -force -format pdf -orientation landscape "$root/build/bd_ddc_diagrams/overview.pdf"
foreach hier {PS_system Xillybus} {
 regenerate_bd_layout -hierarchy [get_bd_cells $hier]
 write_bd_layout -force -format svg -hierarchy [get_bd_cells $hier] "$root/build/bd_ddc_diagrams/$hier.svg"
}
regenerate_bd_layout
save_bd_design
puts "Block design opened. No synthesis or implementation was run."
