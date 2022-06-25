`ifndef CONFIGURATION_PKG_SV
 `define CONFIGURATION_PKG_SV

package configurations_pkg;

   import uvm_pkg::*;      // import the UVM library
  localparam DDR_DEPTH=4096;
  typedef logic [31:0] ddr_mem_type[DDR_DEPTH];
   int 		       use_s_instr_backdoor = 1;
   int 		       use_v_data_backdoor  = 1;
   int 		       use_s_data_backdoor  = 1;
 
 `include "uvm_macros.svh" // Include the UVM macros
    
 `include "config.sv"
   


endpackage : configurations_pkg

`endif

