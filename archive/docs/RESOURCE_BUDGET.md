# Receiver resource baseline — 2026-10-20

Measured with Vivado 2026.1 from the existing **routed** checkpoint:
`build/bd_ddc_build/xillydemo.runs/impl_1/xillydemo_routed.dcp`.
This is the working single-channel 47-tap FIR implementation, before the
block-design-only split. No RTL was rebuilt for this measurement. A sharper
filter, eight-channel scheduling, demodulators and FFTs are not implemented.

| Resource | Whole design | XC7Z020 capacity | Used |
|---|---:|---:|---:|
| LUT | 6055 | 53200 | 11.38% |
| Registers | 7311 | 106400 | 6.87% |
| DSP48 | 6 | 220 | 2.73% |
| 36-Kbit BRAM equivalents | 12.5 | 140 | 8.93% |

## Attribution

| Block | LUT | Registers | DSP | BRAM equivalents |
|---|---:|---:|---:|---:|
| DDC core (mixer, NCO, CICs, 47-tap FIR) | 1907 | 2360 | 6 | 1 |
| Complete receiver including snapshot/control | 1960 | 2511 | 6 | 9 |
| Everything outside receiver | 4095 | 4800 | 0 | 3.5 |

The 4096-pair snapshot allocates two 4096x32 RAMs, using 8 RAMB36.
The DDC uses 2 RAMB18, equivalent to one tile. CIC arithmetic uses no DSP
or BRAM: the three CICs account for 563/483/413 LUTs and 707/707/677 FFs.
Vivado adjusts LUT totals for combining, so child LUT counts need not sum
exactly to a parent's total. PS CPU caches and DDR are not included in PL BRAM.

## Eight-channel estimate — not a fitted design

Retain shared infrastructure once and add seven complete receiver instances:
`current total + 7 * receiver`.

| Resource | Estimate | Capacity used |
|---|---:|---:|
| LUT | 19775 | 37.2% |
| Registers | 24888 | 23.4% |
| DSP48 | 48 | 21.8% |
| BRAM equivalents | 75.5 | 53.9% |

This excludes extra channel controls, demodulation, sharper filtering, FFT
engines, FFT workspace and any double buffering. Routing/timing are unverified
for eight channels. Current design worst setup slack is about +0.240 ns;
resource headroom alone does not establish multichannel timing closure.

Eight standalone packed 4096x48 I/Q arrays contain 192 KiB of data; their
physical BRAM allocation depends on memory organization and port width.
Eight current 32-bit-per-component snapshot buffers use 64 RAMB36 tiles.
Reuse existing capture storage or stream into shared FFT workspace wherever
possible, rather than duplicating full frames per consumer. One scheduled FFT
engine is a candidate, but refresh/overlap and transform configuration must be
specified before its resource and throughput requirements can be measured.

Reports: `build/resource_measurement/{total,hierarchy,timing}.rpt`.
Reproduce with Vivado batch using `scripts/measure_ddc_resources.tcl`.

## Shared sharp FIR update

The new eight-channel 255-tap FIR has been independently routed at 128 MHz:
410 LUTs, 226 registers, 2 DSP48s and 8 BRAM36 equivalents. See
[SHARP_FILTER.md](SHARP_FILTER.md) for its schedule, response and integration.
The historical eight-channel replication estimate above does not represent
the new shared architecture. Demodulators and FFTs are still unimplemented.

The completed sharp-filter single-channel board build uses 6051 LUTs,
7333 registers, 4 DSP48s and 13.5 BRAM36 equivalents, with setup/hold slack
+0.240/+0.050 ns. Its measured per-channel mixer/CIC frontend costs 1545
LUTs, 2140 registers, 2 DSP48s and 1 BRAM36 equivalent. Retaining eight
current snapshot/control blocks and substituting the measured shared FIR
suggests approximately 17513 LUTs, 23354 registers, 18 DSP48s and 83.5 BRAM36
equivalents, before additional input arbitration, channel control banks,
demodulators or FFTs. This is an architectural estimate, not an eight-channel
implementation or timing result. The eight 4096-pair snapshots alone use 64
BRAM36 tiles; buffer reuse remains important for the FFT plan.

## Shared SSB engine

The separate eight-channel Hilbert demodulator uses one DSP48, three BRAM36
equivalents, 354 LUTs and 171 registers at 128 MHz. It operates independently
of the sharp FIR and adds both USB and LSB outputs. See [SSB_RECEIVER.md](SSB_RECEIVER.md).
The future eight-channel mixer/CIC + shared FIR + shared demodulator datapath
would use about 19 DSP48s before FFTs and extra control/transport logic. This
is not an eight-channel implemented board design.

The completed one-channel SSB board image, including continuous PCM transport,
uses 6537 LUTs, 7695 registers, 5 DSP48s and 15 BRAM36 equivalents. Routed
setup/hold slack is +0.240/+0.031 ns; the new audio/control CDC paths are
classified safe. Hardware listening/ADC verification remains a board test.
