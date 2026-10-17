set root [file normalize [file join [file dirname [info script]] ..]]
if {[file exists "$root/build/reference"]} {error "build/reference already exists; open its .xpr or move it aside"}
file mkdir "$root/build"
file copy "$root/vendor/xillinux-eval-SmartZynq-SP2-1.0b" "$root/build/reference"
source "$root/build/reference/verilog/xillydemo-vivado.tcl"
