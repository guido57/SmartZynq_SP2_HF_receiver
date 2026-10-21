#!/usr/bin/env python3
"""Independent causal-convolution oracle, not a copy of the RTL scheduler."""
import argparse
from pathlib import Path
import numpy as np
p=argparse.ArgumentParser();p.add_argument('output',type=Path);p.add_argument('coefficients',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
h=np.array([int(v,16) for v in a.coefficients.read_text().split()],dtype=np.int64);h=np.where(h>=131072,h-262144,h)
N=450;C=8;t=np.arange(N);x=np.zeros((N,C,2),dtype=np.int64);rng=np.random.default_rng(20261021)
for ch,f,amp in [(1,1000,1000000),(2,-1000,1000000),(3,200,1000000),(4,-3000,1000000),(7,1500,7000000)]:
 x[:,ch,0]=np.rint(amp*np.cos(2*np.pi*f*t/8000)).astype(np.int64);x[:,ch,1]=np.rint(amp*np.sin(2*np.pi*f*t/8000)).astype(np.int64)
x[:,5,:]=rng.integers(-8388608,8388608,size=(N,2),dtype=np.int64)
x[:,6,0]=7654321;x[:,6,1]=-4321234
idx=np.arange(127,N);u=np.empty((len(idx),C),dtype=np.int64);l=u.copy()
for ch in range(C):
 hq=np.convolve(x[:,ch,1],h)[:N]>>17;di=x[idx-63,ch,0]
 u[:,ch]=np.clip((di-hq[idx])>>1,-8388608,8388607);l[:,ch]=np.clip((di+hq[idx])>>1,-8388608,8388607)
for array,name,bits in [(x[:,:,0],'input_i',24),(x[:,:,1],'input_q',24),(u.T,'expected_usb',24),(l.T,'expected_lsb',24)]:
 (a.output/(name+'.mem')).write_text(''.join('%06x\n'%(int(v)&0xffffff) for v in array.ravel()))
for ch,selected in [(1,u),(2,l),(3,u),(4,l)]:
 rejected=l if selected is u else u
 rms=lambda v:float(np.sqrt(np.mean(v.astype(float)**2)))
 db=20*np.log10(max(rms(rejected[:,ch]),1e-20)/rms(selected[:,ch]));assert db<-70
 print('Channel',ch,'image rejection',db,'dB')
print('Oracle:',len(idx)*C,'USB/LSB output pairs')
