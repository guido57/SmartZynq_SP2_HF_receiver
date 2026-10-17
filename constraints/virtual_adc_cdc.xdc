# Only the first stages of the two-flop control synchronizers are asynchronous.
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *capture_ins/op1_reg/D}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *capture_ins/ready1_reg/D}]
