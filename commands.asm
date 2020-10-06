;$9EFF
;the asm file for the command interpreter

parseCliInput:

	;check if the inputted command is the print command
	ld hl, $2010
	ld de, printcmd
	ld b, 6
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputPrintString

	;check if the input is the show time command
	ld hl, $2010
	ld de, printtimecmd
	ld b, 4
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputShowTime

	;check if the input is the show date command
	ld hl, $2010
	ld de, printdatecmd
	ld b, 4
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputShowDate

	;check if the input is the set time command
	ld hl, $2010
	ld de, settimecmd
	ld b, 8
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputSetTime

	;check if the input is the set date command
	ld hl, $2010
	ld de, setdatecmd
	ld b, 8
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputSetDate

	;check if the input is the test video command
	ld hl, $2010
	ld de, testvideocmd
	ld b, 9
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputTestVideo

	;check if the input is the vdp status register command
	ld hl, $2010
	ld de, vdpstatuscmd
	ld b, 10
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputVdpStatus

	;check if the input is the vdp manual register set command
	ld hl, $2010
	ld de, setvdpregcmd
	ld b, 7
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputvdpregset

	;check if the input is the load fonts command
	ld hl, $2010
	ld de, loadfontscmd
	ld b, 9
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputLoadFonts

	;check if the input is the clear command
	ld hl, $2010
	ld de, clearscreencmd
	ld b, 5
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputClearScreen

	;check if the input is the testvram command
	ld hl, $2010
	ld de, testvramcmd
	ld b, 8
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputTestVram

	;check if the input is the togglevmode command
	ld hl, $2010
	ld de, togglevmodecmd
	ld b, 11
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputToggleVMode

	;check if the input is the change color command
	ld hl, $2010
	ld de, changecolorcmd
	ld b, 11
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputChangeColor

	;check if the input is the drive status command
	ld hl, $2010
	ld de, driveStatuscmd
	ld b, 11
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputDriveStatus

	;check if the input is the drive error command
	ld hl, $2010
	ld de, driveerrorcmd
	ld b, 10
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputDriveError

	;check if the input is the cftest command
	ld hl, $2010
	ld de, cftestcmd
	ld b, 6
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputCFTest

	;check if the input is the read command
	ld hl, $2010
	ld de, readmemorycmd
	ld b, 5
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputReadMemory

	;check if the input is the iowr command
	ld hl, $2010
	ld de, iowrcmd
	ld b, 5
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputIOWRITE

	;check if the input is the iord command
	ld hl, $2010
	ld de, iordcmd
	ld b, 5
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputIOREAD

	;check if the input is the mmwr command
	ld hl, $2010
	ld de, memwrcmd
	ld b, 5
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputMEMWRITE

	;check if the input is the mmrd command
	ld hl, $2010
	ld de, memrdcmd
	ld b, 5
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputMEMREAD

	;check if the input is the fsinfo command
	ld hl, $2010
	ld de, fsinfocmd
	ld b, 6
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputFsInfo

	;check if the input is the fsinfo command
	ld hl, $2010
	ld de, testaddcmd
	ld b, 7
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputTestAdd

	;check if the input is the ls command
	ld hl, $2010
	ld de, lscmd
	ld b, 2
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputPrintDirectory

	;check if the input is the dir command
	ld hl, $2010
	ld de, dircmd
	ld b, 3
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputPrintDirectory

	;check if the input is the cd command
	ld hl, $2010
	ld de, cdcmd
	ld b, 3
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputChangeDirectory

	;check if the input is the test1 command
	ld hl, $2010
	ld de, test1cmd
	ld b, 5
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliTest1

	;check if the input is the call command
	ld hl, $2010
	ld de, callcmd
	ld b, 5
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliCallCommand

	;check if the input is the run command
	ld hl, $2010
	ld de, runcmd
	ld b, 4
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliRunCommand

	;check if the input is the cfreset command
	ld hl, $2010
	ld de, cfresetcmd
	ld b, 7
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliCfReset

	;check if the input is the help command
	ld hl, $2010
	ld de, helpcmd
	ld b, 4
	call areStringsEqual
	ld a, 1
	cp c
	jp z, parseCliInputHelp

	;check if the input is the get key
	ld hl, $2010
	ld de, getKeyCommandText
	ld b, 6
	call areStringsEqual
	ld a, 1
	cp c
	jr z, parseCliInputGetKey

	jp parseCliInputInvalidCommand

	parseCliInputPrintString:
		call printTextCommand
		jp parseCliInputExit
	parseCliInputShowTime:
		call printTime
		jp parseCliInputExit
	parseCliInputShowDate:
		call printDate
		jp parseCliInputExit
	parseCliInputSetTime:
		call setTime
		jp parseCliInputExit
	parseCliInputSetDate:
		call setDate
		jp parseCliInputExit
	parseCliInputGetKey:
		call getKeyCommand
		jp parseCliInputExit
	parseCliInputTestVideo:
		call initializeVideo
		jr parseCliInputExit
	parseCliInputVdpStatus:
		call VdpStatusManualCommand
		jr parseCliInputExit
	parseCliInputvdpregset:
		call VdpManualSetCommand
		jr parseCliInputExit
	parseCliInputLoadFonts:
		call VdpLoadFonts
		jr parseCliInputExit
	parseCliInputClearScreen:
		call ClearScreen
		jr parseCliInputExit
	parseCliInputTestVram:
		call VdpTestVram
		jr parseCliInputExit
	parseCliInputToggleVMode:
		call togglevmode
		jr parseCliInputExit
	parseCliInputChangeColor:
		call changeColor
		jr parseCliInputExit
	parseCliInputDriveStatus:
		call getCFStatusCommand
		jr parseCliInputExit
	parseCliInputDriveError:
		call getCFErrorCommand
		jr parseCliInputExit
	parseCliInputCFTest:
		call CFTestCommand
		jr parseCliInputExit
	parseCliInputReadMemory:
		call readAndDisplayMemory
		jr parseCliInputExit
	parseCliInputIOREAD:
		call manualioread
		jr parseCliInputExit
	parseCliInputIOWRITE:
		call manualiowrite
		jr parseCliInputExit
	parseCliInputMEMREAD:
		call manualmemread
		jr parseCliInputExit
	parseCliInputMEMWRITE:
		call manualmemwrite
		jr parseCliInputExit
	parseCliInputFsInfo:
		call fsInfoTestCommand
		jr parseCliInputExit
	parseCliInputTestAdd:
		call test32bitAdd
		jr parseCliInputExit
	parseCliInputPrintDirectory:
		call printCurrentDirectory
		jr parseCliInputExit
	parseCliInputChangeDirectory:
		call changeDirectoryCommand
		jr parseCliInputExit
	parseCliTest1:
		call genericTest1Command
		jr parseCliInputExit
	parseCliCallCommand:
		call callCommand
		jr parseCliInputExit
	parseCliRunCommand:
		call runProgramFromDisk
		jr parseCliInputExit
	parseCliCfReset:
		call CfReset
		jr parseCliInputExit
	parseCliInputHelp:
		call helpCommand
		jr parseCliInputExit
	parseCliInputInvalidCommand:
		call invalidCommand
	parseCliInputExit:
		call VdpInsertEnter
		call clearCommandBuffer 		;reset command buffer so you dont have to press backspace a bunch after entering a command
ret

printTime:
	call VdpInsertEnter
	;ld a, %11000000 					;the lcd's address for the 2nd line
	;call lcdBlankLine 					;print a blank line on the 2nd line on the lcd to discard any data from the previous command

	ld hl, time
	;call printString
	call VPrintString

	;hours
	ld hl, $A014
	ld a, (hl)
	call aToScreenHex
	ld a, ":"
	;call printChar 
	call VdpPrintChar

	;minutes
	ld hl, $A012
	ld a, (hl)
	call aToScreenHex
	ld a, ":"
	;call printChar
	call VdpPrintChar

	;seconds
	ld hl, $A010
	ld a, (hl)
	call aToScreenHex

	;call backToPrevCursorPos

ret

printDate:
	;ld a, %11000000 					;the lcd's address for the 2nd line
	;call lcdBlankLine 					;print a blank line on the 2nd line on the lcd to discard any data from the previous command
	call VdpInsertEnter

	;months
	ld hl, $A019
	ld a, (hl)
	call aToScreenHex
	ld a, "/"
	;call printChar
	call VdpPrintChar

	;days
	ld hl, $A016
	ld a, (hl)
	call aToScreenHex
	ld a, "/"
	;call printChar
	call VdpPrintChar

	;years
	ld hl, $A01A
	ld a, (hl)
	call aToScreenHex

	;call backToPrevCursorPos
ret

setTime:
	;inhibit updating to allow time to be set
	call VdpInsertEnter
	ld hl, $A01E
	ld a, %00001110
	ld (hl), a

	ld hl, $2018
	ld a, (hl)
	sub a, 48
	sla a
	sla a
	sla a
	sla a
	and %00110000
	ld b, a
	inc hl
	ld a, (hl)
	sub a, 48
	add a, b 							;now we have the 1s and 10s place for the current hour.
	ld hl, $A014
	ld (hl), a

	ld hl, $201A
	ld a, (hl)
	sub a, 48
	sla a
	sla a
	sla a
	sla a
	and %01110000
	ld b, a
	inc hl
	ld a, (hl)
	sub a, 48
	add a, b 							;now we have the 1s and 10s place for the current minute.
	ld hl, $A012
	ld (hl), a

	ld hl, $201C
	ld a, (hl)
	sub a, 48
	sla a
	sla a
	sla a
	sla a
	and %01110000
	ld b, a
	inc hl
	ld a, (hl)
	sub a, 48
	add a, b 							;now we have the 1s and 10s place for the current second.
	ld hl, $A010
	ld (hl), a

	;re-enable updating now that time has been set
	ld hl, $A01E
	ld a, %00000110
	ld (hl), a

	;ld a, %11000000 					;the lcd's address for the 2nd line
	;call lcdBlankLine 					;print a blank line on the 2nd line on the lcd to discard any data from the previous command
	ld hl, genericok
	;call printString
	call VPrintString
	;call backToPrevCursorPos

ret

setDate:
	call VdpInsertEnter
	;inhibit updating to allow time to be set
	ld hl, $A01E
	ld a, %00001110
	ld (hl), a

	ld hl, $2018
	ld a, (hl)
	sub a, 48
	sla a
	sla a
	sla a
	sla a
	and %00010000
	ld b, a
	inc hl
	ld a, (hl)
	sub a, 48
	add a, b 							;now we have the 1s and 10s place for the current month.
	ld hl, $A019
	ld (hl), a

	ld hl, $201A
	ld a, (hl)
	sub a, 48
	sla a
	sla a
	sla a
	sla a
	and %00110000
	ld b, a
	inc hl
	ld a, (hl)
	sub a, 48
	add a, b 							;now we have the 1s and 10s place for the current day.
	ld hl, $A016
	ld (hl), a

	ld hl, $201C
	ld a, (hl)
	sub a, 48
	sla a
	sla a
	sla a
	sla a
	and %11110000
	ld b, a
	inc hl
	ld a, (hl)
	sub a, 48
	add a, b 							;now we have the 1s and 10s place for the current year.
	ld hl, $A01A
	ld (hl), a

	;re-enable updating now that time has been set
	ld hl, $A01E
	ld a, %00000110
	ld (hl), a

	;ld a, %11000000 					;the lcd's address for the 2nd line
	;call lcdBlankLine 					;print a blank line on the 2nd line on the lcd to discard any data from the previous command
	ld hl, genericok
	;call printString
	call VPrintString
	;call backToPrevCursorPos

ret

;display next pressed key to the screen
getKeyCommand:
	call VdpInsertEnter
	;ld a, %11000000
	;call lcdBlankLine

	printAnotherKey_getKeyCommand:
	call waitChar
	push af
	call aToScreenHex
	pop af

	;esc currently returns "2A" (the ascii value for *). So if that happens, exit the program
	cp $2A
	jr nz, printAnotherKey_getKeyCommand

	;call backToPrevCursorPos

ret

printTextCommand:
	call VdpInsertEnter
	;;ld a, %11000000 					;the lcd's address for the 2nd line
	;;call lcdBlankLine 					;print a blank line on the 2nd line on the lcd to discard any data from the previous command
	;call waitForLcdReady
	;ld hl, $A000
	;ld (hl), %11000000 			;the text is going to be printed on the second line of the lcd
	ld hl, $2016	 			;print whatever's in the saved command variable as a string, discarding the first 6 characters since they are part of the command
	;call printString
	call VPrintString
	;call backToPrevCursorPos
ret

invalidCommand:
	call VdpInsertEnter
	;ld a, %11000000 					;the lcd's address for the 2nd line
	;call lcdBlankLine 					;print a blank line on the 2nd line on the lcd to discard any data from the previous command
	;call waitForLcdReady
	;ld hl, $A000
	;ld (hl), %11000000 			;the text is going to be printed on the second line of the lcd
	ld hl, badcommand	 			;print whatever's in the saved command variable as a string to see just how accurate that thing actually is
	;call printString
	call VPrintString
	;call backToPrevCursorPos
ret

;put the cursor back to whereever it was before typing in the command (not the best thing to do but I will change it later after I get a few other things working)
;will probably no longer be used if I ever get a video card for this
backToPrevCursorPos:
	call waitForLcdReady
	ld hl, $2009
	ld a, (hl)					;get whatever value the character counter has
	add a, %10000000 			;add it to the starting lcd ram address
	ld hl, $A000
	ld (hl), a 					;put the cursor back to whereever it was before typing in the command (not the best thing to do but I will change it later after I get a few other things working)
ret

;if the first b characters of string in de is equal to the string in hl, c becomes set. otherwise, c gets reset
areStringsEqual:
	ld c, 0
	areStringsEqualDoAgain:
	ld a, (de)
	cp (hl)
	jr z, areStringsEqualContinue 
	jr nz, areStringsEqualExit

	areStringsEqualContinue:
	 	inc hl
	 	inc de
	 	dec b

	 	ld a, 0
	 	cp b 

	 	jr nz, areStringsEqualDoAgain
	 	ld c, 1
	 	jr areStringsEqualGTFO
	areStringsEqualExit:
		ld c, 0
	areStringsEqualGTFO:
ret

VdpStatusManualCommand:

	ld a, %11000000
	call lcdBlankLine

	ld a, "R"
	call printChar

	ld hl, $201A		;ram address of whatever command parameter is in the correct place
	ld a, (hl)
	push af
	call printChar
	ld a, "="
	call printChar
	pop af
	sub a, 48
	call VdpReadStatus

	call aToScreenHex
	call backToPrevCursorPos

ret

VdpManualSetCommand:
	ld hl, $2017
	ld a, (hl)
	call aToHex
	sla a
	sla a
	sla a
	sla a
	ld b, a
	inc hl
	ld a, (hl)
	call aToHex
	add a, b
	;assuming the user typed a hex value, we now we have the hex value of the register to use
	ld c, a ;save it to c for temporary safe keeping

	ld hl, $2020
	ld a, (hl)
	call aToHex
	sla a
	sla a
	sla a
	sla a
	ld b, a
	inc hl
	ld a, (hl)
	call aToHex
	add a, b
	
	;now load register a into d and c into a in preparation for the write register subroutine
	ld d, a
	ld a, c

	call VdpWriteToStandardRegister
	ld hl, genericok
	call printString


ret

VdpLoadFonts:

	call VdpCharsIntoRam

	ld a, %11000000
	call lcdBlankLine
	ld hl, fontLoaded
	call printString
	call backToPrevCursorPos
ret

;TO-DO: Fix the bug where it puts the cursor on row 1 and not row zero
ClearScreen:
	
	;set column and row counters to zero
	ld a, 0
	ld hl, $9EFA
	ld (hl), a
	inc hl
	ld (hl), a

	ld hl, $2009
	ld (hl), a

	;fill the 40 character keyboard input store-er with null characters
	inc hl
	ld c, 80
	call clearRangeInRam

	;only thing left is to clear the screen in vram
	call eraseScreen
	;now run this so the vram addres pointer will be at top of screen area and ready to be used some more
	call RowsColumnsToVram


ret

VdpTestVram:
	ld a, %11000000
	call lcdBlankLine	;clear second row of lcd to make room for the test results

	ld a, 14
	ld d, %00000000
	call VdpWriteToStandardRegister
	ld a, %00000010
	out (c), a
	ld a, %01010010
	out (c), a

	ld c, $20
	ld a, %00000000
	out (c), a
	ld a, %11111111
	out (c), a
	ld a, $69
	out (c), a
	ld a, 69
	out (c), a

	ld a, 14
	ld d, %00000000
	call VdpWriteToStandardRegister
	ld a, %00000010
	out (c), a
	ld a, %00010010
	out (c), a

	;start writing results of the vram reads to the screen. Let's see if this son of a bitch actually works or not
	ld c, $20
	in a,(c)
	call aToScreenHex
	in a,(c)
	call aToScreenHex
	in a,(c)
	call aToScreenHex
	in a,(c)
	call aToScreenHex

	ld hl, genericok
	call printString
	call backToPrevCursorPos

ret

togglevmode:
	;first, set cursor to second row of lcd in preparation to print the results
	ld a, %11000000
	call lcdBlankLine	;clear second row of lcd to make room for the test results

	;0 = ntsc. 1 = pal
	ld hl, $9EFD
	ld a, (hl)
	and a, %00000001
	cp %00000001
	jr z, togglevmodePal
		;ntsc. switch to pal

		;write 1 to area in ram to indicate pal
		ld a, 1
		ld (hl), a

		ld a, 9
		ld d, %00000010 	;change respective vdp register. bit 1 = 1 means pal
		call VdpWriteToStandardRegister
		
		;put visual confirmation on lcd that video mode as been changed to correct format
		ld hl, palmsg
		call printString
		jr togglevmodeExit
	togglevmodePal:
		;pal. switch to ntsc

		;write 0 to area in ram to indicate ntsc
		ld a, 0
		ld (hl), a

		ld a, 9
		ld d, %00000000 	;change respective vdp register. bit 1 = 0 means ntsc
		call VdpWriteToStandardRegister

		;put visual confirmation on lcd that video mode as been changed to correct format
		ld hl, ntscmsg
		call printString
		jr togglevmodeExit
	togglevmodeExit:
	call backToPrevCursorPos
ret

changeColor:

	;blank the screen because this didn't work before I blanked it
	ld d, %00000000
	ld a, 1
	call VdpWriteToStandardRegister

	ld hl, $9EFC
	ld a, (hl)
	and a, %00000001
	cp %00000001
	jr z, makeColorRed
		ld a, 1
		ld hl, $9EFC
		ld (hl), a
		ld a, 0
		ld d, %01110000
		ld e, %00000000
		jr changeColorContinue

	makeColorRed:
		ld a, 0
		ld hl, $9EFC
		ld (hl), a
		ld a, 0
		ld d, %00000111
		ld e, %00000000
	changeColorContinue:
	call VdpWriteToPaletteRegister

	;put the screen back to the way it was before
	ld d, %01010000
	ld a, 1
	call VdpWriteToStandardRegister

	ld a, %11000000
	call lcdBlankLine	;clear second row of lcd to make room for the test results
	ld hl, genericok
	call printString
	call backToPrevCursorPos
ret

getCFStatusCommand:
	call VdpInsertEnter

	ld hl, cfstatusequals
	call VPrintString
	call getCFStatus
	call aToScreenHex

ret

getCFErrorCommand:

	call VdpInsertEnter

	ld hl, cferrorequals
	call VPrintString
	ld b, $A0
	ld c, $31
	in a, (c)
	call aToScreenHex

ret

CFTestCommand:

	call readCFSector
	;ld d, $FF
	;ld hl, $3000
	;call displayMemoryToScreen

	call VdpInsertEnter
	ld hl, genericok
	call VPrintString

ret

callCommand:
	;go ahead and make a new line
	call VdpInsertEnter
	ld hl, $2015
	ld a, (hl)
	inc hl
	ld b, (hl)
	call asciiToHex
	ld d, a

	inc hl
	ld a, (hl)
	inc hl
	ld b, (hl)
	call asciiToHex
	ld e, a

	;address of where to jump to is now in hl

	;load return address into hl
	ld hl, callCommandPlaceToReturnTo
	ex de, hl
	push de 	;push return address onto the stack without popping it
	jp (hl) 	;jump to user inputted address
	callCommandPlaceToReturnTo:

ret

readAndDisplayMemory:
	call VdpInsertEnter

	;get the address that the user typed
	ld hl, $2015
	ld a, (hl)
	inc hl
	ld b, (hl)
	call asciiToHex

	ld d, a

	inc hl
	ld a, (hl)
	inc hl
	ld b, (hl)
	call asciiToHex
	ld e, a

	;replace hl register with contents of de
	ex de, hl

	call displayMemoryToScreenPretty

ret

displayMemoryToScreenPretty:

	ld d, $FF
	displayRamDriveTestLoopPrettyNewLine:
	push de
	push hl
		push hl
			call VdpInsertEnter
		pop hl
		ld a, h
		push hl
		call aToScreenHex
		pop hl
		ld a, l
		call aToScreenHex
		ld a, ':'
		call VdpPrintChar
	pop hl
	pop de
	ld e, 20
	displayRamDriveTestLoopPretty:
		ld a, (hl)
		push hl
			push af
				ld a, ' '
				push de
				call VdpPrintChar
				pop de
			pop af
			call aToScreenHex
		pop hl
		inc hl
		dec d
		dec e
		ld a, e
		cp 0
		jr z, displayRamDriveTestLoopPrettyNewLine
		ld a, d
		cp 0
		jr nz, displayRamDriveTestLoopPretty

ret

parseMemoryCommandVariables:

	;get the 4 digit 16 bit address into the de register
	ld hl, $2015
	ld a, (hl)
	inc hl
	ld b, (hl)
	call asciiToHex

	ld d, a

	inc hl
	ld a, (hl)
	inc hl
	ld b, (hl)
	call asciiToHex
	
	ld e, a

	;get the 8 bit value to pass into the actual command
	inc hl
	inc hl
	ld a, (hl)
	inc hl
	ld b, (hl)
	call asciiToHex

ret

manualioread:
	
	call VdpInsertEnter

	call parseMemoryCommandVariables
	ld b, d
	ld c, e
	in a, (c)

	call aToScreenHex

ret

manualmemread:
	
	call VdpInsertEnter

	call parseMemoryCommandVariables
	ld h, d
	ld l, e
	ld a, (hl)

	call aToScreenHex

ret

manualiowrite:

	call parseMemoryCommandVariables
	ld b, d
	ld c, e
	out (c), a
ret

manualmemwrite:

	call parseMemoryCommandVariables
	ld h, d
	ld l, e
	ld (hl), a
ret

fsInfoTestCommand:

	call getPartitionInfo

	call gotoRootDirectory 							;obtaining the lba of the root directory needs to be part of mounting a drive. Therefore i'm putting this in the mount command and not the dir command because this makes more sense for modularity

	ld hl, genericok
	call VPrintString
	call VdpInsertEnter

ret

helpCommand:

	call VdpInsertEnter
	ld hl, availableCommands
	call VPrintString

	call VdpInsertEnter
	ld hl, cftestcmd
	call VPrintString

	call VdpInsertEnter
	ld hl, clearscreencmd
	call VPrintString

	call VdpInsertEnter
	ld hl, printdatecmd
	call VPrintString

	call VdpInsertEnter
	ld hl, driveStatuscmd
	call VPrintString

	call VdpInsertEnter
	ld hl, fsinfocmd
	call VPrintString

	call VdpInsertEnter
	ld hl, helpcmd
	call VPrintString

	call VdpInsertEnter
	ld hl, iordcmd
	call VPrintString
	ld hl, hexformat
	call VPrintString

	call VdpInsertEnter
	ld hl, iowrcmd
	call VPrintString
	ld hl, hexformat
	call VPrintString
	ld hl, eightbithexformat
	call VPrintString

	call VdpInsertEnter
	ld hl, memrdcmd
	call VPrintString
	ld hl, hexformat
	call VPrintString

	call VdpInsertEnter
	ld hl, memwrcmd
	call VPrintString
	ld hl, hexformat
	call VPrintString
	ld hl, eightbithexformat
	call VPrintString
	
	call VdpInsertEnter
	ld hl, printcmd
	call VPrintString

	call VdpInsertEnter
	ld hl, readmemorycmd
	call VPrintString
	ld hl, hexformat
	call VPrintString

	call VdpInsertEnter
	ld hl, setdatecmd
	call VPrintString
	ld hl, dateformat
	call VPrintString

	call VdpInsertEnter
	ld hl, settimecmd
	call VPrintString
	ld hl, timeformat
	call VPrintString

	call VdpInsertEnter
	ld hl, printtimecmd
	call VPrintString

ret

;	$96A0-$96A1: low byte for first value of 32 bit add
;	$96A2-$96A3: high byte for first value of 32 bit add
;	$96A4-$96A5: low byte for second value of 32 bit add
;	$96A6-$96A7: high byte for second value of 32 bit add
;
;	$96A8-$96A9: low byte for result of a 32 bit arithmatic operation
;	$96AA-$96AB: high byte for result of a 32 bit arithmatic operation

test32bitAdd:
	
	call VdpInsertEnter

	call subtract32BitNumber

	;ld hl, $96A3
	;ld a, (hl)
	;call aToScreenHex
	;ld hl, $96A2
	;ld a, (hl)
	;call aToScreenHex
	;ld hl, $96A1
	;ld a, (hl)
	;call aToScreenHex
	;ld hl, $96A0
	;ld a, (hl)
	;call aToScreenHex

	call print1st32bitNum

	ld a, "-"
	call VdpPrintChar

	call print2nd32bitNum
	;ld hl, $96A7
	;ld a, (hl)
	;call aToScreenHex
	;ld hl, $96A6
	;ld a, (hl)
	;call aToScreenHex
	;ld hl, $96A5
	;ld a, (hl)
	;call aToScreenHex
	;ld hl, $96A4
	;ld a, (hl)
	;call aToScreenHex

	ld a, "="
	call VdpPrintChar
	call print32bitresultanswer


ret

printCurrentDirectory:
	
	call VdpInsertEnter
	;if depth = zero, then it's at the root.
	;call gotoRootDirectory
	;call VdpInsertEnter
	call printAllFilesInSector

	;now reset it back to the beginning of the cluster
	call updateDirectoryFromData


ret

changeDirectoryCommand:
	
	;set all string spaces to spaces before doing string compare. This is required to make it work for files with names shorter than 8 characters
	ld hl, $9684
	ld c, 17
	ld e, $20
	call fillRangeInRam

	call VdpInsertEnter

	;first, check if the user inputted the go up a directory command
	ld hl, $2013
	ld a, (hl)
	cp $2E
	jr nz, changeDirectoryCommandContinueAndFindFile
	call goUp1Directory
	jr changeDirectoryCommandExitSuccess

	changeDirectoryCommandContinueAndFindFile:
	;copy the first 8 characters from the input buffer to $9684
	ld hl, $2013
	ld de, $9684
	ld b, 9
	copyCdSearchCharacters:
		;ld a, (hl)
		;cp 0
		;jr nz, copyCdSearchCharactersDontReplaceNull
		;ld a, $20
		;ld (hl), a
		;copyCdSearchCharactersDontReplaceNull:
		;if it's a null, terminate the loop because that's the end of the string
		ld a, (hl)
		cp 0
		jr z, copyCdSearchCharactersGTFO

		call addressToOtherAddress
		inc hl
		inc de
		dec b
		ld a, b
		cp 0
		jr nz, copyCdSearchCharacters
		copyCdSearchCharactersGTFO:

	;now that the filename has been copied, search the current working directory for the file or folder
	call searchFileInDirectory
		
	;check to see if the file was found or not. If $2000-$2003 = 00000000 then the file was not found
	ld hl, $2000
	ld a, (hl)
	cp 0
	jr nz, changeDirectoryCommandContinue
	inc hl
	ld a, (hl)
	cp 0
	jr nz, changeDirectoryCommandContinue
	inc hl
	ld a, (hl)
	cp 0
	jr nz, changeDirectoryCommandContinue
	inc hl
	ld a, (hl)
	cp 0
	jr nz, changeDirectoryCommandContinue
	jr changeDirectoryCommandExitError

	changeDirectoryCommandContinue:

	;if it was found, increment the filesystem depth counter and calculate the lba address of where the file or folder starts
	call enterDirectoryAtLocation
	jr changeDirectoryCommandExitSuccess

	changeDirectoryCommandExitError:
		;file wasn't found. Be sure to rememeber to set it back to the beginning of the cluster
		call updateDirectoryFromData
		ld hl, directoryNotFound
		call VPrintString

	changeDirectoryCommandExitSuccess:

ret

runProgramFromDisk:

	;set all string spaces to spaces before doing string compare. This is required to make it work for files with names shorter than 8 characters
	ld hl, $9684
	ld c, 17
	ld e, $20
	call fillRangeInRam

	call VdpInsertEnter

	;first, check if the user inputted the go up a directory command
	ld hl, $2014
	ld a, (hl)
	cp $2E
	jr nz, runProgramFromDiskContinueAndFindFile
	;display this error if the user tries to run the parent directory as a program
	ld hl, runDotDotError
	call VPrintString
	jr runProgramFromDiskExitSuccess

	runProgramFromDiskContinueAndFindFile:
	;copy the first 8 characters from the input buffer to $9684
	ld hl, $2014
	ld de, $9684
	ld b, 9
	runProgramFromDiskcopyCdSearchCharacters:
		;ld a, (hl)
		;cp 0
		;jr nz, copyCdSearchCharactersDontReplaceNull
		;ld a, $20
		;ld (hl), a
		;copyCdSearchCharactersDontReplaceNull:
		;if it's a null, terminate the loop because that's the end of the string
		ld a, (hl)
		cp 0
		jr z, runProgramFromDiskcopyCdSearchCharactersGTFO

		call addressToOtherAddress
		inc hl
		inc de
		dec b
		ld a, b
		cp 0
		jr nz, runProgramFromDiskcopyCdSearchCharacters
		runProgramFromDiskcopyCdSearchCharactersGTFO:

	;now that the filename has been copied, search the current working directory for the file or folder
	call searchFileInDirectory
		
	;check to see if the file was found or not. If $2000-$2003 = 00000000 then the file was not found
	ld hl, $2000
	ld a, (hl)
	cp 0
	jr nz, runProgramFromDiskContinue
	inc hl
	ld a, (hl)
	cp 0
	jr nz, runProgramFromDiskContinue
	inc hl
	ld a, (hl)
	cp 0
	jr nz, runProgramFromDiskContinue
	inc hl
	ld a, (hl)
	cp 0
	jr nz, runProgramFromDiskContinue
	jr runProgramFromDiskExitError

	runProgramFromDiskContinue:

	;if it was found, increment the filesystem depth counter and calculate the lba address of where the file or folder starts
	;treat the file as a directory
	call enterDirectoryAtLocation
	ld hl, $2110
	ld de, $3000
	ld bc, $0200
	;copy first 512 bytess of the file into ram at $3000. Will change this to copy all the bytes later
	call copyRamBlock
	;now that the stuff has been copied, go up 1 directory to go back to the folder the file is in
	call goUp1Directory
	;run the program which starts at $3000
	call $3000
	jr runProgramFromDiskExitSuccess

	runProgramFromDiskExitError:
		;file wasn't found. Be sure to rememeber to set it back to the beginning of the cluster
		call updateDirectoryFromData
		ld hl, directoryNotFound
		call VPrintString

	runProgramFromDiskExitSuccess:

ret

CfReset:
	
	call driveInit
	call VdpInsertEnter
	ld hl, genericok
	call VPrintString

ret

genericTest1Command:
	call getClusterSize
	;call gotoClusterSector
	;ld hl, $9678
	;ld de, $2000
	;call addressToOtherAddress
	;inc hl
	;inc de
	;call addressToOtherAddress
	;inc hl
	;inc de
	;call addressToOtherAddress
	;inc hl
	;inc de
	;call addressToOtherAddress

ret

cfstatusequals: db "CF card #0 status = ",0
cferrorequals: db "CF card #0 error = ",0
time: db "time= ",0
badcommand: db "invalid syntax",0
printcmd: db "print ",0
printtimecmd: db "time",0
printdatecmd: db "date",0
settimecmd: db "settime ",0
getKeyCommandText: db "getkey",0
setdatecmd: db "setdate ",0
testvideocmd: db "testvideo",0
vdpstatuscmd: db "vdpstatus ",0
setvdpregcmd: db "setreg ",0
readmemorycmd: db "read ",0
loadfontscmd: db "loadfonts",0
clearscreencmd: db "clear",0
iowrcmd: db "iowr ",0
iordcmd: db "iord ",0
memwrcmd: db "mmwr ",0
memrdcmd: db "mmrd ",0
cdcmd: db "cd ",0
fsinfocmd: db "fsinfo",0
lscmd: db "ls",0
dircmd: db "dir",0
testvramcmd: db "testvram",0
driveStatuscmd: db "drivestatus",0
driveerrorcmd: db "driveerror",0
cftestcmd: db "cftest",0
helpcmd: db "help",0
test1cmd: db "test1",0
togglevmodecmd: db "togglevmode",0
changecolorcmd: db "changecolor",0
genericok: db "OK",0
ntscmsg: db "video mode is ntsc",0
palmsg: db "video mode is pal",0
genericfailed: db "failed",0
timeformat: db " [hhmmss]",0
dateformat: db " [MMDDYY]",0
hexformat: db " [NNNN(h)]",0
callcmd: db "call ",0
runcmd: db "run ",0
cfresetcmd: db "cfreset",0
testaddcmd: db "testadd",0
bit16multstring: db "16 bit mult =",0
eightbithexformat: db " [NN(h)]",0
availableCommands: db "Available commands:",0
fontLoaded: db "fonts loaded",0
directoryNotFound: db "Directory not found",0
runDotDotError: db "you can",$27,"t run the parent directory as an executable file, dumbass.",0