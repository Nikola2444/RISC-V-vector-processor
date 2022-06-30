`ifndef BD_V_INSTR_IF_MONITOR
`define BD_V_INSTR_IF_MONITOR
class bd_v_instr_if_monitor extends uvm_monitor;

   // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;
   logic [31:0] v_instr_queue[$];



   int 			branch_skip;
   uvm_analysis_port #(bd_v_instr_if_seq_item) item_collected_port;

   `uvm_component_utils_begin(bd_v_instr_if_monitor)
      `uvm_field_int(checks_enable, UVM_DEFAULT)
      `uvm_field_int(coverage_enable, UVM_DEFAULT)
   `uvm_component_utils_end

   // The virtual interface used to drive and view HDL signals.
   virtual interface backdoor_v_instr_if vif;

   // current transaction
   bd_v_instr_if_seq_item curr_it[4];
   logic[31:0] store_data_queue[$];
   typedef enum {wait_for_start, wait_for_rdy} instr_send_states;

   logic [31:0] instr_queue[4][$];
   logic [2:0] 	sew_queue[4][$];
   logic [2:0] 	lmul_queue[4][$];
   logic [31:0] vl_queue[4][$];
   logic [31:0] scalar_queue[4][$];
   logic [31:0] scalar2_queue[4][$];
   int          driver_processing[4] = '{default:'0};
   int 		watch_dog_cnt=0;
   // coverage can go here
   // ...

   function new(string name = "bd_v_instr_if_monitor", uvm_component parent = null);
      super.new(name,parent);      
      item_collected_port = new("item_collected_port", this);
      if (!uvm_config_db#(virtual backdoor_v_instr_if)::get(this, "", "backdoor_v_instr_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      

   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
   endfunction : connect_phase

   task main_phase(uvm_phase phase);
      int drop_obj=0;
      phase.raise_objection(this);
      forever begin
	 @(negedge vif.clk);
	  fork
	     begin
		lane_driver(0);
	     end
	     begin
		lane_driver(1);
	     end
	     begin
		lane_driver(2);
	     end
	     begin
		lane_driver(3);
	     end
	  join_none

	 if(vif.v_instruction[6:0]==7'h13)
	   watch_dog_cnt++;
	 if (vif.start==0 && vif.ready==4'b1111 && watch_dog_cnt > 10 && drop_obj==0)
	 begin
	    drop_obj = 1;
	    phase.drop_objection(this);
	 end
	  // ...
	  // collect transactions
	  // ...
	  // item_collected_port.write(curr_it);
	  
       end
   endtask : main_phase

   task lane_driver(int idx);


      if (driver_processing[idx]==1 && vif.ready[idx])
      begin
	 fork
	    begin
	       driver_processing[idx] = 0;
	       for (int i=0; i<8; i++) // wait for VECTOR core to finish with the processing, max 8 clk needed
	       begin
		  @(negedge vif.clk);
	       end

	       curr_it[idx]=bd_v_instr_if_seq_item::type_id::create("bd_v_instr_if_seq_item", this);
	       curr_it[idx].v_instruction = instr_queue[idx].pop_front();
	       curr_it[idx].sew = sew_queue[idx].pop_front();
	       curr_it[idx].lmul = lmul_queue[idx].pop_front();
	       curr_it[idx].vl = vl_queue[idx].pop_front();
	       curr_it[idx].scalar = scalar_queue[idx].pop_front();
	       curr_it[idx].scalar2 = scalar2_queue[idx].pop_front();
	       curr_it[idx].vrf_read_ram = vif.vrf_read_ram;
	       item_collected_port.write(curr_it[idx]);
	       $display("READY DRIVER IDX IS: %d, v_instruction:%x", idx, curr_it[idx].v_instruction);	       
	    end
	 join_none
      end
      if (vif.start[idx] && vif.ready[idx])
      begin
	 $display("START DRIVER IDX IS: %d, v_instruction:%x", idx, vif.v_instruction);
	 driver_processing[idx] = 1;
	 instr_queue[idx].push_back(vif.v_instruction);
	 sew_queue[idx].push_back( vif.sew);
	 lmul_queue[idx].push_back(vif.lmul);
	 vl_queue[idx].push_back(vif.vl);
	 scalar_queue[idx].push_back(vif.v_rs1_scalar);
	 scalar2_queue[idx].push_back(vif.v_rs2_scalar);
      end            
   endtask

   
   
endclass : bd_v_instr_if_monitor
`endif
