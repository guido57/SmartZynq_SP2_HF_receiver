> The updated sharp-filter project is `build/bd_ddc_sharp/verilog/vivado/xillydemo.xpr`. It separates `DDC` (64 ksample/s CIC output) and `Channel_filter` (8 ksample/s I/Q). See [SHARP_FILTER.md](SHARP_FILTER.md). Stream packing below is unchanged.

# Visible DDC signal path

Open `build/bd_ddc_split_review/verilog/vivado/xillydemo.xpr`, then open
`vivado_system` and expand the `DDC_receiver` hierarchy.

`ADC_source_switch` supplies the selected signed 14-bit sample and its valid
strobe to `DDC`. The DDC produces signed `i_out[23:0]`, `q_out[23:0]` and
`output_valid`, connected by nets `ddc_i`, `ddc_q`, `ddc_valid` to
`Snapshot_buffer`. Raw ADC samples also connect directly to that buffer.
Configuration still changes only between complete snapshots. No demodulator
or continuous audio stream is added by this refactor.

## 32-bit stream layout

In IQ mode each pair occupies **two** successive 32-bit words:

| Word index | Value |
| --- | --- |
| 0 | sign-extended I[0] |
| 1 | sign-extended Q[0] |
| 2 | sign-extended I[1] |
| 3 | sign-extended Q[1] |

For each word, bits 23:0 hold the two's-complement sample and bits 31:24
repeat bit 23. For example, -1 becomes 0xffffffff; +1 is 0x00000001.
I and Q are not packed into two 16-bit halves. On the little-endian PS,
Python decodes with dtype='<i4', then reshapes to (-1,2): column 0 is I,
column 1 is Q. The standard frame is 4096 pairs, 8192 words, 32768 bytes.
Both components of a pair are captured on the same ddc_valid pulse at 8 kHz.

Raw mode uses one word per ADC sample: bits 31:16 contain its frame index,
and bits 15:0 contain the sign-extended 14-bit ADC value. A raw frame is
4096 words (16384 bytes).

`ddc_receiver_bd.sv` remains a composition wrapper for standalone regression;
the BD instantiates the same component modules separately inside its hierarchy.
The working implementation project and bitstreams have not been rebuilt.

## Simulate

In the split project, close any active simulation and run in the Vivado Tcl console:

```tcl
source /home/guido/Github/SmartZynq_SP2_Xillinux_reference/scripts/open_split_ddc_simulation.tcl
```

This selects `tb_ddc_receiver`, drives the clocks and ADC inputs, and runs
approximately 19 ms of simulation. The wrapper instantiates the same source
selector, DDC port wrapper and snapshot modules as the block design. It uses
32-pair snapshots for speed (hardware uses 4096). It does not simulate Linux,
PS software or proprietary Xillybus IP. The synthesis top stays `xillydemo`.
I/Q are at `/tb_ddc_receiver/dut/ddc/i_out` and `q_out`; their aliases
`/tb_ddc_receiver/dut/ddc_i` and `ddc_q` are preloaded into the wave window.
Select I and Q, choose Waveform Style > Analog and zoom to a few milliseconds.
For subsequent runs use Restart then Run All.
