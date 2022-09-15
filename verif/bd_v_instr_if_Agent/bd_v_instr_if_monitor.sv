`ifndef BD_V_INSTR_IF_MONITOR
`define BD_V_INSTR_IF_MONITOR
class bd_v_instr_if_monitor extends uvm_monitor;

   // control fileds
   bit		checks_enable = 1;
   bit		coverage_enable = 1;
   logic [31:0]	v_instr_queue[$];



   int		branch_skip;
   int		clock_cnt[4];
   int		thread_finished=0;
   logic[31:0] store_data[$];
   
   uvm_analysis_port #(bd_v_instr_if_seq_item) item_collected_port;
   
   `uvm_component_utils_begin(bd_v_instr_if_monitor)
      `uvm_field_int(checks_enable, UVM_DEFAULT)
      `uvm_field_int(coverage_enable, UVM_DEFAULT)
   `uvm_component_utils_end

   // The virtual interface used to drive and view HDL signals.
   virtual interface backdoor_v_instr_if vif;
   virtual interface axi4_if v_axi4_vif;

   // current transaction
   bd_v_instr_if_seq_item curr_it[4];
   bd_v_instr_if_seq_item store_ch_item;
   logic [31:0] 			  store_data_queue[$];
   typedef enum 			  {collect_data_state, wait_for_finish_state, send_data_state} data_gather_states;
   data_gather_states data_gather_fsm[4];
   logic [31:0] 			  instr_queue[4][$];
   logic [2:0] 				  sew_queue[4][$];
   logic [2:0] 				  lmul_queue[4][$];
   logic [31:0] 			  vl_queue[4][$];
   logic [31:0] 			  vrf_read_ram_queue [4][$][`V_LANES][`VRF_DEPTH-1:0];
   logic [`V_LANES-1:0][`VRF_DEPTH-1:0][31:0] temp_vrf_read_ram [4] = '{default:'0};


   logic [$clog2(`VRF_DEPTH)-1:0] 	  waddr[4];
   logic [31:0] 			  scalar_queue[4][$];
   logic [31:0] 			  scalar2_queue[4][$];
   int 					  driver_processing[4][$];
   int                                    elements_processed[4] = '{default:'0};;
   int                                    elements_to_process[4];
   // coverage can go here
   // ...

   function new(string name = "bd_v_instr_if_monitor", uvm_component parent = null);
      super.new(name,parent);      
      item_collected_port = new("item_collected_port", this);
      for (int i=0; i<4; i++)
	data_gather_fsm[i]=collect_data_state;
      

   endfunction // new

   function void build_phase (uvm_phase phase);
      logic [$clog2(`V_LANES)-1:0] vrf_vlane; 
      logic [1:0] 		   byte_sel;      
      int 			   vreg_addr_offset;
      int 			   vreg_to_read;
      super.build_phase(phase);
      if (!uvm_config_db#(virtual backdoor_v_instr_if)::get(this, "", "backdoor_v_instr_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      if (!uvm_config_db#(virtual axi4_if)::get(this, "", "v_axi4_if", v_axi4_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".v_axi4_vif"})

   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
   endfunction : connect_phase

   task main_phase(uvm_phase phase);

      forever begin
	 @(negedge vif.clk);
/* -----\/----- EXCLUDED -----\/-----
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
	 join
 -----/\----- EXCLUDED -----/\----- */

	 store_checker();
      end

	 	  
   endtask : main_phase
   task store_checker();
      if ((vif.start && vif.ready)!=0)
      begin
	 `uvm_info(get_type_name(),
                $sformatf("V_MONITOR: VECTOR INSTRUCTION STARTED,  v_instruction: %x", vif.v_instruction),
                UVM_HIGH)

	 store_ch_item 	       = bd_v_instr_if_seq_item::type_id::create("bd_v_instr_if_seq_item", this);
	 store_ch_item.v_instruction = vif.v_instruction;
	 store_ch_item.sew 	       = vif.sew;
	 store_ch_item.lmul 	       = vif.lmul;
	 store_ch_item.vl 	       = vif.vl;
	 store_ch_item.scalar        = vif.v_rs1_scalar;
	 store_ch_item.scalar2       = vif.v_rs2_scalar;
	 store_ch_item.store_check   = 0;
	 
	 item_collected_port.write(store_ch_item);
	 store_ch_item=null;
      end
      #1;
      if (v_axi4_vif.m_axi_wvalid && v_axi4_vif.m_axi_wready)
      begin
	 store_data.push_back(v_axi4_vif.m_axi_wdata);
	 if (v_axi4_vif.m_axi_wlast)begin
	    store_ch_item = bd_v_instr_if_seq_item::type_id::create("bd_v_instr_if_seq_item", this);
	    store_ch_item.store_data=store_data;
	    store_ch_item.store_check=1;
	    //$display("store_check function called, dut_result: %x", store_data[0]);
	    item_collected_port.write(store_ch_item);
	    store_data.delete();
	    store_ch_item=null;
	 end
      end

      
   endtask
   task lane_driver(int idx);

      case (data_gather_fsm[idx])
	 collect_data_state:begin
	    if (driver_processing[idx][0]==1 && vif.ready[idx])
	      data_gather_fsm[idx]=wait_for_finish_state;
	 end
	 wait_for_finish_state:begin	    
	    clock_cnt[idx]++;
	    if (clock_cnt[idx]==4)
	    begin
	       data_gather_fsm[idx]=send_data_state;
	       clock_cnt[idx]=0;
	    end
	 end
	 send_data_state:begin
	    driver_processing[idx].pop_front();
	    curr_it[idx] 	       = bd_v_instr_if_seq_item::type_id::create("bd_v_instr_if_seq_item", this);
	    curr_it[idx].v_instruction = instr_queue[idx].pop_front();
	    curr_it[idx].sew 	       = sew_queue[idx].pop_front();
	    curr_it[idx].lmul 	       = lmul_queue[idx].pop_front();
	    curr_it[idx].vl 	       = vl_queue[idx].pop_front();
	    curr_it[idx].scalar        = scalar_queue[idx].pop_front();
	    curr_it[idx].scalar2       = scalar2_queue[idx].pop_front();
	    curr_it[idx].vrf_read_ram  = temp_vrf_read_ram[idx];
	    
	    
 	    item_collected_port.write(curr_it[idx]);
 	    `uvm_info(get_type_name(),
		      $sformatf("V_MONITOR: FINISHED, V_INSTR_DRIVER IDX IS: %d, v_instruction:%x", idx, curr_it[idx].v_instruction),
		      UVM_HIGH)
	    data_gather_fsm[idx]=collect_data_state;
	 end
      endcase

/* -----\/----- EXCLUDED -----\/-----
      if (driver_processing[idx][0]==1 && vif.ready[idx])
      begin
	 fork
	    begin
  	       driver_processing[idx][0]=0;
	       //$display ("instruction=%x, driver_processing[idx][0]=%d", instr_queue[idx][0], driver_processing[idx][0]);
	       for (int i=0; i<4; i++) // wait for VECTOR core to finish with the processing, max 4 clk needed
	       begin
		  @(negedge vif.clk);
	       end
	       
	       thread_finished=1;
	       driver_processing[idx].pop_front();
	       curr_it[idx] 		  = bd_v_instr_if_seq_item::type_id::create("bd_v_instr_if_seq_item", this);
	       curr_it[idx].v_instruction = instr_queue[idx].pop_front();
	       curr_it[idx].sew 	  = sew_queue[idx].pop_front();
	       curr_it[idx].lmul 	  = lmul_queue[idx].pop_front();
	       curr_it[idx].vl 		  = vl_queue[idx].pop_front();
	       curr_it[idx].scalar 	  = scalar_queue[idx].pop_front();
	       curr_it[idx].scalar2 	  = scalar2_queue[idx].pop_front();
	       curr_it[idx].vrf_read_ram  = temp_vrf_read_ram[idx];
	       
	
 	       item_collected_port.write(curr_it[idx]);
 	       `uvm_info(get_type_name(),
			 $sformatf("V_MONITOR: FINISHED, V_INSTR_DRIVER IDX IS: %d, v_instruction:%x", idx, curr_it[idx].v_instruction),
			 UVM_HIGH)
	     
	    end
	 join_none
	 
      end
 -----/\----- EXCLUDED -----/\----- */


      //every time write happens, write data into temp vrf.
      for (int lane=0; lane <`V_LANES; lane++)
	for (int byte_idx=0; byte_idx<4; byte_idx++)
	  if (vif.vrf_bwen[idx][lane][byte_idx])
	  begin	     
	     waddr[idx] = vif.vrf_waddr[idx][lane];	     
	     temp_vrf_read_ram[idx][lane][waddr[idx]][byte_idx*8 +: 8] = vif.vrf_wdata[idx][lane][byte_idx*8 +: 8];
	     //$display("temp_vrf_read_ram[%d][%d][%d][%d]= %x", idx, lane, waddr[idx], byte_idx, temp_vrf_read_ram[idx][lane][waddr[idx]][byte_idx*8 +: 8]);
	  end
      if (vif.start[idx] && vif.ready[idx])
      begin
	 `uvm_info(get_type_name(),
                $sformatf("V_MONITOR: START V_INSTR_DRIVER IDX IS: %d, v_instruction:%x", idx, vif.v_instruction),
                UVM_HIGH)

	 driver_processing[idx].push_back(1);

	 instr_queue[idx].push_back(vif.v_instruction);
	 sew_queue[idx].push_back(vif.sew);
	 lmul_queue[idx].push_back(vif.lmul);
	 vl_queue[idx].push_back(vif.vl);
	 scalar_queue[idx].push_back(vif.v_rs1_scalar);
	 scalar2_queue[idx].push_back(vif.v_rs2_scalar); 

      end            
   endtask


   
   
endclass : bd_v_instr_if_monitor
`endif
