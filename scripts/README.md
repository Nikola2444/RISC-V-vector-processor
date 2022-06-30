# TCL Scripts
=============
## How to use
Open Vivado and source *main.tcl* script.


-------------
###Files
There are three present scripts in this directory:
1. riscv-v_package_ip.tcl
  This script creates a new Vivado project and packages
  all the source files into an IP core. After it's finished,
  under *release/RISCV_V_AXI_IP/* will be a new packaged IP.
2. riscv-v_bd_synth_impl_binary.tcl
  This script creates a new project and a block design.
  It instantiates the previously mentioned IP and connects it
  to the Zynq processing system.
3. main.tcl
  This script is used to source the previous two tcl scripts
  in the right order.

### Products
After sourcing each script, new directories will appear under:
1. result
  Used for saving files of created vivado projects.
2. relese
  Used for saving final products of running the scripts.
  i.e. packaged IP core for riscv-v_package_ip.tcl and 
  a bitstream file for riscv-v_bd_synth_impl_binary.tcl

## USE .XSA

If you dont want to go through these steps riscv_v_axi_bd_wrapper.xsa file can be used for
of the board.
