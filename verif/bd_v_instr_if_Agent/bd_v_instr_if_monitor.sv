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
   logic [31:0] 			  store_data_queue[$];
   typedef enum 			  {wait_for_start, wait_for_rdy} instr_send_states;

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

      

   endfunction // new

   function void build_phase (uvm_phase phase);
      logic [$clog2(`V_LANES)-1:0] vrf_vlane; 
      logic [1:0] 		   byte_sel;      
      int 			   vreg_addr_offset;
      int 			   vreg_to_read;
      super.build_phase(phase);
      if (!uvm_config_db#(virtual backdoor_v_instr_if)::get(this, "", "backdoor_v_instr_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
      //init temp_vrf_read_ram with values real vrf has inside it at the beggining
/* -----\/----- EXCLUDED -----\/-----
      for (int driver_idx=0; driver_idx < 4; driver_idx++)
	for (int i=0; i<32; i++)
	  for (logic[31:0] j=0; j<`VLEN/8; j++)
	  begin
	     vrf_vlane=j[$clog2(`V_LANES)-1:0];
	     byte_sel=j[$clog2(`V_LANES) +:2];
	     vreg_to_read=i*(`VLEN/32/`V_LANES);
	     vreg_addr_offset = j[$clog2(`V_LANES) + 2 +: 27];	   
	     temp_vrf_read_ram[driver_idx][i][j[31:2]][j[1:0]*8 +: 8] = vif.vrf_read_ram[vrf_vlane][0][0][vreg_to_read+vreg_addr_offset][byte_sel*8+:8] ^ 
							    vif.vrf_read_ram[vrf_vlane][1][0][vreg_to_read+vreg_addr_offset][byte_sel*8+:8];
	  end
 -----/\----- EXCLUDED -----/\----- */
   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      
   endfunction : connect_phase

   task main_phase(uvm_phase phase);

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
      end

	 	  
   endtask : main_phase

   task lane_driver(int idx);

      
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

	       driver_processing[idx].pop_front();
	       curr_it[idx] 		  = bd_v_instr_if_seq_item::type_id::create("bd_v_instr_if_seq_item", this);
	       curr_it[idx].v_instruction = instr_queue[idx].pop_front();
	       curr_it[idx].sew 	  = sew_queue[idx].pop_front();
	       curr_it[idx].lmul 	  = lmul_queue[idx].pop_front();
	       curr_it[idx].vl 		  = vl_queue[idx].pop_front();
	       curr_it[idx].scalar 	  = scalar_queue[idx].pop_front();
	       curr_it[idx].scalar2 	  = scalar2_queue[idx].pop_front();
	       curr_it[idx].vrf_read_ram  = temp_vrf_read_ram[idx];
	       
/* -----\/----- EXCLUDED -----\/-----
	       for (int i=0; i< `VRF_DEPTH; i++)
		 $display("temp_vrf_read_ram[%d][0][%d]=%x", idx, i, temp_vrf_read_ram[idx][0][i]);
 -----/\----- EXCLUDED -----/\----- */
	       item_collected_port.write(curr_it[idx]);
	       `uvm_info(get_type_name(),
			 $sformatf("V_MONITOR: FINISHED, V_INSTR_DRIVER IDX IS: %d, v_instruction:%x", idx, curr_it[idx].v_instruction),
			 UVM_HIGH)
	    end
	 join_none
      end

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
