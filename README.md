# Stage 2017

This repo will serve to host various projects that could be useful for developing research contributions.

## Active projects
### Félix
#### TestOverlay
A tentative AXI4 Full+Lite peripheral to communicate from the PS to the PL using the Pynq board.
Currently works with a combinatorial module, but not with a synchronous module (work in progress).
#### ConvUnit
A module that encapsulates a complete convolutional neural network. It includes fully customizable convolutional and pooling layers, as well as BRAM-style interlayers to hold data between layers. Currently tested to work with small datasets (3x3 input for example), still needs optimizations to achieve good performance with larger datasets such as MNIST. Also needs an interface for connecting to the AXI Interconnect of the Zynq SoC.
### Gabriel
### Ahmed
### Mehdi
## Completed projects
### Félix
#### LFSR RNG
A module that generates random 8-bit numbers using 32-bit LFSRs (Linear Feedback Shift Registers). The generated numbers can be capped to a maximum using an 8-bit input port.
This design is optimized for minimal area. It can safely operate at 300 MHz (target frequency), up to 440 MHz (after that, negative slack begins to appear).
### Gabriel
### Ahmed
### Mehdi
## Archived projects (or on hold)
### Félix
### Gabriel
### Ahmed
### Mehdi
