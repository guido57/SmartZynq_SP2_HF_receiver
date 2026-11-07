> Historical experiment record. For current software builds and executable test steps, see [sz_hf_rx](https://github.com/guido57/sz_hf_rx) and its [integration tests](https://github.com/guido57/sz_hf_rx/blob/main/docs/integration_tests.md). Older paths and timing examples below describe the original experiment.

# ESP32 FT8 decoder on the Cortex-A9

The ESP32-optimized decoder from
[guido57/ESP32_ft8_lib](https://github.com/guido57/ESP32_ft8_lib) is the
preferred PS decoder path. It is a C decoder with a streaming API and supports
the receiver's 8 kHz mono PCM16 output directly.

The original non-subtract source revision is `b1afc4d165544a1aec72cd51da1768f15482ab36`.

For busy FT8 slots use the `subtract-test` branch, revision
`7041661b344e84720fa29eae84eb5ed8d4f294ea`. This is the residual waveform
subtraction implementation used by the `dev` branch of
[guido57/usdx](https://github.com/guido57/usdx): it decodes a pass, synthesizes
and cancels every successful signal, then rebuilds the waterfall for two more
passes. It is distinct from the `DDC-subtract` branch, whose 200 Hz complex-IQ
pipeline does not match this receiver's PCM stream.

## Build on Xillinux

Copy the runner and build script after cloning the decoder repository:

```bash
git clone --depth 1 https://github.com/guido57/ESP32_ft8_lib.git /root/ESP32_ft8_lib
scp scripts/{esp32_ft8_stream.c,build_esp32_ft8_a9.sh} root@192.168.1.126:/root/
ssh root@192.168.1.126 'chmod 755 /root/build_esp32_ft8_a9.sh && /root/build_esp32_ft8_a9.sh /root/ESP32_ft8_lib'
```

The build uses GCC 5.3 with Cortex-A9, NEON, hard-float and `-O3` options. It
sets `FT8_LDPC_ITERATIONS=50`, which improved weak-signal recovery on the busy
reference recording while preserving the four-receiver timing budget.

## Live one-channel capture

First configure the FPGA for USB audio and tune it so the FT8 passband falls
between 100 Hz and 3.5 kHz. Then run one slot:

```bash
/root/ESP32_ft8_lib/build-a9-stream/ft8-stream-a9 --slots 1 --base-mhz 1.000
```

The program opens `/dev/xillybus_read_8`, waits for the next UTC 15-second
boundary, captures exactly 120,000 signed PCM16 samples, and decodes that slot.
Its producer thread captures the next slot while the foreground thread decodes
the preceding one. This source is currently for the present one-channel stream;
the four-channel packetizer must deinterleave each channel before feeding four
decoder instances. `--base-mhz` affects the frequency printed beside decoded
messages; it must match the receiver's tuned RF frequency.

## Residual-subtraction live capture

Clone the branch and use the separate runner. It explicitly sets
`cand_to_subtract = -1`, which enables automatic subtraction for every
successfully decoded candidate, and requests three passes:

```bash
git clone --depth 1 --branch subtract-test https://github.com/guido57/ESP32_ft8_lib.git /root/ft8_decoder
cd /root/ft8_decoder
make a9
make stream
build/a9-stream/ft8-subtract-stream-a9 --slots 1 --base-mhz 1.000
```

## Cortex-A9 results

`tests/20m_busy/test_01.wav` was resampled to the receiver's 8 kHz PCM16 rate
before these measurements. The expected text file has 24 messages. The decoder
recovered 20 messages, plus two messages not listed in that reference file.

| Workload | Wall time | Result |
| --- | ---: | --- |
| One decoder, default 20 LDPC iterations, 12 kHz source | 1.693 s | 18 messages |
| One decoder, 50 iterations, 12 kHz source | 3.316 s | 20 messages |
| One decoder, 50 iterations, 8 kHz source | 1.831 s | 20 messages |
| Four simultaneous 8 kHz decoders, 50 iterations | 5.067 s | 20 messages each |

Increasing candidates to 480, reducing the sync threshold, or increasing
time/frequency oversampling did not improve the 20-message result on this WAV.
Increasing LDPC iterations beyond 50 also did not improve it. The remaining
gap is decoder sensitivity, not PS throughput.

The four concurrent benchmark fits within a 15-second FT8 slot. It does not
yet prove the end-to-end four-channel receiver: that still requires the PL
packetizer, per-channel slot buffers, and a repeated hardware capture test.

## Residual-subtraction Cortex-A9 result

On the branch above, the native 12 kHz `tests/20m_busy/test_01.wav` decode
produced **27 messages** in **3.083 s**. Pass 0 found 20 messages and pass 1
recovered seven more; pass 2 recovered none. This meets the 27-message target
on the original test recording.

The receiver-format 8 kHz resample produced 25 messages in 1.945 s, so the
current 8 kHz delivery path loses two messages relative to that target. Four
independent 8 kHz three-pass decoders require roughly 7.8 CPU-seconds per
15-second FT8 interval; this fits the two Cortex-A9 cores if they are scheduled
across both cores, but it needs a four-instance benchmark and a live capture
before it is treated as an end-to-end result.
