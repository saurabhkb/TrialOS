#include "vga_buffer.h"

extern void c_main(void *mb_info) {
	char *hello = "hello!";
	char color_code = new_color_code(Red, White);

	Writer w;
	init(&w, &color_code);
	fill_screen(&w, 0);
	write_string(&w, hello, 6);

	while(1);
}
