interface BIPAD_IF;

	logic OE;
	logic IN;
	logic OUT;

	modport PADFRAME_SIDE (
		input OE, 
		input OUT,
		output IN
	);

	modport PERIPH_SIDE (
		output OE, 
		output OUT,
		input IN 
	);

endinterface