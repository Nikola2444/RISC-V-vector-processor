

all: assembly.dump

assembly.dump: assembly.o
	../installs/riscv-gcc/riscv64-unknown-elf/bin/objdump -d assembly.o > assembly.dump
assembly.o: assembly.s
	../installs/riscv-gcc/riscv64-unknown-elf/bin/as -march=rv64iv -o assembly.o assembly.s

.PHONY:clean
clean:
	@rm -r -f -d *.dump *.o *~
