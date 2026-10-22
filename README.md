# SmartZynq SP2 HF receiver

![SmartZynq SP2 HF receiver](docs/images/hero.png)

This repository contains three independent Vivado projects for the HelloFPGA SmartZynq SP2 V1.3B (XC7Z020) running Xillinux 2.0. They retain the vendor Xillinux platform: HDMI display, Ethernet, SSH and Xillybus continue to be provided by the original PS/PL design.

## Hardware

The receiver uses two readily available boards: a HelloFPGA **SmartZynq SP2**
and an **AD9248-65** dual 14-bit ADC board. The ADC board is the acquisition
front end; the SmartZynq provides the FPGA DSP, Linux control plane, HDMI
display and Ethernet connection. The FPGA generates the 64 MHz sampling clock
and receives the ADC's parallel CMOS data through J6. The current receiver
uses channel A; the second converter channel remains available for later work.

The ADC board is not a complete HF front end by itself. A real antenna input
still needs suitable protection, gain or attenuation, band selection and
anti-alias filtering. The PL turns one digitized RF or IF stream into a tuned
complex channel today; the longer-term architecture is to create several
independent receive slices from that same sampled input.

![SmartZynq SP2 and AD9248 acquisition board](docs/images/the_two_boards.jpg)

The individual boards are also documented here: [SmartZynq SP2](docs/images/smartzynq-sp2.png) and [AD9248 ADC board](docs/images/ad9248-board.png).

| Project | Purpose |
| --- | --- |
| [`board_test`](vivado/projects/board_test/) | Minimal vendor-compatible board and Xillinux test. |
| [`adc_simulator`](vivado/projects/adc_simulator/) | Simulated or external AD9248 capture path. |
| [`hf_ssb_receiver`](vivado/projects/hf_ssb_receiver/) | 64 MS/s DDC, sharp channel filter, USB/LSB demodulation, PCM audio and PS-controlled FT8 simulator. |

Each project has its own `create_project.tcl`, `open_block_design.tcl`, and `build.tcl`. Generated Vivado projects live below that project's `project/` directory and are ignored by Git.

## Receiver architecture

The present implementation is one receiver channel; it is the practical
foundation for the future multi-channel receiver. The FPGA handles the
high-rate conversion work, while Xillinux configures the receiver, presents
the local monitor, and provides audio/IQ data over Ethernet.

![Receiver signal path](docs/images/block-diagram.png)

![Future multi-channel monitoring concept](docs/images/multichannel-monitoring.png)

## HF receiver quick start

```bash
source /tools/AMDDesignTools2026.1/2026.1/Vivado/settings64.sh
vivado -mode batch -source vivado/projects/hf_ssb_receiver/build.tcl
python3 scripts/shorten_bit_header.py \
  vivado/projects/hf_ssb_receiver/project/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit \
  build/hf_ssb_receiver-legacy.bit
python3 scripts/deploy_sd.py 192.168.1.126 build/hf_ssb_receiver-legacy.bit
ssh root@192.168.1.126 reboot
```

After boot, copy the receiver utilities once:

```bash
scp scripts/{adc_monitor.py,receiver_control.py,capture_ssb_audio.py,ft8_control.py} root@192.168.1.126:/root/
```

Configure simulated USB reception and listen on the Ubuntu PC:

```bash
ssh root@192.168.1.126 'python3 /root/receiver_control.py --source simulated --mode usb --tune 1000000 --sim-frequency 1001000'
ssh -T root@192.168.1.126 'cat /dev/xillybus_read_8' | aplay -t raw -f S16_LE -c 1 -r 8000
```

## Documentation

- [Receiver operation and FT8 simulator](docs/receiver.md)
- [Build, SD deployment and JTAG programming](docs/deployment.md)
- [Design and verification notes](docs/development.md)
- [JTAG reconfiguration lifecycle](docs/jtag-reconfiguration.md)
- [Project map](vivado/projects/README.md)

Earlier experimental projects, intermediate build notes and superseded guides are retained under [`archive/docs/`](archive/docs/). They are historical reference material, not instructions for the current three supported projects.
