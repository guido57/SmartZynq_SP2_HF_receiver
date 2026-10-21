#!/usr/bin/env python3
"""Design and measure the 8 ksample/s phasing-demodulator Hilbert FIR."""
import argparse,json
from pathlib import Path
import numpy as np
from scipy.signal import remez,freqz
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
h=-remez(127,[150,3850],[1],type='hilbert',fs=8000)
q=np.rint(h*131072).astype(np.int64)
assert np.array_equal(q,-q[::-1])
assert q.min()>=-131072 and q.max()<=131071
f,H=freqz(q/131072.0,worN=131072,fs=8000)
H*=np.exp(2j*np.pi*f*63/8000)
# Positive-frequency analytic input: Q=-j*I in frequency domain.
wanted=abs((1+1j*H)/2);image=abs((1-1j*H)/2)
reject=20*np.log10(np.maximum(image,1e-20)/np.maximum(wanted,1e-20))
band=(f>=200)&(f<=3000)
assert np.max(reject[band]) < -75
assert H[np.argmin(abs(f-1000))].imag < -.99
m=dict(taps=127,sample_rate=8000,group_delay_samples=63,group_delay_ms=7.875,usable_audio_hz=[200,3000],worst_ideal_image_db=float(np.max(reject[band])))
(a.output/'ssb_hilbert_8k.mem').write_text(''.join('%05x\n'%(int(x)&0x3ffff) for x in q))
(a.output/'response.json').write_text(json.dumps(m,indent=2)+'\n')
import matplotlib;matplotlib.use('Agg')
import matplotlib.pyplot as plt
fig,ax=plt.subplots(figsize=(9,4));ax.plot(f,reject);ax.set(xlim=(0,4000),ylim=(-120,0),xlabel='Audio frequency (Hz)',ylabel='Unwanted / wanted sideband (dB)');ax.grid();fig.tight_layout();fig.savefig(str(a.output/'sideband_rejection.png'),dpi=160);plt.close(fig)
print(json.dumps(m,indent=2))
