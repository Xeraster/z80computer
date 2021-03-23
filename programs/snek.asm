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

;$4FF8 = last position snek went in. 0 = up, 1 = right, 2 = down, 3 = left
;$4FFC-$4FFD = number of thingy collision loop iterations
;$4FFE-$4FFF = score
;$5000-$5001 = length of snek
;$5002 = x position of first snek block
;$5003 = y position of first snek block
;$4FF9 = last inputted scancode
;$4FFA = scancode inputted 2 scancodes ago
;$4FFB = scancode inputted 3 scancodes ago
;$2FFD = frames till next snek movement
;$2FFB = thingy position x
;$2FFC = thingy position y

org $3000
	;set 4ffa and 4ffb to zero. They're the scancode history bytes
	ld hl, $4FF9
	ld a, 0
	ld (hl), a
	inc hl
	ld (hl), a

	ld hl, $2007
	ld a, 0
	ld (hl), a
	inc hl
	ld (hl), a
	;clear all the crap off the screen
	call ClearScreen

	;set video mode to g4
	call setupG4Mode 

	;initially draw the score label
	ld hl, score
	call G4PrintString

	call copySpritesToVram

	ld hl, $2FFB
	ld a, 50
	ld (hl), a
	inc hl
	ld a, 64
	ld (hl), a

	ld d, 50
	ld e, 64
	ld a, 0
	ld l, 0
	call changeSpriteSettings

	;set both score bytes to zero
	ld hl, $4FFE
	ld a, 0
	ld (hl), a
	inc hl
	ld (hl), a

	;set length of snek to 1
	ld hl, $5000
	ld a, 1
	ld (hl), a
	inc hl
	ld a, 0
	ld (hl), a

	;set starting position of snek
	ld hl, $5002
	ld a, $3F
	ld (hl), a
	inc hl
	ld (hl), a

	;put an arbitrary amount of time before next snek movement
	ld hl, $2FFD
	ld a, 2
	ld (hl), a

	call updateScore

	;draw a decorative rectangle around the playable game area
	ld bc, $010A
	ld de, $FCAE
	ld a, 1
	call drawRectangle

	call drawSnek

	gameLoop:

	;btw a=1C, s=1B, d=23, w=1D
	call checkChar

	call checkSnekMovement
	call drawSnek
	;call incrementScore


	;call updateScore
	call waitVblank
	jp gameLoop

	GTFO:
	;put everything back to normal
	call ClearScreen
	call initializeVideo
	call ClearScreen

	;print exit message
	ld hl, exitmessage
	call VPrintString
ret

doCrashReport:
	
	push af
		;put everything back to normal
		call ClearScreen
		call initializeVideo
		call ClearScreen

		;print exit message
		ld hl, exceptionEncountered
		call VPrintString
	pop af
	call aToScreenHex
	call waitChar

ret

updateScore:

	;set g4 string cursor position
	ld hl, $2007
	ld a, 24
	ld (hl), a

	;load the 16 bit value at $2FFE-$2FFF into the de register
	ld hl, $4FFF
	ld d, (hl)
	dec hl
	ld e, (hl)
	call b16bitDecimalToHl
	call G4PrintString

ret

incrementScore:

	ld hl, $4FFE
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc de

	ld (hl), d
	dec hl
	ld (hl), e

	call updateScore

ret

drawSnek:
	
	;load x, y to bc
	ld hl, $5002
	ld b, (hl)
	inc hl
	ld c, (hl)

	ld de, $0708
	ld a, 13
	call drawRectangleFilled

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

;see if it's time for the snek to move and if so, move it
checkSnekMovement:

	ld hl, $2FFD
	ld a, (hl)
	cp 0
	jr z, moveSnek

	;if not enough frames have passed, decrement the counter then return to main loop
	dec a
	ld (hl), a
	ret

	moveSnek:
	;first thing to do, reset the counter
	ld (hl), timeTilSnekMoves

	;shift snek data before it moves again in order to erase the tail
	call shiftSnekDataUpOne

	;next thing to do, figure out what direction to move the snek in
	;btw a=1C, s=1B, d=23, w=1D, esc=76
	ld hl, $4FF9
	ld a, (hl)

	cp $1C
	jr nz, moveCheckDown
	call snekLeft
	jr doSnekShift

	moveCheckDown:
	cp $1B
	jr nz, moveCheckRight
	call snekDown
	jr doSnekShift

	moveCheckRight:
	cp $23
	jr nz, checkForEsc
	call snekRight
	jr doSnekShift

	checkForEsc:
	cp $76
	jr nz, moveCheckUp
	;do this to return to system and not the parent subroutine
	pop bc
	ld bc, GTFO
	push bc
	ret

	;if not up, disregard
	moveCheckUp:
	call snekUp

	doSnekShift:
	call checkSnekCollision
	call eraseLastSnekCell

ret

;$2FFB = thingy position x
;$2FFC = thingy position y
;this uses the random number function to make it actually random and stuff
changeThingyPosition:
	
	call randomNumber
	cp $E0
	jr nc, changeThingyPositionXTooLarge
	cp $5
	jr c, changeThingyPositionXTooSmall
	jr changeThingyPositionXIDGAF
	changeThingyPositionXTooLarge:
		sub a, 45
		jr changeThingyPositionXIDGAF
	changeThingyPositionXTooSmall:
		add a, 15
	changeThingyPositionXIDGAF:
	ld hl, $2FFB
	ld (hl), a
	ld d, a

	call randomNumber
	cp $B0
	jr nc, changeThingyPositionYTooLarge
	cp 12
	jr c, changeThingyPositionYTooSmall
	jr changeThingyPositionYIDGAF
	changeThingyPositionYTooLarge:
		add a, 96
		jr changeThingyPositionXIDGAF
	changeThingyPositionYTooSmall:
		add a, 20
	changeThingyPositionYIDGAF:
	ld hl, $2FFC
	ld (hl), a
	ld e, a

	;update changes to the thingy sprite
	;ld d, 50
	;ld e, 64
	ld a, 0
	ld l, 0
	call changeSpriteSettings

ret

;this gets executed each time the snake gets the food/point/goal whatever its called
;the purpose is to move the thing somewhere else on the game board
checkThingyLocation:
	;set the iteration coutner for this loop to 0
	ld hl, $4FFC
	ld a, 0
	ld (hl), a
	inc hl
	ld (hl), a
	
	;load the position of the thingy. $2FFB, $2FFC (x and y pos respectively)
	ld hl, $2FFB
	ld b, (hl)
	ld hl, $2FFC
	ld c, (hl)

	;load the position of the first snek block. $5002, $5003 (x and y pos respectively) 
	ld hl, $5002
	ld d, (hl)
	ld hl, $5003
	ld e, (hl)

	thingyLocationCompareNextIteration:
	;compare the x positions first
	ld a, b
	sub d
	cp 7
	jr c, thingyCollisionTryY

	ld a, d
	sub b
	cp 7
	jr c, thingyCollisionTryY
	jr thingyLocationPrepareNextIteration

	;x position suggests it may be colliding. Check y position now
	thingyCollisionTryY:
		ld a, c
		sub e
		cp 7
		jr c, checkThingyLocationRestart

		ld a, e
		sub c
		cp 7
		jr c, checkThingyLocationRestart

		jr thingyLocationPrepareNextIteration

	;thngy is colliding with the snek at some point. Time to change the position of the thingy and start over the loop
	checkThingyLocationRestart:
		call changeThingyPosition
		jp checkThingyLocation

	thingyLocationPrepareNextIteration:
	;$5000-$5001 = length of snek
	;$4FFC-$4FFD = number of thingy collision loop iterations
	push hl
		ld hl, $5000
		ld a, (hl)
		ld b, a
		ld hl, $4FFC
		ld a, (hl)
	pop hl
	;if number of iterations is the same as snake length, return.
	cp a, b
	ret z

	;if number of iterations is not the same as snake length:
	;	-increment number of iterations by 1
	;	-increment snake position pointer by 1
	;	-jump back to the top of the loop
	push hl
		ld hl, $4FFC
		ld a, (hl)
		inc hl
		ld (hl), a
	pop hl
	inc hl
	;load the position of the nth snek block. 
	ld d, (hl)
	inc hl
	ld e, (hl)
	jp thingyLocationCompareNextIteration


ret

;$4FF8 = last position snek went in. 0 = up, 1 = right, 2 = down, 3 = left
;btw a=1C, s=1B, d=23, w=1D, esc=76
snekRight:
	
	;check to make sure the snek isn't trying to go in the direct opposite direction
	ld hl, $4FF8
	ld a, (hl)
	cp 3
	jr z, snekLeft

	ld hl, $5002
	ld a, (hl)
	add 9
	ld (hl), a

	;store the last direction the snek went in
	ld hl, $4FF8
	ld a, 1
	ld (hl), a

ret

;$4FF8 = last position snek went in. 0 = up, 1 = right, 2 = down, 3 = left
;btw a=1C, s=1B, d=23, w=1D, esc=76
snekLeft:
	
	;check to make sure the snek isn't trying to go in the direct opposite direction
	ld hl, $4FF8
	ld a, (hl)
	cp 1
	jr z, snekRight

	ld hl, $5002
	ld a, (hl)
	sub 9
	ld (hl), a

	;store the last direction the snek went in
	ld hl, $4FF8
	ld a, 3
	ld (hl), a

ret

;$4FF8 = last position snek went in. 0 = up, 1 = right, 2 = down, 3 = left
;btw a=1C, s=1B, d=23, w=1D, esc=76
snekUp:
	
	;check to make sure the snek isn't trying to go in the direct opposite direction
	ld hl, $4FF8
	ld a, (hl)
	cp 2
	jr z, snekDown

	ld hl, $5003
	ld a, (hl)
	sub 9
	ld (hl), a

	;store the last direction the snek went in
	ld hl, $4FF8
	ld a, 0
	ld (hl), a

ret

;$4FF8 = last position snek went in. 0 = up, 1 = right, 2 = down, 3 = left
;btw a=1C, s=1B, d=23, w=1D, esc=76
snekDown:
	
	;check to make sure the snek isn't trying to go in the direct opposite direction
	ld hl, $4FF8
	ld a, (hl)
	cp 0
	jr z, snekUp

	ld hl, $5003
	ld a, (hl)
	add 9
	ld (hl), a

	;store the last direction the snek went in
	ld hl, $4FF8
	ld a, 2
	ld (hl), a

ret

shiftSnekDataUpOne:

	ld hl, $5000
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld a, 2
	call DE_Times_A

	ld bc, $5000
	add hl, bc

	ld d, h
	ld e, l

	ex de, hl
	ld bc, $0002
	add hl, bc
	ex de, hl

	inc hl
	inc de

	doShiftLoopAgain:
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress

	ld a, l
	cp $02
	jr nz, doShiftLoopAgain
	ld a, h
	cp $50
	jr nz, doShiftLoopAgain


ret

eraseLastSnekCell:

	ld hl, $5000
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld a, 2
	call DE_Times_A

	ld bc, $5002
	add hl, bc
	
	;load x, y to bc
	;ld hl, $5004
	ld b, (hl)
	inc hl
	ld c, (hl)

	ld de, $0708
	ld a, 0
	call drawRectangleFilled

ret

checkSnekCollision:
	;check to see if the snek is touching a wall
	;draw a decorative rectangle around the playable game area
	;$010A
	;$FCAE

	;check to see if the snek can pick up the thingy
	ld hl, $2FFB
	ld b, (hl)
	ld hl, $2FFC
	ld c, (hl)

	ld hl, $5002
	ld d, (hl)
	ld hl, $5003
	ld e, (hl)

	ld a, b
	sub d
	cp 7
	jr c, snekCollisionTryY

	ld a, d
	sub b
	cp 7
	jr c, snekCollisionTryY
	ret

	snekCollisionTryY:
		ld a, c
		sub e
		cp 7
		jr c, addOneSnekLength

		ld a, e
		sub c
		cp 7
		jr c, addOneSnekLength

		ret

	addOneSnekLength:
	call makeSnekLonger
	call incrementScore
	call changeThingyPosition
	call checkThingyLocation


ret

makeSnekLonger:

	ld hl, $5000
	ld a, (hl)
	inc a
	ld (hl), a

	call shiftSnekDataUpOne


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

	ld hl, spritep1
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
		ld a, %00000011 	;3 = poop brown color
		out (c), a
		call smallDelay
		dec d
		ld a, d 
		cp 0
		jr nz, sprite01ColorLoop
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

score: db "Score:",0
exitmessage: db "Thank you for playing Snek.",0
exceptionEncountered: db "Exception encountered. Invalid scancode passed as control character: ",0

;the potato sprite
spritep1: db %00011000
spritep2: db %00111100
spritep3: db %01011010
spritep4: db %01111110
spritep5: db %01011010
spritep6: db %01100110
spritep7: db %00111100
spritep8: db %00011000