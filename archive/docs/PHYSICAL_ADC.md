Physical / simulated ADC snapshots
=================================

Build (Vivado 2026.1, from this repository):

    vivado -mode batch -source scripts/build_physical_adc.tcl

This creates an independent build/physical_adc project. Existing reference and virtual-ADC builds are preserved. For GUI inspection open build/physical_adc/verilog/vivado/xillydemo.xpr.

Outputs:

* build/physical_adc/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit (JTAG)
* build/physical_adc-legacy.bit (short metadata header for SD/U-Boot)

Board wiring (existing vendor J6 constraints, Bank 33, LVCMOS33):

| Signal | J6 pin | FPGA ball |
|---|---:|---|
| D0 | 20 | AB15 |
| D1 | 19 | AB14 |
| D2 | 22 | AA13 |
| D3 | 21 | Y13 |
| D4 | 24 | W13 |
| D5 | 23 | V13 |
| D6 | 26 | W17 |
| D7 | 25 | W18 |
| D8 | 28 | AB17 |
| D9 | 27 | AA17 |
| D10 | 30 | Y16 |
| D11 | 29 | W16 |
| D12 | 32 | AA14 |
| D13 | 31 | Y14 |
| OTRA | 34 | V14 |
| CLKA | 33 | V15 |
| CLKB (held LOW) | 18 | AA18 |

J6 VADJ must physically be 3.3 V, compatible with the ADC digital interface. The FPGA drives clock A continuously after its clock generator locks, even in simulated mode. Clock B is held low. Capture is of the 14-bit bus assumed to carry channel A in offset-binary format. The external input flips D13 to convert to two's complement before sign extension; the simulated path remains unchanged. The AD9248's multiplexing selection is determined by its board wiring, not controlled by this design. Confirm that wiring: if MUX_SELECT follows CLKA and the connected output is port A, falling-edge sampling must be checked against board propagation delays and output switching. A B-clock-disabled mux arrangement is a hardware assumption requiring validation with the actual board. The simulation models a stable A bus, not an unknown mux circuit.

The initial physical sample rate is deliberately 8 MS/s (clock A 8 MHz); the simulated source remains 64 MS/s, 1 MHz sine. Physical data and OTRA are captured on the internal 8 MHz clock's falling edge, then transferred through a bundled-data/toggle synchronizer to the 128 MHz capture domain. Input delays use a provisional 0..25 ns board round-trip budget. This must be checked against actual ADC/cable/mux timing before changing rate or treating the timing constraints as production characterization. OTRA is sampled internally but not exported in the existing frame format; rail_codes in adc_monitor.py is not an OTRA counter. OTRB is unused.

Install scripts/adc_source.py on the board alongside adc_monitor.py. Python 3.5 is supported. After loading the new bitstream, simulated mode is the default. Verify that first:

    python3 /root/adc_source.py simulated
    DISPLAY=:0 python3 /root/adc_monitor.py --rate 64000000

Stop the monitor before switching to external:

    python3 /root/adc_source.py external
    DISPLAY=:0 python3 /root/adc_monitor.py --rate 8000000

Switch back with adc_source.py simulated. Calling adc_source.py without an argument reads the requested source. The helper prints the required monitor sample rate. The existing monitor does not detect the rate automatically.

Control: seekable /dev/xillybus_mem_8, byte offset 0, bit 0: 0=simulated, 1=external. Readback reports the requested source. Other offsets retain the demo RAM. The request is synchronized and frozen while the stream is open; changes during capture affect the next frame. An already-running monitor can therefore produce an old-source frame while changing modes. Control byte 0 replaces one demo RAM byte; the old mem_8 full-RAM loopback test must skip that offset.

Streaming format is unchanged: /dev/xillybus_read_32 supplies 4096 little-endian 32-bit words, upper 16 bits index, lower 16 bits sign-extended ADC sample. Each open triggers one finite frame, then EOF. External frame duration is 512 us; simulated frame duration is 64 us. These are repeated snapshots, not continuous recording. Do not run the simulator-specific read_virtual_adc.py periodic-sine checker against external input.

For the first bench test use a modest bipolar sinusoid within the ADC board's specified analog input range; select its frequency well below 4 MHz. Verify clock A frequency and a changing, plausible waveform first. A physical ADC capture still requires board validation.

Simulation:

    vivado -mode batch -source scripts/run_selectable_adc_sim.tcl

Checks simulated periodicity, signed physical ramp samples with delayed ADC output, per-frame source selection (including requests changed during capture), indexed data, host read pauses, EOF, reopen and both switching directions.

Offset-binary correction: confirmed on the board by software reinterpretation of a 1 MHz sine. The FPGA now performs that conversion only for external input. Use the unmodified adc_monitor.py directly, without a CSV conversion or software sign-bit flip. The build script can reopen/rebuild the existing physical_adc project and backs up its previous bitstreams to build/physical_adc_previous.
