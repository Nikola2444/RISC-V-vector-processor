#RISC-V-vector-processor-for-the-acceleration-of-Machine-learning-algorithms


## SIMULATION

To simulate the design in Vivado next .tcl script needs to be sourced to it.

  vivado_pjt/create_pjt.tcl

The easiest way to do this is to open Vivado GUI and source the script by
clicking tools -> Run Tcl Script

Script adds all files that are needed. Simulation needs some RISCV assembly code,
and the default one used by the verification environment is:

RISCV-GCC-compile-scripts/assembly.dump

If you want to generate you own assembly code RISCV-GCC compiler needs to be downloaded

##RISCV-GCC compiler

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







  