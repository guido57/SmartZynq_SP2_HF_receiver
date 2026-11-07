> Historical experiment record. For current software builds and executable test steps, see [sz_hf_rx](https://github.com/guido57/sz_hf_rx) and its [integration tests](https://github.com/guido57/sz_hf_rx/blob/main/docs/integration_tests.md). Older paths and timing examples below describe the original experiment.

# FT8 decoding from the FPGA's simulated audio stream

The receiver can now decode an FT8 transmission generated entirely inside the
SmartZynq FPGA. This provides a repeatable test of the complete path from the
programmable tone generator, through the DDC and USB/LSB demodulator, into the
Xillybus audio stream and the Cortex-A9 decoder.

The PS uploads a 79-symbol FT8 frame to the FPGA through
`/dev/xillybus_mem_8`. The default frame is a valid FT8 transmission:

```text
G0XYZ K1ABC FN43
```

The FPGA emits the frame as a 1 kHz audio signal. USB audio is sent as 8 kHz,
16-bit little-endian PCM over `/dev/xillybus_read_8`; despite that device name,
the Xillybus endpoint transfers one byte at a time, low PCM byte followed by
high PCM byte.

## Setting up the simulated receiver

Set the receiver source, demodulator, DDC frequency, and simulated carrier
once after boot or FPGA configuration:

```bash
python3 /root/receiver_control.py \
  --source simulated \
  --mode usb \
  --tune 1000000 \
  --sim-frequency 1001000
```

The 1 kHz difference between the simulated carrier and DDC tune becomes the
FT8 audio frequency. Uploading the default tone vector starts or restarts the
15-second repeating FPGA transmission:

```bash
python3 /root/ft8_control.py
```

`ft8_control.py` writes the packed 79 tones to the FPGA, verifies every byte,
commits the new frame, and waits for the FPGA acknowledgement.

## Slot timing matters

The live decoder opens `/dev/xillybus_read_8` at a UTC 15-second boundary and
captures 120,000 PCM16 samples. The first seven FT8 symbols form a Costas
synchronization block, so the generator must begin *inside* the captured slot.
Starting it just before the boundary cuts off that first block and prevents
synchronization.

For this test, the tone upload was scheduled 0.75 seconds after the next UTC
boundary while the stream decoder waited for the same boundary:

```bash
cd /root/ft8_decoder
make stream

(
python3 - <<'PY'
import subprocess, time
target = (int(time.time()) // 15 + 1) * 15 + 0.75
time.sleep(max(0.0, target - time.time()))
subprocess.run(["python3", "/root/ft8_control.py"], check=True)
PY
) &

build/a9-stream/ft8-subtract-stream-a9 --slots 1 --base-mhz 1.001
wait
```

The Cortex-A9 produced the expected decode:

```text
snr=+20 dt=+1.14s freq=1000.0Hz text=G0XYZ K1ABC FN43
```

The stream runner uses the same three-pass residual-subtraction decoder as the
WAV test program. It is built with an 80-candidate search limit, which also
allows the receiver's 8 kHz test recording to recover all 27 known messages.

## What this proves

This test validates the FPGA tone upload, simulated RF source, DDC, SSB audio
path, PCM byte order, Xillybus transport, UTC-aligned capture, and native FT8
decoder as one chain. The generator is continuous-phase 8-FSK and does not yet
apply FT8 Gaussian frequency shaping, so it is a deterministic integration
test rather than a substitute for a weak-signal off-air test.
