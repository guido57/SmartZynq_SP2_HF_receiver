# Four independent FT8 receivers

The production target is at least four simultaneous receiver slices and four
independent FT8 decoders on the SmartZynq SP2. All slices consume the same
64 MS/s ADC channel, but each has its own tuning frequency, demodulated audio,
slot buffer, decoder state and output.

## Acceptance criteria

- Four tuning frequencies can be changed independently without stopping the
  other slices.
- Every slice continuously produces signed 8 kHz PCM16 audio without FIFO
  overflow or samples from another slice.
- Four UTC-aligned 15-second buffers are decoded independently.
- The complete four-slice decode workload finishes before the next buffers
  need the same storage. Sustained operation, rather than a single fast test,
  is the criterion.
- Per-slice status reports tuning frequency, slot timestamp, overflow state,
  decoder exit status, elapsed time and decoded messages.
- A test injects a distinct known FT8 signal into every slice and verifies all
  four outputs over repeated slots.

## PL architecture

Instantiate four `ddc_64m_to_64k` front ends. Each front end has an independent
48-bit NCO phase increment and consumes the common ADC sample and valid strobe.
Arbitrate their 64 ksample/s outputs into one channel-tagged stream feeding:

1. one `shared_fir_decimator` configured with `CHANNELS=4`;
2. one `shared_ssb_demod` configured with `CHANNELS=4`;
3. one four-channel audio packetizer and asynchronous Xillybus FIFO.

The shared engines have sufficient cycle capacity at 128 MHz. The FIR consumes
about 2,048 clocks for each 8 ksample/s output job, or about 65.5 million clocks
per second for four channels. The SSB engine consumes about 640 clocks per job,
or about 20.5 million clocks per second for four channels. Both figures are
below 128 million clocks per second and must still be confirmed by simulation
with the sticky overrun outputs checked.

The current routed one-channel image uses 6,537/53,200 LUTs (12.29%), 15/140
BRAM tiles (10.71%), and 5/220 DSPs (2.27%). One DDC front end accounts for
about 1,545 LUTs, 2,140 registers, two RAMB18s and two DSPs. Replicating three
more front ends therefore appears to fit comfortably. A routed four-channel
report and timing closure are required; this estimate is not a substitute for
implementation.

Use one stream rather than four device nodes. Four interleaved PCM16 channels
at 8 ksample/s require only 64,000 bytes/s. Each transport record must carry a
channel identity and preserve sample order. A fixed frame containing one sample
from each channel is preferable when all channels are synchronous:

```text
sample 0: ch0_lo ch0_hi ch1_lo ch1_hi ch2_lo ch2_hi ch3_lo ch3_hi
sample 1: ch0_lo ch0_hi ch1_lo ch1_hi ch2_lo ch2_hi ch3_lo ch3_hi
...
```

The PS reader owns the Xillybus descriptor, deinterleaves the stream, checks
the PL overflow latch, and fills four slot buffers. Independent decoder
processes never read the device directly.

## PS throughput requirement

The Zynq-7020 PS has two Cortex-A9 cores. Four independent decoders do not imply
four simultaneous processes at all times, but their total CPU demand must fit
within two cores. In each 15-second interval the platform provides at most
30 CPU-seconds, with some capacity reserved for acquisition and scheduling.
A practical target is no more than 6 CPU-seconds per complete receiver decode,
or 24 CPU-seconds for all four.

The initial FT8MON evaluation did not meet that target. The ESP32 FT8 decoder
does: four independent 8 kHz jobs, each configured for 50 LDPC iterations,
completed in 5.067 seconds on the PS. See
[ESP32 FT8 decoder on the Cortex-A9](esp32-ft8-a9.md) for the build and
benchmark details.

The four-channel image must still demonstrate decoder quality against expected
messages and sustained operation with real samples. The PS service should use a
persistent two-worker pool, reuse FFT plans and working buffers across slots,
and reserve time for acquisition and reporting.

## Implementation order

1. Build and simulate a four-DDC tagged front end plus the existing shared FIR.
2. Add the four-channel shared SSB path and verify no FIR or SSB overruns.
3. Add the interleaved PCM16 transport and a PS deinterleaver with deterministic
   synthetic test vectors.
4. Add four independent register banks and extend the control utility.
5. Implement UTC slot buffering and a persistent two-worker decoder scheduler.
6. Integrate the ESP32 decoder's streaming API with a persistent two-worker
   scheduler and prove four complete decodes meet the sustained CPU budget.
7. Route the complete image and run repeated four-signal hardware tests.

