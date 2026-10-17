#!/usr/bin/env python
"""Matplotlib viewer for indexed 14-bit Xillybus snapshots; Python 2.7/3."""
from __future__ import print_function
import argparse,os,struct,signal,csv,math,time,sys

def acquire(device,count,timeout):
 def expired(signum,frame):raise RuntimeError('Capture timed out; check bitstream/driver and other readers')
 old=signal.signal(signal.SIGALRM,expired);signal.alarm(timeout);fd=None
 try:
  fd=os.open(device,os.O_RDONLY);raw=b''
  while len(raw)<count*4:
   b=os.read(fd,count*4-len(raw))
   if not b:raise RuntimeError('Short frame: %d of %d bytes'%(len(raw),count*4))
   raw+=b
  values=[]
  for i,w in enumerate(struct.unpack('<%dI'%count,raw)):
   if w>>16!=i:raise RuntimeError('Index mismatch at word %d: received %d'%(i,w>>16))
   v=w&65535;v=v-65536 if v&32768 else v
   if v < -8192 or v>8191:raise RuntimeError('Not a sign-extended 14-bit ADC frame')
   values.append(v)
  return values
 finally:
  if fd is not None:os.close(fd)
  signal.alarm(0);signal.signal(signal.SIGALRM,old)

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--device',default='/dev/xillybus_read_32')
 p.add_argument('--samples',type=int,default=4096)
 p.add_argument('--rate',type=float,default=64000000.,help='sample rate in Hz')
 p.add_argument('--timeout',type=int,default=10)
 p.add_argument('--interval',type=float,default=.5)
 p.add_argument('--wave-us',type=float,default=4.,help='waveform time span in microseconds')
 p.add_argument('--once',action='store_true',help='one frame; leave window open')
 p.add_argument('--save',help='save one PNG/PDF instead of opening a window')
 p.add_argument('--csv',help='plot an existing CSV instead of reading hardware')
 a=p.parse_args()
 if a.rate<=0 or a.samples<8 or a.samples>65536 or a.timeout<1 or a.interval<0 or a.wave_us<=0:p.error('Invalid capture parameters')
 import matplotlib
 if a.save:matplotlib.use('Agg')
 elif not os.environ.get('DISPLAY'):p.error('No graphical display: startx on HDMI, use DISPLAY=:0, or use --save')
 import numpy as np
 import matplotlib.pyplot as plt
 cached=None
 if a.csv:
  with open(a.csv) as f:rows=list(csv.DictReader(f))
  cached=[int(r['sample']) for r in rows]
  if len(cached)<8:raise RuntimeError('CSV must contain at least eight samples')
 fig,axes=plt.subplots(3,1,figsize=(10,8))
 fig.subplots_adjust(hspace=.65,top=.88,bottom=.07)
 try:fig.canvas.manager.set_window_title('Xillinux ADC monitor')
 except AttributeError:
  try:fig.canvas.set_window_title('Xillinux ADC monitor')
  except AttributeError:pass
 frames=0
 def render(values):
  y=np.asarray(values,dtype=float);n=len(y);mean=float(y.mean());ac=y-mean
  rms=float(np.sqrt(np.mean(ac*ac)));peak=float(np.max(np.abs(y)))
  peak_db=20*math.log10(peak/8192.) if peak else float('-inf')
  # RMS dBFS referenced to the RMS of a full-scale sine, excluding DC.
  rms_db=20*math.log10(rms/(8192./math.sqrt(2))) if rms else float('-inf')
  win=np.hanning(n);mag=2*np.abs(np.fft.rfft(ac*win))/sum(win)
  mag[0]/=2
  if n%2==0:mag[-1]/=2
  freq=np.fft.rfftfreq(n,1/a.rate)
  k=int(np.argmax(mag[1:]))+1 if rms else 0
  dominant=float(freq[k]) if rms else 0.
  rails=int(np.count_nonzero((y<=-8192)|(y>=8191)))
  for ax in axes:ax.clear();ax.grid(alpha=.25)
  limit=min(n,max(2,int(a.wave_us*1e-6*a.rate)))
  axes[0].plot(np.arange(limit)/a.rate*1e6,y[:limit],'.-',markersize=2,linewidth=.8)
  axes[0].set_title('Raw signed samples');axes[0].set_xlabel('Time (us)');axes[0].set_ylabel('ADC code');axes[0].set_ylim(-8500,8500)
  axes[1].plot(freq/1e6,20*np.log10(np.maximum(mag/8192.,1e-12)),linewidth=.8)
  axes[1].set_title('Spectrum: Hann window, DC removed');axes[1].set_xlabel('Frequency (MHz)');axes[1].set_ylabel('Peak dBFS');axes[1].set_xlim(0,a.rate/2e6);axes[1].set_ylim(-120,3)
  axes[2].barh([0,1],[100+max(-100,peak_db),100+max(-100,rms_db)],left=0,color=['steelblue','darkorange'])
  axes[2].set_yticks([0,1]);axes[2].set_yticklabels(['Peak','AC RMS']);axes[2].set_xlim(0,103)
  axes[2].set_xticks([0,20,40,60,80,100]);axes[2].set_xticklabels(['-100','-80','-60','-40','-20','0']);axes[2].set_xlabel('dBFS (RMS uses full-scale sine reference)')
  title='Frame %d | %d samples | %.3f MS/s | peak %.2f dBFS | AC RMS %.2f dBFS\nmin %d | max %d | DC %.2f | dominant bin %.3f MHz | rail codes %d'%(frames,n,a.rate/1e6,peak_db,rms_db,min(y),max(y),mean,dominant/1e6,rails)
  fig.suptitle(title,fontsize=10)
  print('Frame %d: min=%d max=%d DC=%.2f AC_RMS=%.2f peak=%.2f dBFS dominant=%.6f MHz rail_codes=%d'%(frames,min(y),max(y),mean,rms,peak_db,dominant/1e6,rails))
  sys.stdout.flush();fig.canvas.draw()
 if not a.save:plt.ion();plt.show()
 try:
  while a.save or plt.fignum_exists(fig.number):
   values=cached if cached is not None else acquire(a.device,a.samples,a.timeout)
   frames+=1;render(values)
   if a.save:fig.savefig(a.save,dpi=150);print('Saved '+a.save);break
   if a.once or cached is not None:plt.ioff();plt.show();break
   plt.pause(max(.01,a.interval))
 except KeyboardInterrupt:pass
 finally:plt.close(fig)
if __name__=='__main__':
 try:main()
 except (RuntimeError,IOError,ImportError) as e:
  print('ERROR: '+str(e),file=sys.stderr);sys.exit(1)
