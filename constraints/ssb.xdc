set_false_path -to [get_pins -hierarchical -filter {NAME =~ *SSB_audio_stream*sopen_meta_reg/D}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *Xillybus*audio_overflow_meta_reg/D}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *Snapshot_buffer*pair_meta_reg/D}]

# Stable symbol bank crosses with a synchronized commit/ack handshake.
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *FT8_simulator*commit_meta_reg/D}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *Xillybus*ft8_ack_meta_reg/D}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *FT8_simulator*active_symbols_reg*/D}]
