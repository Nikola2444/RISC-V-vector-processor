`uvm_analysis_imp_decl(_s)

class riscv_sc_scoreboard extends uvm_scoreboard;

   // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;
   int num_of_tr;
   int match_num;
   // This TLM port is used to connect the scoreboard to the monitor
   uvm_analysis_imp_s#(bd_instr_if_seq_item, riscv_sc_scoreboard) item_collected_imp_s;
   


   typedef enum logic [6:0] {sc_arith_imm=7'b0010011, sc_arith=7'b0110011,  sc_store=7'b0100011, sc_branch=7'b1100011,
			     sc_jal=7'b1101111, sc_jalr=7'b1100111} scalar_opcodes;

   
   logic [6:0] 	opcode;
   logic [0:31][31:0] sc_reg_bank;
   int 		      skip_2_instructions = 0;

   `uvm_component_utils_begin(riscv_sc_scoreboard)
      `uvm_field_int(checks_enable, UVM_DEFAULT)
      `uvm_field_int(coverage_enable, UVM_DEFAULT)
   `uvm_component_utils_end

   function new(string name = "riscv_sc_scoreboard", uvm_component parent = null);
      super.new(name,parent);
      item_collected_imp_s = new("item_collected_imp_s", this);
      
      sc_reg_bank = '{default:'0};
   endfunction : new

   function write_s (bd_instr_if_seq_item tr);
      bd_instr_if_seq_item tr_clone;
      
      $cast(tr_clone, tr.clone());
      `uvm_info(get_type_name(),
                $sformatf("SC_SCBD:vMonitor sent...\n%s", tr_clone.sprint()),
                UVM_MEDIUM)
      opcode = tr_clone.instruction[6:0];
      if(skip_2_instructions==0) begin
	 if (opcode == sc_arith_imm || opcode == sc_arith)
	 begin
	    arith_instr_check(tr_clone, opcode);
	 end
	 else if (opcode == sc_branch)
	 begin
	    branch_instr(tr_clone);
	 end
	 else if (opcode == sc_jal)
	 begin
	    skip_2_instructions=2;
	    jal_instr_check(tr_clone);
	 end
	 else if (opcode == sc_jalr)
	 begin
	    skip_2_instructions=2;
	    jal_instr_check(tr_clone);
	 end
      end
      else
	skip_2_instructions--;
   endfunction : write_s   

   

   function void arith_instr_check(bd_instr_if_seq_item tr, logic [6:0] opcode);

      int instruction;
      logic [2:0] funct3;
      logic [4:0] rs1;
      logic [4:0] rs2;
      logic [4:0] rd;
      logic [6:0] funct7;
      logic [11:0] immediate;
      logic [31:0] op1;
      logic [31:0] op2;

      bd_instr_if_seq_item tr_clone;
      $cast(tr_clone, tr.clone());


      funct3 = tr_clone.instruction[14:12];
      funct7 = tr_clone.instruction[31:25];
      rs1 = tr_clone.instruction[19:15];
      rs2 = tr_clone.instruction[24:20];
      rd = tr_clone.instruction[11:7];
      immediate = tr_clone.instruction[31:20];
      op1 = sc_reg_bank[rs1];
      op2 = sc_reg_bank[rs2];
      $cast(tr_clone, tr.clone());
      
      num_of_tr++;
      if (opcode == sc_arith_imm)
      begin
	 sc_reg_bank[rd]=sc_calculate_arith (op1, immediate, funct3, funct7, 1);
	 assert(sc_reg_bank[rd] == tr_clone.scalar_reg_bank_new[rd])
	   begin
	      `uvm_info(get_type_name(), $sformatf("SC_MATCH: instruction:%x \t expected result: %x, dut_result: %x", tr_clone.instruction, 
						   sc_reg_bank[rd], tr_clone.scalar_reg_bank_new[rd]), UVM_MEDIUM)
	      match_num++;
	   end
	 else
	   `uvm_error("SC_MISSMATCH_IMM", $sformatf("instruction: %x \t expected result[%d]: %x, dut_result[%d]: %x", tr_clone.instruction, 
						rd, sc_reg_bank[rd], rd, tr_clone.scalar_reg_bank_new[rd]))
      end
      else if (opcode == sc_arith)
      begin
	 sc_reg_bank[rd]=sc_calculate_arith (op1, op2, funct3, funct7, 0);
	 assert(sc_reg_bank[rd] == tr_clone.scalar_reg_bank_new[rd])
	   begin
	      `uvm_info(get_type_name(), $sformatf("SC_MATCH: instruction:%x \t expected result: %x, dut_result: %x", tr_clone.instruction, 
						   sc_reg_bank[rd], tr_clone.scalar_reg_bank_new[rd]), UVM_MEDIUM)
	      match_num++;
	   end
	 else
	   `uvm_error("SC_MISSMATCH_ARITH", $sformatf("instruction: %x \t expected result[%d]: %x, dut_result[%d]: %x", tr_clone.instruction, 
						rd, sc_reg_bank[rd], rd, tr_clone.scalar_reg_bank_new[rd]))
      end
      else if (opcode == sc_store)
      begin
	 assert(sc_reg_bank[rs2] == tr_clone.store_data)
	   begin
	      `uvm_info(get_type_name(), $sformatf("SC_MATCH: instruction:%x \t expected result: %x, dut_result: %x", tr_clone.instruction, 
						   sc_reg_bank[rd], tr_clone.scalar_reg_bank_new[rd]), UVM_MEDIUM)
	      match_num++;
	   end
	 else
	 begin
	    `uvm_error("SC_MISSMATCH", $sformatf("instruction: %x \t expected result[%d]: %x, dut_result[%d]: %x", tr_clone.instruction, 
						 rd, sc_reg_bank[rd], rd, tr_clone.scalar_reg_bank_new[rd]))
	 end
      end
      
      
      

      
   endfunction

   function logic [31:0] sc_calculate_arith (logic [31:0] op1, logic[31:0] op2, logic [2:0] funct3, logic [6:0] funct7, logic op2_imm);
      bit funct7_5;
      logic [31:0] res;
      funct7_5 = funct7[5];//check if add or sub
      $display("op1=%d op2=%d", op1, op2);
      case (funct3)
	 000: begin
	    if (op2_imm)
	      res = op1 + op2;
	    else
	      if (funct7_5 == 0)
		res = op1 + op2;
	      else
		res = op1 - op2;	    
	 end
	 001: res = op1 << op2[4:0];
	 010: res = (op1) < (op2);
	 011: res = unsigned'(op1) < unsigned'(op2);
	 100: res = (op1) ^ (op2);
	 101: begin
	    if(funct7_5)
	      res = op1 >>> op2[4:0];
	    else
	      res = op1 >> op2[4:0];
	 end
	 110: res = op1 | op2;
	 111: res = op1 & op2;

      endcase // case (funct3)
      return res;
   endfunction // sc_calculate_arith

   function logic[31:0] branch_instr(bd_instr_if_seq_item tr);
      logic [4:0] 	rs1;
      logic [4:0] 	rs2;
      logic [2:0] 	funct3;
      logic 		res=0;
      logic [11:0] 	branch_imm;
      branch_imm = {tr.instruction[31], tr.instruction[7], 
		    tr.instruction[30:25], tr.instruction[11:8], 1'b0};
      rs1 = tr.instruction[19:15];		       
      rs2 = tr.instruction[24:20];
      funct3 = tr.instruction[14:12];
      num_of_tr++;
      case (funct3)
	 000: res = signed'(sc_reg_bank[rs1]) == signed'(sc_reg_bank[rs2]);
	 001: res = signed'(sc_reg_bank[rs1]) != signed'(sc_reg_bank[rs2]);
	 100: res = signed'(sc_reg_bank[rs1]) < signed'(sc_reg_bank[rs2]);
	 101: res = signed'(sc_reg_bank[rs1]) >= signed'(sc_reg_bank[rs2]);
	 110: res = sc_reg_bank[rs1] < sc_reg_bank[rs2];
	 111: res = sc_reg_bank[rs1] > sc_reg_bank[rs2];
      endcase // case (funct3)
      
      if (res==1)
	skip_2_instructions = 2;
      else
	skip_2_instructions = 0;
      `uvm_info(get_type_name(),
                $sformatf("RES is:%d, skip2_instr=%d", res, skip_2_instructions),
                UVM_MEDIUM)
   endfunction // branch_instr

   function void jal_instr_check(bd_instr_if_seq_item tr);
      logic [31:0] 	jump_addr;
      logic [20:0] 	jal_imm = {tr.instruction[31], tr.instruction[19:12], 
				   tr.instruction[20], tr.instruction[30:21], 1'b0};
      logic [4:0] 	rs1 = tr.instruction[19:15];		       
      logic [4:0] 	rs2 = tr.instruction[24:20];
      logic [4:0] 	rd = tr.instruction[11:7];
      logic [2:0] 	funct3 = tr.instruction[14:12];
      num_of_tr++;
      jump_addr = signed'(jal_imm) + signed'(tr.instruction_addr) + 4;
      if (rd != 0)
	sc_reg_bank[rd]= jump_addr;
      else
	sc_reg_bank[rd]= 0;
      
      assert(sc_reg_bank[rd] == tr.scalar_reg_bank_new[rd])
	begin
	   `uvm_info(get_type_name(), $sformatf("SC_MATCH: instruction:%x \t expected result: %x, dut_result: %x", tr.instruction, 
						sc_reg_bank[rd], tr.scalar_reg_bank_new[rd]), UVM_MEDIUM)
	   match_num++;
	end
      else
	`uvm_error("SC_MISSMATCH", $sformatf("instruction: %x \t expected result[%d]: %x, dut_result[%d]: %x", tr.instruction, 
					     rd, sc_reg_bank[rd], rd, tr.scalar_reg_bank_new[rd]))
      

      
   endfunction // jal_instr_check

   function void jalr_instr_check(bd_instr_if_seq_item tr);
      logic [31:0] jump_addr;
      logic [11:0] jalr_imm = {tr.instruction[31:20]};
      logic [4:0]  rs1 = tr.instruction[19:15];		       
      logic [4:0]  rs2 = tr.instruction[24:20];
      logic [4:0]  rd = tr.instruction[11:7];
      logic [2:0]  funct3 = tr.instruction[14:12];
      num_of_tr++;
      jump_addr = signed'(jalr_imm) + signed'(sc_reg_bank[rs1]);
      if (rd != 0)
	sc_reg_bank[rd]= {jump_addr[31:1], 1'b0};
      else
	sc_reg_bank[rd]= 0;
      
      assert(sc_reg_bank[rd] == tr.scalar_reg_bank_new[rd])
	begin
	   `uvm_info(get_type_name(), $sformatf("SC_MATCH: instruction:%x \t expected result: %x, dut_result: %x", tr.instruction, 
						sc_reg_bank[rd], tr.scalar_reg_bank_new[rd]), UVM_MEDIUM)
	   match_num++;
	end
      else
	`uvm_error("SC_MISSMATCH", $sformatf("instruction: %x \t expected result[%d]: %x, dut_result[%d]: %x", tr.instruction, 
					     rd, sc_reg_bank[rd], rd, tr.scalar_reg_bank_new[rd]))
      

      
   endfunction // jalr_instr_check


   function void report_phase(uvm_phase phase);
      `uvm_info(get_type_name(), $sformatf("RISCV scoreboard examined: %0d TRANSACTIONS", num_of_tr), UVM_LOW);
      `uvm_info(get_type_name(), $sformatf("Calc scoreboard examined: %0d MATCHES", match_num), UVM_LOW);
   endfunction : report_phase
endclass : riscv_sc_scoreboard
