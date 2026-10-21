# Tunable 64 MS/s receiver

The original 47-tap bitstream described below is a frozen baseline. Updated source now uses the [255-tap shared FIR](SHARP_FILTER.md); use its separate project/build instructions.

This is a separate project. The tested `build/bd_adc-legacy.bit` remains available for rollback.

* Reviewed/generated project: `build/bd_ddc/verilog/vivado/xillydemo.xpr`.
* Synthesis/implementation snapshot: `build/bd_ddc_build/xillydemo.xpr`.
* Bitstreams: `build/bd_ddc.bit` (normal header), `build/bd_ddc-legacy.bit` (SD-compatible header).
* Both sources now run at 64 MS/s. Channel A clock is on J6[32]; channel B stays low. Pin ordering and offset-binary conversion are unchanged.
* The source mux feeds the existing `ddc_64m_to_8k`: three /10 order-3 CIC sections, then a 47-tap FIR decimating /8, giving 8 ksample/s complex I/Q. See the RTL, rather than the older ip_ddc README's obsolete CIC description.
* The imported DDC arithmetic is pipelined in the mixer, CIC comb stages and FIR MAC to meet the SmartZynq -1 part's clock timing. Its output sequence is compared bit-for-bit against the original core; only latency changes.
* DDC and simulator NCO increments are computed by Python and committed as 48-bit phase steps. No hardware divider is added. Frequency range: 0 <= f < 32 MHz; sub-Hz programming is accepted.
* Raw and I/Q are finite 4096-sample snapshots on `/dev/xillybus_read_32`. Raw format remains indexed signed ADC words. I/Q is 4096 pairs of signed little-endian int32 words, I then Q, each sign-extended from 24 bits. I/Q capture takes about 0.52 s, plus transport/plot time. This is a live snapshot monitor, not continuous recording.
* DDC runs between captures. Source, mode and frequencies stay fixed during a frame. A setting changed during capture is applied after close. The next I/Q frame discards 64 output pairs for settling.
* The simulator retains the FT8 core's zero-symbol waveform and 15-second slot: 12.64 seconds active, 2.36 seconds quiet. The frequency selector controls its carrier; it does not program FT8 messages.

## Build

From the reference repository, with Vivado 2026.1 configured:

```bash
vivado -mode batch -source scripts/create_ddc_block_design.tcl
vivado -mode batch -source scripts/run_ddc_receiver_sim.tcl
vivado -mode batch -source scripts/build_ddc_block_design.tcl
```

Creation/build refuse to overwrite existing project directories. Open the diagram with `scripts/open_ddc_block_design.tcl` in GUI mode.

## Install and test

From the PC in the reference repository:

```bash
python3 scripts/deploy_sd.py 192.168.1.126 build/bd_ddc-legacy.bit
scp scripts/adc_monitor.py scripts/receiver_control.py root@192.168.1.126:/root/
```

Reboot the board after deployment. Start its graphical desktop, then run over SSH:

```bash
DISPLAY=:0 python3 /root/adc_monitor.py --receiver --source simulated --mode iq --tune 1000000 --sim-frequency 1001000
```

Expect a peak near **+1 kHz** on the complex spectrum. Change tuning to 1002000 Hz and it should move to **-1 kHz**. Set the simulator to 1003000 Hz and it should return to **+1 kHz**. Buttons open frequency-entry dialogs in Hz and work with Xillinux's Python 3.5 / Matplotlib 1.5 Tk backend. Source and Raw ADC/DDC I/Q radio buttons remain in the window.

Raw ADC mode shows the 0–32 MHz RF spectrum. I/Q mode shows the -4–+4 kHz baseband spectrum with DC retained, and both I and Q waveforms. The DDC's useful flat passband is about +/-2 kHz; the display edges are not a flat 8 kHz-wide receiver. Its level plot approximately compensates the mixer and CIC gain, while retaining the FIR response. Keep only one reader/monitor running.

For external testing, select External ADC. The confirmed AD9248-65 is clocked at 64 MHz; no board format change is required. A real 1.001 MHz test signal with a 1.000 MHz tune should also appear at +1 kHz.

Command-line control without graphics:

```bash
python3 /root/receiver_control.py --source simulated --mode iq --tune 1000000 --sim-frequency 1001000
```

The older `adc_source.py` writes a legacy immediate register; use the new monitor or receiver_control.py with this bitstream. Old raw-reader scripts remain valid only in raw mode.

## ADC timing assumptions and validation

The [AD9248 datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/AD9248.pdf) specifies 2–6 ns clock-to-data delay. The 64 MS/s frontend uses input I/O registers on the following rising edge and transfers samples using an XPM asynchronous FIFO; it does not reuse the 8 MS/s toggle/bundled-data crossing. The constraints currently budget an additional **0–3 ns total outbound clock plus return-data board/cable delay**. This is an explicit lab assumption, not a measured cable timing guarantee. Check physical captures at 64 MS/s; routing closure cannot establish the actual external skew.

The final regression also compares 144 output pairs bit-for-bit against the original DDC across frequency/source changes. Simulation covers external sample order and 64 MS/s cadence over 2048 samples, raw indexing/EOF/backpressure, mid-frame config deferral, positive/negative 1 kHz DDC output and simulator frequency updates. Python tests cover GUI source/mode changes, phase-step precision/range, atomic controls, deferred UI requests, signed I/Q parsing, short frames and bitstream marker rejection. A headless monitor test renders a known +1 kHz I/Q stream.

The vendor VGA FIFO still requires explicit checkpoint linking as in the previous hierarchical project. Existing vendor peripheral CDC and incomplete I/O-delay warnings remain; inspect `build/bd_ddc_*` reports. Board validation is required after the build.

## Control protocol

`/dev/xillybus_mem_8` byte offsets:

| Offset | Read | Write |
|---|---|---|
| 0 | committed source (0 simulator, 1 external) | shadow source |
| 1 | committed mode (0 raw, 1 I/Q) | shadow mode |
| 2 | commit toggle | commit all shadow settings |
| 3 | protocol marker 0xd2 | ignored |
| 4–9 | committed DDC phase step, little-endian | shadow DDC phase step |
| 10–15 | committed simulator phase step | shadow simulator phase step |

A settings readback confirms the committed bank, not completion of an in-progress frame. Software must close its stream before applying changes and reopening. Multiple simultaneous configuration writers are not supported.

## Built result (2026-10-18)

Vivado 2026.1: setup WNS +0.240 ns, hold WHS +0.017 ns, pulse-width slack +0.264 ns, zero failing timing endpoints, zero unclocked registers and zero unconstrained internal endpoints. Board testing of the new bitstream remains pending.

SD image SHA256: `8a31df9b8a5ea655e79e7701bb0fa9d5135e9b3ced7b3d981b0993b6c8583d57`.

The two XPM bus-skew checks pass (+7.068 ns and +7.034 ns slack). The new configuration/ADC crossings are classified Safe in report_cdc; inherited Ethernet/VGA CDC warnings remain.

## Vivado waveform simulation

To inspect receiver I/Q, follow [DDC_SIMULATION.md](DDC_SIMULATION.md). In the open project, source `scripts/open_ddc_simulation.tcl` from Vivado's Tcl Console. It selects the driven receiver testbench instead of elaborating the full board's unsupported vendor simulation blocks, and leaves I/Q waveforms open.
