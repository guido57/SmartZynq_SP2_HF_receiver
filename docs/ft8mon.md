# FT8MON on the Xillinux PS

The native build uses [guido57/ft8mon](https://github.com/guido57/ft8mon),
revision `feb1ac5e34dc0bcfaf156d9d165f7e89e540457d`. This fork includes KISS FFT
and a WAV reader; FFTW and libsndfile development packages are not required.
The target is the SmartZynq's ARMv7 PS running Xillinux 2.0 (Ubuntu 16.04),
with GCC/G++ 5.3.1.

## Build the optimized version on the board

Copy the patch and runner from this repository on the PC:

```bash
scp patches/ft8mon-xillinux.patch scripts/decode_ft8mon.py root@192.168.1.126:/root/
```

Run over SSH on Xillinux. The commands use C++14, supported by the installed
compiler, and compile the C files separately to preserve their C linkage.
The fork's root Makefile references sources outside their `src/` directory,
so use these commands instead:

```bash
git clone --depth 1 https://github.com/guido57/ft8mon.git /root/ft8mon
cd /root/ft8mon
git rev-parse HEAD
git apply --check /root/ft8mon-xillinux.patch
git apply /root/ft8mon-xillinux.patch
mkdir -p build-xillinux-optimized
cd build-xillinux-optimized
gcc -O3 -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard -c \
  ../src/libldpc.c ../src/kiss_fft.c ../src/kiss_fftr.c
g++ -O3 -mcpu=cortex-a9 -mfpu=neon -mfloat-abi=hard \
  -std=c++14 -DUSE_NATIVE -pthread -c \
  ../src/ft8mon.cc ../src/ft8.cc ../src/unpack.cc \
  ../src/osd.cc ../src/util.cc ../src/fft.cc
g++ -pthread ft8mon.o ft8.o unpack.o osd.o util.o fft.o \
  libldpc.o kiss_fft.o kiss_fftr.o -o ../ft8mon-cached
```

If `/root/ft8mon` already exists, reuse the checkout and start at `cd`.
The shallow clone follows the fork's current default branch; compare the
printed revision with the one above when reproducing this build.
If the patch is already applied, skip both `git apply` commands; check with
`git apply --reverse --check /root/ft8mon-xillinux.patch`. The tested board
already has the patch, runner and `ft8mon-cached` installed. The original
`ft8mon` executable is retained for comparison.

The patch caches FFT magnitudes once per coarse search, instead of repeatedly
computing the same magnitudes for overlapping frequency/time hypotheses. It
also sizes the input buffer to the actual recording, adds search timings on
stderr, and exposes the budget and frequency range through environment
variables. It keeps the original magnitude metric and decoder thresholds.

## Decode a reference recording

```bash
python3 /root/decode_ft8mon.py /root/ft8mon/data/test_01.wav --budget 30
```

The runner starts two processes covering 150–1925 Hz and 1825–3600 Hz. Each
has its own FFT caches and processing budget. It merges their output and
deduplicates message strings after normalizing whitespace. Use `--workers 1`
to process the whole band in a single process. Output is printed after both
workers finish; progress and the final count go to stderr.

For direct single-process use:

```bash
cd /root/ft8mon
FT8MON_BUDGET=15 ./ft8mon-cached -file data/test_01.wav
```

`FT8MON_MIN_HZ` and `FT8MON_MAX_HZ` select the search range (defaults 150–3600
Hz). `FT8MON_BUDGET` defaults to 5 seconds. The deadline is checked between
candidates after coarse search, so it is not a hard wall-time limit.

## Measured results

Tests on the PS on 2026-11-02, using the bundled `test_01.wav`:

| Build / execution | Budget per process | Wall time | Unique message strings |
| --- | --- | --- | --- |
| Original, generic `-O2`, one process | 5 s | 34.054 s | 3 |
| Cortex-A9 `-O3`, actual input length, no magnitude cache | 5 s | 33.754 s | 3 |
| Cached, one process | 15 s | 15.059 s | 25 |
| Cached, one process via runner | 20 s | 20.211 s | 26 |
| Cached, two processes via runner | 12 s | 12.205 s | 22 |
| Cached, two processes via runner | 30 s | 30.211 s | 30 |

The uncached coarse search took about 11 seconds per pass, exhausting the
five-second budget before candidate decoding. With three passes, the timeout
logic still tried one candidate in each pass: three messages in about 34 seconds.
Caching reduced each full-band coarse search to about 1.8–2.0 seconds.

The bundled `test_01.txt` has 24 lines; it is not an exhaustive reference for
the WAV. The expected minimum is 27 messages. The longer patched PS test
produced 30 distinct message strings; this count alone does not establish the
correctness of every decode, particularly unresolved hashed callsigns. A host
comparison produced the same 33 message strings in the same order with and
without the magnitude cache, both with a five-second budget.

The 12-second run fits within a 15-second slot but misses messages. Recovering
at least 27 messages within that slot remains unverified. These measurements
do not include acquisition or slot scheduling.

## Receiver input

This executable accepts WAV files, rather than a live Xillybus stream. The
receiver's `capture_ssb_audio.py` produces 8 kHz mono PCM16 WAV files. A live
integration also needs recordings aligned to the UTC 15-second FT8 slots;
the FPGA simulator's slots currently start relative to its commit, not UTC.
Building and decoding a reference file does not validate that integration.
