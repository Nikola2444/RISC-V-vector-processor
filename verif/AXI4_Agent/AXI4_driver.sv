`ifndef AXI4_DRIVER_SV
 `define AXI4_DRIVER_SV
class AXI4_driver extends uvm_driver#(AXI4_seq_item);

   `uvm_component_utils(AXI4_driver)
   
   //logic [31:0] ddr_mem[4096];
   typedef enum {rd_idle_phase, rd_phase} read_fsm;
   read_fsm axi_read_channel = rd_idle_phase;

   typedef enum {wr_idle_phase, wr_phase, resp_phase} write_fsm;
   write_fsm axi_write_channel = wr_idle_phase;

   virtual interface axi4_if vif;
   function new(string name = "AXI4_driver", uvm_component parent = null);
      super.new(name,parent);
   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (!uvm_config_db#(virtual axi4_if)::get(this, "", "axi4_if", vif))
        `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"})



   endfunction : connect_phase

   
   task main_phase(uvm_phase phase);


      forever begin  
	 fork
	    // Two threads, one for AXI4 read port and the other
	    // for AXI4 write port.
	    start_axi4_read_slave();
	    start_axi4_write_slave();
	 join 	
      end
   endtask : main_phase


   task start_axi4_read_slave ();
      int num_of_data_read = 0;
      int rd_transfer_base_addr=0;
      int read_burst_length=0;
      forever begin
	 @(negedge vif.clk);
	 case (axi_read_channel)
            rd_idle_phase:  begin
               read_burst_length = vif.burst_len;
               vif.m_axi_rlast = 0;
               vif.m_axi_arready = 0;
               vif.m_axi_rvalid = 0;          
               if (vif.m_axi_arvalid) begin
		  axi_read_channel = rd_phase;
		  vif.m_axi_arready = 1'b1;
		  rd_transfer_base_addr = vif.m_axi_araddr/4;
		  //$display("going to rd phase");
		  read_burst_length = vif.m_axi_arlen;
               end
            end
            rd_phase: begin
               vif.m_axi_arready = 1'b0;
               vif.m_axi_rdata = vif.ddr_mem[rd_transfer_base_addr + num_of_data_read];
               //vif.m_axi_rvalid = $random();
               vif.m_axi_rvalid = 1'b1;
               if (vif.m_axi_rready && vif.m_axi_rvalid) begin            
		  if ((num_of_data_read+1)%(read_burst_length+1)  == 0 && num_of_data_read != 0) begin
		     axi_read_channel = rd_idle_phase;
		     vif.m_axi_rlast = 1;
		     num_of_data_read = 0;
		  end
		  else begin
		     vif.m_axi_rlast = 0;
		     num_of_data_read++;
		  end
               end
            end
	 endcase
      end
   endtask // startaxi4_read_slave


   task start_axi4_write_slave ();
      int i = 0;
      int wr_transfer_base_addr=0;
      int write_burst_length;
      forever begin
	 @(negedge vif.clk);
	 case (axi_write_channel)
            wr_idle_phase:  begin
               i = 0;
               vif.m_axi_bvalid = 0;
               write_burst_length = vif.burst_len;
               vif.m_axi_awready = 0;
               vif.m_axi_wready = 0;               
               if (vif.m_axi_awvalid) begin
		  vif.m_axi_awready = 1;
		  axi_write_channel = wr_phase;
		  wr_transfer_base_addr = vif.m_axi_awaddr/4;
		  write_burst_length = vif.m_axi_awlen;
               end
            end
            wr_phase: begin
               vif.m_axi_awready = 1'b0;        
               vif.m_axi_wready = $random();         
               if (vif.m_axi_wready && vif.m_axi_wvalid) begin
		  vif.ddr_mem[wr_transfer_base_addr+i]=vif.m_axi_wdata[31:0];
		  i++;
		  if (vif.m_axi_wlast)
		    axi_write_channel = resp_phase;
		  //$display("vif.ddr_mem[%d]=%d",wr_transfer_base_addr+i, vif.ddr_mem[wr_transfer_base_addr+i]);
               end
            end
            resp_phase:begin
               vif.m_axi_wready = 1'b0;
               //vif.m_axi_bresp = 2'b00;
               vif.m_axi_bvalid = 1;
               i = 0;
               if (vif.m_axi_bready)
		 axi_write_channel = wr_idle_phase;
            end
	 endcase
      end
   endtask // startaxi4_read_slave
endclass : AXI4_driver

`endif

