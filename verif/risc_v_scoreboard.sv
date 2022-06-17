class riscv_scoreboard extends uvm_scoreboard;

   // control fileds
   bit checks_enable = 1;
   bit coverage_enable = 1;

   // This TLM port is used to connect the scoreboard to the monitor
   uvm_analysis_imp#(calc_seq_item, calc_scoreboard) item_collected_imp;

   int num_of_tr;

   `uvm_component_utils_begin(calc_scoreboard)
      `uvm_field_int(checks_enable, UVM_DEFAULT)
      `uvm_field_int(coverage_enable, UVM_DEFAULT)
   `uvm_component_utils_end

   function new(string name = "calc_scoreboard", uvm_component parent = null);
      super.new(name,parent);
      item_collected_imp = new("item_collected_imp", this);
   endfunction : new

   function write (calc_seq_item tr);
      calc_seq_item tr_clone;
      $cast(tr_clone, tr.clone());
      if(checks_enable) begin
         // do actual checking here
         // ...
         // ++num_of_tr;
      end
   endfunction : write

   function void report_phase(uvm_phase phase);
      `uvm_info(get_type_name(), $sformatf("Calc scoreboard examined: %0d transactions", num_of_tr), UVM_LOW);
   endfunction : report_phase

endclass : calc_scoreboard
