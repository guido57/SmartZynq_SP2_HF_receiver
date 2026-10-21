# Receiver operation and FT8 simulator

The `hf_ssb_receiver` image implements one 64 MS/s receiver. It accepts the simulated source or AD9248 channel A, mixes to the selected frequency, filters to a 6.7 kHz complex channel, and produces raw ADC, I/Q, USB, or LSB snapshots. USB and LSB also provide continuous 8 kHz signed PCM16 through `/dev/xillybus_read_8`.

```bash
python3 /root/receiver_control.py --source external --mode usb --tune 1000000
python3 /root/receiver_control.py --source simulated --mode usb --tune 1000000 --sim-frequency 1001000
DISPLAY=:0 python3 /root/adc_monitor.py --receiver --source simulated --mode iq
```

Continuous audio can be recorded with `capture_ssb_audio.py` or streamed to a PC with `ssh -T ... 'cat /dev/xillybus_read_8' | aplay -t raw -f S16_LE -c 1 -r 8000`.

## FT8 simulator

`ft8_control.py` uploads an arbitrary 79-tone FT8 sequence. Each tone is an integer from 0 to 7. The default sequence is the supplied K1ABC vector.

```bash
python3 /root/ft8_control.py
python3 /root/ft8_control.py --tones '3,1,4,...'
```

The script verifies each byte by readback, commits the complete message, and waits for PL acknowledgement. A commit restarts the transmission at symbol 0. There are 79 symbols at 160 ms each (12.64 seconds), followed by silence until the local 15-second slot repeats. Slots are relative to start/commit, not UTC.

The present generator is continuous-phase 8-FSK. Gaussian frequency shaping is not yet implemented, so it is suitable for receiver-path testing but is not a bit-accurate FT8 GFSK waveform.

The `/dev/xillybus_mem_8` FT8 upload registers are 17 (index), 18 (data), 19 (commit/status), and 20 (feature marker `0xf8`).
