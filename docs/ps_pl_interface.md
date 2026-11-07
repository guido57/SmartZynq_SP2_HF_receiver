# PS–PL interface: hf_ssb_receiver

This is the interface contract for the current single-channel SSB receiver.
Other images, including counter and ADC-only experiments, have different data
semantics even when their Xillybus device names match. Software lives in
[sz_hf_rx](https://github.com/guido57/sz_hf_rx); runnable validation procedures
are in its [hardware validation guide](https://github.com/guido57/sz_hf_rx/blob/main/docs/hardware_validation.md).

## Endpoints and framing

| Endpoint | Current receiver behavior |
| --- | --- |
| `/dev/xillybus_mem_8` | Seekable byte-addressed receiver and simulator controls below. |
| `/dev/xillybus_read_32` | Finite snapshot: 4096 raw or audio words, or 4096 interleaved I/Q pairs. Little-endian 32-bit words; EOF after the frame. Close/reopen for a new frame. |
| `/dev/xillybus_read_8` | Continuous 8 kHz mono signed PCM16, low byte first, in USB/LSB mode. Raw/IQ modes select the legacy byte-loopback path instead; they do not provide receiver audio. |

Raw snapshot words have the sample index in bits 31:16 and a sign-extended
14-bit ADC sample in bits 15:0. The simulator delivers samples at 64 MS/s;
external channel A is selected through the source flag. IQ snapshots contain
signed 24-bit I then Q, each sign-extended to 32 bits, at 8 ksample/s.
USB/LSB snapshots contain signed 24-bit demodulated samples sign-extended to
32 bits, at 8 ksample/s. Continuous PCM16 uses a separate saturating conversion
with gain eight; do not interpret its bytes as snapshot words.

Opening the audio stream flushes stale FIFO data. Overflow is latched while
open and clears when closed; inspect it before closing. Close data readers
before reconfiguring, and keep only one reader per stream. The current decoder
captures one channel; multiple receiver streams are not implemented.

## Receiver registers

Offsets below are byte offsets in `/dev/xillybus_mem_8`.

| Offset | Meaning |
| --- | --- |
| 0 | Source bit 0: 0 simulated, 1 external channel A. Writes stage the source. |
| 1 | Mode bits 1:0: 0 raw, 1 IQ, 2 USB, 3 LSB. Writes stage the mode. |
| 2 | Write commits staged receiver settings and toggles the configuration request. Read bit 0 returns the request toggle. |
| 3 | Read-only protocol marker `0xd3` for SSB; older DDC-only images use `0xd2`. |
| 4–9 | Six little-endian bytes of 48-bit tuning phase increment. |
| 10–15 | Six little-endian bytes of 48-bit simulated carrier phase increment. |
| 16 | Read bit 0: continuous audio FIFO overflow. |

Frequency conversion is `round(frequency_hz * 2^48 / 64000000)`.
Current software accepts frequencies from zero up to, but excluding, 32 MHz.
Writes to source, mode and frequencies update shadow registers; write offset 2
only after all fields are staged. Configuration crosses into the DSP domain
between snapshot frames. Readback returns the committed bus-side bank, not
an independent DSP-domain completion acknowledgement.

## FT8 upload registers

| Offset | Meaning |
| --- | --- |
| 17 | Staged payload byte index, 0–29. |
| 18 | Read/write staged byte at that index. |
| 19 | Read bit 0: commit toggle; bit 1: synchronized acknowledgement toggle. Write requests commit when both toggles match. |
| 20 | Read-only FT8 upload feature marker `0xf8`. |

Pack tone n (0–78, each 0–7) into bits `3*n +: 3`. Transfer the resulting
237 bits as 30 little-endian bytes; leave the unused high three bits zero.
Verify each staged byte, then commit. Wait until status bits 1:0 are both zero
or both one before another transaction. Commit restarts symbol 0.

There are 79 symbols at 160 ms each (12.64 seconds), followed by silence until
the 15-second local cycle repeats. PL does not know UTC: alignment to the next
UTC slot plus 0.5 seconds is supplied by `sz_hf_rx/scripts/ft8_control.py`.
The simulated carrier is the base tone; each tone adds 6.25 Hz. The current
source is continuous-phase 8-FSK without Gaussian frequency shaping.

## Implementation references

- [Endpoint/control logic](../rtl/bd/xillybus_ssb_endpoints_bd.sv)
- [Atomic DSP configuration](../rtl/bd/adc_source_control_ssb_bd.sv)
- [Snapshot framing](../rtl/bd/ssb_snapshot_bd.sv)
- [Continuous audio conversion and FIFO](../rtl/bd/ssb_audio_stream_bd.sv)
- [FT8 source timing](../rtl/ddc/ft8_virtual_rf_tunable.sv)

Update this contract alongside RTL interface changes, and check software
compatibility before combining revisions from the two repositories.
