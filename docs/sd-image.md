# Receiver SD image composition

## Current boot-tested image

[Download v3, 2026-11-08](https://github.com/guido57/SmartZynq_SP2_HF_receiver/releases/tag/sd-image-v3-2026-11-08).
The owner confirmed that this exact SD card boots and works as requested on
2026-11-08, including automatic HDMI/LXDE startup, SSH and authenticated VNC.

| Setting | v3 default |
| --- | --- |
| SSH username | `root` |
| SSH/root password | `root` |
| VNC password | `root` |
| VNC TCP port | `5900` |

Verify the supplied checksum and flash the `.img.gz` to a spare card of 8 GB
or larger. On the board, open **SmartZynq FT8 Demo** or run `sz-hf-rx`.
The complete [first-use guide](https://github.com/guido57/sz_hf_rx/blob/main/docs/sd_image.md)
covers DHCP address discovery, SSH/VNC login, capture and troubleshooting.


The complete image packages the Xillinux root filesystem, tested SmartZynq
boot files and receiver PL bitstream, plus the software repository and its
prebuilt live decoder. First-use and launcher instructions belong in
[sz_hf_rx/docs/sd_image.md](https://github.com/guido57/sz_hf_rx/blob/main/docs/sd_image.md).

## Inputs

- Clean `xillinux-2.0a.img` base image, with its original MBR layout.
- `boot.bin`, `devicetree.dtb`, `uImage` and the boot-compatible `xillydemo.bit`
  from a tested SmartZynq SP2 V1.3B receiver card. Do not substitute unrelated
  PS/PL boot files. The image builder does not shorten bitstream headers.
- A source-only export of `sz_hf_rx`, including `live_capture.py`, `install_sd.py`
  and their documented utilities. Exclude `.git`, caches and personal files.
- The tested ARM hard-float executable
  `ft8_decoder/build/a9-stream/ft8-subtract-stream-a9`.

Use a clean vendor base rather than exporting a personal root filesystem.
Boot files may be read from a working card, but only the four named files
are copied into the image. Do not image a mounted, running root filesystem
and assume that it is a consistent or suitable distribution snapshot.

## Build without root

Install `mtools`, `e2fsprogs` and `dosfstools` on the build PC. The builder uses
`debugfs` and mtools against ordinary files, so no loop mounts or root access
are needed. Provide the prepared inputs:

```bash
python3 scripts/build_receiver_sd_image.py \
  --base-image /path/to/xillinux-2.0a.img \
  --boot-dir /path/to/tested-boot-files \
  --software-tree /path/to/sz_hf_rx-source-export \
  --decoder /path/to/ft8-subtract-stream-a9 \
  --ssh-public-key /path/to/your-key.pub \
  --vnc-access lan \
  --output build/sd-image/smartzynq-hf-rx.img
```

The output path must not already exist. The original image and SD card are
never modified. Allow at least 12 GB of free working space: the builder
extracts partitions and assembles a new image. It preserves the original
partition sizes; expanding to the remainder of a larger card is optional
and outside this build procedure.

The image includes a prebuilt decoder, `/usr/local/bin/sz-hf-rx`, desktop/menu
shortcuts, `/root/START-HERE.txt`, and source/documentation at `/root/sz_hf_rx`.
No capture service is started automatically. The source export does not need
build dependencies to run the default demo.

The builder checks FAT integrity and ext4 consistency, reads back the installed
executable, and emits an external manifest and SHA-256 file. The manifest
contains the exact base-image, boot-file, executable and source-file hashes.
Keep these artifacts with the distributed image. Compress for transfer:

```bash
gzip -1 -k build/sd-image/smartzynq-hf-rx.img
sha256sum build/sd-image/smartzynq-hf-rx.img.gz > build/sd-image/smartzynq-hf-rx.img.gz.sha256
```

A clean filesystem and correct hashes do not establish a successful hardware
boot. Flash a spare card, boot the specified board, run `sz-hf-rx`, and record
the actual decoded result with both source revisions and image hash before
calling a release hardware-boot-validated. The current-card launcher test and
an ARM runtime/library check are useful intermediate checks, not substitutes.

## Remote access and desktop startup (v2)

The source export must now include `scripts/firstboot.py`,
`scripts/install_remote_access.py`, the three units under `systemd/`, and
`packages/packages.json` plus its four VNC `.deb` files. At first boot,
checksum-verified packages install offline and a per-card VNC password is
created in `/root/.vnc/initial-password.txt` (root-readable only). Private SSH keys are not included. Generic builds generate a per-card password;
the explicitly requested v3 demo instead presets root and VNC passwords to `root`.

The builder enables SSH and explicit LXDE/startx and VNC services under the
multi-user target, so it does not depend on LightDM or manual `startx`.
`--ssh-public-key` can be repeated. It provisions root's authorized keys with
StrictModes-compatible permissions; without an explicit key, the clean image
does not inherit the builder's SSH access. The default VNC binding is tunnel
only; `--vnc-access lan` enables password-protected TCP 5900 access on the LAN.
After SSH login, read the initial password with the command above.

The first image booted but did not include these startup services or VNC;
its SSH daemon was running but did not accept the old board's keys. Use the
v3 image, or apply the small startup-repair archive from a board text console
to keep the existing card. The repair merges authorized keys and adds the
same service configuration without replacing the bitstream or root filesystem.

## Image with explicitly chosen login passwords

`set_sd_image_passwords.py` customizes a copy of an existing receiver image.
It preserves the boot partition and startup services, updates the root password
hash and SSH password-login policy, and installs the matching VNC authentication
file. Password inputs are local files; plaintext root passwords are not put in
command arguments or the manifest. The VNC authentication file must have been
created with `x11vnc -storepasswd` for the selected VNC password.

```bash
python3 scripts/set_sd_image_passwords.py \
  --image build/sd-image/smartzynq-hf-rx-xillinux-2026-11-07-v2.img \
  --output build/sd-image/smartzynq-hf-rx-xillinux-2026-11-08-v3.img \
  --root-password-file /path/to/root-password.txt \
  --vnc-password-file /path/to/vnc-password.txt \
  --vnc-auth-file /path/to/vnc.auth
```

The requested v3 image uses SSH user `root`, root password `root`, and VNC
password `root`. It retains automatic LXDE/startx and VNC on TCP 5900. The
VNC password file and initial-password text have mode 0600, and `.vnc` has
mode 0700. The first-boot script preserves the preset VNC credentials rather
than replacing them with a random password. The owner confirmed the physical
boot and requested startup/login behavior on 2026-11-08. The exact published
image is unchanged by these documentation updates.
