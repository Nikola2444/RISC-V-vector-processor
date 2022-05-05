`ifndef TEST_SIMPLE_2_SV
 `define TEST_SIMPLE_2_SV

class test_simple_2 extends test_base;

   `uvm_component_utils(test_simple_2)

   function new(string name = "test_simple_2", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      uvm_config_db#(uvm_object_wrapper)::set(this,
                                              "seqr.main_phase",
                                              "default_sequence",
                                              riscv_v_simple_seq::type_id::get());
   endfunction : build_phase

endclass

`endif
