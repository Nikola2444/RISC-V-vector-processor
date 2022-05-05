`ifndef RISCV_V_SEQ_PKG_SV
 `define RISCV_V_SEQ_PKG_SV
package riscv_v_seq_pkg;
   import uvm_pkg::*;      // import the UVM library
 `include "uvm_macros.svh" // Include the UVM macros
   import bd_instr_if_agent_pkg::bd_instr_if_seq_item;
   import bd_instr_if_agent_pkg::bd_instr_if_sequencer;
 `include "base_seq.sv"
 `include "bd_instr_if_seq.sv"
endpackage 
`endif
