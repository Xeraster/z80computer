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

keyPressByteLocation: equ $927B

;$927B = keyboard key down byte
;bit7 = f. bit6 = e. bit5 = q. bit4 = space. bit3 = d. bit2 = s. bit1 = a. bit0 = w
;the purpose of this program is to develop a method of getting/reading keyboard keys in a way that is useful for games
org $3000
	;clear the keypress location byte
	ld hl, keyPressByteLocation
	ld a, 0
	ld (hl), a

	programLoop:
	;call waitVblank
	call ClearScreen
	call printControlByte
	call kbd8042WaitReadReady
	call getKeys
	ld hl, keyPressByteLocation
	ld a, (hl)
	and %10000000
	cp %10000000
	ret z
	jr programLoop
	;call getKeys
	;cp $76
	;jr nz, programLoop

ret

;a=1c
;s=1b
;d = $23
;w=1D
;$972B = bit 7 = esc, bit 6 = enter, bit 5 = space, bit 4 = q, bit 3 = w, bit 2 = a, bit 1 = s, bit 0 = d
getKeys:
	call checkChar
	cp 0
	ret z

	checkDKey:
	cp $23
	jr nz, checkSKey
	ld c, %00000001
	ld b, %11111110
	jr endKeyCompare

	checkSKey:
	cp $1B
	jr nz, checkAKey
	ld c, %00000010
	ld b, %11111101
	jr endKeyCompare

	checkAKey:
	cp $1C
	jr nz, checkWKey
	ld c, %00000100
	ld b, %11111011
	jr endKeyCompare

	checkWKey:
	cp $1D
	jr nz, checkQKey
	ld c, %00001000
	ld b, %11110111
	jr endKeyCompare

	checkQKey:
	cp $15
	jr nz, checkSpaceKey
	ld c, %00010000
	ld b, %11101111
	jr endKeyCompare

	checkSpaceKey:
	cp $29
	jr nz, checkEnterKey
	ld c, %00100000
	ld b, %11011111
	jr endKeyCompare

	checkEnterKey:
	cp $5A
	jr nz, checkEscKey
	ld c, %01000000
	ld b, %10111111
	jr endKeyCompare

	checkEscKey:
	cp $76
	ret nz
	ld c, %10000000
	ld b, %01111111
	jr endKeyCompare

	endKeyCompare:
	ld a, d
	cp 0
	jr z, DoKeypress
	jr undoKeypress
	DoKeypress:
	ld hl, keyPressByteLocation
	ld a, (hl)
	or c
	ld (hl), a
	ret

	undoKeypress:
	ld hl, keyPressByteLocation
	ld a, (hl)
	and b
	ld (hl), a


ret

;derived from the checkchar subroutine in POMAN game - by the time anyone sees this comment, POMANS whole input system will have probably been redone and this wont be in POMAN anyone
;if there is a character, return it. Otherwise go on
;this variation preserves the $F0 scancode 
;looks like if a = 0 if device was not ready or did not have data ready
;if d = 1 it's an unpress. Otherwise, it's a press down
checkChar:
	ld d, 0
	CheckCharFirstRun:
	ld hl, $A005			;8042 status port
	ld a, (hl)
	and %00000001			;read the data register read ready bit
	cp 1
	ret nz 					;if it's not ready just return fuck it
	;wait for keyboard to be ready
	;put wait ready here unless I forget
	;

	;if the controller said there was input data ready, read it
	ld hl, $A004
	ld a, (hl)
	;store the last typed scancode into this location in ram for safe keeping
	ld hl, $2005
	ld (hl), a
	cp $F0
	ret nz
	;cp $E0
	;jr z, getRidOFE0Key
	call kbd8042WaitReadReady
	ld d, 1
	;if the controller said there was input data ready, read it
	ld hl, $A004
	ld a, (hl)
	;store the last typed scancode into this location in ram for safe keeping
	ld hl, $2005
	ld (hl), a
	ret

	;getRidOFE0Key:
	;ld hl, $A004
	;ld a, (hl)
	;cp $F0
	;jr z, TwoMoreFuckshits
	;ret

	;TwoMoreFuckshits:
	;call kbd8042WaitReadReady
	;ld hl, $A004
	;ld a, (hl)


ret

printControlByte:

	ld e, %00000001
	charPrintingLoop:
		ld hl, keyPressByteLocation
		ld a, (hl)
		and e
		push de
			cp 0
			jr nz, wIsTrue
			wIsFalse:
				ld hl, falseResult
				jr wContinue
			wIsTrue:
				ld hl, trueResult
			wContinue:
				call VPrintString
				call VdpInsertEnter
		pop de
		sla e
		ld a, e
		;if e rotation ran off the byte, making it equal to zero, that means the loop ran all 8 times
		cp %00000000
		jr nz, charPrintingLoop

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

kbd8042WaitWriteReady:
ld hl, $A005
ld a, (hl)
and %00000010
rrc a
cp 0
jr nz, kbd8042WaitWriteReady
ret

wkey: db "W=",0
akey: db "A=",0
skey: db "S=",0
dkey: db "D=",0
spacekey: db "Sp",0
esckey: db "EC",0
qkey: db "Q=",0
ekey: db "E=",0

falseResult: db "false",0
trueResult: db "true",0
startMsg: db "About to change keyboard mode. Press any key to continue",0
keymsg: db "Keyboard is now in F8 mode",0
pressAnyKey: db "Press any key to continue",0