# Supported project map

| Supported project | Origin of the current reviewed design | Purpose |
| --- | --- | --- |
| `board_test/` | `build/reference/vivado-essentials/` | Basic SmartZynq SP2 and Xillinux board test |
| `adc_simulator/` | `build/bd_adc/` | ADC simulator, external ADC path, and capture |
| `hf_ssb_receiver/` | `build/bd_ssb/` | Multichannel DDC, FIR, USB/LSB demodulation, and audio |

The generated implementation projects and bitstreams in `build/` are retained
temporarily as rollback artifacts. They can be removed after the three project
entry scripts have been redirected and verified.
