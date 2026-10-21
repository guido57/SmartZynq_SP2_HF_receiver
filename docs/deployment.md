# Build and deployment

Use a full Vivado `.bit` file for JTAG. The SmartZynq's U-Boot 2013.07 cannot parse the long metadata header emitted by Vivado 2026.1, so an SD-boot image must be shortened with `scripts/shorten_bit_header.py`. The FPGA configuration payload is unchanged by that conversion.

```bash
python3 scripts/shorten_bit_header.py INPUT.bit OUTPUT-legacy.bit
```

For normal SD deployment use the PC-side installer. It backs up the installed image, creates a boot-compatible copy if necessary, verifies hashes, replaces only `/boot/xillydemo.bit`, and leaves the board running until you reboot it.

```bash
python3 scripts/deploy_sd.py 192.168.1.126 build/hf_ssb_receiver-legacy.bit
ssh root@192.168.1.126 reboot
```

The installer stores the original image and manifest under `~/SmartZynq-backups/` on the PC. Do not place a second full bitstream or a desktop Trash directory on the small FAT boot partition.

For temporary JTAG programming, select the unshortened `.bit` in Vivado Hardware Manager. Use the lifecycle procedure in [JTAG reconfiguration](jtag-reconfiguration.md) when Linux is already running.
