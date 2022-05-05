`ifndef BD_INSTR_IF_SEQUENCER_SV
 `define BD_INSTR_IF_SEQUENCER_SV

class bd_instr_if_sequencer extends uvm_sequencer#(bd_instr_if_seq_item);

   `uvm_component_utils(bd_instr_if_sequencer)

   function new(string name = "bd_instr_if_sequencer", uvm_component parent = null);
      super.new(name,parent);
   endfunction

endclass : bd_instr_if_sequencer

`endif

