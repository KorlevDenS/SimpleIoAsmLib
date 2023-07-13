ASM=nasm
ASMFLAGS=-f elf64
LD=ld
%.o: %.asm
	$(ASM) $(ASMFLAGS) -o $@ $<
main.o: main.asm words.inc lib.inc
	$(ASM) $(ASMFLAGS) -o $@ $<
program: main.o dict.o lib.o
	$(LD) -o $@ $^
.PHONY: clean
clean:
	rm *.o temp
