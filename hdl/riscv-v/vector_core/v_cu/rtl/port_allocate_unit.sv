module port_allocate_unit#
  (parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4)
   (
    input logic 			   clk,
    input logic 			   rstn,

    output logic [12:0] 		   instr_rdy_o,
    input logic [12:0] 			   instr_vld_i,
    input logic 			   vrf_starting_addr_vld_i,
    input logic [W_PORTS_NUM-1:0] 	   dependancy_issue_i,
    input logic 			   slide_instr_check_i,
    output logic [W_PORTS_NUM-1:0] 	   start_o,
    input logic [W_PORTS_NUM-1:0] 	   port_rdy_i,
    output logic [$clog2(R_PORTS_NUM)-1:0] op3_port_sel_o,
    output logic [1:0] 			   store_driver_o,
    

    output 				   alloc_port_vld_o
    );

   logic [$clog2(W_PORTS_NUM)-1:0] 	   port_group_to_allocate_reg, port_group_to_allocate_next;
   logic [R_PORTS_NUM/2-1:0] 		   r_port_status;
   logic [3:0]				   store_in_progress_reg;
   logic [3:0] 				   load_in_progress_reg;
   logic [1:0] 				   store_driver_idx;

   

   assign store_driver_idx = store_in_progress_reg == 1 ? 0:
			     store_in_progress_reg == 2 ? 1:
			     store_in_progress_reg == 4 ? 2 : 3;
   assign store_driver_o = store_driver_idx;
   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 store_in_progress_reg <= 'h0;
      end
      else
      begin
	 if (alloc_port_vld_o && (instr_vld_i[3:2]!=0 && instr_rdy_o[3:2]!=0))
	 begin
	    store_in_progress_reg <= start_o;
	 end
	 else if (port_rdy_i[store_driver_idx])
	   store_in_progress_reg <= 'h0;
      end
   end

   assign load_driver_idx =  load_in_progress_reg == 1 ? 0:
			     load_in_progress_reg == 2 ? 1:
			     load_in_progress_reg == 4 ? 2 : 3;
   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 load_in_progress_reg <= 'h0;
      end
      else
      begin
	 if (alloc_port_vld_o && instr_vld_i[5])
	 begin
	    load_in_progress_reg <= start_o;
	 end
	 else if (port_rdy_i[load_driver_idx])
	   load_in_progress_reg <= 'h0;
      end
   end
   

   

   assign mvv_101xxx_instr_check = instr_vld_i[1];
   
   // Sequential logic that updatas register that tells which port group we are using.
   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 port_group_to_allocate_reg <= 'h0;
      end
      else 
      begin
	 if (slide_instr_check_i && port_group_to_allocate_reg!=0)
	   port_group_to_allocate_reg <= 0;
	 else if (start_o[port_group_to_allocate_reg])
	   port_group_to_allocate_reg <= port_group_to_allocate_next;
	 else if (port_rdy_i[port_group_to_allocate_reg]!=1)
	   port_group_to_allocate_reg <= port_group_to_allocate_next;
      end	
   end
   
   assign port_group_to_allocate_next = port_group_to_allocate_reg + 1;

   always_comb
   begin
      for (int i=0;i<W_PORTS_NUM;i++)
      begin
	 if (slide_instr_check_i && port_group_to_allocate_reg != 0)
	   start_o[i] <= 1'b0;
	 else
	   start_o[i] = port_rdy_i[port_group_to_allocate_reg] && i==port_group_to_allocate_reg && alloc_port_vld_o && dependancy_issue_i==0;
      end
   end
   assign alloc_port_vld_o = ((instr_rdy_o[11:0] && instr_vld_i[11:0]) != 0 && vrf_starting_addr_vld_i);

   generate
      for (genvar i=0; i<R_PORTS_NUM/2; i++)
      begin
	 always @(posedge clk)
	 begin
	    if (!rstn )
	    begin
	       r_port_status[i] <= 1'b1;	       
	    end
	    else
	    begin
	       if ((start_o[i]) || (mvv_101xxx_instr_check && op3_port_sel_o==i))
		 r_port_status[i] <= 1'b0;
	       else if (port_rdy_i[i])
		 r_port_status[i] <= 1'b1;
	    end	
	 end
      end	 
   endgenerate


   
   always_comb
   begin      
      op3_port_sel_o <= 'h0;
      for (int i=0; i<W_PORTS_NUM; i++)
      begin
	   if (port_rdy_i[i] && i != port_group_to_allocate_reg)
	   begin	      
	      op3_port_sel_o <= i;
	      break;
	   end   
      end
   end

   // Outputs
   logic rdy_for_instr;
   assign rdy_for_instr = slide_instr_check_i && (port_group_to_allocate_reg!=0) ? 1'b0 : dependancy_issue_i!=0 || !port_rdy_i[port_group_to_allocate_reg] ? 1'b0 : 1'b1;
   assign instr_rdy_o[1:0] = {2{rdy_for_instr}};
   assign instr_rdy_o[3:2] = {2{store_in_progress_reg==0 && rdy_for_instr}};//store_rdy
   assign instr_rdy_o[5:4] = {2{load_in_progress_reg==0 && instr_vld_i[3:2]==0 && rdy_for_instr}};//store_rdy
   assign instr_rdy_o[10:6] = {5{rdy_for_instr}};
   //Config instruction ready
   assign instr_rdy_o[12] = (port_rdy_i == 4'hf && start_o == 0) && dependancy_issue_i==0;
   assign instr_rdy_o[11] = (port_rdy_i[0] == 1'b1) && dependancy_issue_i==0;
   
endmodule
