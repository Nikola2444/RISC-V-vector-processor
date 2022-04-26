src_path ?= nesto
run_synth ?= run_synth.tcl
top ?= nesto
run_implementation = no
run_for_all_boards ?= no
frequency ?= 250
part_name ?= xc7z020clg484-1
#alveo_part_name = xcu200-fsgd2104-2-e  
optimize ?= no
clk_name ?= clk
clk2_name ?= no_clock
mkfile_path := $(abspath $(lastword Makefile))
RISCV_vector_processor_dir := $(shell echo $(mkfile_path) | sed -e 's/RISC-V-vector-processor.*/RISC-V-vector-processor/')

tcl_args = $(top) \
	$(src_path) \
	$(run_implementation) \
	$(run_for_all_boards) \
	$(frequency) \
	$(part_name) \
	$(optimize) \
	$(clk_name)\
	$(clk2_name) 

.PHONY: all
all: run_synth

run_impl:
	$(eval run_implementation := yes)
	@vivado -mode batch -source $(run_synth) -tclargs $(tcl_args)

run_synth:
	@vivado -mode batch -source $(run_synth) -tclargs $(tcl_args)	

check:
	@echo $(NPU_PAR_RTL_DIR)

.EXPORT_ALL_VARIABLES:

COMMON_DIR = $(RISCV_vector_processor_dir)/hdl/common/
V_LANE_DIR = $(RISCV_vector_processor_dir)/hdl/riscv-v/vector_core/v_lane/rtl/

.PHONY: clean
clean:
	@rm -rf result_*
	@rm -f vivado*.jou
	@rm -f vivado*.log
	@rm -rf .Xil
	@rm -rf .srcs
	@rm -rf .gen
	@rm -rf .ip_user_files
	@rm -rf *.dcp
	@rm -rf *.log
	@rm -rf *.*~		
	@rm -rf .#*.*#		
.PHONY: help
help:
	@cat README.md
