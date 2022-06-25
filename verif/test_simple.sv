`ifndef TEST_SIMPLE_SV
 `define TEST_SIMPLE_SV

class test_simple extends test_base;

   `uvm_component_utils(test_simple)

   riscv_v_simple_seq simple_seq;

   function new(string name = "test_simple", uvm_component parent = null);
      super.new(name,parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      simple_seq = riscv_v_simple_seq::type_id::create("simple_seq");
   endfunction : build_phase

   task main_phase(uvm_phase phase);
      if (cfg.use_s_instr_backdoor)
      begin
	 //phase.raise_objection(this);
	 simple_seq.start(env.bd_instr_agent.seqr);
	 //phase.drop_objection(this);
      end            
   endtask : main_phase

endclass

`endif
