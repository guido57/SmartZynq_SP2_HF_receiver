# HDMI DMA lifecycle repair candidate (Python 3.5+)

## Evidence and limits

The user observed a blue FPGA-generated pattern on HDMI while a framebuffer screenshot showed a correctly rendered LXDE desktop. Xillybus documents blue as display-data starvation. A normal SD boot restores normal operation. This localizes the failure to the display readout/reconfiguration path, but does not establish an exact hardware root cause.

The old lifecycle merely unbound xillyvga. The upstream driver's remove path writes zero to the display control register and frees the framebuffer without waiting for HP2 read data to drain. The old script offered no drain evidence before JTAG and relied entirely on driver reprobe afterward.

This version stops the display BEFORE releasing its framebuffer, observes the HP2 read FIFO empty continuously for 100 ms, then unbinds drivers. It checks empty again before permitting JTAG. A nonempty FIFO blocks PREPARED. This check is a bounded observation, not a formal proof of all AXI transactions completing.

After driver rebind it replays the documented display initialization sequence using the NEW framebuffer physical address obtained with framebuffer ioctls: stop, wait for read FIFO empty, preserve/select HP2 32-bit mode, set buffer address, set frame length, enable. It logs HP2 diagnostic registers but does not use RDDEBUG as a functional completion flag.

No reserved SLCR reset bits, global bus resets, DDR registers, SD contents or QSPI are modified. The script is limited to 32-bit ARM, xillyvga at 0x50001000, and the known reference design using HP2 at 0xf800a000. HP2's 100 MHz PS fabric clock must remain active, including while PL is reconfigured. Only use bitstreams with the same PS/AXI/clock configuration. HP FIFO register access can hang if that clock is absent; a userspace timeout cannot fix a stalled bus access.

## Use

Replace /root/jtag_lifecycle.py with the updated scripts/jtag_lifecycle.py. Start from a fresh normal SD boot with working HDMI. Do not reuse an old prepared state. Log out of X before prepare; the script refuses a running Xorg/xinit/LXDE session and open device users.

From the UART shell:

    python3 /root/jtag_lifecycle.py prepare

Only if PREPARED appears, program the SAME currently working bitstream via Vivado JTAG for the first trial. Then:

    python3 /root/jtag_lifecycle.py finish
    timeout 30 python3 /root/read_virtual_adc.py

From SSH or HDMI console, startx and switch to the VT reported by the new Xorg log if needed. Confirm the actual HDMI display updates to the desktop (a framebuffer screenshot alone is insufficient). Check SSH separately.

If prepare reports a stuck FIFO, DO NOT program JTAG; reboot. If finish cannot drain/rearm, reboot the known working SD design. Do not force a reset register or bypass the failed check. Diagnostics are saved under /root/jtag-diagnostics/ as JSON and dmesg text. Preserve those files for further analysis. State format is version 2; old state is refused.

## Local validation

Four mocked hardware tests passed: sustained empty-FIFO detection, stuck-FIFO rejection, use of a new framebuffer allocation with correct register ordering and preserved HP2 configuration bits, and refusal to enable the display if rearm cannot drain. Python 3.5 syntax was checked. Original board-uploaded script is preserved as scripts/jtag_lifecycle.before_hdmi_fix.py.

Hardware validation of this repair candidate remains pending. ADC and network recovery were previously verified, but reliable post-JTAG HDMI desktop recovery was not. Do not describe this as a proven hardware fix until a new board trial succeeds.

## Sources

https://github.com/xillybus/xillinux-kernel/blob/xillinux-2.0a/drivers/video/fbdev/xillyvga.c
https://xillybus.com/downloads/doc/xillybus_getting_started_zynq.pdf
https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Register-axi_hp-AFI_RDDATAFIFO_LEVEL
https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Register-AFI_RDCHAN_CTRL-Details
