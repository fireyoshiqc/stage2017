# Stage 2017
This repo hosts various HDL and Python projects that could be useful for developing research contributions related to neural networks.
## Active projects
### Félix
#### ConvUnit
A module that encapsulates a complete convolutional neural network. It includes fully customizable convolutional and pooling layers, as well as BRAM-style interlayers to hold data between layers. Still needs an interface for connecting to the AXI Interconnect of the Zynq SoC.

### Gabriel

## Completed projects
### Félix
#### LFSR RNG
A module that generates random 8-bit numbers using 32-bit LFSRs (Linear Feedback Shift Registers). The generated numbers can be capped to a maximum using an 8-bit input port.
This design is optimized for minimal area. It can safely operate at 300 MHz (target frequency), up to 440 MHz (after that, negative slack begins to appear).
### Gabriel
#### nnet
A project containing a parametrizable fixed-point VHDL implementation of a fully connected neural network layer, plus interlayers to pass data between fc layers. Also, an implementation of the sigmoid activation function based on linear interpolation between function samples from a ROM.
#### codegen
A format (.nn files) for specifying nnet networks at a high level, plus a program (written in C++, compilable as a library or a command line tool) for converting .nn files to VHDL code that instantiates and connects the needed nnet modules.
#### test_oled
A mechanism for initializing and displaying up to 256 4x4 characters to the ZedBoard's OLED screen.

## Archived projects (or on hold)
### Félix
#### TestOverlay
A tentative AXI4 Full+Lite peripheral to communicate from the PS to the PL using the Pynq board.
Currently works with a combinatorial module, but not with a synchronous module (work in progress).
### Gabriel
#### nnet (fcbin_layer)
Binarized version of ordinary fc layers (works, but not tested with a real trained binarized network).
#### nnet (gpio_portal)
A mechanism to communicate inputs and outputs between the ZedBoard's PS and PL (seemed to work, but on hold due to other factors).