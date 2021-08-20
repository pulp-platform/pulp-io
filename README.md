This module is meant to contain all the pulp IP that communicates with the external world and need to be connected to IO pads.

It contains the old udma_subsystem IP and the new pulp_gpio IP.

There is a pre-defined set of peripheral that can be instantiated in a parametric fashion. The udma_subsystem configuration can be changed by modifying the `udma_cfg_pkg.sv` package to instantiated the desired peripherals.

Note: hyperBus is a timing critical peripheral that often need to take into account IO pad delays during STA. For this purpose, this peripheral can be either instantiated as udma_subsystem peripheral, or implemented as a hard macro and simply connected to the io subsystem. In this case, by specifying the `-t hyper_external` bender target, the udma_subsystem will instantiate a hyper_macro_bridge that exposes the dedicated internal hyperBus udma channel as a module port. The channel connections can then be propagated to where the hard macro is physically instantiated in the design.