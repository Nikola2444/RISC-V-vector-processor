------------------------------------------------------------------------
This makefile runs vivado synthesis and implementaion of 
hdl files in batch mode. On default it synthesizes the whole 
vector processor  design but it can synthesize any cystom design. 

----------------------------SYNTHESIS-----------------------------------

If you want to run synthesis of vector processor design just type:
		
        make run_synth
  		
if you want to run synthesis of custom file there are two ways:

1) If only one file needs to be synthesized type:
          
        make run_synth top=<top_file_name> src_path=<path_to_custom_file>                
	
   Example:
	      make run_synth top=find src_path=../../sources/design/find.sv
  

2) Synthesis of multiple files is done in a similar manner 
   but a .f file, in which all the files being sythesized 
   are listed, is needed.
  
   Example 

        make run_synth top=alu src_path=custom_synth.f

   
   In .f file, files that are being synthesized need to be
   listed like shown below:
         
   --------------------------F_FILE-------------------------           

                ../hdl/riscv-v/vector_core/v_lane/rtl/alu.sv
		../hdl/riscv-v/vector_core/v_lane/rtl/vrf.sv


   --------------------------F_FILE-------------------------
	
   

----------------------------IMPLEMENTATION--------------------------------
	
Implementation is done in a similar manner but instead
of make run_synth you need to type make run_impl

EXAMPLE1: Implementation of vector processor design
  
        make run_impl

EXAMPLE2: Implementation of a single HDL file

	      make run_impl top=find src_path=../../sources/design/find.sv

EXAMPLE3: Implementation of a multiple HDL files

        make run_impla top=find src_path=custom_synth.f


----------------------------RESULTS---------------------------------------
Synthesis results will appear in a directory wich has a name of module
being synthesized concataneted to a time stamp. In this directory
4 kinds of reports will appear:

    -Hierarchy report: resource utilization of each component in
                       the hierarchy.
    -Module report: specifies which components were used to implement
                    the desing (LUT2, LUT3, LUT4, LUT RAM....) 
    -Timing_summary_synthesis report: Timing report after synthesis
    -Timing_summary_implementation report: Timing report after implementation

----------------------------ADVANCED-------------------------------------
Besides top and src_path argumets, make file can also accept:

 1) frequency: You can set syntesis and implementation frequency 
             (Default is 250Mhz). Example is showed below:

        make run_synth top=activation_pipe src_path=custom_synth.f frequency=300

 2) clk_name: This argument needs to be set if clk name of top 
              module is not "clk" and is lets say ap_clk. Example 
              is showed bellow.
        
        make run_synth top=activation_pipe src_path=custom_synth.f clk_name=ap_clk

 3) clk2_name: This argument needs to be set if module has 2 clocks
               .Example is showed bellow.
                       
        make run_synth top=activation_pipe src_path=custom_synth.f clk_name=ap_clk clk2_name=ap_clk_2
             
 4) optimize: "yes" or "no" (defaut is "no").  If this is set to yes, 
              synthesis script reads configuration from impl_opt.tcl 
              and synth_opt.tcl files, in which  you can set what optimization 
              you want the tool to do during synthesis and during implementation. 
              Example is shown below

        make run_synth top=activation_pipe src_path=custom_synth.f optimize=yes

 5) part_name: If you want to synthesize for another board, you need 
               to set board part (default part_name is "xc7z020clg484-1", which is zedboard). 
               Example is showed bellow:
         
        make run_synth top=activation_pipe src_path=custom_synth.f part_name="xc7z020clg484-1" 
