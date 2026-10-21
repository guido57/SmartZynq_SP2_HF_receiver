PC-side SD bitstream installer
=============================

Run on the Linux PC, from the reference repository:

    python3 scripts/deploy_sd.py BOARD_IP /absolute/path/to/xillydemo.bit

Examples:

    python3 scripts/deploy_sd.py 192.168.1.126 build/physical_adc/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit
    python3 scripts/deploy_sd.py smartzynq build/physical_adc-legacy.bit --backup-dir /home/guido/SmartZynq-backups

BOARD_IP may also be an SSH host alias. The connection uses root on the board. SSH password/key authentication and host-key verification work through the system ssh client. Optional --port and --identity select a port/key. Configure keys in a terminal before invoking from an IDE. No Python packages are needed: Python 3.5+ and the PC's ssh client suffice; Python 3 is also needed on Xillinux. Keep scripts/sdboot_remote.py beside scripts/deploy_sd.py; the PC sends that helper over SSH automatically.

Use a compatible full Xillinux XC7Z020 Vivado .bit file. A .bt extension is accepted when the contents are a valid .bit file. Raw .bin images are not accepted. The app validates the bitstream header and part, strips the long metadata suffix that crashes the board's old U-Boot, and preserves the configuration payload. Already-shortened files are accepted unchanged. Part/header validation does not establish that the FPGA design is compatible with the board's Linux drivers.

Sequence:

1. Prepare the boot-compatible image on the PC.
2. Connect over SSH; mount /dev/mmcblk0p1 at /mnt/sdboot if not already mounted. Refuse an unexpected filesystem at that mount point.
3. Save an exact copy of the current /mnt/sdboot/xillydemo.bit in a private deployment directory under /root on the board.
4. Download that original to the PC, flush the local backup and verify its SHA256 before modifying the boot file.
5. Stage and verify the new image under /root on the board.
6. Check available FAT space, including the clusters freed by deleting the old image. Explicitly unlink xillydemo.bit (no desktop Trash), then copy the new image to the same name.
7. Sync and verify the installed SHA256. If a detected write/verification failure occurs, attempt restoration from the board's original copy.
8. Unmount the boot partition if the app mounted it. Preserve a pre-existing mount. Release the deployment lock.

The board is NOT rebooted. Its currently running PL design is unchanged. Reboot manually when ready to boot with the new image. GUI/Xillybus shutdown is not needed just to replace the boot file.

PC backups default to ~/SmartZynq-backups/HOST-TIMESTAMP-ID/:

* original-xillydemo.bit: exact original downloaded from the SD card.
* new-xillydemo.bit: exact boot-compatible image installed by the app.
* deployment.json: source path, board, timestamps in directory name, and hashes.

The app prints both the PC backup path and board recovery-copy path. Board recovery directories /root/.smartzynq-deploy-ID are retained after success; each contains the previous image and state journal. Remove old recovery directories manually when no longer needed to reclaim root-filesystem space.

Do not interrupt power during replacement: the small FAT partition cannot hold both bitstreams atomically. Detected copy failures have rollback; power loss or an SSH interruption cannot guarantee automatic rollback. Keep the PC backup for recovery with a card reader. On uncertain state, inspect UART/SSH before rebooting.

A lock directory /run/smartzynq-sd-deploy.lock prevents simultaneous app deployments. If interrupted, do not blindly delete this lock: read its owner and the matching /root/.smartzynq-deploy-ID/state.json, verify/restore xillydemo.bit and mount state, and ensure no deployment is still running before removing a stale lock.

Validation: nine local tests exercise backup/install, rollback after a partial copy, detection of a changed boot file, insufficient space, replacement on a full partition by reusing clusters, mount ownership, deployment locking, refusal to install after a corrupt PC backup, and invalid input rejection. Header conversion checked against an actual Vivado bitstream and the existing shortened-header result. Both scripts checked against Python 3.5 grammar. Actual SSH/SD deployment remains to be tested on the board.

SSH authentication: each deployment now uses a private OpenSSH ControlMaster socket, reusing one authenticated connection for mount, backup, upload, install and cleanup. Normally you enter the SSH password once per deployment. The app closes its master connection when done and never stores the password. SSH keys remain supported.
