;MEMORY MAP:
;	rom: 0h-1FFFh
;	ram: 2000h-9FFFh
;	lcd: A000h-A003h
;	keyboard: A004h-A007h	(A004 is equivalent to 60h and A005 is equivalent to 64h on ibm x86 compatible pcs)
;	rtc: A010h-A01Fh
;
;
;Notable variable locations:
;	$2005: the last scancode that came from the keyboard
;	$2009: keyboard input character counter variable
;	$2010: character buffer map
;	$9EFF: caps lock true/false
di
ld sp, $9FFF		;set the stack pointer to the top of the ram

;fill the 20 character keyboard input store-er with null characters
ld hl, $2010
ld c, 20
ld a, 0
call fillRangeInRam

;set lcd to 8 bit 2 line mode
call waitForLcdReady
ld hl, $A000
ld (hl), %00111000

;turn display on
call waitForLcdReady
ld hl, $A000
ld (hl), %00001110

;set entry mode to the datasheet example default one
call waitForLcdReady
ld hl, $A000
ld (hl), %00000110

;send command to enable battery powered rtc and 24 hour time format
ld hl, $A01E
ld a, %00000110
ld (hl), a

;set the $2005 and $2009 variables to zero
call initializeVariables

call delayForaWhile				;do a small delay to allow the 8042 time to recover from being reset
;read the 8042
call initializeKeyboard

;get the lcd ram counter to reset to zero
call waitForLcdReady
ld hl, $A000
ld (hl), %10000000

;attempt to write contents of rtc to screen and do it over and over and over again
getTime:

;get whatever the last keyboard output was
;dont do it if there isn't any data ready though
;ld hl, $A005			;8042 status port
;ld a, (hl)
;and %00000001			;read the data register read ready bit
;cp 1
;jr nz, continueAndShowTypedInput

;if the controller said there was input data ready, read it
;ld hl, $A004
;ld a, (hl)
;cp $F0			;because of the way it goes "scancode" - "terminate code" - "scancode", I can discard this since I dont care about typematic
;jr z, FZEROWAITUNPRESS
;jr BYPASSF0WAITUNPRESS
;FZEROWAITUNPRESS:
;call discardUnpressScanCode
;jr continueAndShowTypedInput
;BYPASSF0WAITUNPRESS:
;store the last typed scancode into this location in ram for safe keeping
;ld hl, $2005
;only process if a different key than last time got pressed
;ld b, (hl)
;cp b
;jr z, continueAndShowTypedInput
;ld (hl), a
;if different key, continue and process the new keypress
;convert scancode to ascii value
;call scanCodeToAscii

call waitChar
call checkIfNonChar

cp 0
jr z, dontActuallyDoAnything			;solve that annoying unfindable bug with the caps lock always returning 0 after doing its scancode - f0 -scancode nonsense
cp $1A
jr z, dontActuallyDoAnything			;don't print caps lock as a character
cp $08
jr z, dontActuallyDoAnything 			;dont print backspace as a character
cp $0A
jr z, dontActuallyDoAnything    		;don't print enter as a character

ld hl, $2009
ld b, 0
ld c, (hl)
ld hl, $2010
add hl, bc
ld (hl), a
inc c
push af
ld a, c
cp 40 								;changed from 20 to 40 6:31pm 7/26/20
pop af
jr nc, dontResetInputCounter		;changed from nz to nc 7:39pm 7/25/20

;resetInputCounter:
;ld hl, $2009
;ld a, 0
;ld (hl), a
;jr continueAndShowTypedInput

dontResetInputCounter:
ld hl, $2009
ld (hl), c
jr continueAndShowTypedInput

continueAndShowTypedInput:
call printChar
dontActuallyDoAnything:

;call waitForLcdReady
;ld hl, $A000
;ld (hl), %10000000		;set lcd ram counter to $00 (1st line)
;call showKeyboardInput				;print the contents of whatever's in the user input ram address

;call waitForLcdReady
;ld hl, $A000
;ld (hl), %11000000		;set lcd ram counter to $40 (2nd line)

;call printTime			;see if the print time call works when I put it in a different file

;call delayForaWhile

jp getTime

;pre-conditions: none
;post-conditions: the lcd is 100% for sure ready for a command
;registers changed: a, hl
waitForLcdReady:
ld hl, $A001			;load the address of port 01b
ld a, (hl)				;save the result to the a register
and a, %10000000		;the busy flag at byte 7 is the only thing I care about right now
cp %10000000			;if z = 0, the lcd is busy. is z != 1, the lcd is not busy
jp z, waitForLcdReady	;if lcd is busy, do this again until it isn't busy anymore
ret

;load the a register with starting address of line you wish to erase and this function will do the rest
lcdBlankLine:
	push af
	call waitForLcdReady 			;remember to push and pop af since this function messes with the a register
	pop af
	ld hl, $A000
	ld (hl), a
	ld hl, TwentyCharsNothing
	push af
	call printString
	call waitForLcdReady
	pop af

	ld hl, $A000
	ld (hl), a 						;return to cursor to the beginning of whatever line just got cleared.
ret

;preconditions: hl contains address of string you want to print
;post conditions: hl contains the address of the last character of the desired string + 1
;registers changed: a, hl
printString:
ld a, (hl)				;address of string you want to print
cp 0
jr z, gtfo 				;if char is zero, that means end the string
push hl
call printChar			;print the current character
pop hl
inc hl					;increase string address by 1 to get to the next character
jr printString			;do it again
gtfo:
ret

printChar:

push af
call waitForLcdReady	;make sure the screen is ready first
call checkLength 		;decide if it needs to go to the next line or not

pop af
ld hl, $A002			;address of the character loading port
ld (hl), a	 			;load whatever's in the a register onto the screen
ret

checkLength:
ld hl, $A001
ld a, (hl)
and a, %01111111		;probably not required to do this (right now) but it will probably cause some strange bug further on down the line if i omit it
cp $14					;i think lcd ram address 13 is the last readable space of the first line
jr z, secLine
cp $54					;i think lcd ram address 53 is the last readable space of the first line
jr z, firstLine
jr doNothing

secLine:
call waitForLcdReady
ld a, %11000000			;the command byte that sets lcd ram address counter to $40
ld hl, $A000
ld (hl), a
jr doNothing

firstLine:
call waitForLcdReady
ld a, %10000000			;the command byte that sets lcd ram address counter to $00
ld hl, $A000
ld (hl), a

doNothing:
ret

;converts whatever 4 bit value is in the a register to the valid ascii code for that respective number in hex
aToHex:
	add a, 48
	cp 58
	jr nc, add7More
	jr dontAdd7More
	add7More:
		add a, 7

	dontAdd7More:
ret

aToScreenHex:
	push af
	res 0, a
	res 1, a
	res 2, a
	res 3, a
	rrc a
	rrc a
	rrc a
	rrc a
	call aToHex
	call printChar
	pop af
	res 7, a
	res 6, a
	res 5, a
	res 4, a
	call aToHex
	call printChar
ret

;this function displays whatever is in the a register to the screen in binary form
binaryToScreen:

	ld c, %10000000
	ld d, 8
	binaryToScreen2:
	push af
	and c
	push de
	call rotateARight
	pop de
	cp 0
	jr z, isZero		;if zero, jump to the zero section
	jr isOne			;if not zero its 1. jump to the 1 section

	isZero:
	push af
	ld a, "0"		;write a 0 to the lcd
	call printChar
	pop af
	jr cont 			;advance to next function

	isOne:
	push af
	ld a, "1"			;write a 1 to the lcd
	call printChar
	pop af
	jr cont 			;advance to next function

	cont:
	rrc c 				;shift c to the right by one
	dec d 				;decrease the counter (this is basically a for loop)
	ld a, d 			;copy d to a register to see if its time to end the loop or not
	cp 0
	pop af
	jr nz, binaryToScreen2 		;if d (which is now in a) is not zero, go back to the top of the loop
	;rrc b
	;and a, b
	;push bc
	;call rotateARight
	;call aToHex
	;call printChar
	;pop bc
	;dec c
	;rrc b


	;doTehLoop:
	;push af
	;and a, b 
	;push bc
	;call rotateARight
	;call aToHex
	;call printChar
	;pop bc
	;dec c
	;rrc b
	;ld a, c
	;cp 0
	;pop af
	;jr nz, doTehLoop

ret

delayForaWhile:
LD E,$1
J60:      
	LD B,$FF
J61:      
	LD D,$4F
J62:      
	DEC D
    JP NZ,J62
    DEC B
    JP NZ,J61
    DEC E
    JP NZ,J60
ret

rotateARight:
	DoTheRotation:
		dec d
		rrc a
		push af
		ld a, d
		cp 0
		pop af
		jr nz, DoTheRotation
ret

kbd8042WaitReadReady:
ld hl, $A005			;8042 status port
ld a, (hl)
and %00000001			;read the data register read ready bit
cp 1
jr nz, kbd8042WaitReadReady		;if it's not ready, keep waiting until it is
ret

kbd8042WaitWriteReady:
ld hl, $A005
ld a, (hl)
and %00000010
rrc a
cp 0
jr nz, kbd8042WaitWriteReady
ret


;showKeyboardInput:
	;ld hl, $2025
	;ld a, 0
	;ld (hl), a
	;ld hl, $2010
	;call printString
	;ld c, 0
	;ld b, 0
	;continueKeyboardInput:
		;ld hl, $2010
		;add hl, bc
		;ld a, (hl)
		;sub a, $15
		;ld hl, keyboardMap
		;ld d, 0
		;ld e, 0
		;ld e, a
		;add hl, de
		;ld a, (hl)
		;push bc
		;call printChar
		;pop bc
		;inc c
		;push af
		;ld a, c
		;cp 20
		;pop af
		;jr nz, continueKeyboardInput
;ret

;preconditions: register a contains a keyboard scancode
;post conditions: register a contains the respective ascii value for whatever its previously contained scancode was
scanCodeToAscii:
	
	push af
	ld hl, $9EFF
	ld a, (hl)
	and %00000001
	cp 1
	jr z, scanCodeToAsciiLoadShiftMap
	jr scanCodeToAsciiDontLoadShiftMap

	scanCodeToAsciiLoadShiftMap:
		ld hl, keyboardMapShift 		;load the location of the uppercase/shift scancode table
		jr scanCodeToAsciiContinue
	scanCodeToAsciiDontLoadShiftMap:
		ld hl, keyboardMapNoShift 		;load the location of the lowercase/non-shift scancode table
	scanCodeToAsciiContinue:

	pop af

	sub a, $15						;subtract $15 since it starts at 0 and not $15
	push af

	;gotta use add with carry so that it works correctly
	add   a, l    ; A = A+L
    ld    l, a    ; L = A+L
    adc   a, h    ; A = A+L+H+carry
    sub   l       ; A = H+carry
    ld    h, a    ; H = H+carry

	pop af
	ld a, (hl) 				;load the scancode character into register a
ret

initializeVariables:
ld a, 0
ld hl, $2005
ld (hl), a

ld hl, $2009
ld (hl), a

ld hl, $9EFF
ld (hl), 0
ret

discardUnpressScanCode:
	call kbd8042WaitReadReady
	ld hl, $A004
	ld a, (hl)
	ld hl, $2005
	ld a, 0
	ld (hl), a
ret

;preconditions: hl contains start address to clear. c contains number of bytes to clear
;post conditions: the range in memory has been set to zero
;this doesnt work. I need to fix it
clearRangeInRam:
	ld d, 0
	ld e, 0
	clearrangeramcont:
		ld (hl), 0
		inc hl
		inc e
		push af
		ld a, e
		cp c
		pop af
		jr c, clearrangeramcont
ret

;preconditions: hl contains start address to clear. c contains number of bytes to clear. a contains the value you want to fill in the address range
;post conditions: every byte in memory range has been set to a
;this doesnt work. I need to fix it
fillRangeInRam:
	ld d, 0
	ld e, 0
	fillrangeramcont:
		ld (hl), a
		inc hl
		inc e
		push af
		ld a, e
		cp c
		pop af
		jr c, fillrangeramcont
ret

keyboardGetType:
;see if i can recieve an ack response by disabling scanning
call kbd8042WaitWriteReady
ld hl, $A004
ld a, $F5
ld (hl), a
call kbd8042WaitReadReady
ld hl, $A004
ld a, (hl)
call aToScreenHex

;send identify command to keyboard
call kbd8042WaitWriteReady
ld hl, $A004
ld a, $F2
ld (hl), a
;wait for next response which should be ack anyway
call kbd8042WaitReadReady
ld hl, $A004
ld a, (hl)
call aToScreenHex

;print whatever the keyboard identified as
call kbd8042WaitReadReady
ld hl, $A004
ld a, (hl)
call aToScreenHex

;send command to make it re-enable scanning
call kbd8042WaitWriteReady
ld hl, $A004
ld a, $F6
ld (hl), a
call kbd8042WaitReadReady
ld hl, $A004
ld a, (hl)
call aToScreenHex

ret

;run this function to set up the keyboard controller and any connected devices
initializeKeyboard:
	call kbd8042WaitWriteReady
	;call delayForaWhile
	ld hl, $A005
	ld a, $AD
	ld (hl), a 						;disable devices. There is not going to be a mouse port so I wont use also use A7 to disable that

	ld hl, $A004
	ld a, (hl)						;flush output buffer by just reading from the data output port. It doesn't matter what it was since the chip just turned on and it's just going to be garbage anyway

	call delayForaWhile
	call kbd8042WaitWriteReady		;send the command to set the controller configuration byte
	;call delayForaWhile
	ld hl, $A005
	ld a, $60
	ld (hl), a

	call delayForaWhile
	call kbd8042WaitWriteReady		;once that's finished, actually send the configuration byte
	;call delayForaWhile
	ld a, %00100100					;set the controller configuration byte and be sure to enable port 1 clock
	ld (hl), a

	;perform a controller self-test
	call kbd8042WaitWriteReady
	;call delayForaWhile
	ld a, $AA 						;the self test command
	ld (hl), a
	;call delayForaWhile
	call kbd8042WaitReadReady
	ld hl, $A004
	ld a, (hl)						;read the results of the self test. if it prints to the screen as "55", it worked correctly
	call aToScreenHex

	;perform a ps/2 device test
	call kbd8042WaitWriteReady
	ld hl, $A005
	ld a, $AB						;the self test command
	ld (hl), a
	call kbd8042WaitReadReady
	ld hl, $A004
	ld a, (hl) 						;read the results of the self test
	call aToScreenHex 				;display self test byte to screen as hex

	;enable 1st device
	call kbd8042WaitWriteReady
	call delayForaWhile
	ld hl, $A005
	ld a, $AE 						;AE means enable
	ld (hl), a

	;see what happens afte enabling. Maybe this will help me find out why the keyboard doesnt work unless you reset it after powering on
	call kbd8042WaitReadReady
	ld hl, $A004
	ld a, (hl)
	call aToScreenHex
ret

;this function waits for the user to input a key. Once a keyboard key has been pressed, it loads the a register with the respective ascii code
waitChar:
	;wait for keyboard to be ready
	call kbd8042WaitReadReady

	;if the controller said there was input data ready, read it
	ld hl, $A004
	ld a, (hl)
	cp $F0			;because of the way it goes "scancode" - "terminate code" - "scancode", I can discard this since I dont care about typematic
	jr z, FZEROWAITUNPRESS
	jr BYPASSF0WAITUNPRESS
	FZEROWAITUNPRESS:
	call discardUnpressScanCode
	jr waitChar
	BYPASSF0WAITUNPRESS:
	;store the last typed scancode into this location in ram for safe keeping
	ld hl, $2005
	;only process if a different key than last time got pressed
	ld b, (hl)
	cp b
	jr z, waitChar
	ld (hl), a
	;if different key, continue and process the new keypress
	;ld (hl), a
	;convert scancode to ascii value
	call scanCodeToAscii

	waitCharExit:
ret

;used for checking for stuff such as backspace, caps lock and enter
checkIfNonChar:
	;ld e, 0 						;if e is 0, the ascii code in register a is not a "nonchar". If e is 1, the ascii code in register a in a "nonchar"

	cp $0A							;enter
	jr nz, checkIfNonCharBackspace
	call parseCliInput 				;when running "the terminal" enter always sends whatever the user has typed as a command
									;a different program such as a text editor will need a slightly different version of this function
	jr checkIfNonCharExit

	checkIfNonCharBackspace:
	cp $08							;backspace
	jr nz, checkIfNonCharCaps
	;ld e, 1 						;set e so the cli will know the ascii code in register a is a "nonchar" and won't display it
	push af
	call lcdBackspace
	pop af
	jr checkIfNonCharExit

	checkIfNonCharCaps:
	cp $1A							;caps/shift
	jr nz, checkIfNonCharExit
	;ld e, 1 						;set e so the cli will know the ascii code in register a is a "nonchar" and won't display it
	push af
	call toggleCaps
	pop af

	checkIfNonCharExit:
ret

;this backspaces whatever's on the 20x2 lcd by 1
lcdBackspace:
	ld hl, $2009
	ld a, (hl)      						;load character counter amount into register a
	cp 21
	jr nc, lcdBackspaceCtrMore20
	jr lcdBackspaceCtrLess20
	lcdBackspaceCtrLess20:
		;load register b with starting point for 1st line
		ld b, %10000000						;lcd ram address bit for position 1 line 1
		dec a 								;decrease character counter by 1
		call setCurrentCommandSpaceToNull   ;set the most recent character in the command variable to null
		ld (hl), a 							;go ahead and save it - $2009 should still be in hl register
		jr lcdBackspaceContinue
	lcdBackspaceCtrMore20:
		;load register b for starting point of 2nd line
		ld b, %11000000  					;lcd ram address bit for position 1 line 2
		dec a 								;decrease character counter by 1
		call setCurrentCommandSpaceToNull   ;set the most recent character in the command variable to null
		ld (hl), a 							;go ahead and save it - $2009 should still be in hl register
		sub a, 20 							;be sure to subtract 20 from the ram counter's value AFTER saving. This way, the screen will display the backspace correctly
		jr lcdBackspaceContinue
	lcdBackspaceContinue:
		add a, b 							;now we have the desired lcd ram position for the character to be backspaced
		push af
		call waitForLcdReady
		pop af
		ld hl, $A000
		ld (hl), a
		push af
		ld a, 32							;put a "space" character wherever it got backspaced
		call printChar 						;print the space to create an empty square
		call waitForLcdReady
		pop af
		ld hl, $A000
		ld (hl), a  						;with any luck, it should be ready to go now
ret


toggleCaps:
	;find what the value of the caps bit is
	ld hl, $9EFF
	ld a, (hl)
	and %00000001
	cp 1
	jr z, toggleCapsResetCaps
	jr toggleCapsSetCaps

	toggleCapsSetCaps:
		call kbd8042WaitWriteReady
		ld hl, $A004
		ld (hl), $ED  						;send the set lights command to the keyboard

		call kbd8042WaitWriteReady
		ld hl, $A004
		ld (hl), %00000100 					;turn on the caps led

		ld hl, $9EFF
		ld (hl), 1 							;store caps lock on in ram
		jr toggleCapsExit

	toggleCapsResetCaps:
		call kbd8042WaitWriteReady
		ld hl, $A004
		ld (hl), $ED  						;send the set lights command to the keyboard

		call kbd8042WaitWriteReady
		ld hl, $A004
		ld (hl), %00000000 					;turn off the caps led

		ld hl, $9EFF
		ld (hl), 0 							;store caps lock off in ram

		jr toggleCapsExit

	toggleCapsExit:
ret

;used to update the command saving memory area with a null character whenever backspace is pressed
setCurrentCommandSpaceToNull:
	push af 
	push hl
	ld hl, $2009
	ld a, (hl)				;find character number
	ld hl, $2010

	;gotta use add with carry so that it works correctly
	add   a, l    ; A = A+L
    ld    l, a    ; L = A+L
    adc   a, h    ; A = A+L+H+carry
    sub   l       ; A = H+carry
    ld    h, a    ; H = H+carry

    ;should be ready to write a null value now
    ld (hl), 0

    pop hl
    pop af 

ret

include '9958driver.asm'
include 'commands.asm'

TwentyCharsNothing: db "                    ",0
longMessage: db "This message is longer than 1 line",0
message: db "What hath God wrought",0
ready: db "ready",0
controlPort: db "ctrl port= ",0
kbdtype: db "kbtype:",0

;here is my scancode to ascii table.
;I know, I know, someone call an exorcist
keyboardMapShift: db "Q!$$$ZSAW@$$CXDE$#$$ VFTR%$$NBHGY^$$$MJU&*$$,KIO)($$>?L:P_$$$",$27,"${+$$",$1A,"$",$0A,"}$$$$$$$$$$",$08,"$$1$47$$$0.2568**$+3-*9",0
keyboardMapNoShift: db "q1$$$zsaw2$$cxde43$$ vftr5$$nbhgy6$$$mju78$$,kio09$$./l;p-$$$",$27,"$[=$$",$1A,"$",$0A,"]$$$$$$$$$$",$08,"$$1$47$$$0.2568**$+3-*9",0