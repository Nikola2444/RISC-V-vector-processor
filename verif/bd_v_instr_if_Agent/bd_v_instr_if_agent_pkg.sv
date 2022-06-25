`ifndef BD_V_INSTR_IF_AGENT_PKG
`define BD_V_INSTR_IF_AGENT_PKG

package bd_v_instr_if_agent_pkg;
 
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // include Agent components : driver,monitor,sequencer
   /////////////////////////////////////////////////////////
   import configurations_pkg::*;   
   
   `include "bd_v_instr_if_seq_item.sv"
   `include "bd_v_instr_if_monitor.sv"
   `include "bd_v_instr_if_agent.sv"

endpackage

`endif



