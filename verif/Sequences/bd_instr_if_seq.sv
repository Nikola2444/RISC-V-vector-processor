`ifndef RISCV_V_SIMPLE_SEQ_SV
 `define RISCV_V_SIMPLE_SEQ_SV

class riscv_v_simple_seq extends riscv_v_base_seq;

   `uvm_object_utils (riscv_v_simple_seq)
   typedef  logic [31 : 0] instr_queue[$];
   //string 		   assembly_file_path = "/home/nikola/Documents/git_repos/RISC-V-vector-processor/verif/Assembly_code/assembly_test.b";
   string 		   assembly_file_path = "assembly_test.b";
   instr_queue instr_queue_1;

   function new(string name = "riscv_v_simple_seq");
      super.new(name);
   endfunction

   virtual task body();
      // Ask for address
      instr_queue_1 = read_instr_from_file (assembly_file_path);
      req = bd_instr_if_seq_item::type_id::create("req"); 
      foreach (instr_queue_1[i])
      begin
	 start_item(req);
	 finish_item(req);
	 req.instruction=instr_queue_1[req.instruction_addr/4];
	 // Send the data
	 start_item(req);
	 finish_item(req);
      end
   endtask : body

   function instr_queue read_instr_from_file (string assembly_file_path);       
      logic [31:0] instr;
      int 	   fd = $fopen (assembly_file_path, "r");
      instr_queue instr_queue_1;
      while (!$feof(fd)) begin
	 $fscanf(fd,"%b\n",instr);
	 instr_queue_1.push_back(instr);
      end
      
      foreach (instr_queue_1[i])          	
	`uvm_info(get_type_name(),
                  $sformatf("instruction[%d]: %b", i, instr_queue_1[i]),
                  UVM_FULL)
      return instr_queue_1;
   endfunction
endclass : riscv_v_simple_seq

`endif
