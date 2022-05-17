`ifndef RISCV_V_ENV_SV
 `define RISCV_V_ENV_SV

class riscv_v_env extends uvm_env;

   bd_instr_if_agent bd_instr_agent;
   AXI4_agent axi4_agent;
   riscv_v_config cfg;
   virtual interface axi4_if vif;
   virtual interface backdoor_instr_if backdoor_instr_vif;
   virtual interface backdoor_register_bank_if backdoor_register_bank_vif;
   virtual interface backdoor_sc_data_if backdoor_sc_data_vif;
   `uvm_component_utils (riscv_v_env)

   function new(string name = "riscv_v_env", uvm_component parent = null);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      /************Geting from configuration database*******************/
      if (!uvm_config_db#(virtual axi4_if)::get(this, "", "axi4_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      if (!uvm_config_db#(virtual backdoor_instr_if)::get(this, "", "backdoor_instr_if", backdoor_instr_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      if (!uvm_config_db#(virtual backdoor_sc_data_if)::get(this, "", "backdoor_sc_data_if", backdoor_sc_data_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      if (!uvm_config_db#(virtual backdoor_register_bank_if)::get(this, "", "backdoor_register_bank_if", backdoor_register_bank_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      
      if(!uvm_config_db#(riscv_v_config)::get(this, "", "riscv_v_config", cfg))
        `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
      /*****************************************************************/      

      /************Setting to configuration database********************/
      uvm_config_db#(riscv_v_config)::set(this, "*", "riscv_v_config", cfg);
      uvm_config_db#(virtual axi4_if)::set(this, "axi4_agent", "axi4_if", vif);
      uvm_config_db#(virtual backdoor_instr_if)::set(this, "bd_instr_agent", "backdoor_instr_if", backdoor_instr_vif);
      uvm_config_db#(virtual backdoor_sc_data_if)::set(this, "bd_instr_agent", "backdoor_sc_data_if", backdoor_sc_data_vif);
      uvm_config_db#(virtual backdoor_register_bank_if)::set(this, "bd_instr_agent", "backdoor_register_bank_if", backdoor_register_bank_vif);
      /*****************************************************************/
      bd_instr_agent = bd_instr_if_agent::type_id::create("bd_instr_agent", this);
      axi4_agent     = AXI4_agent::type_id::create("axi4_agent", this);

   endfunction : build_phase

endclass : riscv_v_env

`endif
