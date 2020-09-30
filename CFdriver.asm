;=========================================================================================================
;This is the assembly file that contains the compact flash card driver as well as the Fat32 file explorer
;
;~Welcome to hell~
;=========================================================================================================
;
; 	http://averstak.tripod.com/fatdox/dir.htm
;	https://en.wikipedia.org/wiki/Design_of_the_FAT_file_system#EBPB32_OFS_37h
;	https://www.cs.fsu.edu/~cop4610t/lectures/project3/Week11/Slides_week11.pdf	
;	https://www.cse.scu.edu/~tschwarz/COEN252_09/Lectures/FAT.html
;
;	$96DE: high amount of detected bytes per sector
;	$96DD: low amount of detected bytes per sector (it's a 16 bit value)
;	$96DC: number of logical sectors per cluster
;	$96DB: number of reserved logical sectors (high byte)
;	$96DA: number of reserved logical sectors  (low byte)
;	$96D9: number of file allocation tables
;
;	$96D8: number of logical sectors (high byte)
;	$96D7: number of logical sectors
;	$96D6: number of logical sectors
;	$96D5: number of logical sectors (lowest byte)
;
;	$96D4: logical sectors per FAT (high byte)
;	$96D3: logical sectors per FAT
;	$96D2: logical sectors per FAT
;	$96D1: logical sectors per FAT (lowest byte)
;
;	$96D0: cluster # of root directory start (high byte)
;	$96CF: cluster # of root directory start
;	$96CE: cluster # of root directory start
;	$96CD: cluster # of root directory start (lowest byte)
;
;	$96CC: logical number of FS information sector (high byte)
;	$96CB: logical number of FS information sector (low byte)
;
;	$96CA: lba address of partition 1 (high byte)
;	$96C9: lba address of partition 1
;	$96C8: lba address of partition 1
;	$96C7: lba address of partition 1 (low byte)

;in my current test partition, the lba address of the data sector is 000025e0
; address partition 1 + num reserved sectors + (num fats * logical sectors per fat) = data region start
;	(0800)					(20) 						(2 * 0EE0)
;
; address partition 1 + num reserved sectors = fat1 start
; address partition 1 + num reserved sectors + logical sectors per fat = fat2 start


;======================================
;pretty important
;=====================================
;	$96EF: (LBA27-LBA24) drive head value of next drive operation
;	$96EE: (LBA23-LBA16) high cylinder value of next drive operation
;	$96ED: (LBA15-LBA08) low cylinder value of next driver operation
;	$96EC: (LBA07 - LBA00) sector number of next drive operation
;
;
;===========================================================
;the way the file structure is [going to be] kept track of |
;===========================================================
;
;$9691: filesystem depth high byte
;$9690: how many chains deep in the filesystem (0 if at root directory)
;
;$968F: LBA27-24 of root directory
;$968E: LBA23-16 of root directory
;$968D: LBA15-08 of root directory
;$968C: LBA07-00 of root directory
;
;$968B: LBA27-24 of next directory down
;$968A: LBA23-16 of next directory down
;$9689: LBA15-08 of next directory down
;$9688: LBA07-00 of root directory down
;
; and so on and so fourth for:
;($968F-(current depth*4)): LBA27-24 of current working directory
;($968E-(current depth*4)): LBA23-16 of current working directory
;($968D-(current depth*4)): LBA15-08 of current working directory
;($968C-(current depth*4)): LBA07-00 of current working directory
;
;
;======================================
; file layout structure explained
;======================================
; $00-$1F: vfat data. Actual file starts at $20. Files created on systems before long filenames were invented don't have this
; $20-$27: 8 character file name. If less than 8 characters, pad with spaces at end
; $28-$2A: 3 character file extension padded by null characters
; $2B: file attributes. bit 0 = read only. bit 1 = hidden. bit 2 = file belongs to system. bit 3 = vfat label. bit 4 = subdirectory. bit 5 = archive (has to do with backup software). bit 6 = device. bit 7 = reserved
; $2C: CP/M crap. Just set to zero or ignore
; $2D: creation time in 10 ms intervals. valid numbers are 0 to 199.
; $2E-$2F: file creation time. bits 15-11 = hours(0-23). bits 10-5 = minutes (0-59). bits 4-0 = seconds/2 (0-29)
; $30-$31: file creation date. bits 15-9 = years since 1980 (0-127). bits 8-5 = month (0-12). bits 0-4 - day (1-31)
; $32-$33: last access date using same format as above
; $34-$35. high 2 bytes of first cluster of file
; $36-$37: last modified time
; $38-39: last modified date
; $3A-3B: low two bytes of first cluster of file
; $3C-3F: file size in bytes. little endian
driveInit:
	
	;let's try doing a reset
	ld b, $A0
	ld c, $0E
	ld a, %00001110
	out (c), a
	call smallDelay
	ld a, %00001010
	out (c), a

	;command register drive 0
	ld b, $A0
	ld c, $31 		;we want to write to the feature register

	ld a, $01
	out (c), a 		;enable 8-bit mode

	call WaitCFReady

	ld c, $37 		;change to command register
	ld a, $EF
	out (c), a 		;set features command

	;do this
	call CFsetDefaultDriveOperationValues

ret

;set default values in a location in ram
;this way it's easy and cheap for programs to use the drive
CFsetDefaultDriveOperationValues:

	;set sector save location low byte
	ld hl, $96E9
	ld a, $10
	ld (hl), a
	
	;set sector save location high byte
	ld hl, $96EA
	ld a, $21
	ld (hl), a

	;set sector count variable to 1 (the default value)
	ld hl, $96EB
	ld a, 1
	ld (hl), a

	;set sector number variable to 1
	ld hl, $96EC
	ld a, 0 	;in lba mode, this should be zero instead of 1 if you want to read the first sector
	ld (hl), a

	;set low cylinder variable
	ld hl, $96ED
	ld a, 0
	ld (hl), a

	;set high cylinder variable
	ld hl, $96EE
	ld a, 0
	ld (hl), a

	;set drive head variable
	ld hl, $96EF
	ld a, $E0
	ld (hl), a
ret

getCFStatus:

	ld b, $A0
	ld c, $37
	in a, (c)

ret

;this currently just reads the very first sector of cf card 0
readCFSector:
	ld hl, $96E6
	ld a, 0
	ld (hl), a
	readCFSectorLoop:

	call smallDelay
	call smallDelay
	call smallDelay
	call smallDelay
	call smallDelay

	call WaitCFReady
	call WaitCFReadyForCommand

	;set sector number register to 0
	ld b, $A0
	ld c, $33
	ld hl, $96EC
	ld a, (hl)
	out (c), a
	ld hl, step1
	call printStatusTest

	call WaitCFReady
	call WaitCFReadyForCommand
	;set high and low cylinder registers to zero
	ld c, $34
	ld hl, $96ED
	ld a, (hl)
	out (c), a

	call WaitCFReady
	call WaitCFReadyForCommand
	ld c, $35
	ld hl, $96EE
	ld a, (hl)
	out (c), a
	ld hl, step2
	call printStatusTest

	;set up drive head register values
	call WaitCFReady
	call WaitCFReadyForCommand
	ld c, $36
	ld hl, $96EF
	ld a, (hl)
	out (c), a
	ld hl, step3
	call printStatusTest

	;set sector count register to 1 (because I only want to copy the first sector right now)
	call WaitCFReady
	call WaitCFReadyForCommand
	ld c, $32
	ld hl, $96EB
	ld a, (hl)
	out (c), a
	ld hl, step4
	call printStatusTest

	call WaitCFReady
	call WaitCFReadyForCommand

	;set 20h in command register to indicate I want to read
	ld c, $37
	ld a, $20
	out (c), a
	ld hl, step5
	call printStatusTest

	;call WaitCFReady
		;store the values of whatever this yields into ram starting at address $3000
		ld hl, $96EA
		ld d, (hl)
		ld hl, $96E9
		ld e, (hl)
		ex de, hl
		ld de, $0000

		;clear the contents of the byte read counter
		push hl
			ld a, 0
			ld hl, $96E7
			ld (hl), a
			inc hl
			ld (hl), a
		pop hl

		;now run the part that actually reads the data
		call readDataRegisterUntilFinished

		;check if the number of re-read attempts is a really high number or not
		ld hl, $96E6
		ld a, (hl)
		inc a
		ld (hl), a
		cp $FE 					;maximum amount of retry attempts
		jr z, ReadYeildError

		;now check if the number of bytes read is correct. If not, do it again
		ld hl, $96E8
		ld a, (hl)
		cp $02 					;if number of bytes read = $0200, then it was a 100% perfect read. It never goes over 512 bytes in 5 volt mode
		jp nz, readCFSectorLoop
		jr ExitNoYeildError
	ReadYeildError:
		ld hl, CFyeilderror
		call VPrintString
		call VdpInsertEnter
	ExitNoYeildError:

	ld hl, CFnumretries
	call VPrintString
	ld hl, $96E6
	ld a, (hl)
	call aToScreenHex
	call VdpInsertEnter
	;ld d, $FF
	;call WaitCFReady
	;call WaitCFTransferReady
	;call readDataRegister256Times
	;call readDataRegister256Times
	;ld d, $FD
	;call readDataRegister256Times
	;call readDataRegister256Times

	;done

ret

readDataRegisterUntilFinished:

	ld b, $A0
	readDataRegisterUntilFinishedLoop:
		call WaitCFReady
		push de
		call smallDelay
		pop de
		call getCFStatus
		push af
			and %00000001
			cp $01 		;if $01, that means there was an error.
		pop af
		jr z, readDataRegisterUntilFinishedExitError 	;exit loop but print error message to indicate that the loop ended due to an error flag
		and %01011000
		cp $50 		;if $50, that means there's no more data to be read so the loop can be ended
		jr z, readDataRegisterUntilFinishedGTFO
		cp $58 		;if $58, that means there's data to be read
		jr nz, readDataRegisterUntilFinishedLoop
		
		push de
		;give the capacitors a few hundred extra nanoseoncds to charge up for the next read
		;doesn't make too much of a difference but the results are ~slightly~ better when I do this
		call smallDelay
		pop de

		;write the data to whatever memory address is in the hl register
		ld c, $30
		in a, (c)
		ld (hl), a
		inc hl
		inc de
		jr readDataRegisterUntilFinishedLoop

		readDataRegisterUntilFinishedExitError:
			ld hl, CFerror
			call VPrintString
		readDataRegisterUntilFinishedGTFO:
			;put the number of transferred bytes into ram somewhere to assist in troubleshooting
			ld hl, $96E7
			ld a, e
			ld (hl), a
			inc hl
			ld a, d
			ld (hl), a

			call print16BitDecimal
			;ld hl, $96E7
			;ld a, (hl)
			;ld e, a
			;inc hl
			;ld a, (hl)
			;ld d, a
			;call printBytesTransferred
			;call VdpInsertEnter
			;ld hl, $96E8
			;ld a, (hl)
			;call aToScreenHex
			;ld hl, $96E7
			;ld a, (hl)
			;call aToScreenHex

			ld hl, CFbytescopied
			call VPrintString
			call VdpInsertEnter

ret

;todo- make this into a multipurpose "hex to screen decimal" type function later
;printBytesTransferred:
print16BitDecimal:
	;ld hl, $96E7
	;ld a, (hl)
	;ld e, a
	;inc hl
	;ld a, (hl)
	;ld d, a

	ld hl, $96E5
	ld a, 0
	ld (hl), a

	ex de, hl
	ld c, 10
	call HL_Div_C
	ex de, hl
	add 48
	ld hl, $96E4
	ld (hl),a

	ex de, hl
	ld c, 10
	call HL_Div_C
	ex de, hl
	add 48
	ld hl, $96E3
	ld (hl),a

	ex de, hl
	ld c, 10
	call HL_Div_C
	ex de, hl
	add 48
	ld hl, $96E2
	ld (hl),a

	ex de, hl
	ld c, 10
	call HL_Div_C
	ex de, hl
	add 48
	ld hl, $96E1
	ld (hl),a

	ex de, hl
	ld c, 10
	call HL_Div_C
	ex de, hl
	add 48
	ld hl, $96E0
	ld (hl),a

	ld hl, $96E0
	call VPrintString
	;ld hl, CFbytescopied
	;call VPrintString

ret

;prints the low 2 digits of an 8 bit decimal ignoring the highest digit
print2DigitDecimal:

	ld d, 10
	call CDivD
	add 48
	ld hl, $96C5
	ld (hl), a

	call CDivD
	add 48
	ld hl, $96C4
	ld (hl), a

	ld hl, $96C6
	ld a, 0
	ld (hl), a

	ld hl, $96C4
	call VPrintString

ret

;c needs to contain the value of whatever you want to print as decimal
print8bitDecimal:
	
	ld d, 10
	call CDivD
	add 48
	ld hl, $90C6
	ld (hl), a

	call CDivD
	add 48
	ld hl, $90C5
	ld (hl), a

	call CDivD
	add 48
	ld hl, $90C4
	ld (hl), a

	ld hl, $90C7
	ld a, 0
	ld (hl), a

	ld hl, $90C4
	call VPrintString

ret

;readDataRegister256Times:
	;ld b, $A0
	;ld c, $30
	;ld d, $FF
	;readDataRegister256TimesLoop:
		;wait for status register to be "58h" which indicates it's ready for transfer
		;call WaitCFReady
		;call WaitCFTransferReady
		;ld c, $30
		;in a, (c)
		;ld (hl), a
		;inc hl
		;dec d
		;ld a, d
		;cp 0
		;jr nz, readDataRegister256TimesLoop

;ret

;generic wait command
;waits until the "not ready" bit is zero, indicating that the other bits in the status register are valid and that writing stuff to registers will work
WaitCFReady:
	call getCFStatus
	and %1000000
	cp $80
	jr z, WaitCFReady

ret

;a configurable delay which can be modified by changing $96DF in ram
smallDelay:
	ld e, $03
	smallDelayLoop:
		dec e
		push af
		ld a, e
		cp 0
		pop af
		jr nz, smallDelayLoop

ret

;this will make it wait until it's ready enough to recieve a command
WaitCFReadyForCommand:
	call getCFStatus
	and %01010000
	cp $50
	jr nz, WaitCFReadyForCommand

ret

WaitCFTransferReady:

	call getCFStatus
	and %01011000
	cp $58
	jr nz, WaitCFTransferReady

ret
;this will make it wait until it's ready enough to perform read or write operations to the drive
;WaitCFTransferReady:
;	WaitCFTransferReadyLoop:
;		call getCFStatus
;		and %00000001
;		cp $01
;		jr z, WaitCFTransferReadyLoopGTFO
;		call getCFStatus
;		and %01011000
;		cp $58
;		jr nz, WaitCFTransferReadyLoop
;		jr WaitCFTransferReadyLoopGTFONoErrors
;	WaitCFTransferReadyLoopGTFO:
;		push af
;		push bc
;		push de
;		push hl
;			ld hl, CFerror
;			call VPrintString
;		pop hl
;		pop de
;		pop bc
;		pop af
;		jr WaitCFTransferReadyLoopGTFONoErrors
;	WaitCFTransferReadyLoopGTFONoErrors:
;ret

printStatusTest:

	push af
	push bc 
		call VPrintString
		call VdpInsertEnter
	pop bc
	pop af

ret

;	$96CA: lba address of partition 1 (high byte)
;	$96C9: lba address of partition 1
;	$96C8: lba address of partition 1
;	$96C7: lba address of partition 1 (low byte)
;this function obtains the partition info from the boot sector, locates the fat32 partition and then updates the respective variables in ram
getPartitionInfo:
	
	;set cf registers so that it will be pointing to the boot sector
	call CFsetDefaultDriveOperationValues

	call readCFSector
	;22D6 - lba lowest byte
	;22D7 - lba next higher byte
	;22D8 - lba next higher byte
	;22D9 - lba high byte
	ld hl, $22D9
	ld de, $96CA
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	;now the lba address of partition 1 is in ram

	;this just does what the commented out code code. I made it into a subroutine to save memory since other functions need to use that same block of code
	call prepareSectorData
	;only bits 3-0 of the head register are for lba (lba bits 27-24).
	;the rest is other stuff
	;ld hl, $96CA
	;ld a, (hl)
	;or %11100000
	;ld hl, $96EF
	;ld (hl), a

	;ld hl, $96C9
	;ld de, $96EE
	;call addressToOtherAddress
	;dec hl
	;dec de
	;call addressToOtherAddress
	;dec hl
	;dec de
	;call addressToOtherAddress
	;the the lba address of partition 1 is set in the correct place to be used during next drive read


	call readCFSector
	;sector 1 of the desired drive partition is now in ram starting at $2110

;	$96DE: high amount of detected bytes per sector
;	$96DD: low amount of detected bytes per sector (it's a 16 bit value)
	ld hl, $211B
	ld de, $96DD
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress

;	$96DC: number of logical sectors per cluster
	ld hl, $211D
	ld de, $96DC
	call addressToOtherAddress

;	$96DB: number of reserved logical sectors (high byte)
;	$96DA: number of reserved logical sectors  (low byte)
	ld hl, $211E
	ld de, $96DA
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress

;	$96D9: number of file allocation tables
	ld hl, $2120
	ld de, $96D9
	call addressToOtherAddress

;	$96D8: number of logical sectors (high byte)
;	$96D7: number of logical sectors
;	$96D6: number of logical sectors
;	$96D5: number of logical sectors (lowest byte)
	ld hl, $2130
	ld de, $96D5
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress

;	$96D4: logical sectors per FAT (high byte)
;	$96D3: logical sectors per FAT
;	$96D2: logical sectors per FAT
;	$96D1: logical sectors per FAT (lowest byte)
	ld hl, $2134
	ld de, $96D1
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress

;	$96D0: cluster # of root directory start (high byte)
;	$96CF: cluster # of root directory start
;	$96CE: cluster # of root directory start
;	$96CD: cluster # of root directory start (lowest byte)
	ld hl, $213C
	ld de, $96CD
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress

;	$96CC: logical number of FS information sector (high byte)
;	$96CB: logical number of FS information sector (low byte)
	ld hl, $2140
	ld de, $96CB
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress

ret

partitionStartToMathParam1:

	;load starting address of the partition to arithmatic parameter #1 in preparation for calculations and stuff 
	ld hl, $96CA
	ld de, $96A3
	call addressToOtherAddress
	dec de
	dec hl

	call addressToOtherAddress
	dec de
	dec hl

	call addressToOtherAddress
	dec de
	dec hl

	call addressToOtherAddress

ret

;	$96B0-$96BF: temporary storage for random filesystem related stuff
; address partition 1 + num reserved sectors = fat1 start
; address partition 1 + num reserved sectors + logical sectors per fat = fat2 start
; address partition 1 + num reserved sectors + (num fats * logical sectors per fat) = data region start

;this makes the drive go to the sector of the root directory then copy the contents of the sector into ram starting at $2110
;2 bugs with this function as of 06:53:43 09/29/2020:
;	1. it clears $96C8-$96EF for some reason
gotoRootDirectory:
	;load the partition base address into arithmatic parameter 1
	call partitionStartToMathParam1


	ld hl, $96A6
	ld a, 0
	ld (hl), a
	inc hl
	ld (hl), a

	ld hl, $96DB
	ld de, $96A5
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress

	ld hl, testStringCF1
	call VPrintString
	call VdpInsertEnter

	;add the number of reserved sectors to the partition base starting lba address
	call add32BitNumber

	call print1st32bitNum

	ld a, "+"
	call VdpPrintChar

	call print2nd32bitNum
	ld a, "="
	call VdpPrintChar
	call print32bitresultanswer
	call VdpInsertEnter

	;save for later
	ld hl, $96AB
	ld de, $96BF
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress

	;load number of logical sectors per fat into arithmatic parameter 1
	ld hl, $96D4
	ld de, $96A3
	call addressToOtherAddress
	dec de
	dec hl
	call addressToOtherAddress
	dec de
	dec hl
	call addressToOtherAddress
	dec de
	dec hl
	call addressToOtherAddress

	;load the number of fats into parameter 2
	ld hl, $96A7
	ld a, 0
	ld (hl), a
	dec hl
	ld (hl), a
	dec hl
	ld (hl), a

	ld hl, $96D9
	ld de, $96A4
	call addressToOtherAddress

	;print a message to the screen so I know what's going on
	ld hl, testStringCF2
	call VPrintString
	call VdpInsertEnter

	;multiply the number of sectors per fat by the number of fats
	call ramTomul32Do
	call mul32

	;show the inputs and result of the calculation
	call print1st32bitNum
	ld a, "*"
	call VdpPrintChar
	call print2nd32bitNum
	ld a, "="
	call VdpPrintChar
	ld hl, $96AF
	ld a, (hl)
	call aToScreenHex
	ld hl, $96AE
	ld a, (hl)
	call aToScreenHex
	ld hl, $96AD
	ld a, (hl)
	call aToScreenHex
	ld hl, $96AC
	ld a, (hl)
	call aToScreenHex
	call print32bitresultanswer
	call VdpInsertEnter

	;put the result of that calculation into parameter 1
	call putResultInParameter1

	;take the result of the begin + reserved sectors and put it into parameter 2
	ld hl, $96BF
	ld de, $96A7
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress


	;do this so I know what's about to happen next
	ld hl, testStringCF3
	call VPrintString
	call VdpInsertEnter

	;add them together
	call add32BitNumber

	;now print the results of the above calculation to the screen
	call print1st32bitNum
	ld a, "+"
	call VdpPrintChar
	call print2nd32bitNum
	ld a, "="
	call VdpPrintChar
	call print32bitresultanswer
	call VdpInsertEnter
	
	;the math result variable should now contain the lba address of the root directory starting sector
	;now, it's time to move the value from the arithmatic result location to the "read next" location
	;ld hl, $96A8
	;ld de, $96C7
	;call addressToOtherAddress
	;inc hl
	;inc de
	;call addressToOtherAddress
	;inc hl
	;inc de
	;call addressToOtherAddress
	;inc hl
	;inc de 							;probably completely unneeded
	;call addressToOtherAddress

	;prepare the data in $96C7-$96CA for use when the readCFSector function is run
	;call prepareSectorData
	;96eb-96ef
	ld hl, $96AB
	ld a, (hl)
	or %11100000
	ld hl, $96EF
	ld (hl),a

	ld hl, $96AA
	ld de, $96EE
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress

	;$9691: filesystem depth high byte
	;$9690: how many chains deep in the filesystem (0 if at root directory)
	;update the filesystem depth counter to reflect the fact that it's at the root directory
	ld hl, $9691
	ld a, 0
	ld (hl), a
	dec hl
	ld (hl), a

	;$968F: LBA27-24 of root directory
	;$968E: LBA23-16 of root directory
	;$968D: LBA15-08 of root directory
	;$968C: LBA07-00 of root directory
	;update the lba address linked list - put the lba address of the root directory in position #0
	ld hl, $96AB
	ld de, $968F
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress


	;actually read the desired sector
	call readCFSector

	;if everything worked correctly, there should now be a copy of the first sector of the root directory at $2110

ret

;this is the subroutine that takes the lba number in $96C7-$96CA and prepares it for use in that other location is needs to be in before running "readCFSector"
prepareSectorData:

	;only bits 3-0 of the head register are for lba (lba bits 27-24).
	;the rest is other stuff
	ld hl, $96CA
	ld a, (hl)
	or %11100000
	ld hl, $96EF
	ld (hl), a

	ld hl, $96C9
	ld de, $96EE
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress
	dec hl
	dec de
	call addressToOtherAddress	

ret

;this prints all file entires in whatever sector is loaded into ram starting at $2110
printAllFilesInSector:

	;first, set the address pointer to the start of the sector in ram
	ld hl, $96B0
	ld a, $10
	ld (hl), a
	inc hl
	ld a, $21
	ld (hl), a

	keepCheckingStuff:
		call printFile
	
		;increment address pointer by 32 (the length of a file entry)

		;load the value into bc
		ld hl, $96B0
		ld c, (hl)
		inc hl
		ld b, (hl)
	
		;add 32 to it
		ld l, c
		ld h, b
		ld bc, $0020
		add hl, bc
		ld c, l
		ld b, h

		;store the incremented value back into the pointers address
		ld hl, $96B0
		ld (hl), c
		inc hl
		ld (hl), b

		ld hl, $96DD
		ld e, (hl)
		;ld e, 0
		inc hl
		ld d, (hl)
		;ld d, $02
		ld hl, $2110
		add hl, de
		ex de, hl

		ld a, c
		cp e
		jr nz, keepCheckingStuff
		ld a, b
		cp d

		jr nz, keepCheckingStuff


ret

;this function attempts to read whatever files is stored at the address pointed to by $96B0-$96B1 and prints it to the screen
;the string that should get printed will be stored in $96B2-$96BE with a null terminating character in $96BF. This way, it will work natively with my vprintstring function
printFile:

	ld hl, $96B0
	ld e, (hl)
	inc hl
	ld d, (hl)
	dec hl
	ex de, hl

	;if the first byte is a zero, that means there is no file there
	ld a, (hl)
	cp 0
	jp z, printDirectoryEnd

	;if byte 0b of the entry is 0f, that means it's a vfat entry which I'm going to ignore for now
	ld bc, $000B
	add hl, bc
	ld a, (hl)
	cp $0F
	jp z, printDirectoryEnd

	;if it got this far, that means there is a valid file entry at the specified location

	;set the offset back to zero
	;ld l, e
	;ld h, d
	ld hl, $96B0
	;address of pointer is now loaded into hl
	;now, get address that the pointer is pointing to to be in de
	ld e, (hl)
	inc hl
	ld d, (hl)
	;now put that address into hl
	ex de, hl

	;address of place to save string to goes in IX
	;ld IX, $96B2
	ld de, $96B2
	ld b,0
	;I will want to run this loop 11 times using b as the counter

	fileNameLoop:
		ld a, b
		cp 11
		jr z, fileNameLoopEnd
		;if at position 8, add a period
		ld a, b
		cp 8
		jr nz, fileNameLoopContinue
			ex de, hl
			ld a, "."
			ld (hl), a
			inc hl
			ex de, hl

		fileNameLoopContinue:

		ld a, (hl)
		inc hl
		inc b
		cp $20
		jr z, fileNameLoop
		ex de, hl
		ld (hl), a
		inc hl
		ex de, hl
		ld a, b
		cp 11
		jr nz, fileNameLoop
		fileNameLoopEnd:

	;put a null character at the last location in the string address so it will print properly
	ld a, 0
	ex de, hl
	ld (hl), a
	;now print the string that starts at location $96B2
	ld hl, $96B2
	call VPrintString

	;show the file type
	call VdpInsertTab
	ld hl, $96B0
	ld e, (hl)
	inc hl
	ld d, (hl)
	dec hl
	ex de, hl

	;add 0B (the file attributes byte offset) to find out if it's a file or a folder
	ld bc, $000B
	add hl, bc
	ld a, (hl)
	and %00010000 		;if bit 4 = 1, then it's a folder

	cp %00010000
	jr nz, printFileIsFile

	;if not a file, print that it's a directory
	call VdpInsertTab
	ld hl, isDirectory
	call VPrintString
	;directories don't seem to contain valid date modified data so io'm going to skip doing that for directories
	;jr printFileNextThingAfterFileType
	call VdpInsertEnter
	jp printDirectoryEnd

	printFileIsFile:
		;if it's a file and not a directory, say that it's a file
		ld hl, $96B0
		ld e, (hl)
		inc hl
		ld d, (hl)
		dec hl
		ex de, hl

		;a loop to copy the 3 characters of the file extension into a null terminated character array for printing later
		ld bc, $0008
		add hl, bc
		ld IX, $96B2
		ld d, 0
		printFileIsFileLoop:
			ld a, (hl)
			ld (IX+0), a
			inc d
			inc hl
			inc IX
			ld a, d
			cp 3
			jr nz, printFileIsFileLoop

		;after exiting the loop that prints the 3 file extension letters, put a null character at the end of the variable
		ld a, 0
		ld (IX+0), a

		ld hl, $96B2
		call VPrintString

		ld hl, isFile
		call VPrintString

	printFileNextThingAfterFileType:
		call VdpInsertTab
		ld hl, lastModified
		call VPrintString
		; $16-$17: file creation time. bits 15-11 = hours(0-23). bits 10-5 = minutes (0-59). bits 4-0 = seconds/2 (0-29)
		; $18-$19: file creation date. bits 15-9 = years since 1980 (0-127). bits 8-5 = month (0-12). bits 0-4 - day (1-31)
		
		;load file address pointer into hl
		call fileAddressPointerToHl

		ld bc, $0017
		add hl, bc

		ld a, (hl)
		and %11111000
		srl a
		srl a
		srl a
		;a now contains the hex value of hours since file was modified
		ld c, a
		push hl
		call print2DigitDecimal
		ld a, ":"
		call VdpPrintChar
		pop hl

		ld b, (hl)
		ld a, b
		and %00000111
		ld b, a
		;rotate left 3 times
		sla b
		sla b
		sla b
		dec hl
		ld a, (hl)
		and %11100000
		;rotate right 5 times
		srl a
		srl a
		srl a
		srl a
		srl a
		;combine a and b into a normal number that can be worked with by adding them after they've ben rotated to the correct positions
		add a, b
		ld c, a
		push hl
		call print2DigitDecimal
		ld a, ":"
		call VdpPrintChar
		pop hl
		ld a, (hl)
		and %000011111
		add a
		ld c, a
		push hl
		call print2DigitDecimal

		;time modified has been printed. Now it's time to print date modified
		ld a, " "
		call VdpPrintChar
		pop hl

		call fileAddressPointerToHl
		ld bc, $0019
		add hl, bc

		ld a, (hl)
		and %00000001
		ld b, a
		sla b
		sla b
		sla b
		;sla b
		dec hl
		ld a, (hl)
		and %11100000
		srl a
		srl a
		srl a
		srl a
		srl a
		add a, b
		ld c, a

		push hl
		;print the month
		call print2DigitDecimal
		ld a, "/"
		call VdpPrintChar
		pop hl
		ld a, (hl)
		and %00011111
		ld c, a
		push hl
		;print the day
		call print2DigitDecimal
		ld a, "/"
		call VdpPrintChar
		pop hl

		inc hl
		ld a, (hl)
		and %11111110
		srl a
		ld hl, 1980
		ld b, 0
		ld c, a
		add hl, bc
		ex de, hl

		call print16BitDecimal

		call VdpInsertEnter

	printDirectoryEnd:


ret

;im tired of copy-pasting this over and over plus doing so wastes a lot of memory due to how often it gets used. that's why im making this into a subroutine
;modifies de and hl
;after running this, hl will contain the address in ram of the file pointed to by the "print files in sector" subroutine
fileAddressPointerToHl:

	ld hl, $96B0
	ld e, (hl)
	inc hl
	ld d, (hl)
	dec hl
	ex de, hl

ret

step1: db "assigned sector number",0
step2: db "assigned high and low cyls",0
step3: db "assigned drive head register values",0
step4: db "sector count register",0
step5: db "issued read command",0
CFerror: db "drive read error",0
CFcode50: db "cf is on code $50",0
CFbytescopied: db " bytes copied",0
CFnumretries: db "num retries = ",0
CFyeilderror: db "Could not perform a valid read",0
FAT32: db "FAT 32",0
FAT16: db "FAT 16",0
NTFS: db "NTFS",0
EXTFS: db "EXT",0
unknownfs: db "unknown",0
testStringCF1: db "adding base sector to reserved",0
testStringCF2: db "mult fat size and num of fats",0
testStringCF3: db "adding num fat sectors and that first thing we added",0
isDirectory: db "<DIR>",0
isFile: db " file",0
lastModified: db "last modified ",0