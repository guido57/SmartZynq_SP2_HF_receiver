# Documentation ownership

| Topic | Authoritative home |
| --- | --- |
| Board, RTL, Vivado setup, constraints, synthesis and PL simulation | This repository: README, project guides and development notes |
| Bitstream generation, SD deployment and Vivado JTAG programming | [Deployment](deployment.md), [JTAG](jtag-reconfiguration.md) |
| Device endpoints, registers, sample formats and rates | [PS–PL interface](ps_pl_interface.md) |
| Xillinux tools, decoder builds and receiver operation | [sz_hf_rx](https://github.com/guido57/sz_hf_rx) |
| Preliminary hardware/software transport validation | [hardware_validation.md](https://github.com/guido57/sz_hf_rx/blob/main/docs/hardware_validation.md) |
| Full simulated FT8 signal path and expected results | [integration_tests.md](https://github.com/guido57/sz_hf_rx/blob/main/docs/integration_tests.md) |

Tests that exercise both PS and PL live with the software that drives them.
They link to the required PL design and deployment procedure. Keep one current
procedure per test; link rather than copy commands into both repositories.
Historical experiment logs remain historical evidence, not current setup guides.

For each new test result, record both repository revisions, uncommitted changes,
PL project, exact programmed bitstream path and SHA-256, board revision, commands,
expected/actual results and generated artifacts. A repository revision alone
does not establish which bitstream is loaded. Do not retroactively assign a
bitstream hash to older observations when it was not recorded.
