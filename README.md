# SmartZynq SP2 Xillinux reference rebuild

Separate repository for rebuilding the unchanged HelloFPGA SP2 hardware V1.3 reference before adding custom logic. The supplied reference works on the user's V1.3B board; the rebuilt design still requires hardware validation.

Source: http://www.hellofpga.com/wp-content/uploads/2023/10/xillinux-eval-SmartZynq-SP2-1.0b-hw1.3.zip
Instructions: http://www.hellofpga.com/index.php/2023/10/17/xillinux-demo-bundle/

The original bundle is preserved under vendor/. Its prebuilt bitstream was generated with Vivado 2018.3 on 2024-09-06. No HDL or pin mapping changes are intended. Vendor files include third-party cores; this repository is local and has not been published. Upstream licensing applies.

## Build with Vivado 2026.1

From this repository:

```bash
source /tools/AMDDesignTools2026.1/2026.1/Vivado/settings64.sh
vivado -mode batch -source scripts/build.tcl
```

The build copies the vendor bundle into build/reference, then invokes its project-generation script. The upstream script upgrades IP and may modify the block design in that working copy. Use a fresh build directory for a repeat build.

Output: build/reference/verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit

## Open in the Vivado GUI

For a fresh GUI project, choose Tools > Run Tcl Script and select scripts/create_project.tcl. If a build already exists, open build/reference/verilog/vivado/xillydemo.xpr instead.

## Test on the SD card

Back up the working SD-card xillydemo.bit on the host. Replace only the SD boot partition's xillydemo.bit with the rebuilt file; retain boot.bin, devicetree.dtb and uImage. Safely eject, select SD boot and power-cycle. Check HDMI, Ethernet, SSH, LED2 control and both Xillybus loopbacks. Do not program QSPI for this test. If boot fails, restore the original prebuilt bitstream.

A rebuild need not match the original bytes. Build success alone does not establish hardware compatibility. See BUILD_STATUS.md for actual validation.
