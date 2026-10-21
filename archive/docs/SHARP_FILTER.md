# Shared sharp channel filter

The single-channel receiver now uses a **255-tap, Q1.17 FIR** before the final
/8 decimation. Its engine is designed for one through eight channel-tagged
64 ksample/s complex streams, each producing 8 ksample/s complex output.
Eight channel histories share one coefficient ROM and one 32x18 signed
multiply datapath (implemented with two DSP48s). Each channel still has its
own mixer/NCO/CIC front end; sharing does not force equal tuning frequencies.

## Actual quantized response

| Measurement | Result |
|---|---:|
| FIR passband | 0–3 kHz (symmetrical around tuning) |
| FIR passband ripple | 0.020 dB |
| Combined CIC + FIR passband variation | about 0.114 dB |
| FIR worst stopband gain, 4–32 kHz | -72.52 dB |
| Combined CIC + FIR gain at +5 kHz | -78.57 dB |
| Combined -3 dB edges | +/-3333 Hz |
| Combined -3 dB width | 6666 Hz |
| FIR group delay | 127/64000 = 1.984375 ms |

The previous +5 kHz tone aliased to -3 kHz with about -21.34 dB gain.
Decimation still maps it to -3 kHz, but the sharper filter suppresses it before
that alias occurs. The figures above are linear transfer-function results,
relative to DC. The whole receiver also includes quantization, the small NCO
sine table and numerical noise; its simulated residual need not reach the
ideal -78.57 dB. The full receiver regression measures about 1.41 output-code
RMS at +5 kHz versus about 3809 at +1 kHz (roughly 69 dB suppression).

`build/sharp_fir_design/response.png` and `.pdf` show the response;
`response.json` contains the numerical measurements. Reproduce on the PC:

```sh
python3 scripts/design_sharp_fir.py --output build/sharp_fir_design
```

Runtime hardware reads `rtl/ddc/ddc_fir_sharp_64k.mem`. The older
`ddc_fir_64k.mem` is retained for the frozen 47-tap reference regression.
The design generator requires NumPy, SciPy and Matplotlib on the PC; none
of these new tools needs to run on Xillinux.

## Sharing and scheduling

The tagged input accepts one I/Q pair per clock; eight synchronized frontends
must serialize their eight input pairs onto this bus (the future eight-DDC
integration will add that arbitration). In the current board design only
channel 0 exists, so `Channel_filter` is configured for one channel. The
separate eight-channel simulation and timing build exercise CHANNELS=8.
This is not yet an eight-receiver board bitstream or an audio demodulator.

Each output costs 7*255+2 = 1787 clocks. Eight outputs take 14296 clocks,
89.35% of the available 16000 clocks at 128 MHz. The eight-channel burst test
measures 14289 clocks worst latency relative to the channel's input job,
accounting for input-tag staggering. Each channel has 512 history locations,
so incoming samples cannot overwrite the 255-sample processing window while
other channels are being processed. Valid output begins only after history
fills, and then follows every eight inputs. There is no uninitialized-RAM
output and no skipped input samples at the supported cadence.

`overrun` is sticky: a new job arriving while that channel's previous job is
still pending signals unsupported load rather than a trustworthy stream.
There is no backpressure on input; callers must obey the 64 ksample/s/channel
and CHANNELS<=8 contract. Do not increase tap count without recomputing both
the schedule and ring-history guard and testing timing.

## Measured eight-channel filter resources

Vivado 2026.1, XC7Z020CLG484-1, routed out of context:

| Resource | Shared filter, eight histories |
|---|---:|
| LUTs | 410 |
| Registers | 226 |
| DSP48s | 2 |
| BRAM36 equivalents | 8 |

At 128 MHz, routed setup slack is +1.889 ns and hold slack is +0.071 ns.
A registered boundary harness is used to avoid treating external pin skew as
internal timing. Only paths outside that harness are cut. The resource table
excludes harness registers. Full-board timing is checked separately.
Reports are under `build/sharp_fir_resources/`; reproduce with
`scripts/measure_sharp_fir.tcl`.

## Verification and project

```sh
vivado -mode batch -source scripts/run_shared_fir_sim.tcl
vivado -mode batch -source scripts/run_ddc_receiver_sim.tcl
```

The first test compares **840 complex outputs** from eight independent
channels against direct convolution in NumPy, including random signed
32-bit inputs, saturation, channel isolation, impulses, history wrap,
output cadence and intentional overload reporting. The receiver test compares
3328 mixer/CIC pairs bit-for-bit against the original implementation, checks
source/tune changes and raw capture, and tests rejection of the +5 kHz alias.
The new FIR intentionally differs from the original final DDC output.

Review project: `build/bd_ddc_sharp/verilog/vivado/xillydemo.xpr`.
Open `vivado_system`, then expand `DDC_receiver`:

```
ADC_source_switch -> DDC (mixer/CIC, 64 ksample/s)
                         -> Channel_filter (shared FIR, 8 ksample/s)
                              -> Snapshot_buffer -> Xillybus
```

For receiver simulation in that project, close any active simulation and run:

```tcl
source /home/guido/Github/SmartZynq_SP2_Xillinux_reference/scripts/open_sharp_ddc_simulation.tcl
```

It runs about 52 ms; the longer filter needs the same 64-output settling
interval already used by the hardware. I/Q packing and Python control/monitor
interfaces are unchanged.

Separate board build script: `scripts/build_sharp_ddc_block_design.tcl`.
It snapshots sources to `build/bd_ddc_sharp_build` and produces distinct
`build/bd_ddc_sharp.bit` / `build/bd_ddc_sharp-legacy.bit` artifacts after
checking the existing timing/CDC constraints. It refuses an existing build
directory. The previous `bd_ddc-legacy.bit` remains the rollback image.
Do not copy the isolated eight-channel filter checkpoint to the board.

## Completed single-channel board build

Full board synthesis, place-and-route and bitstream generation passed:
setup slack **+0.240 ns**, hold **+0.050 ns**, pulse-width **+0.264 ns**;
zero unclocked registers and zero unconstrained internal endpoints.
Final DRC has zero errors. Existing vendor VGA/Ethernet methodology/CDC
warnings remain; the new FIR is synchronous to clk128. XPM bus-skew checks
are in the implementation report. The ADC's existing provisional board/cable
input-delay assumption is unchanged.

The complete board uses 6051 LUTs, 7333 registers, 4 DSP48s and 13.5 BRAM36
equivalents. Relative to the previous routed design: -4 LUTs, +22 registers,
-2 DSP48s, +1 BRAM36 equivalent. These are single-channel totals, distinct
from the standalone eight-channel FIR measurement above.

Ready for hardware test (not deployed automatically):

```sh
python3 scripts/deploy_sd.py 192.168.1.126 build/bd_ddc_sharp-legacy.bit
```

Reboot the board and use the existing receiver monitor. Compare a +1 kHz
wanted tone with a +5 kHz tone: the latter still aliases to -3 kHz but should
be much weaker, subject to ADC/NCO noise and quantization. Existing Python
controls and monitor require no update.

SD image SHA256:
`190589f2d9f27e285bd79bec71d5a37095003432ea07f42f37b2a26c9e4fad79`.
`build/bd_ddc_sharp_manifest.json` records both bitstreams and imported RTL
hashes. Normal and legacy headers contain identical configuration payloads.
The original working `bd_ddc-legacy.bit` hash is unchanged.
