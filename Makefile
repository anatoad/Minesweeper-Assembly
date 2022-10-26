all: minesweeper.o minesweeper

minesweeper.o: minesweeper.asm header.asm utils.asm
	nasm -o minesweeper.o -f elf64 minesweeper.asm

minesweeper: minesweeper.o
	ld -o minesweeper -m elf_x86_64 minesweeper.o

clean:
	rm -rf minesweeper.o minesweeper