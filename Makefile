.SUFFIXES:

CC=x86_64-elf-gcc
CFLAGS:=-m64 -std=c11 -ffreestanding -O2 -mno-red-zone -static -Wall -Wextra -nostdlib -nostartfiles -nodefaultlibs

default: build

.PHONY: clean

build: build/os.iso

build/multiboot_header.o: multiboot_header.asm
	mkdir -p build
	nasm -f elf64 multiboot_header.asm -o build/multiboot_header.o

build/boot.o: boot.asm
	mkdir -p build
	nasm -f elf64 boot.asm -o build/boot.o

build/long_mode_init.o: long_mode_init.asm
	mkdir -p build
	nasm -f elf64 long_mode_init.asm -o build/long_mode_init.o

build/kernel.bin: build/multiboot_header.o build/boot.o build/long_mode_init.o build/vga_buffer.o build/cmain.o linker.ld
	ld -n --gc-sections -o build/kernel.bin -T linker.ld build/multiboot_header.o build/boot.o build/long_mode_init.o build/vga_buffer.o build/cmain.o

build/cmain.o: cmain.c 
	$(CC) $(CFLAGS) -c cmain.c -o build/cmain.o

build/vga_buffer.o: vga_buffer.c vga_buffer.h
	$(CC) $(CFLAGS) -c vga_buffer.c -o build/vga_buffer.o

build/os.iso: build/kernel.bin grub.cfg
	mkdir -p build/isofiles/boot/grub
	cp grub.cfg build/isofiles/boot/grub
	cp build/kernel.bin build/isofiles/boot/
	grub-mkrescue -o build/os.iso build/isofiles

clean:
	rm -rf build

run:
	qemu-system-x86_64 -cdrom build/os.iso
