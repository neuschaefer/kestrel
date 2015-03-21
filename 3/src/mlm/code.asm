\ 
\ Cold Boot Entry Point
\ 

-> do-it-again
	X0 brod_initsp		SP	LD

	ZERO	CHAR *		A0	ADDI
	JAL> bios_putchar	RA	JAL

	ZERO	banner		A0	ADDI
	ZERO	banner_length	A1	ADDI
	JAL> bios_putstrc	RA	JAL

	\ Reset the line input buffer control block, and get the line of text.

	ZERO brod_bcb		T0		LD
	T0 bcb_licb		A0		ADDI
	T0 bcb_inpbuf		T2		ADDI
	T2			A0 blicb_buffer	SD	( licb.buffer -> inpbuf )
	ZERO			A0 blicb_length SD	( licb.length = 0 )
	ZERO 80			T2		ADDI
	T2			A0 blicb_capacity SD	( licb.capacity = 80 )
	JAL> bios_getline	RA		JAL

	\ Dump each entered word to the console, on a separate line.
	x0 x0			s9	ori
	x0 brod_bcb		s10	ld
	s10 bcb_licb		s10	addi
	s10 blicb_buffer	s7	ld
	s10 blicb_capacity	s8	ld
-> L1
	s9 s8			b> L2	bge	\ skip whitespace
	s7 s9			s6	add
	s6 0			s5	lb
	x0 33			s4	ori
	s5 s4			b> L2	bge
	s9 1			s9	addi
	L1			x0	JAL
-> L2
	x0 s9			s2	or	\ mark first non-whitespace char
-> L3
	s9 s8			b> L4	bge	\ skip non-whitespace
	s7 s9			a6	add
	a6 0			a5	lb
	x0 33			a4	ori
	a5 a4			b> L4	blt
	s9 1			s9	addi
	L3			x0	JAL
-> L4
	x0 s9			a2	or	\ mark next whitespace char index
	s2 a2			b> L5	beq	\ Are the indices the same?
	s7 s2			a0	add	\ If not, we have a word (of length end-beginning index) to print!
	a2 s2			a1 sub
	JAL> bios_putstrc	ra	JAL
	x0 10			a0	ori
	JAL> bios_putchar	ra	JAL
	L1			x0	JAL
-> L5
	x0 10			a0	addi	\ Print new prompt and repeat.
	JAL> bios_putchar	ra	JAL

  x0 crash_msg a0 addi
  jal> bios_putstrz ra jal
\  lc x0 jal

	do-it-again		X0	JAL

\ 
\ BIOS Character Services
\ 

\ Print a single character to the user's console.

-> bios_putchar ( ch )
		\ A0

	X0 brod_uart_base	T0	LD
	A0		T0 UART_TX	SB
	RA 0			X0	JALR



\ Print a counted string to the user's console.
\ This routine makes no attempt to interpret terminal control codes.

-> bios_putstrc ( strp, strlen )
		\  A0     A1
	SP -16			SP	ADDI
	S0			SP 0	SD
	RA			SP 8	SD

	X0 A0			S0	OR

-> .bios.putstrc.loop
	A1 X0			B> .bios.putstrc.done BEQ
	S0 0			A0	LBU
	bios_putchar		RA	JAL
	S0 1			S0	ADDI
	A1 -1			A1	ADDI
	.bios.putstrc.loop	X0	JAL

-> .bios.putstrc.done
	SP 8			RA	LD
	SP 0			S0	LD
	SP 16			SP	ADDI
	RA 0			X0	JALR

\ Print a zero-terminated string to the user's console.
\ This routine makes no attempt to interpret terminal control codes.

-> bios_putstrz ( strp )
		\  A0

	SP	-16		SP	ADDI
	S0			SP 0	SD
	RA			SP 8	SD

	A0	0		S0	ORI

-> .bios.putstrz.loop
	S0 0			A0			LBU
	ZERO	A0		B> .bios.putstrz.rtn	BEQ
	bios_putchar		RA			JAL
	S0	1		S0			ADDI
	.bios.putstrz.loop	X0			JAL

-> .bios.putstrz.rtn
	SP 8			RA	LD
	SP 0			S0	LD
	SP	16		SP	ADDI
	RA 0			X0	JALR


\ Check to see if a key has been pressed.
\ Returns pending ASCII code if a key is pending; use bios_getchar to pop it.
\ Returns zero otherwise.

-> bios_chkchar ( ) \ ascii
	X0 brod_bcb				T0			LD	( T0 -> BIOS Control Block )
	T0 bcb_keypress				A0			LBU	( do we have a key pending? )
	X0			A0		B> .bios.chkchar.done	BNE	( Yes, just return it )
	X0 brod_uart_base			T1			LD	( T1 -> UART base )
	T1 UART_RX				A0			LBU	( Check UART receive register )
	A0					T0 bcb_keypress		SB	( Hopefully queue key pending buffer )
-> .bios.chkchar.done
	RA 0					X0			JALR


\ Get a character, if it's been pressed.
\ Returns the current ASCII code if pending; zero otherwise.
\ Note that this function does not block.
\ To non-destructively read the next byte, if any, use bios_chkchar.

-> bios_getchar ( ) \ ascii
	X0 brod_bcb				T0			LD	( T0 -> BIOS Control Block )
	X0 brod_uart_base			T1			LD	( T1 -> UART )
	T0 bcb_keypress				A0			LBU	( pending keypress? )
	X0			A0		B> .bios.getchar.q	BNE	( Yes, pop the queue )
	T1 UART_RX				A0			LBU	( otherwise, read directly from uart )
	RA 0					X0			JALR

-> .bios.getchar.q
	X0					T0 bcb_keypress		SB
	RA 0					X0			JALR

\ Get a line of text from the user's console.
\ This routine is genuinely very basic.  It's intended for bootstrapping
\ purposes only.
\ 
\ Takes a pointer to a Line Input Control Block.  You are responsible for
\ initializing the control block prior to calling this procedure.
\ The Buffer field must point to the input buffer.  The Capacity field must
\ contain the maximum size of the buffer.  Unless you know exactly what you're
\ doing, you will want to set the Length field to zero.
\ 
\ Upon return from this procedure, the Length field will contain the number of
\ valid bytes in the buffer.  Note that this procedure WILL NOT null-terminate
\ the buffer contents.  If this is important for your purposes, you'll need to
\ manually terminate the buffer yourself.
-> bios_getline ( licb )
		\  A0
	SP -16			SP	ADD
	RA			SP 0	SD
	S0			SP 8	SD

	ZERO A0			S0	OR

-> wait-for-key
	bios_chkchar		RA	JAL
	X0 A0			wait-for-key BEQ
	bios_getchar		RA	JAL

	S0 blicb_length		T2	LD

	\ If the user presses ENTER, we accept the buffer as-is.
	\ It's up to the consumer to check for zero-length buffers.
	ZERO 10			T3	ADDI
	A0 T3			B> not-cr BNE

	SP 8			S0	LD
	SP 0			RA	LD
	SP 16			SP	ADDI
	RA 0			X0	JALR

	\ If backspace, and buffer non-empty, back up one space.
-> not-cr
	ZERO 127		T3	ORI
	A0 T3			B> bs-del BEQ
	ZERO 8			T3	ORI
	A0 T3			B> not-bs BNE

-> bs-del
	X0 T2			wait-for-key BEQ

	T2 -1			T2	ADDI
	T2			S0 blicb_length SD

	0			A0	AUIPC	( print bs, space, bs )
	A0 12			A0	ADDI
	bios_putstrz		RA	JAL
	wait-for-key		X0	JAL
	8 B, 32 B, 8 B, 0 B,

	\ Ignore key press if there's no room to place it.
-> not-bs
	S0 blicb_capacity	T3	LD
	T2 T3			wait-for-key BEQ

	\ Place the byte, and increment the buffer length.
	S0 blicb_buffer		T3	LD
	T2 T3			T3	ADD
	A0			T3 0	SB
	T2 1			T2	ADDI
	T2			S0 blicb_length SD

	bios_putchar		RA	JAL
	wait-for-key		X0	JAL

