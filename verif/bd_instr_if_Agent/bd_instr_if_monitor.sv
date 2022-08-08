`ifndef BD_INSTR_IF_MONITOR
`define BD_INSTR_IF_MONITOR
class bd_instr_if_monitor extends uvm_monitor;

   // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;
   logic [31:0] sc_instr_queue[$];
   logic [31:0] sc_instr_addr_queue[$];
   logic [31:0] sc_st_instr_queue[$];
   logic [31:0] v_instr_queue[$];



   int 			branch_skip;
   uvm_analysis_port #(bd_instr_if_seq_item) item_collected_port;

   `uvm_component_utils_begin(bd_instr_if_monitor)
      `uvm_field_int(checks_enable, UVM_DEFAULT)
      `uvm_field_int(coverage_enable, UVM_DEFAULT)
   `uvm_component_utils_end

   // The virtual interface used to drive and view HDL signals.
   virtual interface backdoor_instr_if backdoor_instr_vif;
   virtual interface backdoor_register_bank_if backdoor_register_bank_vif;
   virtual interface backdoor_sc_data_if backdoor_sc_data_vif;

   // current transaction
   bd_instr_if_seq_item curr_it;
   logic[31:0] store_data_queue[$];
   logic [31:0] collect_prev_instr_mem_addr=0-1;
   logic [31:0] check_prev_instr_mem_addr=0-1;
   int 	       num_of_instr;

   // coverage can go here
   // ...

   function new(string name = "bd_instr_if_monitor", uvm_component parent = null);
      super.new(name,parent);      
      item_collected_port = new("item_collected_port", this);
      if (!uvm_config_db#(virtual backdoor_instr_if)::get(this, "", "backdoor_instr_if", backdoor_instr_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      if (!uvm_config_db#(virtual backdoor_sc_data_if)::get(this, "", "backdoor_sc_data_if", backdoor_sc_data_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      if (!uvm_config_db#(virtual backdoor_register_bank_if)::get(this, "", "backdoor_register_bank_if", backdoor_register_bank_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      if (!uvm_config_db#(int)::get(this, "", "num_of_instr", num_of_instr))
        `uvm_fatal("NOVIF",{"number of instructions must be set:",get_full_name(),".num_of_instr"})
      $display("num_of_instruction is: %d",num_of_instr);
   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
   endfunction : connect_phase

   task main_phase(uvm_phase phase);
      phase.raise_objection(this);
      for (int i=0; i<5; i++)
      begin
	 sc_instr_queue[i] = 0;// nop instructions go first
	 sc_instr_addr_queue[i] = 0;// nop instructions go first
      end
      forever begin
	 @(negedge backdoor_instr_vif.clk);
	 if (backdoor_instr_vif.rstn)
	 begin
	    fork
	       begin		         	  
		  collect_instruction();
	       end

	       begin
		  collect_and_check_data();
	       end
	    join_none
	 end

	 // End of test mechanism. If program address space is exceeded,
	 // end simulation
	 if(backdoor_instr_vif.instr_mem_address>=5*num_of_instr)	   
	   phase.drop_objection(this);
       end
   endtask : main_phase

   task collect_instruction();
      logic collect_stall;
      collect_stall = backdoor_instr_vif.instr_mem_address == collect_prev_instr_mem_addr;
      if (!collect_stall && backdoor_instr_vif.instr_ready)      
      begin
	 collect_prev_instr_mem_addr = backdoor_instr_vif.instr_mem_address;
//	    if (backdoor_instr_vif.instr_mem_read[2:0] != 3'b111) // scalar instruction
//	    begin	
	 sc_instr_queue.push_back(backdoor_instr_vif.instr_mem_read); //save non store instr
	 sc_instr_addr_queue.push_back(backdoor_instr_vif.instr_mem_address); //save non store instr
//	    end
/* -----\/----- EXCLUDED -----\/-----
	    else
	    begin
	       //v_instr_queue.push_back(backdoor_instr_vif.instr_mem_read);
	       sc_instr_queue.push_back(0); //save non store instr
	       sc_instr_addr_queue.push_back(backdoor_instr_vif.instr_mem_address); //save non store instr
	    end
 -----/\----- EXCLUDED -----/\----- */

      end
   endtask // collect_instruction

   task collect_and_check_data();
      logic [0:31][31:0] sc_reg_bank;
      logic 		 check_stall;
	fork
	   begin // non store thread
	      check_stall = backdoor_instr_vif.instr_mem_address == check_prev_instr_mem_addr;
	      if (sc_instr_queue.size() != 0 && !check_stall && backdoor_instr_vif.instr_ready)
	      begin
		 check_prev_instr_mem_addr = backdoor_instr_vif.instr_mem_address;
		 curr_it=bd_instr_if_seq_item::type_id::create("seq_item", this);
		 curr_it.scalar_reg_bank_new=backdoor_register_bank_vif.scalar_reg_bank;
		 curr_it.instruction = sc_instr_queue.pop_front();
		 curr_it.instruction_addr=sc_instr_addr_queue.pop_front();
		 if (curr_it.instruction[6:0] == 7'b1100011)
		   curr_it.store_data = store_data_queue.pop_front();
		 //$display ("New_reg bank: %x, time: %d", curr_it.scalar_reg_bank_new, $time);
		 item_collected_port.write(curr_it);		 
	      end
	   end // non store thread
	   

	   begin // store thread
	      if (backdoor_sc_data_vif.data_mem_we_o)
	      begin		 
		 store_data_queue.push_front(backdoor_sc_data_vif.data_mem_write_o);		 		 
	      end
	   end // store thread

	join_none
   endtask // collect_and_check_data

   
endclass : bd_instr_if_monitor
`endif
