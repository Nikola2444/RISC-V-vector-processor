module renaming_unit#
  (parameter VLEN=4096,   
   parameter V_LANES=1,
   parameter LANE_VRF_BYTE_NUM=(4096*32/8/V_LANES),
   parameter R_PORTS_NUM = 8,
   parameter W_PORTS_NUM = 4)
   (//input clk,
    //input 					 rstn,
    input 	instr_vld_i,
    output 	instr_rdy_o,
    input[1:0] 	lmul_i, 
    (* dont_touch = "yes" *) input logic [4:0] vs1_i,
    input [4:0] vs2_i,
    input [4:0] vd_i,
   
   
    (* dont_touch = "yes" *)output logic [$clog2(LANE_VRF_BYTE_NUM)-1:0] vrf_starting_waddr_o,
    (* dont_touch = "yes" *) output logic [$clog2(LANE_VRF_BYTE_NUM)-1:0] vrf_starting_raddr0_o,
    (* dont_touch = "yes" *)output logic [$clog2(LANE_VRF_BYTE_NUM)-1:0] vrf_starting_raddr1_o

    //output 					 addresses_vld_o
    );
      
   localparam LP_V_REGISTER_BYTE_LEN = VLEN/8;

   (* dont_touch = "yes" *) logic [$clog2(LANE_VRF_BYTE_NUM)-1:0] 	 base_addr_no_lmul_vs1;
   (* dont_touch = "yes" *)logic [$clog2(LANE_VRF_BYTE_NUM)-1:0] 	 base_addr_no_lmul_vs2;
   (* dont_touch = "yes" *)logic [$clog2(LANE_VRF_BYTE_NUM)-1:0] 	 base_addr_no_lmul_vd;
   
   
   // Currently renaming is not implemented, but in the future this will change.
   typedef logic [4:0][$clog2(LANE_VRF_BYTE_NUM)-1:0] base_addr_array;
   localparam base_addr_array base_addresses=init_base_addr();
   function base_addr_array init_base_addr();
      base_addr_array base_addresses1;
      for (logic [$clog2(LANE_VRF_BYTE_NUM)-1:0] i = 'h0; i<'h20; i++)
      begin
	 base_addresses1[i] = i * LP_V_REGISTER_BYTE_LEN/V_LANES;
	 //base_addresses1[i] = i;
      end
      return base_addresses1;
   endfunction // init_base_addr
   

   assign instr_rdy_o = 1'b1;
   assign base_addr_no_lmul_vs1 = base_addresses[vs1_i] << lmul_i;
   assign base_addr_no_lmul_vs2 = base_addresses[vs2_i] << lmul_i;
   assign base_addr_no_lmul_vd = base_addresses[vd_i] << lmul_i;
   assign vrf_starting_raddr0_o=base_addr_no_lmul_vs1;
   assign vrf_starting_raddr1_o=base_addr_no_lmul_vs2;
   assign vrf_starting_waddr_o=base_addr_no_lmul_vd;
   
endmodule
