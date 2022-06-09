`ifndef BD_V_DATA_IF_SEQ_ITEM_SV
 `define BD_V_DATA_IF_SEQ_ITEM_SV

parameter DATA_WIDTH = 32;
parameter RESP_WIDTH = 2;
parameter CMD_WIDTH = 4;

class bd_v_data_if_seq_item extends uvm_sequence_item;

   logic [31:0] instruction;
   logic [31:0] instruction_addr;

   `uvm_object_utils_begin(bd_v_data_if_seq_item)
      `uvm_field_int(instruction, UVM_DEFAULT)
      `uvm_field_int(instruction_addr, UVM_DEFAULT)
   `uvm_object_utils_end

   function new (string name = "bd_v_data_if_seq_item");
      super.new(name);
   endfunction // new

endclass : bd_v_data_if_seq_item

`endif
