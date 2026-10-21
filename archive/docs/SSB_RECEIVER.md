# PL USB/LSB demodulation and continuous audio

The new profile retains the 255-tap sharp channel filter and adds an
independent time-shared **127-tap Hilbert demodulator**. It computes both
sidebands continuously at **8 ksample/s**; PS selects the one to capture.
The current board image is one tuned receiver. The separate generic engine
has been simulated and routed for eight tagged channels; eight physical
DDC frontends and eight PS decoder channels are not yet instantiated.

```
ADC source -> mixer/CIC -> sharp FIR -> I/Q tap -> USB/LSB phasing
                                  |                  |       |
                                  +-- snapshot mux <-+       +-> PCM16 FIFO -> read_8
                                           |
                                        read_32
```

## Phasing and response

For the verified convention z=I+jQ, positive baseband frequency is above the
tuned RF frequency. The Hilbert FIR has -j response for positive frequency.
Delay I by 63 samples, matching the Hilbert group's 7.875 ms delay:

```
USB = (delayed I - Hilbert(Q))/2
LSB = (delayed I + Hilbert(Q))/2
```

Division by two preserves the I/Q-envelope amplitude. The 18-bit Q1.17
coefficients are antisymmetric, explicitly checked to fit the signed range,
and provide about **79.36 dB ideal image rejection over 200–3000 Hz**.
Performance falls near DC, where the sidebands meet; this does not claim
79 dB rejection down to 0 Hz. The existing sharp FIR limits the outer channel
bandwidth. The full fixed-point RF simulation gives wanted-tone RMS about
2629 codes versus 0.7–1 code for the opposite sideband at 1 kHz (~68–71 dB).
Physical ADC/NCO noise may limit actual board measurements further.

The engine uses a single 24x18 multiply expression (one DSP48), shared across
channels. Each channel needs 4*127+2=510 clocks; eight fit in 4080/16000
clocks (25.5%) at 128 MHz. It runs in parallel with the sharp FIR engine.
Eight independent histories require **3 BRAM36 equivalents**, 354 LUTs and
171 registers in the isolated routed build. Setup/hold slack was
+0.445/+0.094 ns using the same registered boundary harness methodology as
[SHARP_FILTER.md](SHARP_FILTER.md). No multicycle timing relaxation was used.

## PS protocol and stream formats

Protocol marker (byte 3 of `/dev/xillybus_mem_8`) is **0xd3**. Updated Python
also accepts the earlier 0xd2 bitstream for raw/IQ. USB/LSB requests on 0xd2
fail before writing a mode value. Byte 1 selects:

| Value | Mode | read_32 snapshot |
|---|---|---|
| 0 | raw | 4096 words: frame index[31:16], signed ADC[15:0] |
| 1 | iq | 4096 pairs: signed int32 I then signed int32 Q |
| 2 | usb | 4096 signed int32 mono audio samples |
| 3 | lsb | 4096 signed int32 mono audio samples |

I/Q and mono words are sign-extended from 24 bits, little-endian. Byte 0
still selects simulated/external ADC, bytes 4–15 retain the two 48-bit phase
steps, and byte 2 atomically commits. Mode/source/frequency changes are applied
between read_32 snapshots. The audio snapshot discards 192 output samples to
settle after a change. Neither a plotting pause nor snapshot opening resets
the continuously running DDC/Hilbert processing.

In USB/LSB mode, `/dev/xillybus_read_8` provides **continuous little-endian
signed PCM16, 8000 Hz, mono**. Gain is fixed at eight with saturation; a
full-scale RF tone is approximately -0.6 dBFS after CIC gain. This is separate
from the monitor snapshots. A 1024-word asynchronous FIFO handles clock and
DMA scheduling differences. It flushes on close/open; it is not an audio
sample-rate converter. Byte 16 bit 0 is a sticky FPGA FIFO-overflow flag,
valid while the audio stream stays open, and cleared on close. WAV recording
checks this flag before closing and reports an error on sample loss.

Raw/IQ modes keep the earlier read_8/write_8 loopback behavior. Stop a PCM
reader before switching to raw/IQ. Use one read_8 consumer at a time; the
read_32 monitor can run independently with matching settings. Set tuning
through one controller to avoid competing frequency/mode writes.

## Board build and deployment

Review project: `build/bd_ssb/verilog/vivado/xillydemo.xpr`.
Expand `DDC_receiver` to see `SSB_demodulator` and `SSB_audio_stream`.
Implementation snapshot: `build/bd_ssb_build/xillydemo.xpr`.
Previous sharp-filter bitstreams are preserved for rollback.

From the reference repository on the PC, after the build passes:

```sh
python3 scripts/deploy_sd.py 192.168.1.126 build/bd_ssb-legacy.bit
scp scripts/adc_monitor.py scripts/receiver_control.py scripts/capture_ssb_audio.py root@192.168.1.126:/root/
```

Reboot the board. Display the simulated +1 kHz USB tone:

```sh
DISPLAY=:0 python3 /root/adc_monitor.py --receiver --source simulated --mode usb --tune 1000000 --sim-frequency 1001000
```

The mode radio buttons now include USB audio and LSB audio. With the simulated
carrier at 1001000 Hz, USB should show 1 kHz and LSB should suppress it.
At 999000 Hz the selections reverse. The FT8 simulator's existing 15-second
slot still contains a quiet interval; this is not dropped audio data.

Record five continuous seconds on PS (no PS demodulation, NumPy or Matplotlib
required for this command):

```sh
python3 /root/capture_ssb_audio.py /root/usb.wav --mode usb --source simulated --tune 1000000 --sim-frequency 1001000 --seconds 5
```

The command waits 50 ms for tuning transients before opening the audio stream,
records exactly the requested number of PCM samples, then checks overflow.
Copy the WAV to the PC to listen. For live listening without a board sound card,
first configure USB on the board, then on the PC (with ALSA `aplay` available):

```sh
ssh root@192.168.1.126 'python3 /root/receiver_control.py --mode usb --source simulated --tune 1000000 --sim-frequency 1001000'
ssh root@192.168.1.126 'cat /dev/xillybus_read_8' | aplay -t raw -f S16_LE -r 8000 -c 1
```

Ctrl-C stops playback and closes the stream. These instructions provide digital
audio over SSH; no HDMI audio transmitter or physical DAC is added.

## Verification and reproduction

```sh
python3 scripts/design_ssb_hilbert.py --output build/ssb_design
vivado -mode batch -source scripts/run_shared_ssb_sim.tcl
vivado -mode batch -source scripts/run_ssb_receiver_sim.tcl
vivado -mode batch -source scripts/run_ssb_audio_stream_sim.tcl
vivado -mode batch -source scripts/measure_ssb.tcl
vivado -mode batch -source scripts/create_ssb_block_design.tcl
vivado -mode batch -source scripts/build_ssb_block_design.tcl
```

Creation/build refuse existing project directories. Tests compare 2584
USB/LSB output pairs across eight channels to independent direct convolution;
they cover channel isolation, history wrap, clipping, cadence and overload.
The RF test covers both sideband signs, raw/IQ stream compatibility and
mid-frame deferred controls. The transport test covers PCM clipping, byte
order, FIFO wrap/backpressure, a close after the low byte, fresh reopening and
overflow reporting. Python tests cover marker compatibility, atomic controls,
mono parsing, plot units, WAV fragments/overflow and Python 3.5 syntax.

For interactive receiver simulation, open the review project, close any active
simulation and source `scripts/open_ssb_simulation.tcl` in Vivado. It runs
about 134 ms and leaves I/Q, USB/LSB audio and capture signals available.
The response plot is `build/ssb_design/sideband_rejection.png`.

The board build reloads the imported project metadata, refreshes the module-reference
**IP objects** and verifies generated SystemVerilog wrappers before synthesis.
Command reference: [AMD update_module_reference](https://docs.amd.com/r/2023.1-English/ug835-vivado-tcl-commands/update_module_reference).

## Completed board build

The final single-channel board image passes routed setup/hold timing at
**+0.240/+0.031 ns**, pulse-width slack **+0.264 ns**, with zero unclocked
registers and zero unconstrained internal endpoints. Final DRC has zero errors.
The added audio/control CDC paths have no Critical classifications: the
100-bit configuration uses the existing bundled-data/commit scheme; stream
open is registered before two-stage synchronization, format has a registered
source plus two-stage synchronizer, and FIFO/status crossings are synchronized.
Existing vendor VGA/Ethernet CDC warnings remain unchanged. All four XPM
bus-skew checks pass. The original external-ADC board/cable timing assumption
is unchanged.

Whole-board resources: **6537 LUTs, 7695 registers, 5 DSP48s, 15 BRAM36
 equivalents**. Compared with the sharp-filter image this adds 486 LUTs,
362 registers, one DSP48 and 1.5 BRAM36 equivalents. These are single-channel
board totals, distinct from the generic eight-channel demodulator measurement.

The SD-ready `build/bd_ssb-legacy.bit` SHA256 is:
`10e1476a5a0762eae32f71737fecec2554c7c687762ecc82d0f2e15ed51e4cde`.
`build/bd_ssb_manifest.json` verifies normal/legacy payload equality, current
RTL versus imported synthesis sources, software hashes and unchanged sharp
rollback bitstream. The image has not been deployed automatically; physical
ADC/audio listening verification is the next board test.

The Python validation passed 20 checks in the monitor, receiver-control and
SSB suites, including a complete headless USB capture/plot render and Python
3.5 syntax. Final logs are copied into `build/ssb_resources/`.
