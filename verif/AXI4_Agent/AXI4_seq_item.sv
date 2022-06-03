`ifndef AXI4_SEQ_ITEM_SV
 `define AXI4_SEQ_ITEM_SV

parameter DATA_WIDTH = 32;
parameter RESP_WIDTH = 2;
parameter CMD_WIDTH = 4;

class AXI4_seq_item extends uvm_sequence_item;

   logic [31:0] instruction;
   logic [31:0] instruction_addr;

   `uvm_object_utils_begin(AXI4_seq_item)
      `uvm_field_int(instruction, UVM_DEFAULT)
      `uvm_field_int(instruction_addr, UVM_DEFAULT)
   `uvm_object_utils_end

   function new (string name = "AXI4_seq_item");
      super.new(name);
   endfunction // new

endclass : AXI4_seq_item

`endif
