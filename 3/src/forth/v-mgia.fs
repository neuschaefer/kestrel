\ Video Driver for EForth.  Normally, EForth is intended to
\ talk to a serial console.  In some early implementations,
\ it was hooked up to the host OS via special BIOS or MS-DOS
\ entry-points.  Since I'm using EForth as a self-standing
\ OS, the video driver must be written for/in EForth itself.
\ 
\ This software is written with the assumption that the MGIA's
\ 640x480 monochrome bitmap sits at $FF0000 in memory.  It
\ further assumes that the system font uses 8x8 pixel glyphs.

tglobal cursorX	( Ideally, these ought to be headerless )
tglobal cursorY
\ tglobal cursorHidden
\ tglobal cursorVisible

tcreate font
S" v-font.fs" included

t: AT-XY	cursorY ! cursorX ! ;
t: AT-XT?	cursorX @ cursorY @ ;

t: CLS		$FF9600 $FF0000 DO 0 R@ ! 8 +LOOP ;
t: HOME		0 0 AT-XY ;
t: PAGE		CLS HOME ;

t: top		$FF0000 cursorX @ + cursorY @ 640 * + ;
t: plot		font + top 7 FOR OVER C@ OVER C!
		80 + SWAP 256 + SWAP NEXT 2DROP ;
t: feed		$FF0000 $FF9600 $FF0280 DO
		R@ @ OVER ! 8 + 8 +LOOP DROP ;
t: blank	$FF9380 79 FOR 0 OVER ! 8 + NEXT DROP ;
		( line 59 byte address )
t: scroll	feed blank ;
t: bumpy	cursorY @ 59 < IF 1 cursorY +!
		ELSE scroll THEN ;
t: bumpx	cursorX @ 79 < IF 1 cursorX +!
		ELSE 0 cursorX ! bumpy THEN ;
t: !txraw	255 AND plot bumpx ;

t: noop ;
t: dobs		cursorX @ 1 - 0 MAX cursorX ! ;
t: doht		cursorX @ 15 + -8 AND 1- cursorX ! bumpx ;
t: dolf		bumpy ;
t: docr		0 cursorX ! ;

tcreate ctrltab
  t' noop t,	( 00 NUL )
  t' noop t,	( 01 SOH )
  t' noop t,	( 02 STX )
  t' noop t,	( 03 ETX )
  t' noop t,	( 04 EOT )
  t' noop t,	( 05 ENQ )
  t' noop t,	( 06 ACK )
  t' noop t,	( 07 BEL )
  t' dobs t,	( 08 BS  )
  t' doht t,	( 09 HT  )
  t' dolf t,	( 0A LF  )
  t' HOME t,	( 0B VT  )
  t' PAGE t,	( 0C FF  )
  t' docr t,	( 0D CR  )
  t' noop t,	( 0E SO  )
  t' noop t,	( 0F SI  )
  t' noop t,	( 10 DLE )
  t' noop t,	( 11 DC1 )
  t' noop t,	( 12 DC2 )
  t' noop t,	( 13 DC3 )
  t' noop t,	( 14 DC4 )
  t' noop t,	( 15 NAK )
  t' noop t,	( 16 SYN )
  t' noop t,	( 17 ETB )
  t' noop t,	( 18 CAN )
  t' noop t,	( 19 EM  )
  t' noop t,	( 1A SUB )
  t' noop t,	( 1B ESC )
  t' noop t,	( 1C FS  )
  t' noop t,	( 1D GS  )
  t' noop t,	( 1E RS  )
  t' noop t,	( 1F US  )

t: ctrl?	0 32 WITHIN ;
t: doctrl	CELLS ctrltab + @ EXECUTE ;
t: !tx		255 AND DUP ctrl? IF doctrl ELSE !txraw THEN ;
