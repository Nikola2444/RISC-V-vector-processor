class bd_instr_if_agent extends uvm_agent;

   // components
   bd_instr_if_driver drv;
   bd_instr_if_sequencer seqr;
   bd_instr_if_monitor mon;
   
   virtual interface backdoor_instr_if backdoor_instr_vif;
   virtual interface backdoor_register_bank_if backdoor_register_bank_vif;
   virtual interface backdoor_sc_data_if backdoor_sc_data_vif;
   // configuration
   riscv_v_config cfg;
   int value;   
   `uvm_component_utils_begin (bd_instr_if_agent)
      `uvm_field_object(cfg, UVM_DEFAULT)
   `uvm_component_utils_end

   function new(string name = "bd_instr_if_agent", uvm_component parent = null);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      /************Geting from configuration database*******************/
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
      uvm_config_db#(virtual backdoor_instr_if)::set(this, "*", "backdoor_instr_if", backdoor_instr_vif);
      uvm_config_db#(virtual backdoor_sc_data_if)::set(this, "*", "backdoor_sc_data_if", backdoor_sc_data_vif);
      uvm_config_db#(virtual backdoor_register_bank_if)::set(this, "*", "backdoor_register_bank_if", backdoor_register_bank_vif);
      /*****************************************************************/
      
      mon = bd_instr_if_monitor::type_id::create("mon", this);
      if(cfg.instr_agent_active == 1) begin
         drv = bd_instr_if_driver::type_id::create("drv", this);
         seqr = bd_instr_if_sequencer::type_id::create("seqr", this);
      end
   endfunction : build_phase

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if(cfg.instr_agent_active == 1) begin
         drv.seq_item_port.connect(seqr.seq_item_export);
      end
   endfunction : connect_phase

endclass : bd_instr_if_agent
