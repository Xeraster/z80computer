VdpPrintChar: equ $B000
VPrintString: equ $B004
VdpInsertEnter: equ $B008
VdpBackspace: equ $B00C
VdpInsertTab: equ $B010
ClearScreen: equ $B014

;if you do anything to change the video mode, run this when you're done to put things back to the way they were
initializeVideo: equ $B018

;d should contain register data
;a should contain register number
VdpWriteToStandardRegister: equ $B01C

; a register needs to contain palette register number you want to write to (0-15)
; d register needs to contain first palette byte
; e register needs to contain second palette byte
;note that the pointer value in register 16 auto increments each time you do this
VdpWriteToPaletteRegister: equ $B020

;this function waits for the user to input a key. Once a keyboard key has been pressed, it loads the a register with the respective ascii code
waitChar: equ $B024
RowsColumnsToCursorPos: equ $B028 	;update the cursor position
RowsColumnsToVram: equ $B02C
print16BitDecimal: equ $B030
print2DigitDecimal: equ $B034
print8bitDecimal: equ $B038
clearMostVram: equ $B03C
setupDefaultColors: equ $B040
setupG4Mode: equ $B044
drawLine: equ $B048
waitVdpCommandFinished: equ $B04C
drawRectangle: equ $B050
drawRectangleFilled: equ $B054
putResultInParameter1: equ $B058
stupidDivisionPre: equ $B05C
DEHL_Div_C: equ $B060
stupidDivisionPost: equ $B064
add32BitNumber: equ $B068
subtract32BitNumber: equ $B06C
load16bitvaluesFromRam: equ $B070
mul16: equ $B074
loadmul16IntoRam: equ $B078
ramTomul32Do: equ $B07C
mul32: equ $B080
kbd8042WaitReadReady: equ $B084
softwareSpriteToVramCompressed: equ $B088
G4PrintChar: equ $B08C
G4PrintString: equ $B090
HL_Div_C: equ $B094
b16bitDecimalToHl: equ $B098
b8bitDecimalToHl: equ $B09C
b2DigitDecimalToHl: equ $B0A0
fillRangeInRam: equ $B0A4
addressToOtherAddress: equ $B0A8
DE_Times_A: equ $B0AC

;a = sprite entry you want to change 
;d=x position to change the sprite to
;e=y position to change the sprite to
;l=sprite number to change sprite appearance to
changeSpriteSettings: equ $B0B0

randomNumber: equ $B0B4
sysIdentify: equ $B0B8
;$B0BC
aToScreenHex: equ $B0BC
timeTilSnekMoves: equ 8


org $3000
	;clear all the crap off the screen
	call ClearScreen

	;set video mode to g4
	call setupG4Mode

	;call drawBackground

	;mouse pointer border sprite
	ld d, 50
	ld e, 64
	ld a, 0
	ld l, 0
	call changeSpriteSettings

	;mouse pointer border sprite
	ld d, 50
	ld e, 64
	ld a, 1
	ld l, 1
	call changeSpriteSettings


	call copySpritesToVram

	call waitChar
	call waitChar

	call ClearScreen
	call initializeVideo
	call ClearScreen

	;print exit message
	ld hl, exitmessage
	call VPrintString

ret

drawBackground:
	;set column and row counters to zero
	ld a, 0
	ld hl, $9EFA
	ld (hl), a
	inc hl
	ld (hl), a

	;a slow but low-memory way of getting all the registers ready and vram pointer in the correct spot
	call RowsColumnsToVram
	ld hl, $7FFF 				;erase 1920 characters- the entire space of a 80x24 char screen could probably change that to $860 so it'll work in 26.5x80 mode but i haven't tried it yet)
	ld c, $20
	ld e, $88
	ld d, $4

	drawBackgroundContinue:
			ld a, d
			cp 0
			jr nz, GTFOColorChangeBackgroundCompare
			call z, shiftEColorWhatever
			ld d, $4
		GTFOColorChangeBackgroundCompare:

		dec d
		ld b, $A0
		out (c), e
		dec hl
		ld a, h
		or l
		nop
		nop
		jr nz, drawBackgroundContinue

ret

shiftEColorWhatever:
	push af
	ld a, e
	cp $FF
	jr z, setEtoColor1
	jr setEtoColor2
	setEtoColor1:
	ld e, $88
	pop af
	ret
	setEtoColor2:
	ld e, $FF
	pop af

ret

;this function checks to see if the user has pressed a key and if not, doesn't halt the program
checkChar:
	ld hl, $A005			;8042 status port
	ld a, (hl)
	and %00000001			;read the data register read ready bit
	cp 1
	jr z, returnSomethingElse 					;if it's not ready just return fuck it
	returnLastChar:
		ld hl, $4FF9
		ld a, (hl)
		;ld a, 0
		ret
	returnSomethingElse:
	;wait for keyboard to be ready
	;call kbd8042WaitReadReady
	ld hl, $4FF9
	ld a, (hl)
	cp $F0
	jr z, checkCharGTFO
	jr checkCharContinue

	checkCharGTFO:
		;i dont care what this is i'm just loading it to a to discard it from the keyboard controller
		ld hl, $A004		
		ld hl, $4FF9
		ld a, 0
		ld (hl), a
		ret
	checkCharContinue:
	;if the controller said there was input data ready, read it
	ld hl, $A004
	ld a, (hl)
	;adding the following 2 lines seems to have fixed that F0 bug once and for all
	cp $F0
	jr z, checkCharContinue
	;btw a=1C, s=1B, d=23, w=1D, esc=76
	cp $1C
	jr z, validScancodeSoContinue
	cp $1B
	jr z, validScancodeSoContinue
	cp $23
	jr z, validScancodeSoContinue
	cp $1D
	jr z, validScancodeSoContinue
	cp $76
	jr z, validScancodeSoContinue
	jr censorInvalidScancode
	validScancodeSoContinue:
	;store the last typed scancode into this location in ram for safe keeping
	ld hl, $4FFA
	push af
		;store the second till last scancode into $4FFA
		ld a, (hl)
		ld hl, $4FFB
		ld (hl), a
		ld hl, $4FF9
		ld a, (hl)
		ld hl, $4FFA
		ld (hl), a
	pop af
	ld hl, $4FF9
	ld (hl), a

ret

censorInvalidScancode:
	ld hl, $4FF9
	ld a, (hl)
ret

;wait for next frame
;used to make games run at a fixed framerate even if the cpu is much faster than the program was originally designed to be run on
waitVblank:

	;i want to keep checking until bit 6 of S#2 is set
	ld a, 15
	ld d, 2
	call VdpWriteToStandardRegister

	ld b, $A0
	ld c, $21
	in a, (c)
	and %01000000
	cp %01000000
	jr nz, waitVblank
	waitVblankEnd:
	in a, (c)
	and %01000000
	cp 0
	jr nz, waitVblankEnd

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

reallySmallDelay:
	push af
	push de
	ld e, $0F
	reallySmallDelayLoop:
		dec e
		ld a, e
		cp 0
		jr nz, reallySmallDelayLoop
	pop de
	pop af
ret

copySpritesToVram:

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

	ld hl, spriteb1
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

	;now lets set the color table for all the sprites
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

	;sprite 0 and 1 - the potato and the poop
	;just a solid color so this one can be colored with a single loop
	ld d, 16
	sprite01ColorLoop:
		ld a, %00001000 	;8 = dark grey
		out (c), a
		call smallDelay
		dec d
		ld a, d 
		cp 0
		jr nz, sprite01ColorLoop

		ld d, 16

	sprite02ColorLoop:
		ld a, %00001111 	;F = white
		out (c), a
		call smallDelay
		dec d
		ld a, d 
		cp 0
		jr nz, sprite02ColorLoop
ret

score: db "Score:",0
exitmessage: db "Mouse test exit",0
exceptionEncountered: db "Exception encountered. Invalid scancode passed as control character: ",0

;the mouse border sprite
spriteb1: db %10000000
spriteb2: db %11000000
spriteb3: db %10100000
spriteb4: db %10010000
spriteb5: db %10001000
spriteb6: db %10000100
spriteb7: db %10111100
spriteb8: db %11000000

;the mouse main sprite
spritem1: db %00000000
spritem2: db %00000000
spritem3: db %01000000
spritem4: db %01100000
spritem5: db %01110000
spritem6: db %01111000
spritem7: db %01000000
spritem8: db %00000000