> Updated 2026-10-15: use [HDMI_RECOVERY_FIX.md](HDMI_RECOVERY_FIX.md) for the current script. Earlier HDMI recovery claims below were superseded by the blue-pattern failure. The new drain/rearm candidate is locally tested but not yet hardware-verified. Use Python 3.

# Coordinated full-PL JTAG reconfiguration (experimental)

Target: SmartZynq SP2, Xillinux 2.0 / Linux 4.4.30, unchanged reference PS/AXI addresses and core interfaces. Use only the known reference/counter/simulated-ADC family of designs. Arbitrary designs with changed clocks, buses or device tree are not covered.

The script implements driver removal and reprobe; it has not been verified on the board. It does not implement PS hardware AXI isolation, so success must be established by UART boot-independent testing. Keep a known-good SD boot bitstream and use reset/reboot if the lifecycle fails. SD contents and QSPI are not modified by this script or ordinary Vivado JTAG programming.

Source inspection:
- https://github.com/xillybus/xillinux-kernel/blob/xillinux-2.0a/drivers/video/fbdev/xillyvga.c: blanking leaves memory reads active; remove writes control zero and unregisters the framebuffer.
- https://github.com/torvalds/linux/blob/v4.4/drivers/char/xillybus/xillybus_of.c: remove calls endpoint removal; probe rediscovers the FPGA.
- https://github.com/torvalds/linux/blob/v4.4/drivers/char/xillybus/xillybus_core.c: removal requests DMA quiescence; discovery allocates DMA buffers. Quiesce errors are logged even though platform removal returns success, so the script checks new kernel messages.

## Prepare

Upload scripts/jtag_lifecycle.py to /root on the board. Stop reader/writer programs. If a desktop is running, stop its display manager from UART (`systemctl stop lightdm`, if that is your active display manager). The helper refuses when framebuffer/Xillybus/memory-mapped device files are open; it reports the PIDs so you can close applications. It does not kill them automatically.

From the root UART shell (115200 baud, no SSH):

    python /root/jtag_lifecycle.py status
    python /root/jtag_lifecycle.py prepare

Wait for PREPARED. The script saves state in /run, stops NetworkManager if active, takes eth0 down, detaches framebuffer consoles, unbinds the SPI LCD, HDMI, Xillybus Lite and Xillybus drivers. It refuses unknown framebuffer drivers. Driver shutdown must occur while the OLD bitstream is still functioning. If DMA quiescence fails, DO NOT program JTAG: reboot instead.

## Program

From host Vivado Hardware Manager select xc7z020 and Program Device with the NEW ORIGINAL unshortened .bit file. Header shortening is only needed when the legacy U-Boot parses the SD file. Clear stale probes files if no ILA is present. Wait for successful configuration/startup before continuing.

## Restore

From UART:

    python /root/jtag_lifecycle.py finish
    ip -4 addr show eth0
    timeout 30 python /root/read_virtual_adc.py

The helper rebinds Xillybus first, then Lite, then HDMI/LCD; restores framebuffer console bindings; enables Ethernet if previously up; restarts NetworkManager if previously active. Device nodes and new DMA allocations are recreated. If you manually stopped lightdm, restart it after successful rebind (`systemctl start lightdm`). Reconnect SSH using the current IP address.

On partial failure the state file remains. Do not program another bitstream until restoration or a reboot. Do not manually delete the state file to bypass checks. A normal reboot/power cycle will reload the SD bitstream and clear /run state, restoring the known boot configuration.

## Validation

Local Python syntax and mocked lifecycle tests are performed; actual device removal, DMA quiescence, JTAG programming, reprobe, networking and framebuffer recovery remain untested until run on the board. The script is intentionally two-phase: no automatic JTAG action and no implied approval to reconfigure after a failure.

## First board trial (2026-10-13)

Rebind emitted `Bad interrupt message. Stopping.` The original script incorrectly printed RESTORED because driver binding and device nodes alone do not establish health. It now checks new kernel messages after each rebind and retains a reboot-required state on detected driver errors. Even an error-free rebind prints REBOUND, requiring explicit capture/network checks. Coordinated JTAG recovery is not yet validated. The interrupt log alone does not identify the cause or prove transfers cannot recover; investigate initialization/IRQ timing using full logs before modifying the kernel.

## Board trial completed (2026-10-13)

The user confirmed successful JTAG programming after prepare, followed by driver rebind, two finite ADC capture tests, HDMI and SSH recovery. The first capture reported 4096 indexed signed samples with exact 64-sample periodicity. The kernel's interrupt warning preceded `Created 5 device files`. Its root cause remains unconfirmed; an initialization-time interrupt is a hypothesis.

The script now permits a warning only when subsequent device discovery completed, while explicitly requiring a bounded transfer test. A warning after discovery, failure to discover, loss of interrupt-message synchronization, or failed DMA quiescence remains a stop condition. REBOUND reports only driver binding, never validated data transfer. One successful board trial does not establish reliability across repeated cycles or different bitstreams.
