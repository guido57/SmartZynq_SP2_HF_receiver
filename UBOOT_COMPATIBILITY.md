# Legacy U-Boot compatibility

The supplied U-Boot 2013.07 crashes while parsing Vivado 2026.1 bitstream metadata, before Linux. The new design-name field is 138 bytes, versus 43 in the vendor image. Upstream v2013.07 drivers/fpga/xilinx.c uses char buffer[80] and copies the field without a bound check. Crash register values match added metadata characters, strongly implicating stack overflow.

scripts/shorten_bit_header.py removes only SW_CRC and SW_HDR_SHA256 metadata from the design-name field and recomputes the field length. FPGA configuration payload is verified byte-for-byte identical. Original generated files are preserved.

Use build/legacy_compatible/reference-legacy.bit first, installed on SD as xillydemo.bit. Hardware validation is pending. If that boots successfully, test counter-legacy.bit and the counter checker. Future builds require running this conversion before installing on this legacy bootloader.

Upstream source: https://github.com/u-boot/u-boot/blob/v2013.07/drivers/fpga/xilinx.c
