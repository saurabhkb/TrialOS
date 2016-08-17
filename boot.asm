global start
extern long_mode_start

section .text
bits 32
start:
	mov esp, stack_top			; initialize stack pointer (so that call, ret work)
	mov edi, ebx				; move multiboot info (from ebx where grub puts it) into edi to pass as argument to C later
	call check_multiboot
	call check_cpuid
	call check_long_mode

	call setup_page_tables
	call enable_paging

	lgdt [gdt64.pointer]	; load 64b GDT

	; update GDT code and data selectors (indices to code/data segment entries in GDT)
	mov ax, gdt64.data
	mov ss, ax	; stack selector
	mov ds, ax	; data selector
	mov es, ax	; extra selector

	jmp gdt64.code:long_mode_start	; long jump into different code segment (=> different code selector)

	mov word [0xb8000], 0x0248	; H (0248 -> bg (0), fg (2), color (48))
	mov word [0xb8002], 0x0265	; e
	mov word [0xb8004], 0x026c	; l
	mov word [0xb8006], 0x026c	; l
	mov word [0xb8008], 0x026f	; o
	mov word [0xb800a], 0x0221	; !
	hlt

; check if we were loaded by a multiboot compliant bootloader
check_multiboot:
	cmp eax, 0x36d76289	; magic number for multiboot
	jne .no_multiboot
	ret
.no_multiboot:
	mov al, "0"
	jmp error


; CPUID instruction - used to retrieve info about the CPU (mainly supported features)
; Check whether CPUID itself is supported -> ID bit in eflags is modifiable (in eflags register) only if CPUID is supported
check_cpuid:
	pushfd				; save eflags on stack
	pop eax				; copy eflags into eax
	mov ecx, eax		; copy flags into ecx
	xor eax, 0x00200000	; flip ID bit (1 << 21 flip ID bit (1 << 21)
	push eax			; push modified eflags onto stack
	popfd				; attempt to copy modified flags into eflags register
	pushfd				; push possibly modified eflags back to stack
	pop eax				; copy into eax (may or may not be modified depending on CPUID support)
	push ecx			; push flags to stack
	popfd				; restore eflags
	xor eax, ecx		; compare new and old eflags
	jz .no_cpuid
	ret
.no_cpuid:
	mov al, "1"
	jmp error


; check whether long mode is supported (where 64 bit instructions and registers can be accessed)
check_long_mode:
	mov eax, 0x80000000		; Set the A-register to 0x80000000.
	cpuid					; CPU identification.
	cmp eax, 0x80000001		; Compare the A-register with 0x80000001.
	jb .no_long_mode		; It is less, there is no long mode.
	mov eax, 0x80000001		; Set the A-register to 0x80000001.
	cpuid					; CPU identification.
	test edx, 1 << 29		; Test if the LM-bit is set in the D-register.
	jz .no_long_mode		; They aren't, there is no long mode.
	ret
.no_long_mode:
	mov al, "2"
	jmp error
	

; Prints ERR: <error code> to screen and hangs
; @param error code in al
error:
	mov dword [0xb8000], 0x4f524f45	; 4f=>white on red, 52=>R...
	mov dword [0xb8004], 0x4f3a4f52
	mov dword [0xb8008], 0x4f204f20
	mov byte [0xb800a], al
	hlt

; this function identity maps the first GiB (512 entries of 2MiB) of virtual memory (i.e the virtual memory and physical memory have a 1-1 mapping => memory accessible through the same virtual and physical addresses)
setup_page_tables:
	; map first entry of P4 to P3 table
	mov eax, p3_table	; move address of P3 into eax
	or eax, 0b11		; set the present + writable flags
	mov [p4_table], eax	; move the address into the first page table entry of P4

	; map first entry of P3 to P2
	mov eax, p2_table
	or eax, 0b11
	mov [p3_table], eax

	; map each P2 entry (512 in total) to a huge 2MiB page
	mov ecx, 0	; counter
	.map_p2_table:
		; map ecx-th P2 entry to a huge page that starts at address 2MiB * ecx
		mov eax, 0x200000	; 2MiB
		mul ecx				; start address of this iteration's page
		or eax, 0b10000011	; set present + writable + huge flags
		mov [p2_table + ecx * 8], eax	; map ecx-th page table entry to this start address (and flags)

		inc ecx
		cmp ecx, 512
		jne .map_p2_table
	ret

enable_paging:
	; load P4 into CR3 register (CPU uses this to access the root (P4) table)
	mov eax, p4_table
	mov cr3, eax

	; enable PAE flag (Physical address extension) in cr4
	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	; set the long mode bit in the EFER MSR (model specific register)
	mov ecx, 0xC0000080	; ecx points to the EFER register
	rdmsr
	or eax, 1 << 8
	wrmsr

	; enable paging in the cr0 register
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	ret

section .bss
; Initialize page tables (each page table has 512 8Byte entries => 4096B per table)
; We skip the P1 table since we use 2MiB pages instead directly referenced from P2
align 4096
p4_table:
	resb 4096
p3_table:
	resb 4096
p2_table:
	resb 4096
; Create a stack and initialize ESP to point to top
; so that we can call functions
stack_bottom:
	resb 4096
stack_top:

section .rodata
gdt64:
	dq 0															; first zero entry
.code: equ $ - gdt64
	dq (1 << 44) | (1 << 47) | (1 << 41) | (1 << 43) | (1 << 53)	; code segment (setting various flags)
.data: equ $ - gdt64
	dq (1<<44) | (1<<47) | (1<<41)									; data segment
.pointer:
	dw $ - gdt64 - 1	; GDT length - 1
	dq gdt64			; GDT start address

