
module riscv_v_verif_top;
   `include "defines.sv"
   import uvm_pkg::*;     // import the UVM library
`include "uvm_macros.svh" // Include the UVM macros
   function automatic void read_instr_from_dump_file (string assembly_file_path, ref logic[31:0]ddr_mem[`DDR_DEPTH]);
      logic [31:0] instr;
      logic [31 : 0] instr_queue_1[$];
      string       instr_string;
      int 	   fd = $fopen (assembly_file_path, "r");

      while (!$feof(fd)) begin
	 $fgets(instr_string, fd);
	 for (int i = 0; i < instr_string.len(); i++)
	 begin
	    if (instr_string[i]=="." || instr_string[i]==">")
	      break;
	    if (instr_string[i]==":")
	    begin
	       $sscanf(instr_string.substr(i, instr_string.len()-1), (":   %h "), instr);
	       instr_queue_1.push_back(instr);
	    end
	 end	 
      end
      

      foreach (instr_queue_1[i])
      begin
	 $display("instruction[%d]: %h", i, instr_queue_1[i]);
	 ddr_mem[i]=instr_queue_1[i];
      end 
   endfunction


   import riscv_v_test_pkg::*;

/* -----\/----- EXCLUDED -----\/-----
   localparam `V_LANES = 4;
   localparam `VLEN = 4096;
   localparam `VRF_DEPTH=`VLEN/`V_LANES;
 -----/\----- EXCLUDED -----/\----- */

   
   logic [31:0] vrf_lvt [`V_LANES][2][`VRF_DEPTH-1:0] = '{default:'1};
   logic [31:0] vrf_read_ram [`V_LANES][2][4][`VRF_DEPTH-1:0] = '{default:'1};
   logic [31:0] ddr_mem[`DDR_DEPTH];

   logic [$clog2(`V_LANES)-1:0] vrf_vlane_col;
   logic 	ce;
   logic 	clk;
   logic 	clk2;
   logic 	rstn;
   string 	assembly_file_path = "../../../../../../RISCV-GCC-compile-scripts/assembly.dump";
      
   
   
   // interface
   axi4_if v_axi4_vif(clk, rstn, ddr_mem, 256);
   axi4_if s_axi4_vif(clk, rstn, ddr_mem, 8);
   backdoor_instr_if backdoor_instr_vif(clk, rstn);
   backdoor_v_instr_if backdoor_v_instr_vif(clk, rstn);
   backdoor_register_bank_if backdoor_register_bank_vif (clk, rstn);
   backdoor_sc_data_if backdoor_sc_data_vif (clk, rstn);
   backdoor_v_data_if backdoor_v_data_vif (clk, rstn, ddr_mem);

   
   
   
   // DUT
   riscv_v_w_mem_subsystem #
     (/*AUTOINST_PARAM*/
      // Parameters      
      .VLEN				(`VLEN),
      .V_LANES				(`V_LANES))
   DUT
     (
      /*AUTO_INST*/
      // VECTOR CORE AXI FULL_IF
      .v_m_axi_awvalid	(v_axi4_vif.m_axi_awvalid),
      .v_m_axi_awaddr	(v_axi4_vif.m_axi_awaddr[v_axi4_vif.C_M_AXI_ADDR_WIDTH-1:0]),
      .v_m_axi_awlen	(v_axi4_vif.m_axi_awlen[8-1:0]),
      .v_m_axi_wvalid	(v_axi4_vif.m_axi_wvalid),
      .v_m_axi_wdata	(v_axi4_vif.m_axi_wdata[v_axi4_vif.C_M_AXI_DATA_WIDTH-1:0]),
      .v_m_axi_wstrb	(v_axi4_vif.m_axi_wstrb[v_axi4_vif.C_M_AXI_DATA_WIDTH/8-1:0]),
      .v_m_axi_wlast	(v_axi4_vif.m_axi_wlast),
      .v_m_axi_arvalid	(v_axi4_vif.m_axi_arvalid),
      .v_m_axi_araddr	(v_axi4_vif.m_axi_araddr[v_axi4_vif.C_M_AXI_ADDR_WIDTH-1:0]),
      .v_m_axi_arlen	(v_axi4_vif.m_axi_arlen[8-1:0]),
      .v_m_axi_rready	(v_axi4_vif.m_axi_rready),
      .v_m_axi_bready	(v_axi4_vif.m_axi_bready),
      // Inputs
      .clk		(v_axi4_vif.clk),
      .clk2		(clk2),
      .rstn		(v_axi4_vif.rstn),
      .v_m_axi_awready	(v_axi4_vif.m_axi_awready),
      .v_m_axi_wready	(v_axi4_vif.m_axi_wready),
      .v_m_axi_arready	(v_axi4_vif.m_axi_arready),
      .v_m_axi_rvalid	(v_axi4_vif.m_axi_rvalid),
      .v_m_axi_rdata	(v_axi4_vif.m_axi_rdata[v_axi4_vif.C_M_AXI_DATA_WIDTH-1:0]),
      .v_m_axi_rlast	(v_axi4_vif.m_axi_rlast),
      .v_m_axi_bvalid	(v_axi4_vif.m_axi_bvalid),
      // SCALAR CORE AXI FULL
      .s_m_axi_awvalid	(s_axi4_vif.m_axi_awvalid),
      .s_m_axi_awaddr	(s_axi4_vif.m_axi_awaddr[v_axi4_vif.C_M_AXI_ADDR_WIDTH-1:0]),
      .s_m_axi_awlen	(s_axi4_vif.m_axi_awlen[8-1:0]),
      .s_m_axi_wvalid	(s_axi4_vif.m_axi_wvalid),
      .s_m_axi_wdata	(s_axi4_vif.m_axi_wdata[v_axi4_vif.C_M_AXI_DATA_WIDTH-1:0]),
      .s_m_axi_wstrb	(s_axi4_vif.m_axi_wstrb[v_axi4_vif.C_M_AXI_DATA_WIDTH/8-1:0]),
      .s_m_axi_wlast	(s_axi4_vif.m_axi_wlast),
      .s_m_axi_arvalid	(s_axi4_vif.m_axi_arvalid),
      .s_m_axi_araddr	(s_axi4_vif.m_axi_araddr[v_axi4_vif.C_M_AXI_ADDR_WIDTH-1:0]),
      .s_m_axi_arlen	(s_axi4_vif.m_axi_arlen[8-1:0]),
      .s_m_axi_rready	(s_axi4_vif.m_axi_rready),
      .s_m_axi_bready	(s_axi4_vif.m_axi_bready),
      // Inputs      
      .s_m_axi_awready	(s_axi4_vif.m_axi_awready),
      .s_m_axi_wready	(s_axi4_vif.m_axi_wready),
      .s_m_axi_arready	(s_axi4_vif.m_axi_arready),
      .s_m_axi_rvalid	(s_axi4_vif.m_axi_rvalid),
      .s_m_axi_rdata	(s_axi4_vif.m_axi_rdata[v_axi4_vif.C_M_AXI_DATA_WIDTH-1:0]),
      .s_m_axi_rlast	(s_axi4_vif.m_axi_rlast),
      .s_m_axi_bvalid	(s_axi4_vif.m_axi_bvalid),

      .ce(ce),
      .axi_base_address(0)      
      );

`include "backdoor_connections.sv"
   

   // run test
   initial begin      
      uvm_config_db#(virtual axi4_if)::set(null, "uvm_test_top.env", "v_axi4_if", v_axi4_vif);
      uvm_config_db#(virtual axi4_if)::set(null, "uvm_test_top.env", "s_axi4_if", s_axi4_vif);
      uvm_config_db#(virtual backdoor_instr_if)::set(null, "uvm_test_top.env", "backdoor_instr_if", backdoor_instr_vif);
      uvm_config_db#(virtual backdoor_v_instr_if)::set(null, "uvm_test_top.env", "backdoor_v_instr_if", backdoor_v_instr_vif);
      uvm_config_db#(virtual backdoor_register_bank_if)::set(null, "uvm_test_top.env", "backdoor_register_bank_if", backdoor_register_bank_vif);
      uvm_config_db#(virtual backdoor_sc_data_if)::set(null, "uvm_test_top.env", "backdoor_sc_data_if", backdoor_sc_data_vif);
      uvm_config_db#(virtual backdoor_v_data_if)::set(null, "uvm_test_top.env", "backdoor_v_data_if", backdoor_v_data_vif);
      run_test();
   end

   // clock and reset init.
   initial begin
      //vrf_lvt <= '{default:'1};
      clk <= 0;
      clk2 <= 1;
      rstn <= 0;
      #950 rstn <= 1;
      ce <= 1'b1;
      
   end
   logic[31:0] LVT0_xor_LVT1;
   logic [31:0] LVT1_in;
   logic [31:0] LVT0_out;
   assign LVT0_out = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_lvt_banks[0].gen_RAMs[0].gen_BRAM.LVT_RAMs.doutb;
   assign LVT1_in = DUT.riscv_v_inst.vector_core_inst.Vlane_with_low_lvl_ctrl_inst.VL_instances[0].Vector_Lane_inst.VRF_inst.gen_lvt_banks[1].gen_RAMs[0].gen_BRAM.LVT_RAMs.dina;
   assign LVT0_xor_LVT1 = LVT0_out ^ LVT1_in;
   //Initialize VRF
   initial
   begin
      //init DDR
      read_instr_from_dump_file(assembly_file_path, ddr_mem);
      for (logic[31:0] i=256; i < `DDR_DEPTH; i++)
	ddr_mem[i[31:2]][i[1:0]*8+:8] = (i-256)%64;
      //init lvt_rams

      vrf_vlane_col = 0;
      for (logic[31:0] j=0; j<`VRF_DEPTH*4; j++)
      begin

	 for (int i=0;i<`V_LANES;i++)
	 begin
	    vrf_lvt[i][0]='{default:'0};	    
	    vrf_lvt[i][1][j[31:2]][j[1:0]*8 +: 8]= j[(i%4)*8 +: 8] ^ 0;
	 end
      end
      //init read_rams

	 
	 
      for (logic[31:0] j=0; j<`VRF_DEPTH*4; j++)
      begin
	 for (int i=0;i<`V_LANES;i++)
	 begin
	    vrf_read_ram[i][0][0]='{default:'0};
	    vrf_read_ram[i][0][1]='{default:'0};
	    vrf_read_ram[i][0][2]='{default:'0};
	    vrf_read_ram[i][0][3]='{default:'0};
	    vrf_read_ram[i][1][0][j[31:2]][j[1:0]*8 +: 8]=j[(i%4)*8 +: 8] ^ 0;
	    vrf_read_ram[i][1][1][j[31:2]][j[1:0]*8 +: 8]=j[(i%4)*8 +: 8] ^ 0;
	    vrf_read_ram[i][1][2][j[31:2]][j[1:0]*8 +: 8]=j[(i%4)*8 +: 8] ^ 0;
	    vrf_read_ram[i][1][3][j[31:2]][j[1:0]*8 +: 8]=j[(i%4)*8 +: 8] ^ 0;
	 end
      end
   end

   // clock generation
   always #200 clk = ~clk;
   always #100 clk2 = ~clk2;

endmodule : riscv_v_verif_top	// 
// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../hdl/riscv-v/rtl/")
// End:
