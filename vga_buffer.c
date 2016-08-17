#include "vga_buffer.h"

char new_color_code(Color fg, Color bg) {
	char c = bg;
	c <<= 4;
	c |= fg;
	return c;
}

// initializes writer
// sets buffer to point to start of VGA
// sets cursor to (0, 0)
// sets default color to black on white
void init(Writer *w, char *cc) {
	w->buffer = 0xb8000;
	w->row = w->column = 0;
	if(cc)
		w->color_code = *cc;
	else
		w->color_code = new_color_code(Black, White);
}

void write_byte(Writer *w, char ascii_char) {
	int addr = w->row * 80 + w->column;
	w->buffer[addr] = ascii_char;
	w->buffer[addr + 1] = w->color_code;
	w->column += 2;
}

void write_string(Writer *w, char *str, unsigned len) {
	unsigned i = 0;
	for(; i < len; i++) {
		write_byte(w, str[i]);
	}
}

void fill_screen(Writer *w, char *cc) {
	int i = 0;
	int addr = 0;
	char fill_cc = (cc) ? (*cc) : new_color_code(White, White);
	for(; i < 80 * 25 * 2; i++) {
		w->buffer[addr] = ' ';
		w->buffer[addr + 1] = fill_cc;
		addr += 2;
	}
}
