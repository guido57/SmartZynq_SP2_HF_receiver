# PL counter stream

Build: source scripts/build_counter.tcl in Vivado, or run vivado -mode batch -source scripts/build_counter.tcl.
GUI project creation only: source scripts/prepare_counter.tcl.

Original vendor sources and build/reference are preserved. The counter build patches a separate copy of xillydemo.v and adds rtl/counter_stream.v. HDMI, PS, Ethernet, GPIO, 8-bit loopback and memory examples are retained.

The read_32 endpoint returns little-endian uint32 words 0,1,2,... with modulo-2^32 wrap. Closing the reader resets the counter on subsequent bus clocks. Only accepted read requests advance it; host pauses do not lose counts. This validates transfer integrity, not real-time sample capture or ADC overflow behavior.

write_32 is unused and permanently backpressured: do not run the old 32-bit loopback writer. read_8/write_8 remain a loopback.

Back up the working SD bitstream to the Linux root partition and your PC (the FAT boot partition has very little free space). Upload the new bitstream to /root, then copy over /mnt/sdboot/xillydemo.bit, compare, sync, unmount and reboot. Keep boot.bin, devicetree.dtb and uImage.

Upload scripts/check_counter.py to /root on the board and run:

    timeout 30 python /root/check_counter.py 1000000

Expect PASS for one million consecutive words starting at zero. Run again to verify reopening resets the stream. Ensure no other reader is using read_32. The timeout bounds a blocked transfer. Hardware validation is pending until these tests pass on the board.
