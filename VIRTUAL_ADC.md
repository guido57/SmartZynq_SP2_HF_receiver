# Reused ADC simulator: finite Xillybus capture

Uses copies of ft8_virtual_rf_core, ad9248_clock_gen, ad9248_emulator and adc_input from the HF receiver project. The source is configured for a fixed 1 MHz tone (all FT8 symbols zero). A separate clock wizard derives 128 MHz from the existing buffered 100 MHz PS fabric clock; the existing PS configuration is unchanged.

Both emulated channels carry the same tone. The frontend A output is captured at 64 MS/s. This checks the sample transport chain, not identification of distinct A/B channels, physical ADC sampling, analog accuracy, or continuous-stream bandwidth. No physical ADC clock/data pins are used. HDMI, Ethernet, GPIO, 8-bit loopback, and memory examples are retained.

4096 samples are captured after a 256-cycle settling period when read_32 opens. The capture completes before DMA readout; dual-clock block RAM stores the frame. A synchronized completion flag prevents reading memory during capture. Closing/reopening triggers another frame. EOF occurs after 4096 words.

Word format (little endian): bits 31:16 = sample index, bits 15:0 = sign-extended 14-bit sample. Each frame is 16384 bytes and spans 64 microseconds at 64 MS/s. No samples are dropped within a frame. Time between frames is unrecorded. write_32 accepts/discards data; the old 32-bit loopback test does not apply.

## Build

    vivado -mode batch -source scripts/build_virtual_adc.tcl

A separate build/virtual_adc project is created. For the GUI, source scripts/prepare_virtual_adc.tcl, or open the existing build/virtual_adc/verilog/vivado/xillydemo.xpr. The original reference and counter builds are preserved.

For every new build, shorten the header before SD installation:

    python3 scripts/shorten_bit_header.py build/virtual_adc/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit build/virtual_adc-legacy.bit

## Board test

Preserve the working bitstream on the PC and /root on the board. Upload the legacy-compatible bitstream to /root, copy it over /mnt/sdboot/xillydemo.bit, compare, sync, unmount, and reboot. Do not put temporary files or backups on the small FAT boot partition.

Upload scripts/read_virtual_adc.py to /root and run:

    timeout 30 python /root/read_virtual_adc.py

Expect 4096 indexed samples and exact 64-sample repetition. The script writes /root/virtual_adc.bin and /root/virtual_adc.csv, and checks that codes are in the signed 14-bit range and are not constant. CSV may be plotted on the PC. Run again to test a new frame. Hardware validation is pending.

Simulation uses the actual source/emulator/frontend modules and checks bipolar output, 64-sample periodicity, indices, read pauses, EOF and reopening. Existing always_ff in the clock generator was changed to always in this copy for XSim 2026.1 compatibility; main-project files are untouched. See rtl/adc_simulator/PROVENANCE.md.
