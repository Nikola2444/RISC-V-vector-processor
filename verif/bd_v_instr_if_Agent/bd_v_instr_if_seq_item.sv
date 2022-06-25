`ifndef BD_V_INSTR_IF_SEQ_ITEM_SV
 `define BD_V_INSTR_IF_SEQ_ITEM_SV
`include "../defines.sv"
parameter DATA_WIDTH = 32;
parameter RESP_WIDTH = 2;
parameter CMD_WIDTH = 4;

class bd_v_instr_if_seq_item extends uvm_sequence_item;

   logic [31:0] v_instruction;
   logic [2:0] sew;
   logic [2:0] lmul;
   logic [31:0] vl;
   logic [31:0] scalar;
   logic [31:0] scalar2;
   logic [31:0] vrf_read_ram [`V_LANES][2][4][`VRF_DEPTH-1:0];

   `uvm_object_utils_begin(bd_v_instr_if_seq_item)
      `uvm_field_int(v_instruction, UVM_DEFAULT)
      `uvm_field_int(sew, UVM_DEFAULT)
      `uvm_field_int(lmul, UVM_DEFAULT)
      `uvm_field_int(scalar, UVM_DEFAULT)
      `uvm_field_int(vl, UVM_DEFAULT)
   `uvm_object_utils_end

   function new (string name = "bd_v_instr_if_seq_item");
      super.new(name);
   endfunction // new

endclass : bd_v_instr_if_seq_item

`endif
