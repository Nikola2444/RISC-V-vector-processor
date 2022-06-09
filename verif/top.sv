module riscv_v_verif_top;

   import uvm_pkg::*;     // import the UVM library
`include "uvm_macros.svh" // Include the UVM macros

   import riscv_v_test_pkg::*;

   localparam V_LANES = 4;
   localparam VLEN = 4096;
   localparam VRF_DEPTH=VLEN/V_LANES;
   logic [31:0] vrf_lvt [V_LANES][2][VRF_DEPTH-1:0] = '{default:'1};
   logic [31:0] vrf_read_ram [V_LANES][2][4][VRF_DEPTH-1:0] = '{default:'1};
   logic clk;
   logic clk2;
   logic rstn;

   
   // interface
   axi4_if axi4_vif(clk, rstn);
   backdoor_instr_if backdoor_instr_vif(clk, rstn);
   backdoor_register_bank_if backdoor_register_bank_vif (clk, rstn);
   backdoor_sc_data_if backdoor_sc_data_vif (clk, rstn);
   backdoor_v_data_if backdoor_v_data_vif (clk, rstn);

   
   
   
   // DUT
   riscv_v_w_mem_subsystem #
     (/*AUTOINST_PARAM*/
      // Parameters
      .C_M_AXI_ADDR_WIDTH		(32),
      .C_M_AXI_DATA_WIDTH		(32),
      .C_XFER_SIZE_WIDTH		(32),
      .VLEN				(VLEN),
      .V_LANES				(V_LANES))
   DUT
     (
      /*AUTO_INST*/
      // Outputs
      .v_m_axi_awvalid	(axi4_vif.v_m_axi_awvalid),
      .v_m_axi_awaddr	(axi4_vif.v_m_axi_awaddr[axi4_vif.C_M_AXI_ADDR_WIDTH-1:0]),
      .v_m_axi_awlen	(axi4_vif.v_m_axi_awlen[8-1:0]),
      .v_m_axi_wvalid	(axi4_vif.v_m_axi_wvalid),
      .v_m_axi_wdata	(axi4_vif.v_m_axi_wdata[axi4_vif.C_M_AXI_DATA_WIDTH-1:0]),
      .v_m_axi_wstrb	(axi4_vif.v_m_axi_wstrb[axi4_vif.C_M_AXI_DATA_WIDTH/8-1:0]),
      .v_m_axi_wlast	(axi4_vif.v_m_axi_wlast),
      .v_m_axi_arvalid	(axi4_vif.v_m_axi_arvalid),
      .v_m_axi_araddr	(axi4_vif.v_m_axi_araddr[axi4_vif.C_M_AXI_ADDR_WIDTH-1:0]),
      .v_m_axi_arlen	(axi4_vif.v_m_axi_arlen[8-1:0]),
      .v_m_axi_rready	(axi4_vif.v_m_axi_rready),
      .v_m_axi_bready	(axi4_vif.v_m_axi_bready),
      // Inputs
      .clk		(axi4_vif.clk),
      .clk2		(clk2),
      .rstn		(axi4_vif.rstn),
      .v_m_axi_awready	(axi4_vif.v_m_axi_awready),
      .v_m_axi_wready	(axi4_vif.v_m_axi_wready),
      .v_m_axi_arready	(axi4_vif.v_m_axi_arready),
      .v_m_axi_rvalid	(axi4_vif.v_m_axi_rvalid),
      .v_m_axi_rdata	(axi4_vif.v_m_axi_rdata[axi4_vif.C_M_AXI_DATA_WIDTH-1:0]),
      .v_m_axi_rlast	(axi4_vif.v_m_axi_rlast),
      .v_m_axi_bvalid	(axi4_vif.v_m_axi_bvalid));

   `include "backdoor_connections.sv"

   // run test
   initial begin      
      uvm_config_db#(virtual axi4_if)::set(null, "uvm_test_top.env", "axi4_if", axi4_vif);
      uvm_config_db#(virtual backdoor_instr_if)::set(null, "uvm_test_top.env", "backdoor_instr_if", backdoor_instr_vif);
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
      
   end

   //Initialize VRF
   initial
   begin
      //init lvt_rams
      for (int i=0;i<V_LANES;i++)
      begin
	 vrf_lvt[i][0]='{default:'0};
	 for (int j=0; j<VRF_DEPTH; j++)
	 begin
	    vrf_lvt[i][1][j]= j ^ 0;
	 end
      end
      //init read_rams
      for (int i=0;i<V_LANES;i++)
      begin
	 vrf_read_ram[i][0][0]='{default:'0};
	 vrf_read_ram[i][0][1]='{default:'0};
	 vrf_read_ram[i][0][2]='{default:'0};
	 vrf_read_ram[i][0][3]='{default:'0};
	 
	 for (int j=0; j<VRF_DEPTH; j++)
	 begin
	    vrf_read_ram[i][1][0][j]=j^0;
	    vrf_read_ram[i][1][1][j]=j^0;
	    vrf_read_ram[i][1][2][j]=j^0;
	    vrf_read_ram[i][1][3][j]=j^0;
	 end
      end
   end

   // clock generation
   always #100 clk = ~clk;
   always #50 clk2 = ~clk2;

endmodule : riscv_v_verif_top	// 
// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../hdl/riscv-v/rtl/")
// End:
