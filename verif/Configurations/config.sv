class riscv_v_config extends uvm_object;

   uvm_active_passive_enum is_active = UVM_ACTIVE;
   int 		       use_s_instr_backdoor = 0;
   int 		       use_v_data_backdoor  = 0;
   int 		       use_s_data_backdoor  = 1;
   int                 instr_agent_active = use_s_instr_backdoor; 
   `uvm_object_utils_begin (riscv_v_config)
      `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
   `uvm_object_utils_end

   function new(string name = "riscv_v_config");
      super.new(name);
   endfunction

endclass : riscv_v_config
