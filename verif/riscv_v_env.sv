`ifndef RISCV_V_ENV_SV
 `define RISCV_V_ENV_SV

class riscv_v_env extends uvm_env;

   bd_instr_if_agent bd_instr_agent;
   bd_v_instr_if_agent bd_v_instr_agent;
   bd_v_data_if_agent bd_v_data_agent;
   AXI4_agent v_axi4_agent;
   AXI4_agent s_axi4_agent;
   riscv_v_config cfg;
   riscv_sc_scoreboard sc_scbd;
   riscv_v_scoreboard v_scbd;
   virtual interface axi4_if v_axi4_vif;
   virtual interface axi4_if s_axi4_vif;
   virtual interface backdoor_instr_if backdoor_instr_vif;
   virtual interface backdoor_v_instr_if backdoor_v_instr_vif;
   virtual interface backdoor_register_bank_if backdoor_register_bank_vif;
   virtual interface backdoor_sc_data_if backdoor_sc_data_vif;
   virtual interface backdoor_v_data_if backdoor_v_data_vif;
   `uvm_component_utils (riscv_v_env)

   function new(string name = "riscv_v_env", uvm_component parent = null);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      /************Geting from configuration database*******************/
      if (!uvm_config_db#(virtual axi4_if)::get(this, "", "v_axi4_if", v_axi4_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".v_axi4_vif"})
      if (!uvm_config_db#(virtual axi4_if)::get(this, "", "s_axi4_if", s_axi4_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".s_axi4_vif"})
      if (!uvm_config_db#(virtual backdoor_instr_if)::get(this, "", "backdoor_instr_if", backdoor_instr_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".backdoor_instr_vif"})
      if (!uvm_config_db#(virtual backdoor_v_instr_if)::get(this, "", "backdoor_v_instr_if", backdoor_v_instr_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".backdoor_instr_vif"})

      if (!uvm_config_db#(virtual backdoor_sc_data_if)::get(this, "", "backdoor_sc_data_if", backdoor_sc_data_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".backdoor_sc_data_vif"})
      if (!uvm_config_db#(virtual backdoor_register_bank_if)::get(this, "", "backdoor_register_bank_if", backdoor_register_bank_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".backdoor_register_bank_vif"})
      if (!uvm_config_db#(virtual backdoor_v_data_if)::get(this, "", "backdoor_v_data_if", backdoor_v_data_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".backdoor_v_data_vif"})
      
      if(!uvm_config_db#(riscv_v_config)::get(this, "", "riscv_v_config", cfg))
        `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
      /*****************************************************************/      

      /************Setting to configuration database********************/
      uvm_config_db#(riscv_v_config)::set(this, "*", "riscv_v_config", cfg);
      uvm_config_db#(virtual axi4_if)::set(this, "v_axi4_agent", "axi4_if", v_axi4_vif);
      uvm_config_db#(virtual axi4_if)::set(this, "v_scbd", "v_axi4_if", v_axi4_vif);
      uvm_config_db#(virtual axi4_if)::set(this, "s_axi4_agent", "axi4_if", s_axi4_vif);
      uvm_config_db#(virtual backdoor_instr_if)::set(this, "bd_instr_agent", "backdoor_instr_if", backdoor_instr_vif);
      uvm_config_db#(virtual backdoor_v_instr_if)::set(this, "bd_v_instr_agent", "backdoor_v_instr_if", backdoor_v_instr_vif);
      uvm_config_db#(virtual backdoor_v_instr_if)::set(this, "v_scbd", "backdoor_v_instr_if", backdoor_v_instr_vif);
      uvm_config_db#(virtual backdoor_sc_data_if)::set(this, "bd_instr_agent", "backdoor_sc_data_if", backdoor_sc_data_vif);
      uvm_config_db#(virtual backdoor_register_bank_if)::set(this, "bd_instr_agent", "backdoor_register_bank_if", backdoor_register_bank_vif);
      uvm_config_db#(virtual backdoor_v_data_if)::set(this, "bd_v_data_agent", "backdoor_v_data_if", backdoor_v_data_vif);
      /*****************************************************************/
      
      bd_instr_agent   =   bd_instr_if_agent::type_id::create("bd_instr_agent", this);
      bd_v_instr_agent   =   bd_v_instr_if_agent::type_id::create("bd_v_instr_agent", this);      
      s_axi4_agent     = AXI4_agent::type_id::create("s_axi4_agent", this);
      //if (cfg.use_v_data_backdoor==1)	
	//bd_v_data_agent  =   bd_v_data_if_agent::type_id::create("bd_v_data_agent", this);	
      //else
      v_axi4_agent     = AXI4_agent::type_id::create("v_axi4_agent", this);	

      sc_scbd = riscv_sc_scoreboard::type_id::create("sc_scbd", this);
      v_scbd = riscv_v_scoreboard::type_id::create("v_scbd", this);
      

   endfunction : build_phase

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      bd_instr_agent.mon.item_collected_port.connect(sc_scbd.item_collected_imp_s);
      bd_v_instr_agent.mon.item_collected_port.connect(v_scbd.item_collected_imp_v);
   endfunction

endclass : riscv_v_env

`endif
