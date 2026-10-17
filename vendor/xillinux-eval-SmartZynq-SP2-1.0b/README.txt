Xillinux demo bundle instructions
=================================

Xillinux is a complete, graphical, Lubuntu 16.04-based Linux distribution for
Zynq-7000 devices.

The files in this demo bundle are intended for Smart Zynq SP2  boards only , Specifically version V1.3.

Generation of bitstream
-----------------------

1. Unzip this demo bundle (if you can read this TXT document, it means
   you have completed this step).

2. Start Vivado 2018.3 (or a later version of Vivado).

3. After opening Vivado, select Tools > Run Tcl Script... from the upper
   menu bar. In the pop-up window, select the xillydemo-vivado.tcl file
   under the verilog/ directory inside the unzipped demo bundle. Vivado
   will automatically load the Tcl script and create a new Vivado project,
   which contains the source files and various settings required to
   generate the bitstream.

4. When "INFO: Project created: xillydemo" appears in the "Tcl Console"
   tab at the bottom of the Vivado window, it means that the project has
   been successfully created.

5. Then click "Generate Bitstream" to the bottom left in order to implement
   the project and generate the bitstream file. This process will take several
   minutes. There should be no errors or critical warnings.

6. After this process is completed, the newly generated bitstream file can
   be found as verilog/vivado/xillydemo.runs/impl_1/xillydemo.bit.

7. Please copy the xillydemo.bit file just generated to the first partition
   of the TF card (assuming that the Xillinux image has already been written
   to this TF card, before this step). In addition to xillydemo.bit, you also 
   need to copy the devicetree.dtb and boot.bin files in the bootfiles/
   directory to the first partition of the TF card.

The bootfiles/ directory contains xillydemo.bit, which can be used
instead of creating this file with Vivado. This ready-for-use file is
intended for those who are not interested in the FPGA part of Xillinux.

For more detailed instructions on how to prepare a TF card and lots of other
information, please visit this webpage:

http://www.hellofpga.com/index.php/2023/10/12/xillinux/

Other sources of information
----------------------------

1. Xillinux' official homepage: https://xillybus.com/xillinux

2. Getting Started Guide:
   https://xillybus.com/downloads/doc/xillybus_getting_started_zynq.pdf

3. Xillybus' documentation page: https://xillybus.com/doc
