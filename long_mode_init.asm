global long_mode_start

section .text
bits 64
long_mode_start:
	; call C main
	extern c_main
	call c_main
	hlt
