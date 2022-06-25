`ifndef AXI4_AGENT_PKG
 `define AXI4_AGENT_PKG


package AXI4_agent_pkg;
 
   import uvm_pkg::*;
   `include "uvm_macros.svh"

   //////////////////////////////////////////////////////////
   // include Agent components : driver,monitor,sequencer
   /////////////////////////////////////////////////////////
   import configurations_pkg::*;
     
   `include "AXI4_seq_item.sv"
   `include "AXI4_driver.sv"
   `include "AXI4_monitor.sv"
   `include "AXI4_agent.sv"

endpackage

`endif



