#!/usr/bin/env python3
"""Compose a clean Xillinux receiver image without mounting or root access."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile


def digest(path):
    h = hashlib.sha256()
    with open(str(path), 'rb') as stream:
        for data in iter(lambda: stream.read(8 * 1024 * 1024), b''):
            h.update(data)
    return h.hexdigest()


def run(command):
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.returncode:
        raise RuntimeError('%s\n%s' % (' '.join(command), result.stdout.decode(errors='replace')))
    return result.stdout.decode(errors='replace')


def copy_range(source, target, offset, size):
    source.seek(offset)
    while size:
        data = source.read(min(size, 8 * 1024 * 1024))
        if not data:
            raise RuntimeError('Truncated source image')
        target.write(data)
        size -= len(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base-image', type=Path, required=True)
    parser.add_argument('--boot-dir', type=Path, required=True,
                        help='tested boot.bin, devicetree.dtb, uImage and xillydemo.bit')
    parser.add_argument('--software-tree', type=Path, required=True,
                        help='clean source export of sz_hf_rx; no .git or personal files')
    parser.add_argument('--decoder', type=Path, required=True, help='tested ARM stream executable')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--ssh-public-key', type=Path, action='append', default=[],
                        help='authorize this public key for root SSH; repeat for additional keys')
    parser.add_argument('--vnc-access', choices=('lan', 'tunnel'), default='tunnel')
    args = parser.parse_args()
    for tool in ('debugfs', 'e2fsck', 'mcopy', 'mdir', 'fsck.fat'):
        if not shutil.which(tool):
            parser.error('Required tool missing from PATH: ' + tool)
    if args.output.exists():
        parser.error('Output already exists; choose a new filename')
    boot_names = ('boot.bin', 'devicetree.dtb', 'uImage', 'xillydemo.bit')
    for name in boot_names:
        if not (args.boot_dir / name).is_file():
            parser.error('Missing boot file: ' + name)
    for name in ('scripts/live_capture.py', 'scripts/ft8_control.py', 'scripts/receiver_control.py',
                 'scripts/firstboot.py', 'scripts/install_remote_access.py', 'packages/packages.json'):
        if not (args.software_tree / name).is_file():
            parser.error('Incomplete software export: ' + name)
    if (args.software_tree / '.git').exists():
        parser.error('Export source files first; do not include Git configuration in the image')
    with args.base_image.open('rb') as source:
        mbr = source.read(512)
    if mbr[510:512] != b'\x55\xaa':
        parser.error('Expected an MBR-partitioned Xillinux image')
    parts = []
    for index, expected in ((0, (0x0b, 0x0c, 0x06)), (1, (0x83,))):
        entry = mbr[446 + 16 * index:462 + 16 * index]
        if entry[4] not in expected:
            parser.error('Unexpected Xillinux partition type')
        start, count = struct.unpack_from('<II', entry, 8)
        if not start or not count or (start + count) * 512 > args.base_image.stat().st_size:
            parser.error('Invalid partition bounds')
        parts.append((start * 512, count * 512))
    if parts[0][0] + parts[0][1] > parts[1][0]:
        parser.error('Overlapping partitions')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='sz-image-', dir=str(args.output.parent)) as tmp:
        tmp = Path(tmp)
        fat, ext = tmp / 'boot.fat', tmp / 'root.ext4'
        with args.base_image.open('rb') as source:
            for path, (offset, size) in zip((fat, ext), parts):
                with path.open('wb') as target:
                    copy_range(source, target, offset, size)
        print('Installing the tested boot files.', flush=True)
        for name in boot_names:
            run(['mcopy', '-o', '-i', str(fat), str(args.boot_dir / name), '::' + name])
        run(['fsck.fat', '-n', str(fat)])
        stage = tmp / 'stage'
        stage.mkdir()
        shutil.copytree(str(args.software_tree), str(stage / 'root/sz_hf_rx'))
        binary = stage / 'root/sz_hf_rx/ft8_decoder/build/a9-stream/ft8-subtract-stream-a9'
        binary.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(str(args.decoder), str(binary))
        binary.chmod(0o755)
        (stage / 'root/sz_hf_rx/scripts/live_capture.py').chmod(0o755)
        startup = ['python3', str(args.software_tree / 'scripts/install_remote_access.py'),
                   '--root', str(stage), '--vnc-access', args.vnc_access]
        for key in args.ssh_public_key:
            startup += ['--ssh-public-key', str(key)]
        run(startup)
        desktop = '''[Desktop Entry]
Type=Application
Name=SmartZynq FT8 Demo
Comment=Capture and decode the internal test signal
Exec=/bin/bash -c "sz-hf-rx; read -r -p 'Press Enter to close...' answer"
Terminal=true
Icon=utilities-terminal
Categories=HamRadio;Education;
'''
        for name in ('root/Desktop/sz-hf-rx.desktop', 'usr/share/applications/sz-hf-rx.desktop'):
            path = stage / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(desktop)
            path.chmod(0o755)
        (stage / 'root/START-HERE.txt').write_text(
            'SmartZynq HF receiver\n\nRun sz-hf-rx in a terminal, or open SmartZynq FT8 Demo.\n'
            'The default uses the internal FPGA source: no antenna is required.\n'
            'Allow up to 15.5 seconds for tone alignment, then about 30 seconds for capture.\n'
            'Expected message: G0XYZ K1ABC FN43. Ctrl+C stops the program.\n\n'
            'External reception: sz-hf-rx --source external --tune 14074000 --slots 2\n'
            'Documentation and source: /root/sz_hf_rx/README.md\n')
        source_hashes = {str(p.relative_to(args.software_tree)): digest(p)
                         for p in sorted(args.software_tree.rglob('*')) if p.is_file()}
        manifest = {'base_image_sha256': digest(args.base_image),
                    'boot_files': {n: digest(args.boot_dir / n) for n in boot_names},
                    'stream_decoder_sha256': digest(args.decoder),
                    'software_files': source_hashes,
                    'board': 'HelloFPGA SmartZynq SP2 V1.3B, XC7Z020',
                    'default_command': 'sz-hf-rx', 'default_source': 'simulated',
                    'desktop_autostart': True, 'vnc_access': args.vnc_access,
                    'ssh_public_key_sha256': [digest(key) for key in args.ssh_public_key]}
        (stage / 'root/sz_hf_rx/sd-image-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        commands = []
        directories = {Path('usr/local/bin')}
        for path in stage.rglob('*'):
            if path.is_dir():
                directories.add(path.relative_to(stage))
        # Make missing directories only; the stock filesystem contains /root, etc.
        for relative in sorted(directories, key=lambda p: (len(p.parts), str(p))):
            target = '/' + str(relative)
            stat = run(['debugfs', '-R', 'stat ' + target, str(ext)])
            if 'Inode:' not in stat:
                commands.append('mkdir ' + json.dumps(target))
        for path in sorted(stage.rglob('*')):
            target = '/' + str(path.relative_to(stage))
            if path.is_symlink():
                stat = run(['debugfs', '-R', 'stat ' + target, str(ext)])
                if 'Inode:' in stat:
                    commands.append('rm ' + json.dumps(target))
                commands.append('symlink %s %s' % (json.dumps(target), json.dumps(os.readlink(str(path)))))
                continue
            if not path.is_file():
                continue
            stat = run(['debugfs', '-R', 'stat ' + target, str(ext)])
            if 'Inode:' in stat:
                commands.append('rm ' + json.dumps(target))
            commands.append('write %s %s' % (json.dumps(str(path)), json.dumps(target)))
            mode = '0%o' % (0o100000 | (path.stat().st_mode & 0o777))
            commands.append('set_inode_field %s mode %s' % (json.dumps(target), mode))
        # Authentication directories and key files must satisfy sshd StrictModes.
        for relative in ('root/.ssh',):
            commands.append('set_inode_field /%s mode 040700' % relative)
        commands.append('symlink /usr/local/bin/sz-hf-rx /root/sz_hf_rx/scripts/live_capture.py')
        script = tmp / 'debugfs.commands'
        script.write_text('\n'.join(commands) + '\n')
        log = run(['debugfs', '-w', '-f', str(script), str(ext)])
        for error in ('File not found', 'Could not allocate', 'No space left', 'Ext2 file already exists'):
            if error in log:
                raise RuntimeError('Filesystem injection failed: ' + log)
        check = subprocess.run(['e2fsck', '-f', '-y', str(ext)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if check.returncode not in (0, 1):
            raise RuntimeError(check.stdout.decode(errors='replace'))
        # Read back the executable to catch failed debugfs writes, not just metadata errors.
        verify = tmp / 'verify-decoder'
        run(['debugfs', '-R', 'dump /root/sz_hf_rx/ft8_decoder/build/a9-stream/ft8-subtract-stream-a9 ' + str(verify), str(ext)])
        if digest(verify) != manifest['stream_decoder_sha256']:
            raise RuntimeError('Installed decoder checksum mismatch')
        print('Assembling the image; original base and SD card remain unchanged.', flush=True)
        shutil.copyfile(str(args.base_image), str(args.output))
        with args.output.open('r+b') as target:
            for path, (offset, size) in zip((fat, ext), parts):
                target.seek(offset)
                with path.open('rb') as source:
                    copy_range(source, target, 0, size)
        manifest['image_sha256'] = digest(args.output)
        args.output.with_suffix('.manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        args.output.with_suffix('.img.sha256').write_text(manifest['image_sha256'] + '  ' + args.output.name + '\n')
        print('Created ' + str(args.output), flush=True)


if __name__ == '__main__':
    main()
