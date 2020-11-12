VdpWriteToStandardRegister: equ $B01C
ClearScreen: equ $B014
initializeVideo: equ $B018
waitChar: equ $B024
VdpInsertEnter: equ $B008
VdpPrintChar: equ $B000
VPrintString: equ $B004
clearMostVram: equ $B03C
VdpWriteToPaletteRegister: equ $B020
setupG4Mode: equ $B044
drawLine: equ $B048
waitVdpCommandFinished: equ $B04C
drawRectangle: equ $B050
drawRectangleFilled: equ $B054

load16bitvaluesFromRam: equ $B070
mul16: equ $B074
loadmul16IntoRam: equ $B078
putResultInParameter1: equ $B058
add32BitNumber: equ $B068
kbd8042WaitReadReady: equ $B084
G4PrintString: equ $B090

;$927B = keyboard key down byte
;bit7 = f. bit6 = e. bit5 = q. bit4 = space. bit3 = d. bit2 = s. bit1 = a. bit0 = w
;the purpose of this program is to develop a method of getting/reading keyboard keys in a way that is useful for games
org $3000
	
	programLoop:
	call waitVblank
	call ClearScreen
	call printControlByte
	call waitChar
	call getKeys
	cp $76
	jr nz, programLoop

ret

getKeys:

	call checkChar
	;see if the last one was the termination character or not
	ld hl, $2005
	ld a, (hl)
	cp $F0
	jr nz, isNotFZero

	;if it was the termination character ($F0), do this stuff
	isFZero:
	
	ret

	isNotFZero:
		ld hl, $927B
		ld a, (hl)
		;set bit 0 (w bit) to on 
		or %00000001
		ld (hl), a

ret

;derived from the checkchar subroutine in POMAN game - by the time anyone sees this comment, POMANS whole input system will have probably been redone and this wont be in POMAN anyone
;if there is a character, return it. Otherwise go on
;this variation preserves the $F0 scancode 
;looks like if a = 0 if device was not ready or did not have data ready
checkChar:
	ld hl, $A005			;8042 status port
	ld a, (hl)
	and %00000001			;read the data register read ready bit
	cp 1
	ret z 					;if it's not ready just return fuck it
	;wait for keyboard to be ready
	;put wait ready here unless I forget
	;

	;if the controller said there was input data ready, read it
	ld hl, $A004
	ld a, (hl)
	;store the last typed scancode into this location in ram for safe keeping
	ld hl, $2005
	ld (hl), a

ret

printControlByte:

	ld e, %00000001
	charPrintingLoop:
		ld hl, $927B
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