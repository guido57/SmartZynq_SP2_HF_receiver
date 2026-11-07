# PL deployment tests

`test_deploy_sd.py` tests the PC-side deployment utility and its SSH helper,
including backup verification, rollback and deployment locking. Hardware/SSH
operations are mocked; running it does not modify an SD card.

Run from this repository root on Linux with Python 3:

```bash
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

Receiver, audio, monitor and JTAG lifecycle software tests moved to
[sz_hf_rx/tests](https://github.com/guido57/sz_hf_rx/tree/main/tests).
The retired FT8MON wrapper test is in [archive/tests](../archive/tests/).
RTL testbenches and Vivado simulation tools remain in `sim/`, `scripts/`
and the relevant `vivado/projects/` directories; see
[development notes](../docs/development.md).
