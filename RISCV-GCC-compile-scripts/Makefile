
src ?= assembly.s
all: assembly.dump

assembly.dump: assembly.o
	../installs/riscv-gcc/riscv64-unknown-elf/bin/objdump -d assembly.o > assembly.dump
assembly.o: $(src)
	../installs/riscv-gcc/riscv64-unknown-elf/bin/as -march=rv64iv -o assembly.o $(src)

.PHONY:clean
clean:
	@rm -r -f -d *.dump *.o *~
