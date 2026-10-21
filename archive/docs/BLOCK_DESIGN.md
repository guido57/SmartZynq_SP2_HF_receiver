# Hierarchical ADC block design

This is a separate project at build/bd_adc/verilog/vivado/xillydemo.xpr. The working build/physical_adc project and its bitstreams are preserved. The reviewed diagram remains in this project. Synthesis and implementation use a separate snapshot at build/bd_adc_build/xillydemo.xpr so the diagram can stay open in Vivado.

The top-level block diagram is vivado_system:

* PS_system: Zynq processing_system7, AXI interconnect, reset controller, XillyVGA/HDMI, interrupt concatenation, GMII/RGMII conversion, Ethernet reset inversion and the 128 MHz / 8 MHz ADC clock generator.
* Xillybus: original PS/ACP bridge, complete DMA core and endpoint logic, Xillybus Lite, 8-bit FIFO loopback, seekable RAM/source-control register and Lite demo RAM.
* FT8_simulator: existing FT8 RF core plus its ADC-emulation/frontend path; exports channel-A samples and valid at 64 MS/s.
* External_ADC_input: existing physical ADC frontend, including fixed offset-binary conversion and clock-domain crossing; exports samples and valid at 8 MS/s.
* ADC_switch_and_capture: synchronized per-frame source selection, 4096-word snapshot RAM and Xillybus read/EOF handshakes.
* ADC_clock_output: ODDR forwarding of channel A clock; channel B held low.

The board top now contains only physical pin wiring, I/O buffers, LED/key wiring and the block-design instantiation. Custom logic is represented by real RTL module references in the diagram, not decorative placeholders. Double-click a hierarchy block to inspect its contents; use Go To Source on an RTL module reference to inspect its implementation.

The source-control byte and indexed sample format are retained. CPU-visible register addresses remain Xillybus 0x50000000, VGA 0x50001000 and Lite 0x50002000. ACP and HP2 DDR mappings remain 512 MiB. These were checked in the saved BD. Vivado validate_bd_design passed with the inherited ACP user-width warnings; no validation errors occurred.

Open in Vivado:

    vivado -mode gui -source scripts/open_adc_block_design.tcl

Or open the .xpr and select IP INTEGRATOR → Open Block Design. A new Vivado GUI was opened during creation. Collapsed top-level and individual hierarchy diagrams are exported under build/bd_adc_diagrams/.

To recreate from scratch (requires build/bd_adc not to exist):

    vivado -mode batch -source scripts/create_adc_block_design.tcl

This script creates/validates the BD only. Open it with the GUI script to export diagram images; Vivado does not support write_bd_layout image export in batch mode.

Build the reviewed design (requires build/bd_adc_build not to exist):

    vivado -mode batch -source scripts/build_adc_block_design.tcl

The build script generates the VGA FIFO explicitly and links its checkpoint in a pre-optimization hook because it is instantiated inside the vendor EDIF netlist. Vivado emits checkpoint-flow warnings for this workaround; the generated FIFO constraint file contains no active constraints, and its temporary out-of-context clock constraints are excluded from implementation. It checks the adapted ADC timing-constraint endpoints after synthesis and implementation, checks routed setup/hold timing, and exports:

* build/bd_adc.bit: normal Vivado bitstream for JTAG or the deployment script.
* build/bd_adc-legacy.bit: shortened metadata for the board's legacy U-Boot SD loader. Configuration payload is identical.
* build/bd_adc_timing.rpt, bd_adc_cdc.rpt, bd_adc_drc.rpt and bd_adc_io.rpt: implementation reports.

Simulation with scripts/run_bd_adc_sim.tcl compares the split BD modules against selectable_adc_snapshot and passed bit-for-bit in simulated/external modes, source changes, backpressure, EOF and reopen. This checks the capture refactor; the proprietary PS/DMA/VGA integration still requires a board boot test. External ADC input delays retain the provisional 8 MS/s lab budget from the physical ADC project.

To install using the existing PC deployment tool:

    python3 scripts/deploy_sd.py 192.168.1.126 build/bd_adc.bit

It backs up the current SD bitstream to the PC and handles legacy metadata. Reboot the board separately after deployment; this is the reliable path for testing HDMI and Xillinux together.

Vivado 2026.1 routed timing on 2026-10-18: setup WNS +0.240 ns, hold WHS +0.055 ns, pulse-width slack +0.264 ns; no failing timing endpoints, no unclocked registers and no unconstrained internal endpoints. The vendor design still reports incomplete peripheral I/O delay constraints; these figures do not establish full external interface timing closure. Board validation remains pending.
