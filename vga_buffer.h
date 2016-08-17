#ifndef VGA_BUFFER_H
#define VGA_BUFFER_H

typedef enum {
	Black		= 0,
	Blue		= 1,
	Green		= 2,
	Cyan		= 3,
	Red			= 4,
	Magenta		= 5,
	Brown		= 6,
	LightGray	= 7,
	DarkGray	= 8,
	LightBlue	= 9,
	LightGreen	= 10,
	LightCyan	= 11,
	LightRed	= 12,
	Pink		= 13,
	Yellow		= 14,
	White		= 15,
} Color;


typedef struct {
	unsigned row;
	unsigned column;
	char color_code;
	char *buffer;
} Writer;

char new_color_code(Color, Color);
void init(Writer *, char *);
void write_byte(Writer *, char);
void write_string(Writer *, char *, unsigned);
void fill_screen(Writer *, char *);

#endif
