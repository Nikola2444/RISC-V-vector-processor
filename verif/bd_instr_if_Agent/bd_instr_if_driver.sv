`ifndef BD_INSTR_IF_DRIVER_SV
 `define BD_INSTR_IF_DRIVER_SV
class bd_instr_if_driver extends uvm_driver#(bd_instr_if_seq_item);

   `uvm_component_utils(bd_instr_if_driver)

   typedef enum {idle, send_instruction} instr_send_states;
   instr_send_states instr_send_fsm = idle;

   virtual interface backdoor_instr_if backdoor_instr_vif;
   function new(string name = "bd_instr_if_driver", uvm_component parent = null);
      super.new(name,parent);
      if (!uvm_config_db#(virtual backdoor_instr_if)::get(this, "", "backdoor_instr_if", backdoor_instr_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

   endfunction : connect_phase

   
   task main_phase(uvm_phase phase);
      backdoor_instr_vif.instr_ready = 1'b0;
      forever begin
	 
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
	    backdoor_instr_vif.instr_ready = 1'b1;
            // do actual driving here
	    /* TODO */	    
            seq_item_port.item_done();
	 end	
      end
   endtask : main_phase

endclass : bd_instr_if_driver

`endif

