#!/usr/bin/env python3
"""Back up SmartZynq's SD bitstream to this PC, then install a Vivado .bit file."""
import argparse,datetime,hashlib,json,os
from pathlib import Path
import re,shlex,struct,subprocess,sys,tempfile,uuid

def compatible_bitstream(data):
 """Shorten metadata for U-Boot 2013.07; preserve configuration bytes."""
 def take(n):
  nonlocal pos
  if n<0 or pos+n>len(data):raise ValueError('Truncated .bit file')
  value=data[pos:pos+n];pos+=n;return value
 def number(n):return int.from_bytes(take(n),'big')
 pos=0
 take(number(2))
 if take(2)!=b'\x00\x01':raise ValueError('Not a supported Vivado .bit file')
 prefix=data[:pos];fields=[]
 for key in b'abcd':
  if take(1)!=bytes([key]):raise ValueError('Invalid .bit header')
  fields.append(take(number(2)))
 if take(1)!=b'e':raise ValueError('Missing configuration payload')
 payload=take(number(4))
 if pos!=len(data) or not payload:raise ValueError('Invalid configuration length')
 if not fields[1].rstrip(b'\0').lower().startswith(b'7z020'):
  raise ValueError('Expected an XC7Z020 bitstream; part field is '+repr(fields[1]))
 fields[0]=fields[0].split(b';SW_CRC=')[0].split(b';SW_HDR_SHA256=')[0].rstrip(b'\0')+b'\0'
 if any(len(f)>=80 for f in fields):raise ValueError('Metadata exceeds the legacy bootloader buffer')
 return prefix+b''.join(bytes([k])+struct.pack('>H',len(f))+f for k,f in zip(b'abcd',fields))+b'e'+struct.pack('>I',len(payload))+payload

def sha(data):return hashlib.sha256(data).hexdigest()

class Connection:
 def __init__(self,host,port,identity):
  self.socket_dir=tempfile.TemporaryDirectory(prefix='szssh-')
  self.socket=str(Path(self.socket_dir.name)/'s')
  self.command=['ssh','-p',str(port),'-o','ConnectTimeout=10',
                '-o','ControlMaster=auto','-o','ControlPersist=60',
                '-o','ControlPath='+self.socket]
  if identity:self.command+=['-i',str(identity)]
  self.command.append('root@'+host)
  self.helper=Path(__file__).with_name('sdboot_remote.py').read_text()
 def close(self):
  try:
   if os.path.exists(self.socket):
    subprocess.run(self.command[:-1]+['-O','exit',self.command[-1]],stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL,timeout=5)
  except (OSError,subprocess.TimeoutExpired):pass
  finally:self.socket_dir.cleanup()
 def run(self,action,token,expected=None,data=None,binary=False):
  args=['python3','-c',self.helper,action,token]
  if expected:args.append(expected)
  result=subprocess.run(self.command+[' '.join(shlex.quote(x) for x in args)],input=data,stdout=subprocess.PIPE)
  if result.returncode:
   raise RuntimeError('SSH action %s failed (exit %d); see the board error above'%(action,result.returncode))
  return result.stdout if binary else json.loads(result.stdout.decode())

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('host',help='Board IP or SSH host alias; connects as root')
 p.add_argument('bitstream',type=Path,help='Vivado .bit file (a .bt extension is also accepted if content is valid)')
 p.add_argument('--port',type=int,default=22)
 p.add_argument('--identity',type=Path,help='SSH private key file')
 p.add_argument('--backup-dir',type=Path,default=Path.home()/'SmartZynq-backups')
 a=p.parse_args()
 if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.:-]*',a.host):p.error('Invalid board hostname')
 if not 1<=a.port<=65535:p.error('Invalid SSH port')
 image=compatible_bitstream(a.bitstream.read_bytes())
 expected=sha(image)
 token=uuid.uuid4().hex
 stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
 backup=a.backup_dir/(a.host.replace(':','_')+'-'+stamp+'-'+token[:8])
 backup.mkdir(parents=True,exist_ok=False)
 # Keep the exact boot-compatible image installed by this operation.
 (backup/'new-xillydemo.bit').write_bytes(image)
 c=Connection(a.host,a.port,a.identity)
 prepared=False
 try:
  print('Connecting and mounting the SD boot partition...',flush=True)
  metadata=c.run('prepare',token);prepared=True
  print('Downloading current bitstream to the PC...',flush=True)
  original=c.run('download',token,binary=True)
  if len(original)!=metadata['old_size'] or sha(original)!=metadata['old_sha256']:
   raise RuntimeError('Downloaded backup verification failed; SD will not be changed')
  path=backup/'original-xillydemo.bit'
  with path.open('xb') as f:f.write(original);f.flush();os.fsync(f.fileno())
  if sha(path.read_bytes())!=metadata['old_sha256']:raise RuntimeError('Local backup verification failed')
  metadata.update(board=a.host,input=str(a.bitstream.resolve()),new_sha256=expected)
  (backup/'deployment.json').write_text(json.dumps(metadata,indent=2)+'\n')
  print('Verified PC backup: '+str(path),flush=True)
  print('Uploading new image, deleting the old SD image, and installing...',flush=True)
  c.run('upload',token,expected=expected,data=image)
  installed=c.run('install',token)
  if installed['sha256']!=expected:raise RuntimeError('Installed checksum mismatch')
  metadata['phase']='installed'
  (backup/'deployment.json').write_text(json.dumps(metadata,indent=2)+'\n')
  print('Installed and verified SHA256: '+expected,flush=True)
 finally:
  try:
   if prepared:
    try:
     result=c.run('finish',token)
     print('Board recovery copy: '+result['board_backup'],flush=True)
    except Exception as e:
     print('Cleanup could not complete: %s. Inspect the board over SSH/UART before rebooting.'%e,file=sys.stderr)
     raise
  finally:c.close()
 print('Done. Board has NOT been rebooted.',flush=True)

if __name__=='__main__':
 try:main()
 except (OSError,ValueError,RuntimeError,subprocess.CalledProcessError) as e:
  print('Deployment failed: '+str(e),file=sys.stderr);sys.exit(1)
