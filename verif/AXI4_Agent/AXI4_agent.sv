class AXI4_agent extends uvm_agent;

   // components
   AXI4_driver drv;
   
   AXI4_monitor mon;
   virtual interface axi4_if vif;
   // configuration
   riscv_v_config cfg;
   int value;   
   `uvm_component_utils_begin ( AXI4_agent)
      `uvm_field_object(cfg, UVM_DEFAULT)
   `uvm_component_utils_end

   function new(string name = " AXI4_agent", uvm_component parent = null);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      /************Geting from configuration database*******************/
      if (!uvm_config_db#(virtual axi4_if)::get(this, "", "axi4_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      
      if(!uvm_config_db#(riscv_v_config)::get(this, "", "riscv_v_config", cfg))
        `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".cfg"})
      
      /*****************************************************************/
      
      /************Setting to configuration database********************/
      uvm_config_db#(virtual axi4_if)::set(this, "*", "axi4_if", vif);
      /*****************************************************************/
      
      mon = AXI4_monitor::type_id::create("mon", this);
      if(cfg.is_active == UVM_ACTIVE) begin
         drv = AXI4_driver::type_id::create("drv", this);         
      end
   endfunction : build_phase

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
/* -----\/----- EXCLUDED -----\/-----
      if(cfg.is_active == UVM_ACTIVE) begin
         drv.seq_item_port.connect(seqr.seq_item_export);
      end
 -----/\----- EXCLUDED -----/\----- */
   endfunction : connect_phase

endclass :  AXI4_agent
