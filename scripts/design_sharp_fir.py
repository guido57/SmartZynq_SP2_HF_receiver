#!/usr/bin/env python3
"""Generate Q1.17 FIR coefficients and verify the actual quantized response."""
from pathlib import Path
import argparse,json
import numpy as np
from scipy.signal import remez,freqz

def design():
    h=remez(255,[0,3000,4000,32000],[1,0],weight=[1,10],fs=64000)
    h/=h.sum()
    q=np.rint(h*131072).astype(np.int64)
    q[127]+=131072-int(q.sum())
    return q

def measure(q):
    f,H=freqz(q/131072.0,worN=262144,fs=64000)
    fir=np.abs(H)
    cic=np.ones_like(f)
    for fs in (64e6,6.4e6,640e3):
        cic*=np.abs(np.sinc(10*f/fs)/np.sinc(f/fs))**3
    combined=fir*cic
    db=lambda v:20*np.log10(np.maximum(v,1e-20))
    pb=f<=3000;sb=f>=4000
    # First descending -3 dB crossing, relative to DC.
    i=np.flatnonzero(db(combined)<=-3)[0]
    edge=float(np.interp(-3,db(combined)[i-1:i+1][::-1],f[i-1:i+1][::-1]))
    m=dict(taps=len(q),sample_rate=64000,decimation=8,coefficient_bits=18,
           coefficient_fraction_bits=17,dc_gain=float(q.sum()/131072.0),
           fir_passband_ripple_db=float(np.ptp(db(fir[pb]))),
           fir_stopband_worst_db=float(np.max(db(fir[sb]))),
           combined_passband_min_db=float(np.min(db(combined[pb]))),
           combined_passband_max_db=float(np.max(db(combined[pb]))),
           combined_minus3db_halfwidth_hz=edge,combined_minus3db_width_hz=2*edge,
           combined_at_5khz_db=float(np.interp(5000,f,db(combined))))
    assert m['fir_stopband_worst_db'] < -60
    assert m['fir_passband_ripple_db'] < .1
    assert np.array_equal(q,q[::-1]) and q.sum()==131072
    return f,db(fir),db(combined),m

def main():
    p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    a.output.mkdir(parents=True,exist_ok=True)
    q=design();f,fd,cd,m=measure(q)
    (a.output/'ddc_fir_sharp_64k.mem').write_text(''.join('%05x\n'%(int(x)&0x3ffff) for x in q))
    (a.output/'response.json').write_text(json.dumps(m,indent=2)+'\n')
    import matplotlib;matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig,ax=plt.subplots(figsize=(9,5));ax.plot(f/1000,fd,label='255-tap quantized FIR');ax.plot(f/1000,cd,label='CIC + FIR')
    ax.axvline(3,color='gray',ls=':');ax.axvline(4,color='gray',ls=':');ax.axhline(-60,color='gray',ls=':')
    ax.set(xlim=(0,12),ylim=(-120,2),xlabel='Offset from tuned frequency (kHz)',ylabel='Gain relative to DC (dB)');ax.grid();ax.legend();fig.tight_layout()
    fig.savefig(str(a.output/'response.png'),dpi=160);fig.savefig(str(a.output/'response.pdf'));plt.close(fig)
    print(json.dumps(m,indent=2))
if __name__=='__main__':main()
