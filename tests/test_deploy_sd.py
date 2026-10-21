import importlib.util,io,json,subprocess,tempfile,unittest
from pathlib import Path
from unittest.mock import patch

def module(name,path):
 spec=importlib.util.spec_from_file_location(name,str(path));m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
ROOT=Path(__file__).resolve().parent
if ROOT.name=='tests':ROOT=ROOT.parent/'scripts'
host=module('deploy',ROOT/'deploy_sd.py');remote=module('remote',ROOT/'sdboot_remote.py')
TOKEN='a'*32
class Tests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
  remote.MOUNT=str(self.root/'sdboot');Path(remote.MOUNT).mkdir()
  remote.LOCK=str(self.root/'lock');remote.STAGE_ROOT=str(self.root)
  self.target=Path(remote.MOUNT)/'xillydemo.bit';self.target.write_bytes(b'original')
  self.calls=[]
  def run(args,**kw):return subprocess.CompletedProcess(args,0,stdout=b'/dev/mmcblk0p1\n')
  self.patches=[patch.object(remote.os,'geteuid',return_value=0),patch.object(remote.subprocess,'run',side_effect=run),patch.object(remote.subprocess,'check_output',return_value=b'/dev/mmcblk0p1\n'),patch.object(remote.subprocess,'check_call',side_effect=lambda args:self.calls.append(args))]
  for p in self.patches:p.start()
 def tearDown(self):
  for p in reversed(self.patches):p.stop()
  self.temp.cleanup()
 def prepare_upload(self):
  state=remote.invoke('prepare',TOKEN)
  self.assertEqual(state['old_sha256'],host.sha(b'original'))
  with patch.object(remote.sys,'stdin',type('Input',(),{'buffer':io.BytesIO(b'new configuration')})()):
   remote.invoke('upload',TOKEN,host.sha(b'new configuration'))
 def test_install_and_backup(self):
  self.prepare_upload()
  with patch.object(remote.sys,'stdout',type('Output',(),{'buffer':io.BytesIO()})()) as out:
   remote.invoke('download',TOKEN);self.assertEqual(out.buffer.getvalue(),b'original')
  self.assertEqual(remote.invoke('install',TOKEN)['sha256'],host.sha(b'new configuration'))
  result=remote.invoke('finish',TOKEN)
  self.assertEqual(Path(result['board_backup']).read_bytes(),b'original')
  self.assertEqual(self.target.read_bytes(),b'new configuration')
  self.assertFalse(Path(remote.LOCK).exists())
  self.assertFalse(any(x[0]=='umount' for x in self.calls))
 def test_write_failure_rolls_back(self):
  self.prepare_upload();copy=remote.shutil.copyfile
  def faulty(src,dst):
   if str(src).endswith('/new.bit'):
    Path(dst).write_bytes(b'partial');raise OSError('injected write failure')
   return copy(src,dst)
  with patch.object(remote.shutil,'copyfile',side_effect=faulty):
   with self.assertRaises(OSError):remote.invoke('install',TOKEN)
  self.assertEqual(self.target.read_bytes(),b'original')
  remote.invoke('finish',TOKEN)
 def test_changed_original_refuses_delete(self):
  self.prepare_upload();self.target.write_bytes(b'changed outside app')
  with self.assertRaisesRegex(RuntimeError,'changed since backup'):remote.invoke('install',TOKEN)
  self.assertEqual(self.target.read_bytes(),b'changed outside app')
  remote.invoke('finish',TOKEN)
 def test_no_space_refuses_delete(self):
  self.prepare_upload()
  with patch.object(remote.shutil,'disk_usage',return_value=type('Usage',(),{'free':0})()),patch.object(remote.os,'statvfs',return_value=type('FS',(),{'f_frsize':1})()):
   with self.assertRaisesRegex(RuntimeError,'Not enough space'):remote.invoke('install',TOKEN)
  self.assertEqual(self.target.read_bytes(),b'original');remote.invoke('finish',TOKEN)
 def test_full_partition_can_reuse_existing_cluster(self):
  self.prepare_upload()
  with patch.object(remote.shutil,'disk_usage',return_value=type('Usage',(),{'free':0})()),patch.object(remote.os,'statvfs',return_value=type('FS',(),{'f_frsize':4096})()):
   remote.invoke('install',TOKEN)
  self.assertEqual(self.target.read_bytes(),b'new configuration')
  remote.invoke('finish',TOKEN)
 def test_owned_mount_is_unmounted(self):
  with patch.object(remote.subprocess,'run',return_value=subprocess.CompletedProcess([],1,stdout=b'')):
   remote.invoke('prepare',TOKEN)
  remote.invoke('finish',TOKEN)
  self.assertIn(['mount',remote.DEVICE,remote.MOUNT],self.calls)
  self.assertIn(['umount',remote.MOUNT],self.calls)
 def test_lock_refuses_second_deployment(self):
  remote.invoke('prepare',TOKEN)
  with self.assertRaisesRegex(RuntimeError,'lock exists'):remote.invoke('prepare','b'*32)
  remote.invoke('finish',TOKEN)
 def test_host_bad_download_never_installs(self):
  calls=[]
  def call(action,token,**kw):
   calls.append(action)
   if action=='prepare':return {'old_size':8,'old_sha256':host.sha(b'original')}
   if action=='download':return b'corrupt'
   if action=='finish':return {'board_backup':'/root/old.bit'}
  bit=self.root/'input.bit';bit.write_bytes(b'fixture')
  args=['deploy','board',str(bit),'--backup-dir',str(self.root/'backups')]
  with patch.object(host.sys,'argv',args),patch.object(host,'compatible_bitstream',return_value=b'valid bitstream'),patch.object(host.Connection,'run',side_effect=call):
   with self.assertRaisesRegex(RuntimeError,'backup verification failed'):host.main()
  self.assertEqual(calls,['prepare','download','finish'])
 def test_reject_invalid_image(self):
  with self.assertRaises(ValueError):host.compatible_bitstream(b'not a bitstream')

class SSHReuseTests(unittest.TestCase):
 def test_reuses_private_socket_and_closes_master(self):
  c=host.Connection('board',22,None)
  directory=Path(c.socket_dir.name)
  self.assertEqual(directory.stat().st_mode & 0o777,0o700)
  try:
   with patch.object(host.subprocess,'run',return_value=subprocess.CompletedProcess([],0,stdout=b'{}')) as run:
    c.run('prepare',TOKEN);c.run('finish',TOKEN)
    commands=[call[0][0] for call in run.call_args_list]
    for cmd in commands:
     self.assertIn('ControlMaster=auto',cmd)
     self.assertIn('ControlPath='+c.socket,cmd)
    Path(c.socket).touch()
    c.close()
    command=run.call_args_list[-1][0][0]
    self.assertEqual(command[-3:],['-O','exit','root@board'])
  finally:c.close()
  self.assertFalse(directory.exists())
 def test_failed_connection_still_cleans_socket_directory(self):
  c=host.Connection('board',22,None);directory=Path(c.socket_dir.name)
  try:
   with patch.object(host.subprocess,'run',return_value=subprocess.CompletedProcess([],255,stdout=b'')):
    with self.assertRaisesRegex(RuntimeError,'SSH action prepare failed'):c.run('prepare',TOKEN)
  finally:c.close()
  self.assertFalse(directory.exists())

if __name__=='__main__':unittest.main()
