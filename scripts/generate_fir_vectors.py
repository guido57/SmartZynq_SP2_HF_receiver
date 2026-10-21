#!/usr/bin/env python3
"""Independent direct-convolution oracle for channel-tagged FIR RTL."""
from pathlib import Path
import argparse
import numpy as np
p=argparse.ArgumentParser();p.add_argument('output',type=Path);p.add_argument('coefficients',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
h=np.array([int(x,16) for x in a.coefficients.read_text().split()],dtype=np.int64);h=np.where(h>=131072,h-262144,h)
N=1100;channels=8;t=np.arange(N);rng=np.random.default_rng(20261020)
x=np.zeros((N,channels,2),dtype=np.int64)
x[:,1,0]=123456;x[:,1,1]=-654321;x[600,1,0]+=1000000
for ch,f,amp in [(2,1000,1000000),(3,5000,1000000),(5,2000,20000000),(7,-2000,345678)]:
 x[:,ch,0]=np.rint(amp*np.cos(2*np.pi*f*t/64000)).astype(np.int64)
 x[:,ch,1]=np.rint(amp*np.sin(2*np.pi*f*t/64000)).astype(np.int64)
x[:,4,:]=rng.integers(-(1<<30),1<<30,size=(N,2),dtype=np.int64)
x[:,6,:]=rng.integers(-2000000,2000000,size=(N,2),dtype=np.int64)
indices=np.arange(len(h)+7,N,8)
y=np.zeros((len(indices),channels,2),dtype=np.int64)
for ch in range(channels):
 for iq in range(2):
  # Full, causal convolution; coefficient zero multiplies newest sample.
  v=np.convolve(x[:,ch,iq],h)[:N]
  y[:,ch,iq]=np.clip(v[indices]>>17,-8388608,8388607)
for iq,label in enumerate(['i','q']):
 (a.output/('input_'+label+'.mem')).write_text(''.join('%08x\n'%(int(v)&0xffffffff) for v in x[:,:,iq].ravel()))
 (a.output/('expected_'+label+'.mem')).write_text(''.join('%06x\n'%(int(v)&0xffffff) for v in y[:,:,iq].T.ravel()))
print('Oracle:',len(indices),'outputs per channel;',len(indices)*channels,'total complex outputs')
