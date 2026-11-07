# JTAG reconfiguration

Use JTAG for temporary PL testing only. A power cycle or reboot reloads the
SD-card image. Program Vivado's original, unshortened `.bit`; header shortening
is needed only for SD boot.

The lifecycle helper is maintained in [sz_hf_rx](https://github.com/guido57/sz_hf_rx).
When Xillinux is running, execute the lifecycle helper from the UART console,
not SSH, because Ethernet is deliberately interrupted:

```bash
python3 /root/sz_hf_rx/scripts/jtag_lifecycle.py prepare
# Program the compatible full bitstream with Vivado Hardware Manager.
python3 /root/sz_hf_rx/scripts/jtag_lifecycle.py finish
```

Use only bitstreams that retain the same PS, Xillybus, VGA and Ethernet
interfaces. After `finish`, verify a bounded Xillybus capture, HDMI, and the
network before relying on the new image. If `prepare` reports that DMA did not
quiesce, reboot rather than program JTAG.

For post-programming tests, use the software repository
[hardware validation guide](https://github.com/guido57/sz_hf_rx/blob/main/docs/hardware_validation.md).

The earlier investigation notes and failed recovery experiments are kept in
`archive/docs/`.
