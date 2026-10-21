# Reference build validation

Built successfully on 2026-10-08 with Vivado 2026.1 (SW build 6511674), using the original hardware-V1.3 bundle. HDL and pin constraints were unchanged. Vendor project generation upgraded the FIFO IP and migrated the block design in the build copy.

- Synthesis passed.
- Routing completed; all user-specified timing constraints met.
- Setup WNS: +0.240 ns; hold WHS: +0.036 ns; zero failing endpoints.
- Bitstream generation DRC: zero errors.
- No ERROR or CRITICAL WARNING messages in synthesis/implementation run logs.
- Ordinary vendor/migration warnings remain; see preserved logs and reports.
- Hardware validation of this rebuilt bitstream is pending.

The validated artifact and reports are under build/validated/. These generated files are ignored by Git. The build ran in a temporary working copy; create a fresh project using scripts/create_project.tcl in this repository for GUI work.
