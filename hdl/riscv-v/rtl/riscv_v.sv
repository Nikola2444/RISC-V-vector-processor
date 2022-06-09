module riscv_v #
  (
   parameter integer C_M_AXI_ADDR_WIDTH = 32,
   parameter integer C_M_AXI_DATA_WIDTH = 32,
   parameter integer C_XFER_SIZE_WIDTH = 32,
   parameter VLEN=4096,
   parameter V_LANES=16,
   parameter CHAINING=4)
   (/*AUTOARG*/
    // Outputs
    fencei_o, instr_mem_address_o, instr_mem_en_o, data_mem_address_o,
    data_mem_we_o, ctrl_raddr_offset_o, ctrl_rxfer_size_o,
    ctrl_rstart_o, rd_tready_o, ctrl_waddr_offset_o, ctrl_wxfer_size_o,
    ctrl_wstart_o, wr_tdata_o, wr_tvalid_o,
    // Inputs
    clk, clk2, ce, rstn, instr_ready_i, data_ready_i, instr_mem_read_i,
    data_mem_read_i, data_mem_write_o, data_mem_re_o, ctrl_rdone_i,
    rd_tdata_i, rd_tvalid_i, rd_tlast_i, ctrl_wdone_i, wr_tready_i
    );
   input 	     clk;
   input 	     clk2;
   input 	     ce;
   input 	     rstn;

   // Instruction interface

   
   // Vector data interface

   // Scalar core interface
   output 	     fencei_o;
   input 	     instr_ready_i;
   input 	     data_ready_i;
   
   // Instruction memory interface
   output [31:0]     instr_mem_address_o;
   input [31:0]      instr_mem_read_i; 
   //output 	  instr_mem_flush_o;
   output 	     instr_mem_en_o;
   // Scalar Data memory interface      
   output [31:0]     data_mem_address_o;
   input [31:0]      data_mem_read_i;
   input [31:0]      data_mem_write_o;
   output [3:0]      data_mem_we_o;
   input 	     data_mem_re_o;
   // MCU <=> AXIM CONTROL IF [read channel]
   output logic [C_M_AXI_ADDR_WIDTH-1:0] ctrl_raddr_offset_o ;
   output logic [C_XFER_SIZE_WIDTH-1:0]  ctrl_rxfer_size_o ;
   output logic 			 ctrl_rstart_o ;
   input logic 				 ctrl_rdone_i ;
   input logic [C_M_AXI_DATA_WIDTH-1:0]  rd_tdata_i ;
   input logic 				 rd_tvalid_i ;
   output logic 			 rd_tready_o ;
   input logic 				 rd_tlast_i ;
   // MCU <=> AXIM CONTROL IF [write channel]
   output logic [C_M_AXI_ADDR_WIDTH-1:0] ctrl_waddr_offset_o ;
   output logic [C_XFER_SIZE_WIDTH-1:0]  ctrl_wxfer_size_o ;
   output logic 			 ctrl_wstart_o ;
   input logic 				 ctrl_wdone_i ;
   output logic [C_M_AXI_DATA_WIDTH-1:0] wr_tdata_o ;
   output logic 			 wr_tvalid_o ;
   input logic 				 wr_tready_i ;


   //---------------------------- VECTOR CORE INTERFACE---------------------------
   // Vector core status signals
   logic 				 all_v_stores_executed;
   logic 				 all_v_loads_executed;
   logic 				 vector_stall;
   // Signals going to M_CU inside vector core
   logic 				 scalar_load_req;
   logic 				 scalar_store_req;
   
   // Values of rs1 and rs2 from register bank going to Vector core
   logic [31:0] 			 v_instruction;
   logic [31:0] 			 rs1;
   logic [31:0] 			 rs2;

   scalar_core scalar_core_inst
     (
      .clk                     ( clk),
      .ce                      ( ce),          
      .reset                   ( rstn),
      //instruction if
      .instr_ready_i           ( instr_ready_i),
      .fencei_o                (fencei_o),
      .instr_mem_address_o     ( instr_mem_address_o),
      .pc_reg_o                (),
      .instr_mem_read_i        ( instr_mem_read_i),
      //.instr_mem_flush_o       ( instr_mem_flush_o),
      .instr_mem_en_o          ( instr_mem_en_o),
      // Vector if
      .all_v_stores_executed_i ( all_v_stores_executed),
      .all_v_loads_executed_i  ( all_v_loads_executed),
      .vector_stall_i          ( vector_stall),
      .scalar_load_req_o       ( scalar_load_req),
      .scalar_store_req_o      ( scalar_store_req),
      .v_instruction_o         ( v_instruction),
      .rs1_o                   ( rs1),
      .rs2_o                   ( rs2),
      //data if
      .data_ready_i            ( data_ready_i),
      .data_mem_address_o      ( data_mem_address_o),
      .data_mem_read_i         ( data_mem_read_i),
      .data_mem_write_o        ( data_mem_write_o),
      .data_mem_we_o           ( data_mem_we_o),
      .data_mem_re_o           ( data_mem_re_o));

   vector_core # 
     (.VLEN			(VLEN),
      .VLANE_NUM		(V_LANES))
   vector_core_inst
     (/*AUTO_INST*/
      // Outputs

      .ctrl_raddr_offset_o		(ctrl_raddr_offset_o[C_M_AXI_ADDR_WIDTH-1:0]),
      .ctrl_rxfer_size_o		(ctrl_rxfer_size_o[C_XFER_SIZE_WIDTH-1:0]),
      .ctrl_rstart_o			(ctrl_rstart_o),
      .rd_tready_o			(rd_tready_o),
      .ctrl_waddr_offset_o		(ctrl_waddr_offset_o[C_M_AXI_ADDR_WIDTH-1:0]),
      .ctrl_wxfer_size_o		(ctrl_wxfer_size_o[C_XFER_SIZE_WIDTH-1:0]),
      .ctrl_wstart_o			(ctrl_wstart_o),
      .wr_tdata_o			(wr_tdata_o[C_M_AXI_DATA_WIDTH-1:0]),
      .wr_tvalid_o			(wr_tvalid_o),
      // Inputs
      .clk				(clk),
      .clk2				(clk2),
      .rstn				(rstn),      
      .ctrl_rdone_i			(ctrl_rdone_i),
      .rd_tdata_i			(rd_tdata_i[C_M_AXI_DATA_WIDTH-1:0]),
      .rd_tvalid_i			(rd_tvalid_i),
      .rd_tlast_i			(rd_tlast_i),
      .ctrl_wdone_i			(ctrl_wdone_i),
      .wr_tready_i			(wr_tready_i),
      //scheduler i/o
      .rs1_i				(rs1[31:0]),
      .rs2_i				(rs2[31:0]),
      .vector_instr_i			(v_instruction[31:0]),
      .vector_stall_o			(vector_stall));

   

   
endmodule

// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../../../../common/" "../vector_core/rtl")
// End:
