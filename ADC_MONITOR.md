# PS-side Matplotlib ADC monitor

Python 2.7/3-compatible viewer for the existing simulated-ADC bitstream. Requires NumPy and Matplotlib; uses no additional hardware or bitstream changes. Upload scripts/adc_monitor.py to /root/adc_monitor.py on Xillinux.

## GUI on HDMI

From a terminal in the Xillinux graphical desktop:

    python /root/adc_monitor.py

If only the HDMI text console is running, start the desktop with startx first. From SSH, target the existing root-owned X session:

    DISPLAY=:0 python /root/adc_monitor.py

DISPLAY does not start an X server or grant access to one. If there is a display/authorization/backend error, run from the desktop terminal instead. Close the window or press Ctrl+C to stop. Each update captures a new finite frame; this is not a continuous oscilloscope acquisition. Do not run another Xillybus reader at the same time, and stop this program before jtag_lifecycle.py prepare.

## Headless / single capture

    python /root/adc_monitor.py --save /root/adc_monitor.png
    python /root/adc_monitor.py --once

PNG output works without DISPLAY or a desktop. --once captures one frame and leaves its GUI window open. The same program can plot a saved CSV:

    python /root/adc_monitor.py --csv /root/virtual_adc.csv --save /root/adc_monitor.png

## Measurements

Waveform: first 4 us by default, signed ADC codes; change --wave-us.
Spectrum: Hann window, DC removed, amplitude normalized by window sum and full-scale peak (8192 codes). DC and Nyquist use one-sided scaling corrections.
Levels: peak dBFS and AC-RMS dBFS. AC RMS uses full-scale sine RMS (8192/sqrt(2)) as its reference, so a full-scale sine is near 0 dBFS on both meters. DC mean, extrema, dominant FFT bin, and rail-code count are shown. Rail codes do not by themselves prove analog clipping, especially with the full-scale simulated sine. No volts are reported because analog gain/input span have not been calibrated.

Default sample rate 64 MS/s and frame size 4096 must match the current FPGA snapshot design. --rate changes time/frequency interpretation only; --samples changes the number requested, not FPGA behavior. Format: little-endian uint32, high 16 bits sample index, low 16 bits sign-extended 14-bit code. Other bitstreams/formats are not interchangeable.

## Validation

Tested locally against the real transferred virtual_adc.csv: 4096 samples, 1 MHz dominant FFT bin, extrema -8192/8191, AC RMS 5792.50 codes. PNG output visually inspected. Capture tests passed for signed decoding, index mismatch rejection, short frames and timeout during a blocked device open. On-board GUI and repeated live capture remain to be tested. Capture timeout defaults to 10 seconds. Errors stop the program rather than displaying a stale frame as current.
