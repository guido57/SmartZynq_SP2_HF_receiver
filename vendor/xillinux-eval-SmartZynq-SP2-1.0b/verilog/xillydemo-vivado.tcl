# Xillydemo project generation script for Vivado 2014.4 and up

set origin_dir [file dirname [info script]]

if {[string first { } $origin_dir] >= 0} {
send_msg_id xillydemo-1 error "The path to the the project directory contains white space(s): \"$origin_dir\". This is known to cause problems with Vivado. Please move the project to a path without white spaces, and try again."
}

set essentials_dir "[file normalize "$origin_dir/../vivado-essentials"]"
set proj_lang Verilog
set proj_suffix v

source $essentials_dir/main.tcl
