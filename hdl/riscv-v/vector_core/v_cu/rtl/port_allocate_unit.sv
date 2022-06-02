module port_allocate_unit#
  (parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4)
   (
    input logic 			   clk,
    input logic 			   rstn,

    output logic [11:0] 		   instr_rdy_o,
    input logic [11:0] 			   instr_vld_i,
    input logic 			   vrf_starting_addr_vld_i,
    output logic [W_PORTS_NUM-1:0] 	   start_o,
    input logic [W_PORTS_NUM-1:0] 	   port_rdy_i,
    output logic [$clog2(R_PORTS_NUM)-1:0] op3_port_sel_o,


    output 				   alloc_port_vld_o
    );

   logic [$clog2(W_PORTS_NUM)-1:0] 	   port_group_to_allocate_reg, port_group_to_allocate_next;
   logic [R_PORTS_NUM/2-1:0] 		   r_port_status;

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
	 if (alloc_port_vld_o && port_rdy_i[port_group_to_allocate_reg])
	   port_group_to_allocate_reg <= port_group_to_allocate_next; 
      end	
   end
   
   assign port_group_to_allocate_next = port_group_to_allocate_reg + 1;

   always_comb
   begin
      for (int i=0;i<W_PORTS_NUM;i++)
      begin
	 start_o[i] = r_port_status[port_group_to_allocate_reg] && i==port_group_to_allocate_reg;
      end
   end
   assign alloc_port_vld_o = start_o[port_group_to_allocate_reg]&&((instr_rdy_o && instr_vld_i) != 0 && vrf_starting_addr_vld_i) ;

   generate
      for (genvar i=0; i<R_PORTS_NUM/2; i++)
      begin
	 always @(posedge clk)
	 begin
	    if (!rstn || port_rdy_i[i])
	    begin
	       r_port_status[i] <= 1'b1;	       
	    end
	    else
	    begin
	       if ((start_o[i] && alloc_port_vld_o) || (mvv_101xxx_instr_check && op3_port_sel_o==i))
		 r_port_status[i] = 1'b0;
	    end	
	 end
      end	 
   endgenerate

   always_comb
   begin      
      op3_port_sel_o = 'h0;
      for (int i=0; i<R_PORTS_NUM; i++)
      begin
	   if (r_port_status[i] && i != port_group_to_allocate_reg)
	   begin	      
	      op3_port_sel_o = i;
	      break;
	   end   
      end
   end

   // Outputs
   assign instr_rdy_o = {12{r_port_status != 0}}; 
   
endmodule
