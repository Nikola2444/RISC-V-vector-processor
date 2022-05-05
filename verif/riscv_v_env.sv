`ifndef RISCV_V_ENV_SV
 `define RISCV_V_ENV_SV

class riscv_v_env extends uvm_env;

   bd_instr_if_agent agent;
   riscv_v_config cfg;
   virtual interface riscv_v_if vif;
   virtual interface backdoor_instr_if backdoor_instr_vif;
   `uvm_component_utils (riscv_v_env)

   function new(string name = "riscv_v_env", uvm_component parent = null);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      /************Geting from configuration database*******************/
      if (!uvm_config_db#(virtual riscv_v_if)::get(this, "", "riscv_v_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      if (!uvm_config_db#(virtual backdoor_instr_if)::get(this, "", "backdoor_instr_if", backdoor_instr_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      
      if(!uvm_config_db#(riscv_v_config)::get(this, "", "riscv_v_config", cfg))
        `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
      /*****************************************************************/


      /************Setting to configuration database********************/
      uvm_config_db#(riscv_v_config)::set(this, "agent", "riscv_v_config", cfg);
      uvm_config_db#(virtual riscv_v_if)::set(this, "agent", "riscv_v_if", vif);
      uvm_config_db#(virtual backdoor_instr_if)::set(this, "agent", "backdoor_instr_if", backdoor_instr_vif);
      /*****************************************************************/
      agent = bd_instr_if_agent::type_id::create("agent", this);
      
   endfunction : build_phase

endclass : riscv_v_env

`endif
