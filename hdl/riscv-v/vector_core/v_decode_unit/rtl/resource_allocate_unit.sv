module resource_allocate_unit#
  (parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4)
   (
    input logic 			   clk,
    input logic 			   rstn,

    output logic [11:0] 		   instr_rdy_o,
    input logic [11:0] 			   instr_vld_i,
    output logic [R_PORTS_NUM-1:0] 	   r_port_en_o,
    output logic [W_PORTS_NUM-1:0] 	   w_port_en_o,
    output logic [$clog2(R_PORTS_NUM)-1:0] op3_port_sel_o,


    output 				   alloc_resources_vld_o,
    input 				   alloc_resources_rdy_i,
    input [R_PORTS_NUM-1:0] 		   free_r_port_i,
    input [W_PORTS_NUM-1:0] 		   free_w_port_i
    );

   logic [W_PORTS_NUM-1:0] 		   port_group_to_allocate_reg, port_group_to_allocate_next;
   logic [R_PORTS_NUM/2-1:0] 		   r1_port_group_reg, r1_port_group_next;
   logic [R_PORTS_NUM/2-1:0] 		   r2_port_group_reg, r2_port_group_next;
   logic [R_PORTS_NUM-1:0] 		   r12_port_group_reg;
   logic [R_PORTS_NUM/2-1:0] 		   r1_group_port_sel;
   logic [R_PORTS_NUM/2-1:0] 		   r2_group_port_sel;
   logic [R_PORTS_NUM-1:0] 		   r3_port_sel;
   logic [W_PORTS_NUM-1:0] 		   w_port_group_reg, w_port_group_next;

   logic [R_PORTS_NUM/2-1:0] 		   group_r_port_status;
   logic [W_PORTS_NUM-1:0] 		   vv_group_rdy;
   logic [W_PORTS_NUM-1:0] 		   vi_vx_group_rdy;
   logic [W_PORTS_NUM-1:0] 		   st_idx_ld_group_rdy;
   logic [W_PORTS_NUM-1:0] 		   idx_st_group_rdy;
   logic [W_PORTS_NUM-1:0] 		   ld_group_rdy;
   logic 				   no_resources_in_group;
   logic 				   vv_instr_check;
   logic 				   vi_vx_instr_check;
   logic 				   ld_instr_check;
   logic 				   st_instr_check;
   logic 				   idx_ld_instr_check;
   logic 				   idx_st_instr_check;


   // Sequential logic that updatas register that tells which port group we are using.
   always @(posedge clk)
   begin
      if (!rstn)
      begin
	 port_group_to_allocate_reg <= 'h0;
      end
      else
      begin
	 if (no_resources_in_group)
	   port_group_to_allocate_reg <= port_group_to_allocate_next; 
      end	
   end
   
   assign port_group_to_allocate_next = port_group_to_allocate_reg + 1;

   /**********************************************************************************/
   // logic bellow updates register that tell which port is being used.
   // R1 port group reg contains information about read ports 0,2,4,6
   // R2 port group reg contains information about read ports 1,3,5,7
   // W port group reg contains information about write ports 0,1,2,3
   generate
      for (genvar i=0; i<R_PORTS_NUM/2; i++)
      begin
	 always @(posedge clk)
	 begin
	    if (!rstn || free_r_port_i[i*2])
	    begin
	       r1_port_group_reg[i] <= 1'b0;	       
	    end
	    else
	    begin
	       if (alloc_resources_vld_o && alloc_resources_rdy_i)
		 r1_port_group_reg[i/2] = r_port_en_o[i*2];
	    end	
	 end

	 always @(posedge clk)
	 begin
	    if (!rstn || free_r_port_i[i*2+1])
	    begin
	       r2_port_group_reg[i] <= 1'b0;
	    end
	    else
	    begin	 
	       if (alloc_resources_vld_o && alloc_resources_rdy_i)		 
		 r2_port_group_reg[i/2] = r_port_en_o[i*2+1];
	    end	
	 end

	 if (i%2)
	   assign r12_port_group_reg[i] = r1_port_group_reg[i/2];
	 else
	   assign r12_port_group_reg[i] = r2_port_group_reg[i/2];
      end
   endgenerate

   generate
      for (genvar i=0; i< W_PORTS_NUM; i++)
      begin
	 always @(posedge clk)
	 begin
	    if (!rstn || free_w_port_i[i])
	    begin
	       w_port_group_reg[i] <= 1'b0;	    
	    end
	    else
	    begin
	       if (alloc_resources_vld_o && alloc_resources_rdy_i)		 
		 w_port_group_reg[i] = w_port_en_o[i];
	    end	
	 end	 
      end // for (genvar i=0; i<R_PORTS_NUM/2; i++)
   endgenerate
   /********************************************************************************/
   
   // Logic that selects first read port availabe when the third is needs for OPMVV_101xxx instructions
   
   always_comb
   begin      
      r3_port_sel = 'h0;
      for (int i=0; i<R_PORTS_NUM; i++)
      begin
	 if (i/2 != port_group_to_allocate_reg)
	   if ( !r12_port_group_reg[i])
	   begin
	      r3_port_sel[i] = 1'b1;
	      op3_port_sel_o = i;
	      break;
	   end   
      end
   end
   

   always_comb
   begin
      for (int i = 0; i < R_PORTS_NUM/2; i++)
      begin
	 group_r_port_status[i] = r1_port_group_reg[i] || r2_port_group_reg[i];
      end	
   end

   // there is at least one group of r1 and r2 where r1 is being used.
   assign r_port_priority_check =  group_r_port_status != 0;


   //We check if instruction is: OPIVV, OPMVV, OPMVV_101xxx and OPMVX_101xxx. 
   // The last one is there becvause even though it is a vector scalar instruction,
   // we need to read two vectors.
   assign vv_instr_check = instr_vld_i[8] || instr_vld_i[6] || instr_vld_i[1] || instr_vld_i[0];
   assign mvv_101xxx_instr_check = instr_vld_i[1];

   //We check if instruction is: OPIVI, OPIMVX and OPIVX_101xxx. 
   assign vi_vx_instr_check = instr_vld_i[10] || instr_vld_i[8] || instr_vld_i[9];

   assign ld_instr_check = instr_vld_i[5];
   assign idx_ld_instr_check = instr_vld_i[5];
   assign st_instr_check = instr_vld_i[3];
   assign idx_st_instr_check = instr_vld_i[2];

   
   always_comb
   begin
      for (int i=0; i<W_PORTS_NUM;i++)
      begin
	 vv_group_rdy[i] = (r1_port_group_reg[i] &&
			    r2_port_group_reg[i] &&
			    w_port_group_reg[i]);

	 vi_vx_group_rdy[i] = (r1_port_group_reg[i] &&
			       w_port_group_reg[i]);
	 st_idx_ld_group_rdy [i] = (!r1_port_group_reg[i] || !r2_port_group_reg[i]) ;
	 idx_st_group_rdy [i] = r1_port_group_reg[i] && r2_port_group_reg[i] ;
	 ld_group_rdy [i] = !w_port_group_reg[i];	 
	 
      end
   end

   assign alloc_resources_vld_o = (vv_group_rdy[port_group_to_allocate_reg] && vv_instr_check) || 
				  (vi_vx_group_rdy[port_group_to_allocate_reg] && vi_vx_instr_check)||
				  (st_idx_ld_group_rdy[port_group_to_allocate_reg] && (st_instr_check || idx_ld_instr_check))||
				  (idx_st_group_rdy[port_group_to_allocate_reg] && idx_st_instr_check) ||
				  (ld_group_rdy[port_group_to_allocate_reg] && ld_instr_check);
   
   always_comb
   begin
      no_resources_in_group = 1'b0;
      if (!vv_group_rdy[port_group_to_allocate_reg] || !vi_vx_group_rdy[port_group_to_allocate_reg])	  
	no_resources_in_group = 1'b1;
      else if (vv_instr_check || vi_vx_instr_check)
	no_resources_in_group = 1'b1;
   end

   /*OUTPUTS*/

   //generating enable for VRF read ports
   always_comb
   begin
      for (int i=0; i<R_PORTS_NUM;i+=2)
      begin
	 if (i==port_group_to_allocate_reg)
	 begin
	    r_port_en_o[i] = (vv_group_rdy[i] && vv_instr_check) || 
			     (vi_vx_group_rdy[i] && vi_vx_instr_check) || 
			     ((st_idx_ld_group_rdy[i] && (st_instr_check || idx_ld_instr_check)) && r_port_en_o[i+1]) ||
			     (idx_st_group_rdy[i] && idx_st_instr_check);
	    r_port_en_o[i+1] = (vi_vx_group_rdy[i] && vi_vx_instr_check) || 
			       (st_idx_ld_group_rdy[i] && (st_instr_check || idx_ld_instr_check)) ||
			       (idx_st_group_rdy[i]&&idx_st_instr_check);
	 end
         else if (mvv_101xxx_instr_check)
	   r_port_en_o[i] = r3_port_sel[i];
         else
	   r_port_en_o[i]=1'b0;
      end
      //generating enable for VRF write ports
      for (int i=0; i<W_PORTS_NUM; i++)
      begin
	 if (i==port_group_to_allocate_reg)
	 begin
	    w_port_en_o[i] = (vv_group_rdy[i] && vv_instr_check) || 
			     (vi_vx_group_rdy[i] && vi_vx_instr_check) ||
			     (ld_group_rdy[i] && ld_instr_check);
	 end
	 else
	   w_port_en_o[i] = 1'b0;
      end
   end

   assign instr_rdy_o[0] =  vv_group_rdy != 0 && (&(st_idx_ld_group_rdy)); // OPMVV_101xxx
   assign instr_rdy_o[1] =  vv_group_rdy != 0;//OPMVX_101xxx
   assign instr_rdy_o[2] =  idx_st_group_rdy != 0;//indexed store rdy
   assign instr_rdy_o[4:3] =  st_idx_ld_group_rdy != 0;//Indexed load and store rdy
   assign instr_rdy_o[5] =  ld_group_rdy != 0; //LOAD_Rdy
   assign instr_rdy_o[6] =  vv_group_rdy != 0; //OPMVV_rdy
   assign instr_rdy_o[7] =  vi_vx_group_rdy != 0; //OPMVX_rdy
   assign instr_rdy_o[8] =  vv_group_rdy != 0; //OPIVV_rdy
   assign instr_rdy_o[9] =  vi_vx_group_rdy != 0; //OPIVI_rdy
   assign instr_rdy_o[10] =  vi_vx_group_rdy != 0; //OPIVX_rdy
   assign instr_rdy_o[12] =  1'b1; //OPCFG TODO, get info from lane if this can be updated.

endmodule // resource_allocate_unit












