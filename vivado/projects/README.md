# Supported Vivado projects

This directory contains the three supported SmartZynq SP2 designs. Each one is
independent and can be opened and built without the others:

- `board_test`: the minimal board/Xillinux reference design.
- `adc_simulator`: ADC simulator and capture path.
- `hf_ssb_receiver`: single-board-channel DDC and USB/LSB receiver, including
  the PS-controlled FT8 simulator.

The generated project for each design is below its `project/` directory.
