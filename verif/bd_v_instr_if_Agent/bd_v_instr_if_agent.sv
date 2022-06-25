`ifndef BD_V_INSTR_IF_AGENT
`define BD_V_INSTR_IF_AGENT
class bd_v_instr_if_agent extends uvm_agent;

   // components
   
   bd_v_instr_if_monitor mon;
   
   virtual interface backdoor_v_instr_if backdoor_v_instr_vif;

   // configuration
   riscv_v_config cfg;
   int value;   
   `uvm_component_utils_begin (bd_v_instr_if_agent)
      `uvm_field_object(cfg, UVM_DEFAULT)
   `uvm_component_utils_end

   function new(string name = "bd_v_instr_if_agent", uvm_component parent = null);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      /************Geting from configuration database*******************/
      if (!uvm_config_db#(virtual backdoor_v_instr_if)::get(this, "", "backdoor_v_instr_if", backdoor_v_instr_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})      

      if(!uvm_config_db#(riscv_v_config)::get(this, "", "riscv_v_config", cfg))
        `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
      
      /*****************************************************************/
      
      /************Setting to configuration database********************/
      uvm_config_db#(virtual backdoor_v_instr_if)::set(this, "*", "backdoor_v_instr_if", backdoor_v_instr_vif);

      /*****************************************************************/
      
      mon = bd_v_instr_if_monitor::type_id::create("mon", this);      
   endfunction : build_phase

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

   endfunction : connect_phase

endclass : bd_v_instr_if_agent
`endif
