;port #0 VRAM Data (R/W)		$A020
;port #1 Status register (R) / VRAM Address (W) / Register set-up (W)	$A021
;port #2 Palette registers (W)	$A022
;port #3 Register indirect addressing (W)
initializeVideo:
	call VdpCharsIntoRam

	;set up palette register with 4 colors
	;ld a, 0
	;ld d, %00000000		;green
	;ld e, %00000111
	;call VdpWriteToPaletteRegister

	;ld a, 1
	;ld d, %00000111
	;ld e, %00000000 	;blue
	;call VdpWriteToPaletteRegister

	;ld a, 2
	;ld d, %01110111
	;ld e, %00000111 	;white
	;call VdpWriteToPaletteRegister

	;ld a, 3
	;ld d, %00000000
	;ld e, %00000000 	;black
	;call VdpWriteToPaletteRegister

	;setup text mode 1

	;register 0
	ld d, %00000100 		;change to %00000100 for text2. %00000000
	ld a, 0
	call VdpWriteToStandardRegister

	;set up register 1
	ld d, %01010000
	ld a, 1
	call VdpWriteToStandardRegister

	;set up register 8
	;ld d, %00101000
	;ld a, 8
	;call VdpWriteToStandardRegister

	;set up register 9
	;ld d, %00000000 	;dot clock in "output" mode. s1 and s0 "simultaneous mode" (Whatever that means) set to zero
	;ld a, 9
	;call VdpWriteToStandardRegister

	ld d, %11110000 	;do it again just to make sure
	ld a, 7
	call VdpWriteToStandardRegister

	;set up register 12 and configure cursor color in text 2 mode
	ld d, %00100011
	ld a, 12
	call VdpWriteToStandardRegister

	;configure register 13, the cursor blink time register
	ld d, %01110111
	ld a, 13
	call VdpWriteToStandardRegister

	;set values of pattern generator, pattern layout and pattern color table
	;I am using "MSX system default" values
	;text 2 pattern generator: 01000h-017FFh. Pattern layout: 00000h-0077Fh (00000h-0086Fh in 26.5 line mode). Pattern color table 800h-8EFh (800h-90Dh in 26.5 mode)
	ld d, %00000000
	ld a, 2
	call VdpWriteToStandardRegister

	ld d, %00000010
	ld a, 4
	call VdpWriteToStandardRegister

	ld d, %00100000
	ld a, 3
	call VdpWriteToStandardRegister

	ld d, %00000000
	ld a, 10
	call VdpWriteToStandardRegister

	;do this after loading registers in case its needed or something
	call writeRegisterOne

	;put a visual confirmation on the lcd that this function finished
	ld a, %11000000 					;the lcd's address for the 2nd line
	call lcdBlankLine 					;print a blank line on the 2nd line on the lcd to discard any data from the previous command

	ld hl, donemsg
	call printString

	call backToPrevCursorPos

ret

;reads status from whatever status register number the a register contains
VdpReadStatus:

	;write contents of a register to vdp register 15 (should be 0-9)
	;ld hl, $A021
	;ld (hl), a
	ld b, $A0
	ld c, $21
	out (c), a

	ld a, 15 + 128
	out (c), a

	;it shoud now be set up to read the status of the inputted register
	in a, (c)

ret

;d should contain register data
;a should contain register number
VdpWriteToStandardRegister:
	ld b, $A0
	ld c, $21

	;write the data byte first because that's just what you do
	out (c), d

	;write the register number next
	;add a, 128
	or %10000000		;different way of adding 128 to a
	out (c), a
ret

; a register needs to contain palette register number you want to write to (0-15)
; d register needs to contain first palette byte
; e register needs to contain second palette byte
;note that the pointer value in register 16 auto increments each time you do this
VdpWriteToPaletteRegister:
	push af
	push de
		ld d, a
		ld a, 16
		call VdpWriteToStandardRegister
	pop de
	pop af

	ld b, $A0
	ld c, $22
	out (c), d
	out (c), e


ret

;text 2 pattern generator: 01000h-017FFh. Pattern layout: 00000h-0077Fh (00000h-0086Fh in 26.5 line mode)
VdpCharsIntoRam:
	ld a, 14
	ld d, %00000000 	;bits a16, a15 and a14
	call VdpWriteToStandardRegister
	;pro-gamer move: since register b and c got set in the prev function, i'm not setting them again
	ld a, %00000000 	;bits a0-a7
	out (c), a
	ld a, %00010000 	;bits a8-a13. bit 6 is r/w. bit 7 should stay zero
	out (c), a

	;now, time to make a bigass loop
	;get ready to start writing to port 0 - the vram access port
	ld b, $A0
	ld c, $20

	ld hl, letters_space
	ld a, (hl)
	
	VdpCharsIntoRamLoopStart:
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		out (c), a
		inc hl
		ld a, (hl)
		cp %11111111
		jr nz, VdpCharsIntoRamLoopStart

	call writeRegisterOne

ret

;because a guy on a forum said setting bit 6 of register 1 for screen on after any register command might work
writeRegisterOne:

	ld b, $A0
	ld c, $21
	;set up register 1
	ld d, %01010000
	ld a, 1
	call VdpWriteToStandardRegister

ret

donemsg: db "done",0

;here is the font data. Have fun actually copying it to the vram. heh.

letters_space: db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
letters_exclamation: db %00100000, %00100000, %00100000, %00100000, %00100000, %00000000, %00100000, %00000000
letters_dquotes: db %00000000, %01010000, %01010000, %00000000, %00000000, %00000000, %00000000, %00000000
letters_pound: db %00000000, %01010000, %11111000, %01010000, %11111000, %01010000, %00000000, %00000000
letters_dollar: db %00100000, %01110000, %01100000, %01110000, %00110000, %01110000, %00100000, %00000000
letters_percent: db %00000000, %00000000, %01101000, %01010000, %00101000, %01011000, %00000000, %00000000
letters_ampersand: db %00000000, %01110000, %11010000, %11110000, %10010000, %01010000, %01111000, %00000000
letters_quote: db %00000000, %00100000, %00100000, %00000000, %00000000, %00000000, %00000000, %00000000
letters_lparenth: db %00001000, %00010000, %00100000, %00100000, %00100000, %00010000, %00001000, %00000000
letters_rparenth: db %00100000, %00010000, %00001000, %00001000, %00001000, %00010000, %00100000, %00000000
letters_asteri: db %00100000, %10101000, %01110000, %00100000, %01010000, %10001000, %00000000, %00000000
letters_plus: db %00000000, %00100000, %00100000, %11111000, %00100000, %00100000, %00000000, %00000000
letters_idk1: db %00011000, %00110000, %00100000, %00000000, %00000000, %00000000, %00000000, %00000000
letters_minus: db %00000000, %00000000, %00000000, %11111000, %00000000, %00000000, %00000000, %00000000
letters_period: db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %01000000, %00000000
letters_fslash: db %00000000, %00001000, %00010000, %00100000, %01000000, %10000000, %00000000, %00000000
letters_0: db %00101010, %00000000, %10000000, %10000000, %10100000, %10000000, %10001000, %10000000
letters_1: db %10000010, %10000000, %10000000, %10000000, %00101010, %00000000, %00000000, %00000000
letters_2: db %00101000, %00000000, %10101000, %00000000, %00001000, %00000000, %00001000, %00000000
letters_3: db %00001000, %00000000, %00001000, %00000000, %10101010, %10000000, %00000000, %00000000
letters_4: db %10101010, %00000000, %10000000, %10000000, %00000000, %10000000, %00000000, %10000000
letters_6: db %10101010, %10000000, %10000000, %00000000, %10101010, %10000000, %00000000, %00000000
letters_7: db %10101010, %10000000, %10000000, %10000000, %00000000, %10000000, %00101010, %10000000
letters_8: db %00000000, %10000000, %10000000, %10000000, %10101010, %10000000, %00000000, %00000000
letters_9: db %00001010, %00000000, %00100010, %00000000, %10000010, %00000000, %10101010, %10000000
letters_colon: db %00000010, %00000000, %00000010, %00000000, %00000010, %00000000, %00000000, %00000000
letters_semicolon: db %10101010, %10000000, %10000000, %00000000, %10000000, %00000000, %10101010, %00000000
letters_leftarrow: db %00000000, %10000000, %00000000, %10000000, %10101010, %00000000, %00000000, %00000000
letters_equal: db %00101010, %00000000, %10000000, %10000000, %10000000, %00000000, %10101010, %00000000
letters_rightarrow: db %10000000, %10000000, %10000000, %10000000, %00101010, %00000000, %00000000, %00000000
letters_question: db %10101010, %10000000, %00000000, %10000000, %00000010, %00000000, %00001000, %00000000
letters_email: db %00001000, %00000000, %00001000, %00000000, %00001000, %00000000, %00000000, %00000000
letters_A: db %00100000, %01010000, %10001000, %10001000, %11111000, %10001000, %10001000, %00000000
letters_B: db %11110000, %10001000, %10001000, %11110000, %10001000, %10001000, %11110000, %00000000
letters_C: db %00111000, %01000000, %10000000, %10000000, %10000000, %01000000, %00111000, %00000000
letters_D: db %11110000, %10001000, %10001000, %10001000, %10001000, %10001000, %11110000, %00000000
letters_E: db %11111000, %10000000, %10000000, %11100000, %10000000, %10000000, %11111000, %00000000
letters_F: db %11111000, %10000000, %10000000, %11100000, %10000000, %10000000, %10000000, %00000000
letters_G: db %01110000, %10001000, %10000000, %10000000, %10011000, %10001000, %01110000, %00000000
letters_H: db %10001000, %10001000, %10001000, %11111000, %10001000, %10001000, %10001000, %00000000
letters_I: db %11111000, %00100000, %00100000, %00100000, %00100000, %00100000, %11111000, %00000000
letters_J: db %01111000, %00010000, %00010000, %00010000, %10010000, %10010000, %01100000, %00000000
letters_K: db %10001000, %10010000, %10100000, %11000000, %10100000, %10010000, %10001000, %00000000
letters_L: db %10000000, %10000000, %10000000, %10000000, %10000000, %10000000, %11111000, %00000000
letters_M: db %10001000, %11011000, %10101000, %10101000, %10001000, %10001000, %10001000, %00000000
letters_N: db %10001000, %11001000, %10101000, %10101000, %10101000, %10011000, %10001000, %00000000
letters_O: db %01110000, %10001000, %10001000, %10001000, %10001000, %10001000, %01110000, %00000000
letters_P: db %11110000, %10001000, %10001000, %11110000, %10000000, %10000000, %10000000, %00000000
letters_Q: db %01100000, %10010000, %10010000, %10010000, %10110000, %10110000, %01111000, %00000000
letters_R: db %11110000, %10001000, %10001000, %11110000, %10100000, %10010000, %10001000, %00000000
letters_S: db %01111000, %10000000, %10000000, %01110000, %00001000, %00001000, %11110000, %00000000
letters_T: db %11111000, %00100000, %00100000, %00100000, %00100000, %00100000, %00100000, %00000000
letters_U: db %10001000, %10001000, %10001000, %10001000, %10001000, %10001000, %01110000, %00000000
letters_V: db %10001000, %10001000, %10001000, %10001000, %10001000, %01010000, %00100000, %00000000
letters_W: db %10001000, %10101000, %10101000, %10101000, %10101000, %10101000, %01010000, %00000000
letters_X: db %10001000, %01010000, %01010000, %00100000, %01010000, %01010000, %10001000, %00000000
letters_Y: db %10001000, %10001000, %01010000, %00100000, %00100000, %00100000, %00100000, %00000000
letters_Z: db %11111000, %00001000, %00010000, %00100000, %01000000, %10000000, %11111000, %00000000
letters_halfsquare1: db %11100000, %10000000, %10000000, %10000000, %10000000, %10000000, %11100000, %00000000
letters_backwardsslash: db %10000000, %01000000, %00100000, %00100000, %00010000, %00001000, %00001000, %00000000
letters_halfsquare2: db %11100000, %00100000, %00100000, %00100000, %00100000, %00100000, %11100000, %00000000
letters_idk2: db %00100000, %01010000, %10001000, %00000000, %00000000, %00000000, %00000000, %00000000
letters_idk3: db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %11111000, %00000000
letters_a: db %00000000, %01100000, %00010000, %01110000, %10010000, %10010000, %01111000, %00000000
letters_b: db %10000000, %10000000, %10000000, %11110000, %10001000, %10001000, %11110000, %00000000
letters_c: db %00000000, %00000000, %01110000, %10000000, %10000000, %10000000, %01110000, %00000000
letters_d: db %00001000, %00001000, %00001000, %01111000, %10001000, %10001000, %01111000, %00000000
letters_e: db %00000000, %00000000, %01110000, %10001000, %11111000, %10000000, %01111000, %00000000
letters_f: db %00111000, %01000000, %01000000, %11111000, %01000000, %01000000, %01000000, %00000000
letters_g: db %00000000, %01111000, %10001000, %10001000, %01111000, %00001000, %01111000, %00000000
letters_h: db %10000000, %10000000, %10000000, %11110000, %10001000, %10001000, %10001000, %00000000
letters_i: db %00000000, %00100000, %00000000, %00100000, %00100000, %00100000, %00100000, %00000000
letters_j: db %00000000, %00100000, %00000000, %00100000, %00100000, %10100000, %01000000, %00000000
letters_k: db %00000000, %10000000, %10001000, %10010000, %11100000, %10010000, %10001000, %00000000
letters_l: db %00000000, %01100000, %00100000, %00100000, %00100000, %00100000, %00110000, %00000000
letters_m: db %00000000, %00000000, %10001000, %11011000, %10101000, %10101000, %10001000, %00000000
letters_n: db %00000000, %10000000, %11110000, %10001000, %10001000, %10001000, %10001000, %00000000
letters_o: db %00000000, %00000000, %01110000, %10001000, %10001000, %10001000, %01110000, %00000000
letters_p: db %00000000, %00000000, %11110000, %10001000, %11110000, %10000000, %10000000, %00000000
letters_q: db %00000000, %00000000, %01111000, %10001000, %01111000, %00001000, %00001000, %00000000
letters_r: db %00000000, %00000000, %10110000, %11001000, %10000000, %10000000, %10000000, %00000000
letters_s: db %00000000, %00000000, %01111000, %10000000, %01110000, %00001000, %11110000, %00000000
letters_t: db %00100000, %00100000, %11111000, %00100000, %00100000, %00101000, %00010000, %00000000
letters_u: db %00000000, %00000000, %10010000, %10010000, %10010000, %10010000, %01111000, %00000000
letters_v: db %00000000, %00000000, %10001000, %10001000, %10001000, %01010000, %00100000, %00000000
letters_w: db %00000000, %00000000, %10001000, %10001000, %10101000, %10101000, %01010000, %00000000
letters_x: db %00000000, %00000000, %10001000, %01010000, %00100000, %01010000, %10001000, %00000000
letters_y: db %00000000, %00000000, %10001000, %01010000, %00100000, %00100000, %11000000, %00000000
letters_z: db %00000000, %00000000, %11111000, %00001000, %01110000, %10000000, %11111000, %00000000
letters_idk4: db %00110000, %01000000, %01000000, %11000000, %01000000, %01000000, %00110000, %00000000
letters_pipeiguess: db %00100000, %00100000, %00100000, %00100000, %00100000, %00100000, %00100000, %00000000
letters_idk5: db %11000000, %00100000, %00100000, %00110000, %00100000, %00100000, %11000000, %00000000
letters_errorchar: db %10101000, %01010100, %10101000, %01010100, %10101000, %01010100, %10101000, %00000000
letters_end: db %11111111	;the termination char - makes ending the vram loading loop take much less code. Just keep in mind that no font sprite can have a straight line across or it will end the loop early resulting in not all the character fonts getting loaded

spritesLoadedOk: db "Sprites loaded",0
