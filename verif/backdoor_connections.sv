`ifndef BACKDOOR_CONNECTIONS_SV
 `define BACKDOOR_CONNECTIONS_SV
// This file just connects inner DUT connections to signals defined in the top.sv.
// This is needed because some verification components need to see these inner signals
// for automated checking.

// Instruction interface backdoor connections
assign backdoor_instr_vif.instr_ready = DUT.instr_ready; 
assign backdoor_instr_vif.instr_mem_read=DUT.instr_mem_read;
assign backdoor_instr_vif.instr_mem_address = DUT.instr_mem_address;
assign backdoor_instr_vif.instr_mem_flush = DUT.instr_mem_flush;
// assign backdoor_instr_vif.instr_mem_en = DUT.riscv_v_inst.scalar_core_inst.instr_mem_en_s;

// Register bank backdoor connections
assign backdoor_register_bank_vif.rd_we_i=DUT.riscv_v_inst.scalar_core_inst.data_path_1.register_bank_1.white_box_inst.rd_we_i;
assign backdoor_register_bank_vif.rs1_address_i=DUT.riscv_v_inst.scalar_core_inst.data_path_1.register_bank_1.white_box_inst.rs1_address_i;
assign backdoor_register_bank_vif.rs2_address_i=DUT.riscv_v_inst.scalar_core_inst.data_path_1.register_bank_1.white_box_inst.rs2_address_i;
assign backdoor_register_bank_vif.rs1_data_o=DUT.riscv_v_inst.scalar_core_inst.data_path_1.register_bank_1.white_box_inst.rs1_data_o;
assign backdoor_register_bank_vif.rs2_data_o=DUT.riscv_v_inst.scalar_core_inst.data_path_1.register_bank_1.white_box_inst.rs2_data_o;
assign backdoor_register_bank_vif.rd_address_i=DUT.riscv_v_inst.scalar_core_inst.data_path_1.register_bank_1.white_box_inst.rd_address_i;
assign backdoor_register_bank_vif.rd_data_i=DUT.riscv_v_inst.scalar_core_inst.data_path_1.register_bank_1.white_box_inst.rd_data_i;
assign backdoor_register_bank_vif.scalar_reg_bank=DUT.riscv_v_inst.scalar_core_inst.data_path_1.register_bank_1.white_box_inst.scalar_reg_bank;

// Scalar core data interface

//assign DUT.data_ready = 1'b1;
assign DUT.data_ready=1'b1;
assign backdoor_sc_data_vif.data_mem_address_o=DUT.data_mem_address; 
assign DUT.data_mem_read = backdoor_sc_data_vif.data_mem_read_i;
assign backdoor_sc_data_vif.data_mem_write_o=DUT.data_mem_write;
assign backdoor_sc_data_vif.data_mem_we_o=DUT.data_mem_we;
assign backdoor_sc_data_vif.data_mem_re_o=DUT.data_mem_re;


// ****************************Vector core instr interface***********************
assign 	  backdoor_v_instr_vif.start = DUT.riscv_v_inst.vector_core_inst.v_cu_inst.start_o;
assign 	  backdoor_v_instr_vif.v_rs1_scalar = DUT.riscv_v_inst.vector_core_inst.v_cu_inst.scalar_rs1_reg;
assign 	  backdoor_v_instr_vif.v_rs2_scalar = DUT.riscv_v_inst.vector_core_inst.v_cu_inst.scalar_rs2_reg;

assign 	  backdoor_v_instr_vif.ready = DUT.riscv_v_inst.vector_core_inst.v_cu_inst.port_group_ready_i;
assign    backdoor_v_instr_vif.v_instruction = DUT.riscv_v_inst.vector_core_inst.v_cu_inst.vector_instr_reg;
assign 	  backdoor_v_instr_vif.lmul=DUT.riscv_v_inst.vector_core_inst.v_cu_inst.lmul_o;
assign 	  backdoor_v_instr_vif.sew= DUT.riscv_v_inst.vector_core_inst.v_cu_inst.sew_o;
assign 	  backdoor_v_instr_vif.vl = DUT.riscv_v_inst.vector_core_inst.v_cu_inst.vl_o;
//assign    backdoor_v_instr_vif.vrf_read_ram = vrf_read_ram;

//bwen for all lanes and all drivers
generate
   if (`V_LANES > 1)
   begin
      assign backdoor_v_instr_vif.vrf_waddr[0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.waddr_i[0];
      assign backdoor_v_instr_vif.vrf_waddr[1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.waddr_i[1];
      assign backdoor_v_instr_vif.vrf_waddr[2][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.waddr_i[2];
      assign backdoor_v_instr_vif.vrf_waddr[3][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.waddr_i[3];

      assign backdoor_v_instr_vif.vrf_waddr[0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.waddr_i[0];
      assign backdoor_v_instr_vif.vrf_waddr[1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.waddr_i[1];
      assign backdoor_v_instr_vif.vrf_waddr[2][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.waddr_i[2];
      assign backdoor_v_instr_vif.vrf_waddr[3][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.waddr_i[3];

   end
   if (`V_LANES > 2)
   begin

      assign backdoor_v_instr_vif.vrf_waddr[0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.waddr_i[0];
      assign backdoor_v_instr_vif.vrf_waddr[1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.waddr_i[1];
      assign backdoor_v_instr_vif.vrf_waddr[2][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.waddr_i[2];
      assign backdoor_v_instr_vif.vrf_waddr[3][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.waddr_i[3];

      assign backdoor_v_instr_vif.vrf_waddr[0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.waddr_i[0];
      assign backdoor_v_instr_vif.vrf_waddr[1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.waddr_i[1];
      assign backdoor_v_instr_vif.vrf_waddr[2][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.waddr_i[2];
      assign backdoor_v_instr_vif.vrf_waddr[3][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.waddr_i[3];
   end
   if (`V_LANES > 4)
   begin      
      assign backdoor_v_instr_vif.vrf_waddr[0][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.waddr_i[0];
      assign backdoor_v_instr_vif.vrf_waddr[1][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.waddr_i[1];
      assign backdoor_v_instr_vif.vrf_waddr[2][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.waddr_i[2];
      assign backdoor_v_instr_vif.vrf_waddr[3][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.waddr_i[3];

      assign backdoor_v_instr_vif.vrf_waddr[0][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.waddr_i[0];
      assign backdoor_v_instr_vif.vrf_waddr[1][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.waddr_i[1];
      assign backdoor_v_instr_vif.vrf_waddr[2][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.waddr_i[2];
      assign backdoor_v_instr_vif.vrf_waddr[3][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.waddr_i[3];

      assign backdoor_v_instr_vif.vrf_waddr[0][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.waddr_i[0];
      assign backdoor_v_instr_vif.vrf_waddr[1][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.waddr_i[1];
      assign backdoor_v_instr_vif.vrf_waddr[2][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.waddr_i[2];
      assign backdoor_v_instr_vif.vrf_waddr[3][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.waddr_i[3];

      assign backdoor_v_instr_vif.vrf_waddr[0][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.waddr_i[0];
      assign backdoor_v_instr_vif.vrf_waddr[1][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.waddr_i[1];
      assign backdoor_v_instr_vif.vrf_waddr[2][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.waddr_i[2];
      assign backdoor_v_instr_vif.vrf_waddr[3][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.waddr_i[3];
   end
endgenerate
generate
   if (`V_LANES > 1)
   begin
      assign backdoor_v_instr_vif.vrf_wdata[0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.din_i[0];
      assign backdoor_v_instr_vif.vrf_wdata[1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.din_i[1];
      assign backdoor_v_instr_vif.vrf_wdata[2][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.din_i[2];
      assign backdoor_v_instr_vif.vrf_wdata[3][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.din_i[3];

      assign backdoor_v_instr_vif.vrf_wdata[0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.din_i[0];
      assign backdoor_v_instr_vif.vrf_wdata[1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.din_i[1];
      assign backdoor_v_instr_vif.vrf_wdata[2][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.din_i[2];
      assign backdoor_v_instr_vif.vrf_wdata[3][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.din_i[3];

   end
   if (`V_LANES > 2)
   begin

      assign backdoor_v_instr_vif.vrf_wdata[0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.din_i[0];
      assign backdoor_v_instr_vif.vrf_wdata[1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.din_i[1];
      assign backdoor_v_instr_vif.vrf_wdata[2][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.din_i[2];
      assign backdoor_v_instr_vif.vrf_wdata[3][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.din_i[3];

      assign backdoor_v_instr_vif.vrf_wdata[0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.din_i[0];
      assign backdoor_v_instr_vif.vrf_wdata[1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.din_i[1];
      assign backdoor_v_instr_vif.vrf_wdata[2][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.din_i[2];
      assign backdoor_v_instr_vif.vrf_wdata[3][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.din_i[3];
   end
   if (`V_LANES > 4)
   begin      
      assign backdoor_v_instr_vif.vrf_wdata[0][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.din_i[0];
      assign backdoor_v_instr_vif.vrf_wdata[1][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.din_i[1];
      assign backdoor_v_instr_vif.vrf_wdata[2][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.din_i[2];
      assign backdoor_v_instr_vif.vrf_wdata[3][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.din_i[3];

      assign backdoor_v_instr_vif.vrf_wdata[0][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.din_i[0];
      assign backdoor_v_instr_vif.vrf_wdata[1][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.din_i[1];
      assign backdoor_v_instr_vif.vrf_wdata[2][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.din_i[2];
      assign backdoor_v_instr_vif.vrf_wdata[3][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.din_i[3];

      assign backdoor_v_instr_vif.vrf_wdata[0][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.din_i[0];
      assign backdoor_v_instr_vif.vrf_wdata[1][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.din_i[1];
      assign backdoor_v_instr_vif.vrf_wdata[2][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.din_i[2];
      assign backdoor_v_instr_vif.vrf_wdata[3][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.din_i[3];

      assign backdoor_v_instr_vif.vrf_wdata[0][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.din_i[0];
      assign backdoor_v_instr_vif.vrf_wdata[1][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.din_i[1];
      assign backdoor_v_instr_vif.vrf_wdata[2][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.din_i[2];
      assign backdoor_v_instr_vif.vrf_wdata[3][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.din_i[3];
   end
endgenerate

//bwen for all lanes and all drivers
generate
   if (`V_LANES > 1)
   begin
      assign backdoor_v_instr_vif.vrf_bwen[0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.bwe_i[0];
      assign backdoor_v_instr_vif.vrf_bwen[1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.bwe_i[1];
      assign backdoor_v_instr_vif.vrf_bwen[2][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.bwe_i[2];
      assign backdoor_v_instr_vif.vrf_bwen[3][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.bwe_i[3];

      assign backdoor_v_instr_vif.vrf_bwen[0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.bwe_i[0];
      assign backdoor_v_instr_vif.vrf_bwen[1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.bwe_i[1];
      assign backdoor_v_instr_vif.vrf_bwen[2][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.bwe_i[2];
      assign backdoor_v_instr_vif.vrf_bwen[3][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.bwe_i[3];

   end
   if (`V_LANES > 2)
   begin

      assign backdoor_v_instr_vif.vrf_bwen[0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.bwe_i[0];
      assign backdoor_v_instr_vif.vrf_bwen[1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.bwe_i[1];
      assign backdoor_v_instr_vif.vrf_bwen[2][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.bwe_i[2];
      assign backdoor_v_instr_vif.vrf_bwen[3][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.bwe_i[3];

      assign backdoor_v_instr_vif.vrf_bwen[0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.bwe_i[0];
      assign backdoor_v_instr_vif.vrf_bwen[1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.bwe_i[1];
      assign backdoor_v_instr_vif.vrf_bwen[2][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.bwe_i[2];
      assign backdoor_v_instr_vif.vrf_bwen[3][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.bwe_i[3];
   end
   if (`V_LANES > 4)
   begin      
      assign backdoor_v_instr_vif.vrf_bwen[0][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.bwe_i[0];
      assign backdoor_v_instr_vif.vrf_bwen[1][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.bwe_i[1];
      assign backdoor_v_instr_vif.vrf_bwen[2][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.bwe_i[2];
      assign backdoor_v_instr_vif.vrf_bwen[3][4] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.bwe_i[3];

      assign backdoor_v_instr_vif.vrf_bwen[0][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.bwe_i[0];
      assign backdoor_v_instr_vif.vrf_bwen[1][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.bwe_i[1];
      assign backdoor_v_instr_vif.vrf_bwen[2][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.bwe_i[2];
      assign backdoor_v_instr_vif.vrf_bwen[3][5] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.bwe_i[3];

      assign backdoor_v_instr_vif.vrf_bwen[0][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.bwe_i[0];
      assign backdoor_v_instr_vif.vrf_bwen[1][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.bwe_i[1];
      assign backdoor_v_instr_vif.vrf_bwen[2][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.bwe_i[2];
      assign backdoor_v_instr_vif.vrf_bwen[3][6] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.bwe_i[3];

      assign backdoor_v_instr_vif.vrf_bwen[0][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.bwe_i[0];
      assign backdoor_v_instr_vif.vrf_bwen[1][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.bwe_i[1];
      assign backdoor_v_instr_vif.vrf_bwen[2][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.bwe_i[2];
      assign backdoor_v_instr_vif.vrf_bwen[3][7] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.bwe_i[3];
   end
endgenerate


generate
   if (`V_LANES > 1)
   begin
      assign backdoor_v_instr_vif.vrf_read_ram[0][0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[0][1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;      
      
      assign backdoor_v_instr_vif.vrf_read_ram[1][0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[1][1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;      
   end

   if (`V_LANES > 2)
   begin

      assign backdoor_v_instr_vif.vrf_read_ram[2][0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign  backdoor_v_instr_vif.vrf_read_ram[2][0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[2][0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[2][0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[2][1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[2][1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[2][1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[2][1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      

      assign backdoor_v_instr_vif.vrf_read_ram[3][0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[3][1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;   
   end
   if (`V_LANES > 4)
   begin
      assign backdoor_v_instr_vif.vrf_read_ram[4][0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[4][1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;      
      
      assign backdoor_v_instr_vif.vrf_read_ram[5][0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[5][1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;      
   



      assign backdoor_v_instr_vif.vrf_read_ram[6][0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign  backdoor_v_instr_vif.vrf_read_ram[6][0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[6][0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[6][0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[6][1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[6][1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[6][1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[6][1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      

      assign backdoor_v_instr_vif.vrf_read_ram[7][0][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][0][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][0][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][0][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[7][1][0] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][1][1] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][1][2] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][1][3] = DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;   
   end
endgenerate
// *****************************************************************************************
// ********Vector core data IF***************

//read IF
/* -----\/----- EXCLUDED -----\/-----
assign backdoor_v_data_vif.ctrl_raddr_offset_o = DUT.riscv_v_inst.ctrl_raddr_offset_o;
assign backdoor_v_data_vif.ctrl_rxfer_size_o = DUT.riscv_v_inst.ctrl_rxfer_size_o;
assign backdoor_v_data_vif.ctrl_rstart_o = DUT.riscv_v_inst.ctrl_rstart_o;
 -----/\----- EXCLUDED -----/\----- */

/* -----\/----- EXCLUDED -----\/-----
assign backdoor_v_data_vif.rd_tready_o = DUT.riscv_v_inst.rd_tready_o;
assign DUT.ctrl_rdone = backdoor_v_data_vif.ctrl_rdone_i;
assign DUT.rd_tdata = backdoor_v_data_vif.rd_tdata_i;
assign DUT.rd_tvalid = backdoor_v_data_vif.rd_tvalid_i;
assign DUT.rd_tlast = backdoor_v_data_vif.rd_tlast_i;
 -----/\----- EXCLUDED -----/\----- */
// Write if
/* -----\/----- EXCLUDED -----\/-----
assign backdoor_v_data_vif.ctrl_waddr_offset_o = DUT.riscv_v_inst.ctrl_waddr_offset_o;
assign backdoor_v_data_vif.ctrl_wxfer_size_o = DUT.riscv_v_inst.ctrl_wxfer_size_o;
assign backdoor_v_data_vif.ctrl_wstart_o = DUT.riscv_v_inst.ctrl_wstart_o;
 -----/\----- EXCLUDED -----/\----- */



/* -----\/----- EXCLUDED -----\/-----
assign DUT.riscv_v_inst.wr_tready_i = backdoor_v_data_vif.wr_tready_i;
assign DUT.riscv_v_inst.ctrl_wdone_i = backdoor_v_data_vif.ctrl_wdone_i;
assign backdoor_v_data_vif.wr_tdata_o = DUT.riscv_v_inst.wr_tdata_o;
assign backdoor_v_data_vif.wr_tvalid_o = DUT.riscv_v_inst.wr_tvalid_o;
 -----/\----- EXCLUDED -----/\----- */



/***********************************************************/
// Vector core VRF backdoor interface
//LANE0 VRF_INIT
/* -----\/----- EXCLUDED -----\/-----
assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[0][0];
assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[0][1];

assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][0][0];
assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][0][1];
assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][0][2];
assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][0][3];

assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][1][0];
assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][1][1];
assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][1][2];
assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][1][3];

generate
   if (`V_LANES > 1)
   begin
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[1][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[1][1];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[1].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][1][3];      
   end

   if (`V_LANES > 2)
   begin
            assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[2][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[2][1];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[2].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][1][3];


            assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[3][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[3][1];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[3].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][1][3];   
   end
   if (`V_LANES > 4)
   begin
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[4][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[4][1];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[4].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][1][3];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[5][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[5][1];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[5].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][1][3];      

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[6][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[6][1];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[6].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][1][3];


      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[7][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[7][1];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[7].vector_lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][1][3];   
   end
endgenerate
 -----/\----- EXCLUDED -----/\----- */


//assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_BRAMs.BRAM = vrf_lvt;
//assign DUT.riscv_v_inst.vector_core_inst.v_dpu_inst.VL_instances[0].vector_lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt;





`endif
