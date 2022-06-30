
`uvm_analysis_imp_decl(_v)
`include "defines.sv"
class riscv_v_scoreboard extends uvm_scoreboard;

   // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;
   int num_of_tr;
   int match_num;

   const logic [2 : 0] OPIVV = 3'b000;
   const logic [2 : 0] OPIVX = 3'b100;
   const logic [2 : 0] OPIVI = 3'b011;
   const logic [2 : 0] OPMVV = 3'b010;
   const logic [2 : 0] OPMVX = 3'b110;
   const logic [2 : 0] OPCFG = 3'b111;
   // This TLM port is used to connect the scoreboard to the monitor
   virtual interface axi4_if v_axi4_vif;
   virtual interface backdoor_v_instr_if backdoor_v_instr_vif;
   uvm_analysis_imp_v#(bd_v_instr_if_seq_item, riscv_v_scoreboard) item_collected_imp_v;
   
   logic [31:0] vrf_read_ram [31:0][`VLEN/32-1:0];

   typedef enum logic [6:0] {v_arith=7'b1010111, v_store=7'b0100111, v_load=7'b0000111} vector_opcodes;
   
   logic [6:0] 	opcode;
   int 		skip_2_instructions = 0;
   
   `uvm_component_utils_begin(riscv_v_scoreboard)
      `uvm_field_int(checks_enable, UVM_DEFAULT)
      `uvm_field_int(coverage_enable, UVM_DEFAULT)
   `uvm_component_utils_end

   function new(string name = "riscv_v_scoreboard", uvm_component parent = null);
      super.new(name,parent);
      item_collected_imp_v = new("item_collected_imp_v", this);
   endfunction : new

   function void build_phase (uvm_phase phase);
      logic [$clog2(`V_LANES)-1:0] vrf_vlane; 
      logic [1:0] 		   byte_sel;      
      int 			   vreg_addr_offset;
      int 			   vreg_to_read;
      super.build_phase(phase);
      
      if (!uvm_config_db#(virtual axi4_if)::get(this, "", "v_axi4_if", v_axi4_vif)) // needed for ddr access
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".v_axi4_vif"})
      if (!uvm_config_db#(virtual backdoor_v_instr_if)::get(this, "", "backdoor_v_instr_if", backdoor_v_instr_vif)) // needed for initialization of vrf ref model
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".backdoor_v_instr_vif"})
      //init ref model vrf
      for (int i=0; i<32; i++)
	for (logic[31:0] j=0; j<`VLEN/8; j++)
	begin
	   vrf_vlane=j[$clog2(`V_LANES)-1:0];
	   byte_sel=j[$clog2(`V_LANES) +:2];
	   //byte_sel=j[3:2];
	   vreg_to_read=i*(`VLEN/32/`V_LANES);
	   vreg_addr_offset = j[$clog2(`V_LANES) + 2 +: 27];
	   // $display ("vrf_vlane=%0d, \t vreg_to_read+vreg_addr_offset=%0d", vrf_vlane, vreg_to_read+vreg_addr_offset);	   
	   vrf_read_ram[i][j[31:2]][j[1:0]*8 +: 8] = backdoor_v_instr_vif.vrf_read_ram[vrf_vlane][0][0][vreg_to_read+vreg_addr_offset][byte_sel*8+:8] ^ 
						     backdoor_v_instr_vif.vrf_read_ram[vrf_vlane][1][0][vreg_to_read+vreg_addr_offset][byte_sel*8+:8];

	end
      // foreach(vrf_read_ram[i])
	// foreach(vrf_read_ram[i][j])
	  // $display ("vrf_read_ram[%0d][%0d]=%0d", i, j, vrf_read_ram[i][j]);
   endfunction

   function write_v (bd_v_instr_if_seq_item tr);
      bd_v_instr_if_seq_item tr_clone;      
      $cast(tr_clone, tr.clone());

      `uvm_info(get_type_name(),
                $sformatf("V_SCBD:vMonitor sent...\n%s", tr_clone.sprint()),
                UVM_MEDIUM)
      num_of_tr++;
      if (tr_clone.v_instruction[6:0]==v_load)
	load_instr_check(tr_clone);
      if (tr_clone.v_instruction[6:0]==v_arith && (tr_clone.v_instruction[31:26]==6'b001110 || tr_clone.v_instruction[31:26]==6'b001111)) // slides
	slide_instr_check(tr_clone);
      else if (tr_clone.v_instruction[6:0]==v_arith)
	arith_instr_check(tr_clone);
      
	//arith_instr_check(tr_clone);
	
	//arith_instr_check(tr_clone);
      
   endfunction: write_v
      

   function void arith_instr_check(bd_v_instr_if_seq_item tr);
      logic [4:0] vs1;
      logic [4:0] vs2;
      logic [4:0] vd;
      logic 	  vm;
      logic [2:0] funct3;
      logic [5:0] funct6;
      logic [31:0] op1;
      logic [31:0] op2;
      logic [31:0] op1_sign_ext;
      logic [31:0] op2_sign_ext;
      int 	   vrf_addr_offset;
      int 	   vreg_to_update;
      int 	   read_element_idx;
      int 	   write_element_idx;
      int 	   vrf_vlane;
      int 	   byte_sel;
      logic [7:0]  dut_vrf_data;
      int 	   match=0;
      logic [1:0]  sew;
      logic [31:0] res;

      vd=tr.v_instruction[11:7];
      vm=tr.v_instruction[25];
      funct3=tr.v_instruction[14:12];
      funct6=tr.v_instruction[31:26];
      if (funct3==OPMVX || funct3==OPIVX || funct3==OPIVI)
	vs1=tr.v_instruction[24:20];
      else
	vs1=tr.v_instruction[19:15];
      vs2=tr.v_instruction[24:20];

      
      for (int i=0; i<tr.vl; i++)
      begin
	 sew = ~(tr.sew[1:0] + 1);
	 read_element_idx =  i[sew +: 32];
	 if (funct6[5:3]==3'b110 || funct6[5:3]==3'b111)
	   write_element_idx =  i[(sew-1) +: 32];
	 else
	   write_element_idx =  i[sew +: 32];

	 if (tr.sew==3'b000)
	 begin
	    if (funct3==OPMVV && funct6[5:3] == 3'b000) // reduction
	      if (i==0)//only first element
		op1={24'b0, vrf_read_ram[vs1][read_element_idx][i[1:0]*8 +:8]};
	      else
		op1=res;
	    else
	      op1={24'b0, vrf_read_ram[vs1][read_element_idx][i[1:0]*8 +:8]};
	    if (funct3 == OPIVV || funct3 == OPMVV)
	      op2={24'b0, vrf_read_ram[vs2][read_element_idx][i[1:0]*8 +:8]};
	    else if (funct3 == OPIVX || funct3 == OPMVX)
	      op2={24'b0, tr.scalar[7:0]};
	    else
	      op2={27'b0, tr.v_instruction[19:15]};//immediate

	    op1_sign_ext = {{24{op1[7]}}, op1[7:0]};
	    op2_sign_ext = {{24{op2[7]}}, op2[7:0]};
	    res = sc_calculate_arith(op1_sign_ext, op2_sign_ext, funct6, funct3, tr.sew);
	    if (funct3==OPMVV && funct6[5:3] == 3'b000) // reduction
	      vrf_read_ram[vd][0][7:0]=res[7:0];
	    else if (funct6[5:0] == 6'b111011)
	      vrf_read_ram[vd][write_element_idx][i[0]*16 +: 16]=res[15:0];
	    else
	      vrf_read_ram[vd][write_element_idx][i[1:0]*8 +: 8]=res[7:0];

	    //$display("op1_sign_ext=%0d, op2_sign_ext=%0d, res[%0d][%0d][%0d]=%0d", op1_sign_ext, op2_sign_ext, vd, read_element_idx, i[1:0], res);
	 end
	 else if (tr.sew==3'b001)
	 begin
	    if (funct3==OPMVV && funct6[5:3] == 3'b000)
	      if (i==0)
		op1={16'b0, vrf_read_ram[vs1][read_element_idx][i[0]*16 +:16]};
	      else
		op1=res;
	    else
	      op1={16'b0, vrf_read_ram[vs1][read_element_idx][i[0]*16 +:16]};
	    if (funct3 == OPIVV || funct3 == OPMVV)
	      op2={16'b0, vrf_read_ram[vs2][read_element_idx][i[0]*16 +:16]};
	    else if (funct3 == OPIVX || funct3 == OPMVX)
	      op2={16'b0, tr.scalar[15:0]};
	    else
	      op2={27'b0, tr.v_instruction[19:15]};//immediate

	    op1_sign_ext = {{16{op1[15]}}, op1[15:0]};
	    op2_sign_ext = {{16{op2[15]}}, op2[15:0]};
	    res = sc_calculate_arith(op1_sign_ext, op2_sign_ext, funct6, funct3, tr.sew);

	    if (funct3==OPMVV && funct6[5:3] == 3'b000) // reduction
	      vrf_read_ram[vd][0][15 : 0]=res[15:0];
	    else if (funct6[5:0] == 6'b111011)
	      vrf_read_ram[vd][write_element_idx]=res;
	    else
	      vrf_read_ram[vd][write_element_idx][i[0]*16 +: 16]=res[15:0];

	    //$display("vrf=%0x, op1_sign_ext=%0d, op2_sign_ext=%0d, res[%0d][%0d]=%0d, i[0]=%d", vrf_read_ram[vs1][read_element_idx], op1_sign_ext, op2_sign_ext, vd, read_element_idx, res, i[0]);
	 end
	 else
	 begin
	    if (funct3==OPMVV && funct6[5:3] == 3'b000)
	      if (read_element_idx==0)
		op1=vrf_read_ram[vs1][read_element_idx][31:0];
	      else
		op1=res;
	    else
	      op1=vrf_read_ram[vs1][read_element_idx][31:0];
	    if (funct3 == OPIVV || funct3 == OPMVV)
	      op2=vrf_read_ram[vs2][read_element_idx][31:0];
	    else if (funct3 == OPIVX || funct3 == OPMVX)
	      op2=tr.scalar;
	    else
	      op2={27'b0, tr.v_instruction[19:15]};//immediate
	    op1_sign_ext = op1;
	    op2_sign_ext = op2;
	    res = sc_calculate_arith(op1_sign_ext, op2_sign_ext, funct6, funct3, tr.sew);
	    if (funct3==OPMVV && funct6[5:3] == 3'b000) // reduction
	      vrf_read_ram[vd][0]=res;
	    else
	      vrf_read_ram[vd][read_element_idx]=res;
	    //$display("op1_sign_ext=%0d, op2_sign_ext=%0d, res[%0d][%0d]=%0d", op1_sign_ext, op2_sign_ext, vd, read_element_idx, res);
	 end

	 
	 
      end // for (int i=0; i<tr.vl; i++)
      cmp_exp_with_real(tr);
/* -----\/----- EXCLUDED -----\/-----
      vreg_to_update = vd*(`VLEN/32/`V_LANES);
	for (logic[31:0] j=0; j<`VLEN/8; j++)
	begin
	   vrf_vlane=j[$clog2(`V_LANES)-1:0]; // 1:0
	   byte_sel=j[$clog2(`V_LANES) +:2];
	   vrf_addr_offset = j[$clog2(`V_LANES) + 2 +: 27];
	   dut_vrf_data = backdoor_v_instr_vif.vrf_read_ram[vrf_vlane][0][0][vreg_to_update+vrf_addr_offset][byte_sel*8 +: 8] ^
			  backdoor_v_instr_vif.vrf_read_ram[vrf_vlane][1][0][vreg_to_update+vrf_addr_offset][byte_sel*8 +: 8];
	   //$display("vrf_addr_offset=%0d, vreg_to_update=%0d",vrf_addr_offset, vreg_to_update);
	   assert (vrf_read_ram[vd][j[31:2]][j[1:0]*8 +: 8] == dut_vrf_data)
	   
	     begin
		$display("instruction: %0x \t expected result[%0d][%0d][%0d]: %0x, dut_result[%0d][%0d][%0d]: %0x", tr.v_instruction, 
			 vd, j[31:2], j[1:0], vrf_read_ram[vd][j[31:2]][j[1:0]*8 +: 8], //exp result
			 vrf_vlane, vreg_to_update+vrf_addr_offset, byte_sel, dut_vrf_data);
		match_num++;
		match = 1;	
	   end
	   else
	   begin
	      match = 0;
	      `uvm_error("VECTOR_MISSMATCH", $sformatf("instruction: %0x \t expected result[%0d][%0d][%0d]: %0x, dut_result[%0d][%0d][%0d]: %0x", tr.v_instruction, 
						       vd, j[31:2], j[1:0], vrf_read_ram[vd][j[31:2]][j[1:0]*8 +: 8], //exp result
						       vrf_vlane, vreg_to_update+vrf_addr_offset, byte_sel, dut_vrf_data)) // dut result
	   end	   
	end
      if (match == 1)
      begin
	 `uvm_info(get_type_name(), $sformatf("V_MATCH: instruction: %0x", tr.v_instruction), UVM_MEDIUM)
      end
 -----/\----- EXCLUDED -----/\----- */
   endfunction


   function logic [31:0] sc_calculate_arith (logic [31:0] op1, logic[31:0] op2, logic [5:0] funct6, logic [2:0] funct3, sew);
      bit funct7_5;
      logic [31:0] res;

      if (funct3 == OPIVV || funct3 == OPIVX || funct3 == OPIVI)
	case (funct6)
	   6'b000000: begin	    
	      res = signed'(op1) + signed'(op2);	    
	   end
	   6'b000001: res = signed'(op1) - signed'(op2);
	   6'b000010: res = signed'(op1) - signed'(op2);
	   
	   6'b001001: res = op1 & op2;
	   6'b001010: res = op1 | op2;
	   6'b001011: res = op1 ^ op2;
	   6'b011000: res = op1 == op2;
	   6'b011001: res = op1 != op2;
	   6'b011010: res = unsigned'(op1) < unsigned'(op2);
	   6'b011011: res = signed'(op1) < signed'(op2);
	   6'b011100: res = unsigned'(op1) <= unsigned'(op2);
	   6'b011101: res = signed'(op1) <= signed'(op2);
	   6'b011110: res = unsigned'(op1) > unsigned'(op2);
	   6'b011111: res = signed'(op1) > signed'(op2);
	   default:begin
		`uvm_fatal("VECTOR INVALID INSTR", "FUNCT6 not implemeted or invalid")		// 
	   end

	endcase // case (funct6)
      else
	case (funct6)
	   6'b000000: begin	    
	      res = signed'(op1) + signed'(op2);	    
	   end
	   6'b000001: res = op1 & op2;
	   6'b000010: res = op1 | op2;
	   
	   6'b000011: res = op1 ^ op2;
	   6'b000100: res = unsigned'(op1) < unsigned'(op2) ? op1 : op2;
	   6'b000101: res = signed'(op1) < signed'(op2) ? op1 : op2;
	   6'b000110: res = unsigned'(op1) > unsigned'(op2) ? op1 : op2;
	   6'b000111: res = unsigned'(op1) > unsigned'(op2) ? op1 : op2;
	   6'b100100: begin
	      res = unsigned'(op1) * unsigned'(op2);
	      if (sew == 2'b00)
		return res[15:8];
	      else if (sew == 2'b01)
		return res[31:16];
	   end
	   6'b100101: res = signed'(op1) * signed'(op2);
	   6'b100110: res = unsigned'(op1) * signed'(op2);
	   6'b100111: begin
	      res = signed'(op1) * signed'(op2);
	      if (sew == 2'b00)
		return res[15:8];
	      else if (sew == 2'b01)
		return res[31:16];
	   end
	   6'b111011: begin
	      res = signed'(op1) * signed'(op2);
	      if (sew == 2'b00)
		return res[15:0];
	      else if (sew == 2'b01)
		return res[31:0];
	      else
		`uvm_fatal("VECTOR INVALID INSTR", "WIDENING MULTIPLY, WRONG SEW")		// 
	   end
	     
	   default:begin
	      `uvm_fatal("VECTOR INVALID INSTR", "FUNCT6 not implemeted or invalid")		// 
	   end

	endcase // case (funct6)
	

      return res;
   endfunction // sc_calculate_arith


   function void slide_instr_check(bd_v_instr_if_seq_item tr);
      logic [4:0] vs1;
      logic [4:0] vs2;
      logic [4:0] vd;
      logic 	  vm;
      logic [2:0] funct3;
      logic [5:0] funct6;
      logic [31:0] op1;
      logic [31:0] op2;
      logic [31:0] op1_sign_ext;
      logic [31:0] op2_sign_ext;
      int 	   vrf_addr_offset;
      int 	   vreg_to_update;
      int 	   element_idx;

      int          src_element_idx;
      int 	   vrf_vlane;
      int 	   byte_sel;
      int 	   dest_byte_sel;
      logic [7:0]  dut_vrf_data;
      int 	   match=0;
      logic [1:0]  sew;
      logic [31:0] res;
      vs1=tr.v_instruction[19:15];
      vs2=tr.v_instruction[24:20];
      vd=tr.v_instruction[11:7];
      vm=tr.v_instruction[25];
      funct3=tr.v_instruction[14:12];
      funct6=tr.v_instruction[31:26];

      //do the slide
      if (funct6==6'b001110)//slideup
	for (int i=0; i<(tr.vl<<tr.sew)-(tr.scalar << tr.sew); i++)
	begin	 
	   element_idx = i + (tr.scalar << tr.sew);
	   src_element_idx = i[31:2];
	   vrf_read_ram[vd][element_idx[31:2]][element_idx[1:0]*8 +: 8] = vrf_read_ram[vs2][src_element_idx][i[1:0]*8 +: 8];
	   //$display("vrf_dest[%0d][%0d][%0d]=%0x, vrf_src[%0d][%0d][%0d]=%0x", vd, element_idx[31:2], element_idx[1:0], vrf_read_ram[vd][element_idx[31:2]][element_idx[1:0]*8 +: 8], vs2, src_element_idx[31:2], src_element_idx[1:0], vrf_read_ram[vs2][src_element_idx[31:2]][src_element_idx[1:0]*8 +: 8]);
	end // for (int i=0; i<tr.vl; i++)
      else // slidedown
      begin
	 element_idx = (tr.vl<<tr.sew)-(tr.scalar << tr.sew) -1;
	 src_element_idx = (tr.vl << tr.sew)-1;
	 for (int i=0; i<(tr.vl<<tr.sew)-(tr.scalar << tr.sew); i++)
	 begin	 
	    vrf_read_ram[vd][element_idx[31:2]][element_idx[1:0]*8 +: 8] = vrf_read_ram[vs2][src_element_idx[31:2]][src_element_idx[1:0]*8 +: 8];
	    //$display("vrf_dest[%0d][%0d][%0d]=%0x, vrf_src[%0d][%0d][%0d]=%0x", vd, element_idx[31:2], element_idx[1:0], vrf_read_ram[vd][element_idx[31:2]][element_idx[1:0]*8 +: 8], vs2, src_element_idx[31:2], src_element_idx[1:0], vrf_read_ram[vs2][src_element_idx[31:2]][src_element_idx[1:0]*8 +: 8]);
	    element_idx--;
	    src_element_idx--;
	 end // for (int i=0; i<tr.vl; i++)
      end
      cmp_exp_with_real(tr);
      
   endfunction // slide_instr_check

   function void load_instr_check(bd_v_instr_if_seq_item tr);
      logic [4:0] vs1;
      logic [4:0] vs2;
      logic [4:0] vd;
      logic 	  vm;
      logic [2:0] width;
      logic [5:0] funct6;
      logic [1:0] mop;
      logic [31:0] op1;
      logic [31:0] op2;
      logic [31:0] op1_sign_ext;
      logic [31:0] op2_sign_ext;
      int 	   vrf_addr_offset;
      int 	   vreg_to_update;
      int 	   src_element_idx;
      int 	   element_idx;
      int 	   vrf_vlane;
      int 	   byte_sel=0;
      int 	   dest_byte_sel;
      logic [7:0]  dut_vrf_data;
      int 	   match=0;
      logic [1:0]  sew;
      logic [31:0] res;
      vs1=tr.v_instruction[19:15];
      vs2=tr.v_instruction[24:20];
      vd=tr.v_instruction[11:7];
      vm=tr.v_instruction[25];
      width=tr.v_instruction[14:12];
      mop = tr.v_instruction[27:26];
      
      funct6=tr.v_instruction[31:26];

      if (mop==2'b00)
      begin
	 src_element_idx = tr.scalar;
	 for (int i=0; i<tr.vl<<width[1:0]; i++)
	 begin
	    vrf_read_ram[vd][i[31:2]][i[1:0]*8 +: 8]=v_axi4_vif.ddr_mem[src_element_idx[31:2]][src_element_idx[1:0]*8 +: 8];
	    src_element_idx ++;
	 end // for (int i=0; i<tr.vl; i++)
      end
      if (mop==2'b10)
      begin
	 src_element_idx = tr.scalar;
	 byte_sel = src_element_idx[1:0];
	 for (int i=0; i<tr.vl<<tr.sew; i++)
	 begin
	    vrf_read_ram[vd][i[31:2]][i[1:0]*8 +: 8]=v_axi4_vif.ddr_mem[src_element_idx[31:2]][byte_sel*8 +: 8];
	    byte_sel++;
	    if (byte_sel==4)
	    begin
	       byte_sel = 0;
	       src_element_idx += tr.scalar2;
	    end
	 end // for (int i=0; i<tr.vl; i++)
      end
      
      cmp_exp_with_real(tr);
   endfunction // load_instr_check


   function void cmp_exp_with_real(bd_v_instr_if_seq_item tr);
      int 	   vrf_addr_offset;
      int 	   vreg_to_update;

      int 	   vrf_vlane;
      int 	   byte_sel;
      logic [7:0]  dut_vrf_data;
      int 	   match=0;
      logic [4:0]  vs1;
      logic [4:0] vs2;
      logic [4:0] vd;
      vs1=tr.v_instruction[19:15];
      vs2=tr.v_instruction[24:20];
      vd=tr.v_instruction[11:7];

      vreg_to_update = vd*(`VLEN/32/`V_LANES);
      for (logic[31:0] j=0; j<`VLEN/8; j++)
      begin
	 vrf_vlane=j[$clog2(`V_LANES)-1:0]; // 1:0
	 byte_sel=j[$clog2(`V_LANES) +:2];
	 vrf_addr_offset = j[$clog2(`V_LANES) + 2 +: 27];
	 dut_vrf_data = backdoor_v_instr_vif.vrf_read_ram[vrf_vlane][0][0][vreg_to_update+vrf_addr_offset][byte_sel*8 +: 8] ^
			backdoor_v_instr_vif.vrf_read_ram[vrf_vlane][1][0][vreg_to_update+vrf_addr_offset][byte_sel*8 +: 8];
	 //$display("vrf_addr_offset=%0d, vreg_to_update=%0d",vrf_addr_offset, vreg_to_update);
	 assert (vrf_read_ram[vd][j[31:2]][j[1:0]*8 +: 8] == dut_vrf_data)
	    
	   begin
/* -----\/----- EXCLUDED -----\/-----
	      $display("instruction: %0x \t expected result[%0d][%0d][%0d]: %0x, dut_result[%0d][%0d][%0d]: %0x", tr.v_instruction, 
		       vd, j[31:2], j[1:0], vrf_read_ram[vd][j[31:2]][j[1:0]*8 +: 8], //exp result
		       vrf_vlane, vreg_to_update+vrf_addr_offset, byte_sel, dut_vrf_data);
 -----/\----- EXCLUDED -----/\----- */
	      match_num++;
	      if (match==0)
		match = 1;	
	   end
	 else
	 begin	    
	    match = 0;
	    `uvm_error("VECTOR_MISSMATCH", $sformatf("instruction: %0x \t expected result[%0d][%0d][%0d]: %0x, dut_result[%0d][%0d][%0d]: %0x", tr.v_instruction, 
						     vd, j[31:2], j[1:0], vrf_read_ram[vd][j[31:2]][j[1:0]*8 +: 8], //exp result
						     vrf_vlane, vreg_to_update+vrf_addr_offset, byte_sel, dut_vrf_data)) // dut result
	 end	   
      end
      if (match == 1)
      begin
	 `uvm_info(get_type_name(), $sformatf("V_MATCH: instruction: %0x", tr.v_instruction), UVM_LOW)
      end
   endfunction
   function void report_phase(uvm_phase phase);
      `uvm_info(get_type_name(), $sformatf("RISCV scoreboard examined: %0d TRANSACTIONS", num_of_tr), UVM_LOW);
      `uvm_info(get_type_name(), $sformatf("Calc scoreboard examined: %0d MATCHES", match_num), UVM_LOW);
   endfunction : report_phase

   
endclass : riscv_v_scoreboard
