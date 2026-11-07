# Receiver operation has moved

The current Xillinux receiver tools and operating instructions are maintained
in [sz_hf_rx/docs/receiver.md](https://github.com/guido57/sz_hf_rx/blob/main/docs/receiver.md).

- [Preliminary PL–PS validation](https://github.com/guido57/sz_hf_rx/blob/main/docs/hardware_validation.md)
- [Complete internal FT8 test](https://github.com/guido57/sz_hf_rx/blob/main/docs/integration_tests.md)
- [PS–PL interface contract](ps_pl_interface.md), maintained here with the RTL
- [Build and program the PL](deployment.md)

The old `/root/*.py` examples are superseded by utilities in
`/root/sz_hf_rx/scripts/`. The software FT8 uploader now schedules commit at
UTC slot boundary +0.5 seconds; the FPGA itself uses commit-relative timing.
