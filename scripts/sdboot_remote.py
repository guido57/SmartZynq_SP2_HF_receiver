"""Private SSH-side helper. Python 3.5+, no third-party dependencies."""
import hashlib,json,os,shutil,subprocess,sys

MOUNT='/mnt/sdboot'
DEVICE='/dev/mmcblk0p1'
LOCK='/run/smartzynq-sd-deploy.lock'
STAGE_ROOT='/root'

def digest(path):
 h=hashlib.sha256()
 with open(path,'rb') as f:
  for b in iter(lambda:f.read(1048576),b''):h.update(b)
 return h.hexdigest()

def sync_file(path):
 with open(path,'rb') as f:os.fsync(f.fileno())
 subprocess.check_call(['sync'])

def save(path,state):
 with open(path,'w') as f:json.dump(state,f)

def invoke(action,token,expected=None):
 if os.geteuid()!=0:raise RuntimeError('Connect as root on Xillinux')
 if len(token)!=32 or any(c not in '0123456789abcdef' for c in token):raise RuntimeError('Invalid deployment token')
 stage=STAGE_ROOT+'/.smartzynq-deploy-'+token
 statefile=stage+'/state.json'
 target=MOUNT+'/xillydemo.bit'
 old=stage+'/original.bit'
 new=stage+'/new.bit'
 if action=='prepare':
  try:os.mkdir(LOCK,0o700)
  except FileExistsError:raise RuntimeError('Deployment lock exists: '+LOCK+'; inspect it before retrying')
  try:
   with open(LOCK+'/owner','w') as f:f.write(token)
   os.mkdir(stage,0o700)
   s={'owned_mount':False,'phase':'preparing'};save(statefile,s)
   os.makedirs(MOUNT,exist_ok=True)
   r=subprocess.run(['findmnt','-rn','-M',MOUNT,'-o','SOURCE'],stdout=subprocess.PIPE)
   if r.returncode:
    subprocess.check_call(['mount',DEVICE,MOUNT]);s['owned_mount']=True;save(statefile,s)
   source=subprocess.check_output(['findmnt','-rn','-M',MOUNT,'-o','SOURCE']).decode().strip()
   if os.path.realpath(source)!=DEVICE:raise RuntimeError('Unexpected boot partition: '+source)
   if not os.path.isfile(target):raise RuntimeError('Existing xillydemo.bit not found; nothing will be replaced')
   before=digest(target)
   shutil.copyfile(target,old);sync_file(old)
   if digest(old)!=before or digest(target)!=before:raise RuntimeError('Boot image changed while backing up')
   s.update(phase='prepared',old_sha256=before,old_size=os.path.getsize(old));save(statefile,s)
   return s
  except BaseException:
   # Return mount/network state even when preparation fails.
   if os.path.exists(statefile):
    with open(statefile) as f:s=json.load(f)
    if s['owned_mount']:subprocess.check_call(['umount',MOUNT])
   if os.path.exists(LOCK+'/owner'):os.unlink(LOCK+'/owner')
   os.rmdir(LOCK)
   raise
 with open(LOCK+'/owner') as f:
  if f.read()!=token:raise RuntimeError('Deployment lock belongs to another operation')
 with open(statefile) as f:s=json.load(f)
 if action=='download':
  with open(old,'rb') as f:shutil.copyfileobj(f,sys.stdout.buffer)
  return None
 if action=='upload':
  with open(new,'wb') as f:shutil.copyfileobj(sys.stdin.buffer,f);f.flush();os.fsync(f.fileno())
  if digest(new)!=expected:raise RuntimeError('Uploaded image checksum mismatch')
  s.update(phase='uploaded',new_sha256=expected);save(statefile,s)
  return {'new_sha256':expected}
 if action=='install':
  if s['phase']!='uploaded' or digest(new)!=s['new_sha256']:raise RuntimeError('No verified upload')
  if digest(target)!=s['old_sha256']:raise RuntimeError('SD image changed since backup; refusing overwrite')
  free=shutil.disk_usage(MOUNT).free
  cluster=os.statvfs(MOUNT).f_frsize or os.statvfs(MOUNT).f_bsize
  allocated=lambda n:((n+cluster-1)//cluster)*cluster
  if free+allocated(os.path.getsize(target))<allocated(os.path.getsize(new)):
   raise RuntimeError('Not enough space on SD boot partition')
  s['phase']='installing';save(statefile,s)
  try:
   # Explicit unlink bypasses desktop Trash and releases the old FAT clusters.
   os.unlink(target)
   shutil.copyfile(new,target);sync_file(target)
   if digest(target)!=s['new_sha256']:raise RuntimeError('SD image checksum mismatch')
  except BaseException:
   try:
    if os.path.exists(target):os.unlink(target)
    shutil.copyfile(old,target);sync_file(target)
    if digest(target)!=s['old_sha256']:raise RuntimeError('Rollback checksum mismatch')
    s['phase']='rolled-back';save(statefile,s)
   except BaseException as e:
    s['phase']='rollback-failed';save(statefile,s)
    raise RuntimeError('ROLLBACK FAILED: %s; original is in %s'%(e,old))
   raise
  s['phase']='installed';save(statefile,s)
  return {'sha256':digest(target),'bytes':os.path.getsize(target)}
 if action=='finish':
  if s['phase'] in ('installing','rollback-failed'):
   raise RuntimeError('Uncertain SD state; retain lock and inspect '+stage)
  subprocess.check_call(['sync'])
  if s['owned_mount']:subprocess.check_call(['umount',MOUNT])
  os.unlink(LOCK+'/owner');os.rmdir(LOCK)
  # Retain the original and journal on the board as a second recovery copy.
  if os.path.exists(new):os.unlink(new)
  return {'board_backup':old,'phase':s['phase']}
 raise RuntimeError('Unknown action')

if __name__=='__main__':
 try:
  result=invoke(*sys.argv[1:])
  if result is not None:print(json.dumps(result))
 except Exception as e:
  print('ERROR: '+str(e),file=sys.stderr);sys.exit(1)
