;a program that draws a line in graphics mode
VdpWriteToStandardRegister: equ $B01C
ClearScreen: equ $B014
initializeVideo: equ $B018
waitChar: equ $B024
VdpInsertEnter: equ $B008
VPrintString: equ $B004
clearMostVram: equ $B03C
VdpWriteToPaletteRegister: equ $B020

org $3000

;clear all the crap off the screen
call ClearScreen

call setupG4Mode

;set x starting point of line
ld d, %01000000
ld a, 36
call VdpWriteToStandardRegister
ld d, %00000000
ld a, 37
call VdpWriteToStandardRegister

;set y starting point of line
ld d, %00000100
ld a, 38
call VdpWriteToStandardRegister
ld d, %00000000
ld a, 39
call VdpWriteToStandardRegister

;set long side dots num
ld d, %00100100
ld a, 40
call VdpWriteToStandardRegister
ld d, %00000000
ld a, 41
call VdpWriteToStandardRegister

;set short side dots num
ld d, %00001000
ld a, 42
call VdpWriteToStandardRegister
ld d, %00000000
ld a, 43
call VdpWriteToStandardRegister

;set line color
ld d, %00000011
ld a, 44
call VdpWriteToStandardRegister

;set register 45
ld d, %00000010
ld a, 45
call VdpWriteToStandardRegister

;define logical operation - %01110000 for line command
ld d, %01110000
ld a, 46
call VdpWriteToStandardRegister

;copy sprite into sprite pattern table position 1
call copySpriteToVram

;ld a, 5 	;change palette number 5
;ld d, %00000111
;ld e, %00000111
;call VdpWriteToPaletteRegister

;ld a, 6 	;change palette number 6
;ld d, %01110111
;ld e, %00000000
;call VdpWriteToPaletteRegister

;ld a, 7 	;change palette number 7
;ld d, %01110000
;ld e, %00000111
;call VdpWriteToPaletteRegister

;set sprite color table for sprite 0
ld a, 14
ld d, %00000001 	;bits a16, a15 and a14
call VdpWriteToStandardRegister
ld a, %00000000 	;bits a0-a7
out (c), a
ld a, %01110100 	;bits a8-a13. bit 6 is r/w. bit 7 should stay zero
out (c), a
;get ready to start writing to port 0 - the vram access port
ld b, $A0
ld c, $20

ld a, %00000101
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a


ld a, %00000110
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a
call smallDelay
out (c), a

;copy the sprite info to the attribute table at $7000
ld a, 14
ld d, %00000001 	;bits a16, a15 and a14
call VdpWriteToStandardRegister
ld a, %00000000 	;bits a0-a7
out (c), a
ld a, %01110110 	;bits a8-a13. bit 6 is r/w. bit 7 should stay zero
out (c), a

;get ready to start writing to port 0 - the vram access port
ld b, $A0
ld c, $20

ld a, $50
out (c), a ;xpos = 50
call smallDelay
ld a, $40
out (c), a 	;ypos = 50
call smallDelay
ld a, 0
out (c), a 		;pattern number 0
call smallDelay
ld a, 0
out (c), a
call smallDelay

;do the stuff for the second sprite
ld a, $20
out (c), a
call smallDelay
ld a, $20
out (c), a
call smallDelay
ld a, 1
out (c), a
call smallDelay
ld a, 0
out (c), a
call smallDelay

ld bc, $2020
ld de, $08A0
ld a, 6
call drawLine
call waitVdpCommandFinished

ld bc, $100F
ld de, $AAA0
ld a, 7
call drawLine
call waitVdpCommandFinished

ld bc, $A000
ld de, $A0C0
ld a, 7
call drawLine
call waitVdpCommandFinished

ld bc, $4040
ld de, $0510
ld a, 5
call drawRectangle

ld bc, $6060
ld de, $1005
ld a, 6
call drawRectangleFilled

;wait for user to press any key
call waitChar

;clear the screen a couple times and reset video mode back to 80 column text
call ClearScreen
call initializeVideo
call ClearScreen

ld hl, randomstring1
call VPrintString
call VdpInsertEnter

ld hl, randomstring2
call VPrintString
call VdpInsertEnter

ld hl, randomstring3
call VPrintString
call VdpInsertEnter


ret

copySpriteToVram:

	ld a, 14
	ld d, %00000001 	;bits a16, a15 and a14
	call VdpWriteToStandardRegister
	ld a, %00000000 	;bits a0-a7
	out (c), a
	ld a, %01111000 	;bits a8-a13. bit 6 is r/w. bit 7 should stay zero
	out (c), a

	;get ready to start writing to port 0 - the vram access port
	ld b, $A0
	ld c, $20

	ld hl, spritel1
	;ld a, (hl)
	ld d, 16

	copySpriteToVramLoopStart:
		call smallDelay
		call smallDelay
		ld a, (hl)
		out (c), a
		inc hl
		dec d
		ld a, d
		cp 0
		jr nz, copySpriteToVramLoopStart

ret

smallDelay:
	push af
	push de
	ld e, $FF
	smallDelayLoop:
		dec e
		ld a, e
		cp 0
		jr nz, smallDelayLoop
	pop de
	pop af
ret

randomstring1: db "Here is a pointless string",0
randomstring2: db "Here is another pointless string",0
randomstring3: db "Here is yet another pointless string",0

spritel1: db %00011000
spritel2: db %00111100
spritel3: db %01011010
spritel4: db %11111111
spritel5: db %11011011
spritel6: db %01100110
spritel7: db %00111100
spritel8: db %00011000

spritel9: db %00001000
spritel10: db %00011000
spritel11: db %00011000
spritel12: db %00111100
spritel13: db %00111100
spritel14: db %01111110
spritel15: db %11111111
spritel16: db %11111111
spriteTerminate: db %00000000

;this draws a line onto page 0 while in graphics 4 mode
;b = xpos start. c = ypos start.
;d = xpos end. e = ypos end
;a = color index
drawLine:

	push af
	ex de, hl
	push hl
		push bc
		;set x starting point of line
		ld d, b
		ld a, 36
		call VdpWriteToStandardRegister
		ld d, %00000000
		ld a, 37
		call VdpWriteToStandardRegister
		pop bc
		push bc
		;set y starting point of line
		ld d, c
		ld a, 38
		call VdpWriteToStandardRegister
		ld d, %00000000
		ld a, 39
		call VdpWriteToStandardRegister
	pop bc
	pop hl
	;if d is greater than b, I want d to become the result of d-b
	;otherwise, I want d to become the result of b-d
	ex de, hl
	ld hl, $0000

	ld a, d
	cp b
	jr nc, dIsGreater
	jr bIsGreater

	dIsGreater:
		sub b
		ld d, a
		;x transfer diretion = right. Therefore there is no need to change the x transfer direction bit
		jr firstComparisonGTFO
	bIsGreater:
		ld a, b
		sub d
		ld d, a
		;x transfer direction = left
		ld a, l
		or %00000100
		ld l, a

	firstComparisonGTFO:

	ld a, e
	cp c
	jr nc, eIsGreater
	jr cIsGreater

	eIsGreater:
		sub c
		ld e, a
		;y transfer direction = down. Therefore there is no need to change the y transfer direction bit
		jr secondComparisonGTFO
	cIsGreater:
		ld a, c
		sub e
		ld e, a
		;y transfer direction = up
		ld a, l
		or %00001000
		ld l, a

	secondComparisonGTFO:

	;de should now contain x length and y length
	;now I need to figure out which one to assign to long side and low side
	;I also don't need the contents of bc anymore. bc can now be used for variable storage or whatever
	ld a, d
	cp e
	jr nc, dIsLongSide
	jr eIsLongSide

	dIsLongSide:
		ld c, e
		ld b, d
		jr thirdComparisonGTFO
	eIsLongSide:
		ld c, d
		ld b, e
		ld a, l
		or %00000001
		ld l, a

	thirdComparisonGTFO:
		push hl
			push bc
				;set long side dots num
				ld d, b
				ld a, 40
				call VdpWriteToStandardRegister
				ld d, %00000000
				ld a, 41
				call VdpWriteToStandardRegister
			pop bc
			;set short side dots num
			ld d, c
			ld a, 42
			call VdpWriteToStandardRegister
			ld d, %00000000
			ld a, 43
			call VdpWriteToStandardRegister
		pop hl

	pop af
	push hl
		;set line color
		ld d, a
		ld a, 44
		call VdpWriteToStandardRegister
	pop hl
	;set register 45
	ld d, l
	ld a, 45
	call VdpWriteToStandardRegister

	;define logical operation - %01110000 for line command
	ld d, %01110000
	ld a, 46
	call VdpWriteToStandardRegister


ret

;waits until the vdp is finished with a command by checking CE bit (bit 0) of status register S#2
waitVdpCommandFinished:

	ld d, 2
	ld a, 15
	call VdpWriteToStandardRegister
	ld c, $21
	in a, (c)
	and %00000001
	cp 0
	jr nz, waitVdpCommandFinished

ret

;draws a non-filled in rectangle.
;b = x position of rectangle start
;c = y position of recangle start
;d = size x of rectangle
;e = size y of rectangle
;a = color index
drawRectangle:

	;draw top line
	push bc
	push de 
	push af
		ld l, a
		ld a, d
		add a, b
		ld d, a

		ld e, c
		ld a, l
		call drawLine
		call waitVdpCommandFinished
	pop af
	pop de
	pop bc

	;draw bottom line
	push bc
	push de
	push af
		ld l, a
		ld a, d
		add a, b
		ld d, a

		ld a, e
		add a, c
		ld e, a
		ld c, a
		ld a, l
		call drawLine
		call waitVdpCommandFinished
	pop af
	pop de
	pop bc

	;draw leftmost line
	push bc
	push de
	push af
		ld l, a
		ld d, b

		ld a, c
		add a, e
		ld e, a
		ld a, l
		call drawLine
		call waitVdpCommandFinished
	pop af
	pop de
	pop bc

	;draw rightmost line
	push bc
	push de
	push af
		ld l, a
		ld a, b
		add a, d
		ld d, a
		ld b, a

		ld a, c
		add a, e
		ld e, a
		ld a, l
		call drawLine
		call waitVdpCommandFinished
	pop af
	pop de
	pop bc

ret

drawRectangleFilled:
	;first draw the outline
	;call drawRectangle

	push af
		ld a, e
		;add a, e
		ld hl, $2FFE
		ld (hl), a
	pop af
	;calculate first horizontal line
	ld l, a
	ld a, d
	add a, b
	ld d, a

	ld e, c
	drawRectangleFilledContinueLoop:
	ld a, l
	push hl
	push af
	push bc
	push de
		call drawLine
		call waitVdpCommandFinished
	pop de
	pop bc
	pop af
	ld hl, $2FFE
	ld a, (hl)
	dec a
	inc c
	inc e
	ld (hl), a
	pop hl
	cp 0
	jr nz, drawRectangleFilledContinueLoop

ret


;sets up and configures graphics 4 mode
;	pattern layout (bitmap): 00000h-069ffh
;	sprite patterns 07800h-07fffh
;	sprite attributes 07600h-0767Ffh
;	sprite colors 07400h-075ffh
setupG4Mode:

	;put the vdp into graphics mode 4. m5 = 0. m4 = 1. m3 = 1. m2 = 0. m1 = 0
	;register 0
	ld d, %00000110 		;change to %00000100 for text2. %00000000
	ld a, 0
	call VdpWriteToStandardRegister

	;set up register 1
	ld d, %01000000
	ld a, 1
	call VdpWriteToStandardRegister

	;set up register 8
	ld d, %00001000
	ld a, 8
	call VdpWriteToStandardRegister

	;set register 23 to zero
	ld d, 0
	ld a, 23
	call VdpWriteToStandardRegister

	call clearMostVram

	;here's what I need to set:
	;	pattern layout (bitmap): 00000h-069ffh
	;	sprite patterns 07800h-07fffh
	;	sprite attributes 07600h-0767Ffh
	;	sprite colors 07400h-075ffh

	;pattern layout table
	ld d, %00011111
	ld a, 2
	call VdpWriteToStandardRegister

	;sprite patterns
	ld d, %00001111
	ld a, 6
	call VdpWriteToStandardRegister

	;sprite attributes high
	ld d, %00000000
	ld a, 11
	call VdpWriteToStandardRegister

	;sprite attributes low ($7600)
	ld d, %11101111
	ld a, 5
	call VdpWriteToStandardRegister

	;sprite color table high
	ld d, %00000001
	ld a, 10
	call VdpWriteToStandardRegister

	;sprite color table low
	ld d, %11010000
	ld a, 3
	call VdpWriteToStandardRegister

ret