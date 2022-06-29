`ifndef BACKDOOR_CONNECTIONS_SV
 `define BACKDOOR_CONNECTIONS_SV
// This file just connects inner DUT connections to signals defined in the top.sv.
// This is needed because some verification components need to see these inner signals
// for automated checking.

// Instruction interface backdoor connections
assign DUT.instr_ready = backdoor_instr_vif.instr_ready; 
assign DUT.instr_mem_read=backdoor_instr_vif.instr_mem_read;
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

generate
   if (`V_LANES > 1)
   begin
      assign backdoor_v_instr_vif.vrf_read_ram[0][0][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][0][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][0][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][0][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[0][1][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][1][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][1][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[0][1][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;      
      
      assign backdoor_v_instr_vif.vrf_read_ram[1][0][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][0][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][0][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][0][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[1][1][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][1][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][1][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[1][1][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;      
   end

   if (`V_LANES > 2)
   begin

      assign backdoor_v_instr_vif.vrf_read_ram[2][0][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign  backdoor_v_instr_vif.vrf_read_ram[2][0][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[2][0][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[2][0][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[2][1][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[2][1][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[2][1][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[2][1][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      

      assign backdoor_v_instr_vif.vrf_read_ram[3][0][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][0][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][0][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][0][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[3][1][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][1][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][1][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[3][1][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;   
   end
   if (`V_LANES > 4)
   begin
      assign backdoor_v_instr_vif.vrf_read_ram[4][0][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][0][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][0][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][0][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[4][1][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][1][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][1][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[4][1][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;      
      
      assign backdoor_v_instr_vif.vrf_read_ram[5][0][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][0][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][0][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][0][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[5][1][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][1][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][1][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[5][1][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;      
   



      assign backdoor_v_instr_vif.vrf_read_ram[6][0][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign  backdoor_v_instr_vif.vrf_read_ram[6][0][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[6][0][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[6][0][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[6][1][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[6][1][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[6][1][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[6][1][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      

      assign backdoor_v_instr_vif.vrf_read_ram[7][0][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][0][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][0][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][0][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;

      assign backdoor_v_instr_vif.vrf_read_ram[7][1][0] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][1][1] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][1][2] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM;
      assign backdoor_v_instr_vif.vrf_read_ram[7][1][3] = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM;   
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
assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[0][0];
assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[0][1];

assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][0][0];
assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][0][1];
assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][0][2];
assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][0][3];

assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][1][0];
assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][1][1];
assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][1][2];
assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][1][3];

generate
   if (`V_LANES > 1)
   begin
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[1][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[1][1];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[1].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[1][1][3];      
   end

   if (`V_LANES > 2)
   begin
            assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[2][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[2][1];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[2].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[2][1][3];


            assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[3][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[3][1];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[3].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[3][1][3];   
   end
   if (`V_LANES > 4)
   begin
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[4][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[4][1];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[4][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[4].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[0][1][3];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[5][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[5][1];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[5].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[5][1][3];      

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[6][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[6][1];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[6].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[6][1][3];


      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[7][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt[7][1];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][0][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][0][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][0][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][0][3];

      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[0].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][1][0];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[1].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][1][1];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[2].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][1][2];
      assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[7].Vector_Lane_inst.VRF_inst.gen_read_banks[1].gen_RAMs[3].gen_BRAM.READ_RAMs.BRAM = vrf_read_ram[7][1][3];   
   end
endgenerate


//assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_read_banks[0].gen_RAMs[0].gen_BRAM.READ_BRAMs.BRAM = vrf_lvt;
//assign DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.BRAM = vrf_lvt;





`endif
