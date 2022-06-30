# RISC-V-vector-processor-for-the-acceleration-of-Machine-learning-algorithms

## Project description

In the last ten years the emergence of highly advanced machine learning algorithms
and especially neural networks has caused major changes in many engineering disciplines.
For that reason we  wanted to create a piece of hardware that would be general enough
to execute various types of machine learning algorithms.
With the introduction of the vector extension to the RISC-V ISA, this option has become
even more interesting, because hard work of creating a meaningful set of instructions has
already been done in advance and additionally it gives engineers who want to work with it
more flexibility because of its open-source nature.

This project is a work in progress and in time it may be updated.

## Directories
* hdl - Contains hardware source files and also some simple test benches used to verify
         basic functionality of some modules.
* RISCV-GCC_compile-scripts - contains scripts used to compile RISCV assembly code.
                               Check sections COMPILE SCRIPTS for more information
* synth-Contains scripts which enable vivado synthesis and implementation of hardware
         from bash
* verif-Contains main source file used to create the verification environment
* vivado_pjt-Contains scripts used to create vivado project and add all hardware and verification files.
              Check section SIMULATION.
* Software - Contains assembly and .c examples
* Vitis_test_app - contains example software used for programming of Zedboard from Vitis.
* Scripts - .tcl files used for packaging of all the hardware files

	      
## SIMULATION

To simulate the design in Vivado next .tcl script needs to be sourced to it.

  vivado_pjt/create_pjt.tcl

The easiest way to do this is to open Vivado GUI and source the script by
clicking tools -> Run Tcl Script

Script adds all files that are needed. Simulation needs some RISCV assembly code,
and the default one used by the verification environment is:

RISCV-GCC-compile-scripts/assembly.dump

If you want to generate you own assembly code RISCV-GCC compiler needs to be downloaded

## RISCV-GCC compiler

Create installs dir:

```bash
mkdir installs
```

And in it clone the next repository:

```bash
cd installs

git clone https://github.com/riscv-collab/riscv-gnu-toolchain
```
Go into cloned directory and Folow the steps provided in its README file.

After everything has been installed you can go into RISCV-GCC-compile-scripts directory
rewrite assembly.s file (write your own assembly instructions) and compile them
with the next command:

```bash
make
```

The makefile will automaticaly compile everything and create assembly.dump file that
is used by the simulator







  