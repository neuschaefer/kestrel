		include "asrt.i"

		include "tests/numb/eitherHexOrDecimal.asm"
		include "numb_eitherHexOrDecimal.asm"
		include "numb_nextChar.asm"


epv_numbTryUnsignedNumber = 0


numbTryUnsignedNumber:
		ld	t0, zpV(x0)
		jalr	x0, epv_numbTryUnsignedNumber(t0)


		align 4
start_tests:	jal	a0, asrtBoot
		align	8
		dword	2
		dword	romBase+testNumbDecimal
		dword	romBase+testNumbHex

		; Must be the very last thing in the ROM image.
		include "asrt.asm"
