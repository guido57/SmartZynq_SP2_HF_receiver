#!/usr/bin/env python3
"""Customize passwords in a copy of a receiver SD image without mounting it."""
import argparse
import crypt
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import time


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for data in iter(lambda: stream.read(8388608), b''):
            h.update(data)
    return h.hexdigest()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for name in ('image', 'output', 'root-password-file', 'vnc-password-file', 'vnc-auth-file'):
        p.add_argument('--' + name, type=Path, required=True)
    a = p.parse_args()
    if a.output.exists():
        p.error('Output already exists')
    root_password = a.root_password_file.read_text().rstrip('\n')
    vnc_password = a.vnc_password_file.read_text().rstrip('\n')
    if not root_password or '\n' in root_password or not 1 <= len(vnc_password.encode('ascii')) <= 8:
        p.error('Expected a nonempty root password and a 1-8 byte VNC password')
    if a.vnc_auth_file.stat().st_size != 8:
        p.error('Expected an 8-byte VNC authentication file')
    with a.image.open('rb') as stream:
        mbr = stream.read(512)
    assert mbr[510:512] == b'\x55\xaa'
    start, count = struct.unpack_from('<II', mbr, 446 + 16 + 8)
    offset, size = start * 512, count * 512
    assert offset + size <= a.image.stat().st_size
    a.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='sz-passwords-', dir=str(a.output.parent)) as tmp:
        tmp = Path(tmp)
        fs = tmp / 'root.ext4'
        with a.image.open('rb') as src, fs.open('wb') as dst:
            src.seek(offset)
            left = size
            while left:
                data = src.read(min(left, 8388608)); assert data
                dst.write(data); left -= len(data)
        def debug(command):
            return subprocess.check_output(['debugfs', '-R', command, str(fs)], stderr=subprocess.DEVNULL).decode()
        def read(path):
            target = tmp / ('read-' + path.replace('/', '_'))
            debug('dump ' + path + ' ' + str(target))
            return target.read_text()
        shadow = read('/etc/shadow').splitlines()
        hashed = subprocess.run(['openssl', 'passwd', '-6', '-stdin'], input=root_password.encode()+b'\n',
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True).stdout.decode().strip()
        assert crypt.crypt(root_password, hashed) == hashed
        found = False
        for i, line in enumerate(shadow):
            if line.startswith('root:'):
                fields = line.split(':'); fields[1] = hashed; fields[2] = str(int(time.time() // 86400)); fields[7] = ''
                shadow[i] = ':'.join(fields); found = True
        assert found
        ssh = read('/etc/ssh/sshd_config')
        ssh = '\n'.join(line for line in ssh.splitlines() if not line.lstrip().startswith(('PermitRootLogin ', 'PasswordAuthentication ')))
        files = {'/etc/shadow': ('\n'.join(shadow)+'\n', 0o600),
                 '/etc/ssh/sshd_config': ('PermitRootLogin yes\nPasswordAuthentication yes\n'+ssh+'\n', 0o644),
                 '/root/.vnc/initial-password.txt': (vnc_password+'\n', 0o600),
                 '/root/START-HERE.txt': ('SmartZynq HF receiver\n\nSSH login: root\nSSH password: '+root_password+
                    '\nVNC password: '+vnc_password+'\nVNC port: 5900\n\nHDMI/LXDE and VNC start automatically.\n'
                    'Run sz-hf-rx or open SmartZynq FT8 Demo.\nDocumentation: /root/sz_hf_rx/README.md\n', 0o600)}
        note = ('Image login defaults\n====================\nSSH user: root\nSSH password: '+root_password+
                '\nVNC password: '+vnc_password+'\n\nThe image boots LXDE/startx and VNC automatically.\n\n')
        for name in ('README.md', 'docs/sd_image.md', 'docs/remote_access.md'):
            path = '/root/sz_hf_rx/'+name
            files[path] = (note + read(path), 0o644)
        manifest = json.loads(read('/root/sz_hf_rx/sd-image-manifest.json'))
        manifest.update(parent_image_sha256=sha(a.image), root_password_configured=True,
                        ssh_password_login=True, vnc_password_preset=True)
        for path, (text, mode) in files.items():
            if path.startswith('/root/sz_hf_rx/'):
                manifest['software_files'][path[len('/root/sz_hf_rx/'):]] = hashlib.sha256(text.encode()).hexdigest()
        files['/root/sz_hf_rx/sd-image-manifest.json'] = (json.dumps(manifest, indent=2)+'\n', 0o644)
        commands = []
        if 'Inode:' not in debug('stat /root/.vnc'):
            commands.append('mkdir /root/.vnc')
        commands.append('set_inode_field /root/.vnc mode 040700')
        for index, (path, (text, mode)) in enumerate(files.items()):
            source = tmp / ('payload-'+str(index)); source.write_text(text)
            if 'Inode:' in debug('stat '+path): commands.append('rm '+path)
            commands += ['write '+str(source)+' '+path, 'set_inode_field '+path+' mode 0%o'%(0o100000|mode)]
        if 'Inode:' in debug('stat /root/.vnc/passwd'): commands.append('rm /root/.vnc/passwd')
        commands += ['write '+str(a.vnc_auth_file.resolve())+' /root/.vnc/passwd',
                     'set_inode_field /root/.vnc/passwd mode 0100600']
        batch = tmp/'commands'; batch.write_text('\n'.join(commands)+'\n')
        result = subprocess.check_output(['debugfs', '-w', '-f', str(batch), str(fs)], stderr=subprocess.STDOUT).decode()
        assert not any(e in result for e in ('File not found', 'No space left', 'Could not allocate')), result
        check = subprocess.run(['e2fsck','-fy',str(fs)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        assert check.returncode in (0,1), check.stdout.decode()
        verify = read('/etc/shadow').splitlines()
        root_hash = next(line.split(':')[1] for line in verify if line.startswith('root:'))
        assert crypt.crypt(root_password,root_hash)==root_hash
        assert read('/root/.vnc/initial-password.txt').strip()==vnc_password
        out = tmp/'vnc-check'; debug('dump /root/.vnc/passwd '+str(out))
        assert out.read_bytes()==a.vnc_auth_file.read_bytes()
        for name in ('ssh','sz-hf-rx-firstboot','sz-hf-rx-desktop','sz-hf-rx-vnc'):
            assert 'Type: symlink' in debug('stat /etc/systemd/system/multi-user.target.wants/'+name+'.service')
        print('Verified passwords, SSH policy and all startup service links.',flush=True)
        shutil.copyfile(str(a.image),str(a.output))
        with a.output.open('r+b') as dst,fs.open('rb') as src:
            dst.seek(offset);shutil.copyfileobj(src,dst,8388608)
        manifest['image_sha256']=sha(a.output)
        a.output.with_suffix('.manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
        a.output.with_suffix('.img.sha256').write_text(manifest['image_sha256']+'  '+a.output.name+'\n')
        print('Created '+str(a.output),flush=True)


if __name__=='__main__':
    main()
