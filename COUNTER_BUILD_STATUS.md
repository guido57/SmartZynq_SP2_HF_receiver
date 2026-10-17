# Counter build validation

Vivado 2026.1 build completed on 2026-10-09. Synthesis and implementation passed. Bitstream generation: 0 errors, 0 critical warnings (6 ordinary warnings). Timing met: WNS +0.240 ns, WHS +0.050 ns, zero failing endpoints. Obsolete fifo_32x512 IP removed from the counter project; vendor originals and reference project retained.

XSim test passed: sequence, reader pauses, closing/reopening reset and modulo-2^32 wraparound. This tests the counter module, not the complete hardware transfer path. Board verification is pending.

Bitstream: build/counter/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit
SHA-256: 072837082eb235277ec23f27be283c67a35cf064479198d17000ecbf83d5a893
