`ifndef BD_INSTR_IF_DRIVER_SV
 `define BD_INSTR_IF_DRIVER_SV
class bd_instr_if_driver extends uvm_driver#(bd_instr_if_seq_item);

   `uvm_component_utils(bd_instr_if_driver)
   
   virtual interface riscv_v_if vif;
   virtual interface backdoor_instr_if backdoor_instr_vif;
   function new(string name = "bd_instr_if_driver", uvm_component parent = null);
      super.new(name,parent);
      if (!uvm_config_db#(virtual riscv_v_if)::get(this, "", "riscv_v_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (!uvm_config_db#(virtual riscv_v_if)::get(this, "", "riscv_v_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"})
      if (!uvm_config_db#(virtual backdoor_instr_if)::get(this, "", "backdoor_instr_if", backdoor_instr_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
   endfunction : connect_phase

   
   task main_phase(uvm_phase phase);
      
      forever begin
	 backdoor_instr_vif.instr_ready = 1'b1;
	 @(negedge backdoor_instr_vif.clk);
	 if (backdoor_instr_vif.rstn)
	 begin
	    seq_item_port.get_next_item(req);
	    req.instruction_addr = backdoor_instr_vif.instr_mem_address;
	    seq_item_port.item_done();

            seq_item_port.get_next_item(req);
            `uvm_info(get_type_name(),
                      $sformatf("Driver sending...\n%s", req.sprint()),
                      UVM_HIGH)
	    backdoor_instr_vif.instr_mem_read = req.instruction;

            // do actual driving here
	    /* TODO */	    
            seq_item_port.item_done();
	 end	
      end
   endtask : main_phase

endclass : bd_instr_if_driver

`endif

