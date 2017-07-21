# Stage 2017
This repo hosts various HDL and Python projects that could be useful for developing research contributions related to neural networks.
## Active projects
### Félix
#### ConvUnit
A module that encapsulates a complete convolutional neural network. It includes fully customizable convolutional and pooling layers, as well as BRAM-style interlayers to hold data between layers. Still needs an interface for connecting to the AXI Interconnect of the Zynq SoC.
#### KeraGen
A Python library to convert FPGA hardware-compatible .nn files into trainable Keras models.
##### Current features
* S-Expression parser that converts .nn files to a tree-like data structure.
* Support for hardware-compatible FC (fully-connected) layers.
* Support for hardware-compatible Conv2D and MaxPooling layers.
* Support for the MNIST dataset, provided by Keras.
* Support for sigmoid and ReLU hardware-compatible activation functions.
* Support for software (Keras) dropout and softmax layers.
* Parametrizable training parameters such as batch size and number of epochs.
* Complete Keras-enabled python file creation and saving.
* Dynamic execution of native Keras training routine from the keragen.py script.
* Saving of weights and biases in .nn files once the model is trained.
* Dynamic .nn file fixed-point precision handling (from saved weights and biases).
##### Planned features
* Allow for more training parameters to be modified (optimizer, regularizers, etc.)
* Support for custom datasets.
* Handling more than one neural network per .nn file.
* Dynamic .nn file import handling (add saved weights and biases as imports).
* Implement as a real library, eventually a Python wheel.
### Gabriel

## Completed projects
### Félix
#### LFSR RNG
A module that generates random 8-bit numbers using 32-bit LFSRs (Linear Feedback Shift Registers). The generated numbers can be capped to a maximum using an 8-bit input port.
This design is optimized for minimal area. It can safely operate at 300 MHz (target frequency), up to 440 MHz (after that, negative slack begins to appear).
### Gabriel

## Archived projects (or on hold)
### Félix
#### TestOverlay
A tentative AXI4 Full+Lite peripheral to communicate from the PS to the PL using the Pynq board.
Currently works with a combinatorial module, but not with a synchronous module (work in progress).
### Gabriel
