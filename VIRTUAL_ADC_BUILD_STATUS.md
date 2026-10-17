# Simulated ADC build validation

Vivado/XSim 2026.1, 2026-10-12.

Simulation passed for the actual reused source/emulator/frontend: bipolar 1 MHz sine, exact 64-sample period, indexed capture, read pauses, finite EOF and reopening. A reduced 256-sample frame was used in simulation; hardware frame is 4096 words.

Synthesis, implementation and bitstream generation passed: 0 errors, 0 critical warnings; 6 ordinary warnings in final bitstream step. Timing WNS +0.240 ns, WHS +0.020 ns; zero failing endpoints. Clock wizard input is the verified 100 MHz Xillybus fabric clock, output 128 MHz. First-stage control synchronizer inputs have explicit false-path constraints; downstream stages remain timed.

Legacy-compatible artifact: build/virtual_adc-legacy.bit
SHA256: 8965775a0bbe52b8301662d77add79b2974af05647e820f49af22fc28c9b3c8a
Raw FPGA payload identical before/after header shortening.

Board validation is pending. Physical ADC pins are not driven by this design.
