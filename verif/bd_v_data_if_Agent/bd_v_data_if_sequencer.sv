`ifndef BD_V_DATA_IF_SEQUENCER_SV
 `define BD_V_DATA_IF_SEQUENCER_SV

class bd_v_data_if_sequencer extends uvm_sequencer#(bd_v_data_if_seq_item);

   `uvm_component_utils(bd_v_data_if_sequencer)

   function new(string name = "bd_v_data_if_sequencer", uvm_component parent = null);
      super.new(name,parent);
   endfunction

endclass : bd_v_data_if_sequencer

`endif

