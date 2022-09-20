
src ?= assembly.s
all: assembly.dump convert_to_raw_hex assembly.h 
bin_path = /opt/riscv/riscv64-unknown-elf/bin

assembly.h : assembly_noaddr.dump convert_to_raw_hex
	./convert_to_raw_hex
convert_to_raw_hex : convert_to_raw_hex.c
	gcc -o convert_to_raw_hex convert_to_raw_hex.c
assembly_noaddr.dump: assembly.o
	$(bin_path)/objdump -d --no-addresses assembly.o > assembly_noaddr.dump

assembly.dump: assembly.o
	$(bin_path)/objdump -d assembly.o > assembly.dump
assembly.o: $(src)
	$(bin_path)/as -march=rv64iv -o assembly.o $(src)

.PHONY:clean
clean:
	@rm -r -f -d *.dump *.o *~ *.h convert_to_raw_hex
