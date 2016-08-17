ENTRY(start)

SECTIONS {
	. = 1M;

	.boot :
	{
		/* ensure that the nultiboot header is at the beginning */
		/* we use --gc-sections (garbage collect sections) flag on ld to remove any extraneous sections that get compiled in */
		/* but we must keep this one even if we are not referring to it explicitly */
		KEEP(*(.multiboot_header))
	}

	.text :
	{
		*(.text)
	}
}
