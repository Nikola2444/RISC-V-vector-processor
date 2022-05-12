module riscv_v #
  (parameter VLEN=4096,
   parameter V_LANES=16,
   parameter CHAINING=4)
   (
    input 	  clk,
    input 	  ce,
    input 	  rstn,

    // Instruction interface

   
    // Vector data interface

    // Scalar core interface
    output 	  fencei_o,
    input 	  instr_ready_i,
    input 	  data_ready_i,
   
    // Instruction memory interface
    output [31:0] instr_mem_address_o,
    input [31:0]  instr_mem_read_i, 
    //output 	  instr_mem_flush_o,
    output 	  instr_mem_en_o,
    // Scalar Data memory interface      
    output [31:0] data_mem_address_o,
    input [31:0]  data_mem_read_i,
    input [31:0]  data_mem_write_o,
    output [3:0]  data_mem_we_o,
    input 	  data_mem_re_o


   
   );

   //---------------------------- VECTOR CORE INTERFACE---------------------------
   // Vector core status signals
   logic 	  all_v_stores_executed;
   logic 	  all_v_loads_executed;
   logic 	  vector_stall;
   // Signals going to M_CU inside vector core
   logic 	  scalar_load_req;
   logic 	  scalar_store_req;
   
   // Values of rs1 and rs2 from register bank going to Vector core
   logic [31:0]   v_instruction;
   logic [31:0]   rs1;
   logic [31:0]   rs2;

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
      //.vector_stall_i          ( vector_stall),
      .vector_stall_i          ( 1'b0),
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

   vector_core vector_core_inst
     (/*AUTOINST*/
      // Outputs
      .vector_stall_o			(vector_stall),
      // Inputs
      .clk				(clk),
      .rstn				(rstn),
      .rs1_i				(rs1[31:0]),
      .rs2_i				(rs2[31:0]),
      .vector_instr_i			(v_instruction[31:0]));

   

   
endmodule

// Local Variables:
// verilog-library-extensions:(".v" ".sv" "_stub.v" "_bb.v")
// verilog-library-directories:("." "../../../../common/" "../vector_core/rtl")
// End:
