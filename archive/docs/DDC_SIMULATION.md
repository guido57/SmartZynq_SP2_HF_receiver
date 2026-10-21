> Updated RTL uses a 255-tap shared FIR. The current receiver test runs about 52 ms and compares the mixer/CIC against the original core; the changed FIR has a separate eight-channel, independent-convolution regression. See [SHARP_FILTER.md](SHARP_FILTER.md).

# Inspecting the receiver in Vivado simulation

The board top `xillydemo` is a synthesis top, with physical inputs and vendor blocks. The bundled Xillybus Lite IP lists synthesis/implementation EDIF views but no behavioral simulation view. Behavioral elaboration of the full board therefore reports `vivado_system_xillybus_lite_0_0 not found`. Regenerating the bitstream or changing LIBRARY_PATH does not supply that model.

Open `build/bd_ddc_build/xillydemo.xpr`. In the **Vivado Tcl Console**, run:

```tcl
source /home/guido/Github/SmartZynq_SP2_Xillinux_reference/scripts/open_ddc_simulation.tcl
```

Close any previous active simulation first. The script adds the testbench and original DDC reference to simulation sources, selects `tb_ddc_receiver`, launches behavioral simulation, sets up the waveform view and runs the complete regression (about 19 ms of simulated time). It leaves the wave window open. It changes simulation settings only; synthesis stays at `xillydemo` and no bitstream build is launched.

At the top of the waveform, expand **DDC output - 8 ksample/s I/Q**:

* `I`: `/tb_ddc_receiver/dut/ddc_i`.
* `Q`: `/tb_ddc_receiver/dut/ddc_q`.
* `sample_valid`: `/tb_ddc_receiver/dut/ddc_valid` (a one-clock strobe for each output pair).

I/Q are already set to **Signed Decimal**. Select I and Q, right-click **Waveform Style → Analog**, and use Zoom Fit, then zoom into a few milliseconds after the initial filter startup (for example 3–6 ms). At a 1 kHz output offset, one period is 1 ms with eight samples per period. This display method is documented in [AMD's analog waveform tutorial](https://docs.amd.com/r/en-US/2026.1/ug937-vivado-design-suite-simulation-tutorial/Step-3-Using-the-Analog-Wave-Viewer).

The `dut` instance is the `ddc_receiver_bd` RTL used by the BD's DDC_receiver module reference. Its `ddc` child is the pipelined DDC itself. This testbench substitutes clock/ADC/control/readout stimuli for the PS and Xillybus; it does not simulate Linux, the vendor DMA core or the complete board.

The testbench uses a 32-pair snapshot (AW=5) to keep the run short; hardware has 4096 pairs (AW=12). The DDC arithmetic, sampling and output rates are the same. The sequence tests external raw capture, a 1.001 MHz simulated carrier tuned at 1.000 MHz (+1 kHz), retuning to 1.002 MHz (-1 kHz), then moving the simulator to 1.003 MHz (+1 kHz). Initial output values include filter startup/transients.

Raw DDC I/Q amplitudes are approximately 3800 codes for the full-scale simulated carrier. The PS monitor applies mixer/CIC gain compensation, so its displayed input-referred amplitude is larger.

The waveform also contains source/configuration and stream-read signals. CIC stage signals are logged and can be added from `dut/ddc` later without rerunning. Avoid logging the RAM arrays unnecessarily.

Wave layout is saved as `build/ddc_receiver.wcfg`. Save that layout after changing to analog if you want Vivado to retain your display choices. Once the simulation top is configured, **Run Behavioral Simulation** starts at time zero; click **Run All** to execute the test. To restart the currently open simulation:

```tcl
restart
run all
```

For setup without launching, source `scripts/setup_ddc_simulation.tcl`. The standalone batch regression remains:

```bash
vivado -mode batch -source scripts/run_ddc_receiver_sim.tcl
```

Both entry points check a testbench completion flag and report an error if the regression stops before success. The GUI setup was validated using an isolated copy of the full hardware project with Vivado 2026.1: all regression checks passed and the synthesis top remained unchanged.
