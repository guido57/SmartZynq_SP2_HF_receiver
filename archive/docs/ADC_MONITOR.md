# PS-side Matplotlib ADC monitor

For the new **64 MS/s external ADC + tunable DDC** project, follow [DDC_RECEIVER.md](DDC_RECEIVER.md). The instructions below describe the legacy selectable ADC bitstream with its 8 MS/s external source. The updated monitor auto-detects either protocol.

Python 3.5+ monitor for the selectable physical/simulated ADC bitstream. Requires NumPy and Matplotlib, including a working graphical backend for the live window. Upload scripts/adc_monitor.py and scripts/receiver_control.py to /root/ on Xillinux. adc_source.py is not required by the monitor.

Start the Xillinux GUI with startx, then run from a desktop terminal:

    python3 /root/adc_monitor.py

Or target the running GUI from SSH:

    DISPLAY=:0 python3 /root/adc_monitor.py

Two radio buttons at the bottom select Simulated ADC or External ADC. Startup reads the current source without changing it. Each button request is applied between captures, after the previous Xillybus descriptor is closed. Readback is verified before another frame is acquired. Sample rate, waveform time axis, FFT frequency axis and title automatically follow the source: simulated 64 MS/s, external 8 MS/s. The title labels the source of the displayed frame; status text shows a queued switch. No FPGA rebuild or restart is needed.

Optional initial source:

    DISPLAY=:0 python3 /root/adc_monitor.py --source external
    DISPLAY=:0 python3 /root/adc_monitor.py --source simulated

Control uses byte 0, bit 0 of /dev/xillybus_mem_8. Override with --control-device if needed. This requires the selectable ADC bitstream, with the external offset-binary conversion already in the FPGA. The monitor performs no additional data-format conversion. It assumes no other application changes the source while it is running.

For older simulator-only bitstreams without source control:

    DISPLAY=:0 python3 /root/adc_monitor.py --no-source-control --rate 64000000

With live source control enabled, omit --rate: it follows the source automatically. An explicitly supplied initial --rate must match the source setting. A button selection subsequently updates it automatically.

Each update is a fresh finite 4096-sample snapshot, not a gap-free recording. Close the window or press Ctrl+C to stop. Stop the monitor before PL reconfiguration, and avoid other Xillybus readers.

## Headless / saved-data operation

    python3 /root/adc_monitor.py --source external --save /root/adc_monitor.png
    python3 /root/adc_monitor.py --once
    python3 /root/adc_monitor.py --csv /root/virtual_adc.csv --rate 64000000 --save /root/adc_monitor.png

--save captures one frame and creates a PNG/PDF without a GUI. --once leaves a single captured frame in a window. These static modes have no interactive selector. CSV playback never accesses hardware and uses --rate for its axis scaling (default 64 MS/s). CSV titles explicitly say playback.

## Measurements

Waveform shows the first 4 us by default; change --wave-us. Spectrum uses a Hann window, DC removal and one-sided amplitude normalization. Peak dBFS is relative to 8192 codes; AC RMS dBFS uses a full-scale sine RMS reference of 8192/sqrt(2). DC, min/max, dominant FFT bin and extreme-code count are displayed. Extreme-code counts do not by themselves prove analog clipping. Volts are not reported because analog gain/input span have not been calibrated.

4096 words represent 64 us in simulated mode or 512 us in external mode. Wire format remains little-endian uint32: high 16 bits sample index, low 16 bits sign-extended 14-bit sample. --samples changes the requested count, not FPGA capture length. Acquisition and source control have a default 10-second timeout. Errors stop acquisition rather than labelling stale data as a current frame.

## Validation

Four local tests check deferred switching, rejection of a failed switch, real Matplotlib radio-button events in both directions with matching acquisition rates, and CSV plotting without hardware access. The GUI layout was rendered and visually inspected. Python 3.5 syntax checked. Radio-button interaction on the board remains to be verified; the previous monitor and PS source helper have been tested on Xillinux.

## Responsive live controls

The live monitor runs device configuration and capture in a separate process. The GUI services events approximately every 30 ms while waiting; one frame can be in flight, and settings are applied after its descriptor closes. The frame title continues to describe the data actually displayed, even if a newer selection is queued. The process retains signal-based I/O timeouts and is stopped when the window closes.

Plot lines and level bars are reused. On TkAgg, blitting updates the changing artists; axes and tick labels are rebuilt only for a mode/rate change or resize. Other backends fall back to normal drawing. No FPGA rebuild or new Python dependency is required. Copy the updated scripts/adc_monitor.py from the PC and restart the monitor.

Buttons can respond before a new frame is available: 4096 I/Q pairs still require about 0.52 seconds of acquisition, and a requested setting waits for the current frame to close. `--interval` controls the pause between capture requests, not GUI event handling. An exactly silent frame shows “No signal” instead of reporting the first FFT bin (-4 kHz).

Regression tests:

    python3 -B -m unittest discover -s tests -p 'test_*monitor*.py'
    python3 -B -m unittest discover -s tests -p test_receiver_control.py
    xvfb-run -a python3 -B tests/check_monitor_tk.py

The Tk test clicks the frequency button while a deliberately delayed capture is in progress, verifies the dialog callback runs before the first frame completes, checks source/frequency changes on the next frame, and closes during capture without leaving a worker running. Target-board responsiveness still needs confirmation.

## PL USB/LSB modes

The marker-0xd3 SSB image adds USB audio and LSB audio radio selections and
`--mode usb|lsb`, with 8 kHz mono waveform/spectrum plots. Updated controls
retain marker-0xd2 raw/IQ compatibility. See [SSB_RECEIVER.md](SSB_RECEIVER.md)
for continuous PCM16 capture/listening and the separate board bitstream.
