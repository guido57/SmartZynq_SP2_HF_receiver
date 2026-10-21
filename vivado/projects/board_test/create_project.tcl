# Create the standalone board-test project from the bundled Xillybus reference.
set root [file normalize [file join [file dirname [info script]] ../../..]]
set generated "$root/vivado/projects/board_test/project"
if {[file exists $generated]} {error "Already exists: $generated"}
file mkdir $generated
file copy -force "$root/vendor/xillinux-eval-SmartZynq-SP2-1.0b/verilog" "$generated/verilog"
file copy -force "$root/vendor/xillinux-eval-SmartZynq-SP2-1.0b/vivado-essentials" "$generated/vivado-essentials"
file copy -force "$root/vendor/xillinux-eval-SmartZynq-SP2-1.0b/cores" "$generated/cores"
source "$generated/verilog/xillydemo-vivado.tcl"
puts "READY: $generated/vivado/xillydemo.xpr"
