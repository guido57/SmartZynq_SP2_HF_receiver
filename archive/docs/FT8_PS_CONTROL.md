# PS-controlled FT8 simulator

The HF SSB receiver accepts 79 tones (each 0..7) from Linux using
`scripts/ft8_control.py`. The default is the supplied K1ABC tone sequence.
A commit restarts the simulator at symbol 0. Frames have 79 symbols of 160 ms
(12.64 seconds), followed by silence to complete a local 15-second slot.
Slots are relative to startup/commit, not UTC synchronized.

The present generator uses continuous-phase FSK with abrupt frequency changes;
Gaussian frequency shaping remains to be implemented.

Copy `ft8_control.py` and `receiver_control.py` to `/root` on the board. Then:

```bash
python3 /root/ft8_control.py
# Or supply another complete sequence:
python3 /root/ft8_control.py --tones '3,1,4,...'
```

The Python API is `ft8_control.upload(tones)`. It validates all 79 values,
verifies each shadow byte by readback, commits, and waits for acknowledgement.
Use only one uploader at a time. Existing tuning/mode controls remain compatible.

Control window in `/dev/xillybus_mem_8`:

| Offset | Access | Meaning |
| --- | --- | --- |
| 16 | R | Existing audio overflow flag |
| 17 | RW | Byte index 0..29 |
| 18 | RW | Indexed shadow payload byte |
| 19 | R | Bit 0 commit toggle; bit 1 synchronized acknowledgement |
| 19 | W | Commit bank if previous commit acknowledged |
| 20 | R | Feature marker 0xf8 |

Payload is little endian: tone n occupies bits 3*n through 3*n+2.
The top three bits of byte 29 are ignored. The committed bank stays stable
until the simulator acknowledges its capture. The simulator synchronizes the
commit, captures the bank, resets the generator for two 128 MHz cycles, and
acknowledges. An update cannot mix partial old/new messages.

Commit/restart coverage is in `sim/tb_ft8_ps_upload.sv`.
A focused accelerated XSim test is in `sim/tb_ft8_ps_tones.sv`; it verifies
79-symbol progression, transmission end, silence and slot repetition.
