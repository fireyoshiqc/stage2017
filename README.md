# Stage 2017
This repo hosts various HDL and Python projects that could be useful for developing research contributions related to neural networks.
## Active projects
### Félix

### Gabriel

## Completed projects
### Félix
#### ShiftNN
A module that implements the Programmable Logic (PL) part of the Multiplierless Overlay Architecture for DNNs on FPGA, proposed by Ahmed Abdelsalam. It is a fully functioning version, which allows for a maximum of ~1000 hidden shift-neurons and ~30 output classes. The single-layer neural network that is implemented in the _test_interface.v_ file is ready to be synthesized, implemented and made as a bitstream for any Xilinx FPGA. Network parameters can be changed on the fly by providing control signals to the module, dictating the desired number of active shift-neurons and output classes. The network is intended to be used in a Teacher-to-Student configuration, receiving pre-trained data from a software floating point network. This is described in the paper _A Single Hidden Layer Multiplierless Overlay Architecture for DNNs on FPGA_ by Ahmed Abdelsalam et al. For complete implementation and 100%-correct functionality, it should be used in conjunction with the AXI4 data interconnect described in the paper.
#### ConvUnit
A module that encapsulates a complete convolutional neural network. It includes fully customizable convolutional and pooling layers, as well as BRAM-style interlayers to hold data between layers. Still needs an interface for connecting to the AXI Interconnect of the Zynq SoC.
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
