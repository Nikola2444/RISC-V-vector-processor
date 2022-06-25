`ifndef BD_V_DATA_IF_DRIVER_SV
 `define BD_V_DATA_IF_DRIVER_SV
class bd_v_data_if_driver extends uvm_driver#(bd_v_data_if_seq_item);

   `uvm_component_utils(bd_v_data_if_driver)

   typedef enum {rd_idle_phase, rd_phase} read_fsm;
   read_fsm read_channel = rd_idle_phase;

   typedef enum {wr_idle_phase, wr_phase, resp_phase} write_fsm;
   write_fsm write_channel = wr_idle_phase;

   //logic [31:0] backdoor_v_data_vif.ddr_mem[4096];

   virtual interface backdoor_v_data_if backdoor_v_data_vif;
   function new(string name = "bd_v_data_if_driver", uvm_component parent = null);
      super.new(name,parent);
      if (!uvm_config_db#(virtual backdoor_v_data_if)::get(this, "", "backdoor_v_data_if", backdoor_v_data_vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set:",get_full_name(),".vif"})
   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);

   endfunction : connect_phase

   
   task main_phase(uvm_phase phase);      
      forever begin	 	 
	 fork
	    start_read_slave();
	    start_write_slave();
	 join	 
      end
   endtask : main_phase
   
   task start_read_slave ();
      logic [31:0] ctrl_raddr_offset;
      logic [31:0] ctrl_rxfer_size;
      int 	   data_offset=0;
      forever
      begin
	 @(negedge backdoor_v_data_vif.clk);
	 case(read_channel)
	    rd_idle_phase: begin
	       backdoor_v_data_vif.ctrl_rdone_i = 1'b0;
	       backdoor_v_data_vif.rd_tvalid_i = 0;
	       backdoor_v_data_vif.rd_tlast_i = 1'b0;
	       if (backdoor_v_data_vif.ctrl_rstart_o) 
	       begin
		  data_offset = 0;
		  ctrl_raddr_offset = backdoor_v_data_vif.ctrl_raddr_offset_o;
		  ctrl_rxfer_size = backdoor_v_data_vif.ctrl_rxfer_size_o/4;
		  read_channel = rd_phase;
	       end
	    end
	    rd_phase: begin
	       backdoor_v_data_vif.rd_tvalid_i = $urandom_range(0, 1);
	       if (backdoor_v_data_vif.rd_tready_o && backdoor_v_data_vif.rd_tvalid_i)
	       begin
		  backdoor_v_data_vif.rd_tdata_i = backdoor_v_data_vif.ddr_mem[ctrl_raddr_offset+data_offset];
		  data_offset++;
		  if (data_offset==ctrl_rxfer_size)
		  begin
		     backdoor_v_data_vif.ctrl_rdone_i = 1'b1;
		     backdoor_v_data_vif.rd_tlast_i = 1'b1;
		     read_channel=rd_idle_phase;
		  end
	       end
	    end
	 endcase
      end
   endtask // startread_slave

   task start_write_slave ();
      logic [31:0] ctrl_waddr_offset;
      logic [31:0] ctrl_wxfer_size;
      int 	   data_offset=0;

      forever
      begin
	 @(negedge backdoor_v_data_vif.clk);
	 case(write_channel)
	    wr_idle_phase: begin
	       backdoor_v_data_vif.wr_tready_i = 0;
	       backdoor_v_data_vif.ctrl_wdone_i=1'b0;
	       if (backdoor_v_data_vif.ctrl_wstart_o) 
	       begin
		  data_offset = 0;
		  ctrl_waddr_offset = backdoor_v_data_vif.ctrl_waddr_offset_o;
		  ctrl_wxfer_size = backdoor_v_data_vif.ctrl_wxfer_size_o;
		  write_channel = wr_phase;
	       end
	    end
	    wr_phase: begin
	       backdoor_v_data_vif.wr_tready_i = $urandom_range(0, 1);
	       if (backdoor_v_data_vif.wr_tready_i && backdoor_v_data_vif.wr_tvalid_o)
	       begin
		  backdoor_v_data_vif.ddr_mem[ctrl_waddr_offset+data_offset] = backdoor_v_data_vif.wr_tdata_o;
		  data_offset++;
		  if (data_offset==ctrl_wxfer_size)
		  begin
		     backdoor_v_data_vif.ctrl_wdone_i=1'b1;
		     write_channel=wr_idle_phase;
		  end
	       end
	    end
	 endcase
      end
   endtask

endclass : bd_v_data_if_driver

`endif

