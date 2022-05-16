`ifndef BD_INSTR_IF_MONITOR
`define BD_INSTR_IF_MONITOR
class bd_instr_if_monitor extends uvm_monitor;

   // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;

   uvm_analysis_port #(bd_instr_if_seq_item) item_collected_port;

   `uvm_component_utils_begin(bd_instr_if_monitor)
      `uvm_field_int(checks_enable, UVM_DEFAULT)
      `uvm_field_int(coverage_enable, UVM_DEFAULT)
   `uvm_component_utils_end

   // The virtual interface used to drive and view HDL signals.
   virtual interface backdoor_instr_if vif;

   // current transaction
   bd_instr_if_seq_item curr_it;

   // coverage can go here
   // ...

   function new(string name = "bd_instr_if_monitor", uvm_component parent = null);
      super.new(name,parent);      
      item_collected_port = new("item_collected_port", this);
      if (!uvm_config_db#(virtual backdoor_instr_if)::get(this, "", "backdoor_instr_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
   endfunction : connect_phase

   task main_phase(uvm_phase phase);
       forever begin
	  @(negedge vif.clk);
      // curr_it = bd_instr_if_seq_item::type_id::create("curr_it", this);
      // ...
      // collect transactions
      // ...
      // item_collected_port.write(curr_it);
	  
       end
   endtask : main_phase

endclass : bd_instr_if_monitor
`endif
