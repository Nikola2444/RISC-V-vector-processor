`ifndef BD_INSTR_IF_SEQ_ITEM_SV
 `define BD_INSTR_IF_SEQ_ITEM_SV

parameter DATA_WIDTH = 32;
parameter RESP_WIDTH = 2;
parameter CMD_WIDTH = 4;

class bd_instr_if_seq_item extends uvm_sequence_item;

   logic [31:0] instruction;
   logic [31:0] instruction_addr;
   logic [31:0] store_data;
   logic [0:31][31:0] scalar_reg_bank_new;
   logic [0:31][31:0] scalar_reg_bank_old;

   `uvm_object_utils_begin(bd_instr_if_seq_item)
      `uvm_field_int(instruction, UVM_DEFAULT)
      `uvm_field_int(instruction_addr, UVM_DEFAULT)
      `uvm_field_int(scalar_reg_bank_old, UVM_DEFAULT)
      `uvm_field_int(scalar_reg_bank_new, UVM_DEFAULT)
      `uvm_field_int(store_data, UVM_DEFAULT)
   `uvm_object_utils_end

   function new (string name = "bd_instr_if_seq_item");
      super.new(name);
   endfunction // new

endclass : bd_instr_if_seq_item

`endif
