`ifndef RISCV_V_TEST_PKG_SV
 `define RISCV_V_TEST_PKG_SV

package riscv_v_test_pkg;

   import uvm_pkg::*;      // import the UVM library   
 `include "uvm_macros.svh" // Include the UVM macros

   import bd_instr_if_agent_pkg::*;
   import riscv_v_seq_pkg::*;
   import configurations_pkg::*;   
`include "riscv_v_env.sv"   
`include "test_base.sv"
`include "test_simple.sv"
`include "test_simple_2.sv"


endpackage : riscv_v_test_pkg

`include "riscv_v_if.sv"
`include "backdoor_if.sv"

`endif

