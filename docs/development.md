# Design and verification notes

The receiver front end is a 64 MS/s NCO mixer and CIC followed by a 255-tap shared FIR. Its measured combined -3 dB width is about 6.7 kHz. The USB/LSB stage uses a 127-tap Hilbert filter and provides approximately 68–71 dB fixed-point image suppression around a 1 kHz test tone.

The committed `hf_ssb_receiver` bitstream passed routed timing in Vivado 2026.1 with setup slack +0.232 ns and hold slack +0.024 ns. The current PS-upload version also passed focused XSim tests for all 79 FT8 symbols, frame timing, commit synchronization, acknowledgement, and message restart.

The design is presently one receiver channel. The shared FIR and SSB engines were separately evaluated for eight tagged channels, but an eight-DDC board image and eight simultaneous decoder streams have not been built.

Relevant simulations are in `sim/`, including `tb_ft8_ps_tones.sv` and `tb_ft8_ps_upload.sv`. Filter and SSB coefficient generators are in `scripts/`. Historical resource estimates and intermediate DDC work are preserved in `archive/docs/`.
