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

;$96BF-$96BC - a temporary storage location for storing a single 32 bit number (little endian). normally used for saving when you've just calculated it with the 32 bit math suite and need it for another 32 bit calculation but have to do another 32 bit calculation first
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
;all values including the variables below are stored in little endian
;it needs to make cluster numbers rather than lba addresses to make it easier to obtain the block size
;
;$2000-$2003: input parameter (cluster #) of gotoClusterSector subroutine
;$2004: cluster offset of last gotoClusterSector calculation
;	$2006: sector countdown for print files subroutine
;
;$9684-$968F: file or folder name to search for in file/folder search function
;$9690-$969B: file or folder name in the current file search comparison query
;$969C: file attribute byte of current file or folder
;$969D: search result - if anything other than 0, there was an error of some kind including file not found
;$2000-$2003: cluster# to get the sizeof in the get cluster size function
;
;$9683: size in clusters high byte
;$9682: size in clusters low byte       ;the size of whatever the last calculation of getClusterSize determined
;$9681: filesystem depth high byte
;$9680: how many chains deep in the filesystem (0 if at root directory)
;
;$967F: LBA27-24 of root directory
;$967E: LBA23-16 of root directory
;$967D: LBA15-08 of root directory
;$967C: LBA07-00 of root directory
;
;$967B: 32bit cluster number of root directory and therefore the upper-most file level
;$967A: 32bit cluster number of root directory and therefore the upper-most file level
;$9679: 32bit cluster number of root directory and therefore the upper-most file level
;$9678: 32bit cluster number of root directory and therefore the upper-most file level
;
;$9677: 32bit cluster number of next directory down
;$9676: 32bit cluster number of next directory down
;$9675: 32bit cluster number of next directory down
;$9674: 32bit cluster number of root directory down
;
; and so on and so fourth for:
;($967B-(current depth*4)): 32bit cluster number of current working directory
;($967A-(current depth*4)): 32bit cluster number of current working directory
;($9679-(current depth*4)): 32bit cluster number of current working directory
;($9678-(current depth*4)): 32bit cluster number of current working directory
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

;modifies hl and bc
;increases whatever number is in $9682-$9683 by 1
incrementClusterVariableByOne:

	;$9683: size in clusters high byte
	;$9682: size in clusters low byte       ;the size of whatever the last calculation of getClusterSize determined
	;reset the cluster size to zero because this function increments it to keep track of size
	ld hl, $9682
	ld c, (hl)
	inc hl
	ld b, (hl)
	inc bc
	ld (hl), b
	dec hl
	ld (hl), c

ret

;goes to whatever cluster is in $2000-$2003 little endian, copies it to ram at $2110 and then stores the (offset / 4) of where in the 512 byte $2110 block the cluster starts into address $96BF 
gotoClusterSector:

	;load lda address of partition start sector into math parameter 1
	call partitionStartToMathParam1

	;load the number of reserved sectors into  math parameter 2
	ld hl, $96DA
	ld de, $96A4
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress

	;number of reserve sectors is a 16 bit value so load zeros into the 2 upper bits of math parameter 2
	;inc hl
	ex de, hl
	ld a, 0
	ld (hl), a
	inc hl
	ld (hl), a

	;now add partition start + number of reserved sectors
	call add32BitNumber
	;call print32bitresultanswer
	;call VdpInsertEnter
	;the lba address of the first fat is now in the math result variable space

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

	;now that we know the address of the first sector and it's saved in ram for later use, calculate which fat sector the requested cluster number is going to be in
	
	;divide sector size by 4. This basically means this will only work on 1023 byte or less sectors due to the limitation where the divisor can't be greater than 255 
	;this is almost pointless except that some cf cards use 576 byte sectors for in like 0.1% of cases, it will come in handy
	ld hl, $96DD
	ld de, $96A0
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress
	inc hl
	ld a, 0
	ld (hl), a
	inc hl
	ld (hl), a

	;divide by 4 - put an 4 into $96A4
	;inc hl
	ld hl, $96A4
	ld a, $04
	ld (hl), a

	;divide the number of bytes per sector by 8. 
	call stupidDivisionPre
	call DEHL_Div_C
	call stupidDivisionPost
	;call VdpInsertEnter
	;call VdpInsertEnter
	;call print1st32bitNum
	;call VdpInsertEnter
	;call print2nd32bitNum
	;call VdpInsertEnter
	;call print32bitresultanswer
	;call VdpInsertEnter
	;call VdpInsertEnter

	;move the result of the last division calculation into math parameter 2
	ld hl, $96A8
	ld de, $96A4
	;the division function only can output an 8 digit number below but ill copy the whole number in case I fix that later
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

	;cluster number to math parameter 1
	ld hl, $2000
	ld de, $96A0
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

	call stupidDivisionPre
	call DEHL_Div_C
	call stupidDivisionPost
	;call print32bitresultanswer
	;call VdpInsertEnter

	;result ($96A8-$96AB) = the sector number that has the cluster we want
	;remainder ($96AC) = the offset in the sector where the cluster entry itself is at

	;put the result in math parameter 1 in preparation to add it to the lba address
	call putResultInParameter1

	;copy the lba address of the fat that we saved earlier into math parameter 2
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

	;copy the remainder into $2004 to save it for later. If i leave it at $96AC it might get overwritten if the 32 bit add gets the carry flag and has to put a 1 at that location
	ld hl, $96AC
	ld de, $2004
	call addressToOtherAddress

	;rememeber to add parameter 1 (sector offset) and parameter 2 (lba of fat #1 start) together
	call add32BitNumber
	;call print32bitresultanswer
	;call VdpInsertEnter

	;now all that is left to do is to copy and convert the lba address we've just finished calculating into $96EC-$96EF, read the 4 bytes at the offset stored in $96BF and determine if the cluster is a single cluster, a multi cluster or a fragmented multi cluster

	;really should make this into a subroutine but anyway this copies the thing in the math result address, converts the high byte to set the required upper bits and then copies it to the cf read address
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

	;read the cf sector at hte (hopefully) correct lba address that just got finished being calculated
	call readCFSector


ret

;gets the cluster size of whatever cluster number is stored in $2000-$2003 little endian
;a valid fat 32 has to be mounted and all the relevant variables have to be updated correctly in order for this to work
getClusterSize:
	;$9683: size in clusters high byte
	;$9682: size in clusters low byte       ;the size of whatever the last calculation of getClusterSize determined
	;reset the cluster size to zero because this function increments it to keep track of size
	ld hl, $9682
	ld a, 0
	ld (hl), a
	inc hl
	ld (hl), a

	;go to the sector that the desired cluster number is in, load it into ram starting at $2110 and find the offset (in 4 byte blocks) of the location of the desired cluster in the loaded fat table sector
	call gotoClusterSector

	;there are 4 cases:
	;	1. the cluster in question is a single 4 byte entry
	;	2. the cluster is a valid non-fragmented multi cluster long entry
	;	3. the cluster is a valid fragmented multi cluster long entry
	;	4. non of the above, in which case return an error

	;cluster low byte location = (4*cluster number)
	;for example cluster 02's low byte would be at $2117 (assuming the sector got loaded into ram starting $2110)
	;also, this is cluster offset (which will be at $2004 at this point), not absolute cluster number

	;first, let's check if it's case 1
		;if the block is either "0FFFFFFF" or "0FFFFFF8", then it's a single cluster
	ld hl, $2004
	ld e, (hl)
	ld d, 0
	ld a, 4
	;4 * cluster number
	call DE_Times_A
	;hl now contains (4*cluster number) which is the offset number of the low byte entry of the desired cluster block
	;add $2110 to hl to obtain the absolute memory address in ram of the lowest byte entry of the desired cluster block
	ld bc, $2110
	add hl, bc
	;load it into the a register to start the comparisons
	ld a, (hl)
	cp $F8
	jr z, getClusterSizeIsCase1
	cp $FF
	jr z, getClusterSizeIsCase1
	jr getClusterSizeNotCase1

	getClusterSizeIsCase1:
		inc hl
		ld a, (hl)
		cp $FF
		jr nz, getClusterSizeNotCase1
		inc hl
		ld a, (hl)
		cp $FF
		jr nz, getClusterSizeNotCase1
		inc hl
		ld a, (hl)
		cp $0F
		jr nz, getClusterSizeNotCase1

		call incrementClusterVariableByOne

		call VdpInsertEnter
		ld hl, clustersinglefat
		call VPrintString
		call VdpInsertEnter

		;$96DE: high amount of detected bytes per sector
		;$96DD: low amount of detected bytes per sector (it's a 16 bit value)
		;$96DC: number of logical sectors per cluster
		;print the number of bytes in size that the cluster is - we need to use 16 bit multiplication for this
		ld hl, $96DE
		ld d, (hl)
		ld hl, $96DD
		ld e, (hl)
		ld hl, $96DC
		ld a, (hl)
		call DE_Times_A
		ex de, hl
		call print16BitDecimal
		ld a, " "
		call VdpPrintChar
		ld hl, genericBytes
		call VPrintString
		call VdpInsertEnter

		jp getClusterSizeExitCaseComparisons

	getClusterSizeNotCase1:
		push hl
			call incrementClusterVariableByOne
			call VdpInsertEnter
			ld hl, clusterNOsinglefat
			call VPrintString
		pop hl
		;The algorithm is the same for fragmented files as it is for non-fragmented files. Doing it this way is slower and requires more drive reads (impacting reliability) but it's so much easier to debug and troubleshoot
		;I have to do this in a non-recursive way or else it will cause a stack overflow on large files
		;decrement hl back to the way it was before doing all those comparisons in case 1
		;dec hl
		;dec hl
		;dec hl
		;dec hl
		;first, make sure that the entry isn't "F7" indicating an invalid block
		ld a, (hl)
		cp $F7
		jp z, getClusterSizeInvalidBlock

		jr getClusterSizeNotCase1LoopFirstIteration
		;if it isn't an invalid block or bad sector, load the value of the cluster block into $2000-$2003
		getClusterSizeNotCase1Loop:
			;uncomment out all this stuff if you start having problems for some debugging messages (current hl address with press any key to continue prompt)
			;push hl
				;ld a, h
				;call aToScreenHex
			;pop hl
			;push hl
				;ld a, l
				;call aToScreenHex
				;call VdpInsertEnter
				;call waitChar
			;pop hl
		getClusterSizeNotCase1LoopFirstIteration:
			;if current block is not an end block, loop and do it again, remembering to update the cluster variable each time it happens
			;ld a, (hl)
			;and %11111000 		;because technically according to spec, anything from F8-FF is valid here. Should probably put this test case comparison in my single cluster block compare also.
			;cp $F8
			;jr nz, getCLusterLoop2Continue
			
			inc hl
			ld a, (hl)
			cp $FF
			dec hl
			jr nz, getCLusterLoop2Continue

			inc hl
			inc hl
			ld a, (hl)
			cp $FF
			dec hl
			dec hl
			jr nz, getCLusterLoop2Continue

			inc hl
			inc hl
			inc hl
			ld a, (hl)
			cp $0F
			dec hl
			dec hl
			dec hl
			jr nz, getCLusterLoop2Continue
			jr getClusterLoop2GTFO

			getCLusterLoop2Continue:
			ld de, $2000
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

			call gotoClusterSector

			;load absolute address of new block into hl
			ld hl, $2004
			ld e, (hl)
			ld d, 0
			ld a, 4
			;4 * cluster number
			call DE_Times_A
			;hl now contains (4*cluster number) which is the offset number of the low byte entry of the desired cluster block
			;add $2110 to hl to obtain the absolute memory address in ram of the lowest byte entry of the desired cluster block
			ld bc, $2110
			add hl, bc

			;increment counter by 1
			push hl
			push bc
				call incrementClusterVariableByOne
			pop bc
			pop hl
			jr getClusterSizeNotCase1Loop


			;if it got to this point, that means it's at the last block
			;print the number of used bytes and exit the loop
		getClusterLoop2GTFO:
		;$96DE: high amount of detected bytes per sector
		;$96DD: low amount of detected bytes per sector (it's a 16 bit value)
		;$96DC: number of logical sectors per cluster
		;print the number of bytes in size that the cluster is - we need to use 16 bit multiplication for this
		ld hl, $96DE
		ld d, (hl)
		ld hl, $96DD
		ld e, (hl)
		ld hl, $96DC
		ld a, (hl)
		call DE_Times_A
		ex de, hl
		
		;load number of bytes per cluster into math parameter 1
		ld hl, $96A0
		ld (hl), e
		inc hl
		ld (hl), d
		inc hl
		ld a, 0
		ld (hl), a
		inc hl
		ld (hl), a
		;load number of clusters into math parameter 2
		ld hl, $9682
		ld de, $96A4
		call addressToOtherAddress
		inc hl
		inc de
		call addressToOtherAddress
		inc hl
		inc de
		call addressToOtherAddress
		inc hl
		ld a, 0
		ld (hl), a
		inc hl
		ld (hl), a

		call ramTomul32Do
		call mul32
		call VdpInsertEnter
		;call print32bitresultanswer
		ld hl, $96A8
		ld e, (hl)
		inc hl
		ld d, (hl)
		call print16BitDecimal
		ld hl, genericBytes
		call VPrintString

		jr getClusterSizeExitCaseComparisons

	getClusterSizeInvalidBlock:
		call VdpInsertEnter
		ld hl, clusterIsInvalidError
		call VPrintString

	getClusterSizeExitCaseComparisons:

ret

;searches for a file or folder to determine if it exists in the current working directory
searchFileInWorkingDirectory:



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
	;ld hl, step1
	;call printStatusTest

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
	;ld hl, step2
	;call printStatusTest

	;set up drive head register values
	call WaitCFReady
	call WaitCFReadyForCommand
	ld c, $36
	ld hl, $96EF
	ld a, (hl)
	out (c), a
	;ld hl, step3
	;call printStatusTest

	;set sector count register to 1 (because I only want to copy the first sector right now)
	call WaitCFReady
	call WaitCFReadyForCommand
	ld c, $32
	ld hl, $96EB
	ld a, (hl)
	out (c), a
	;ld hl, step4
	;call printStatusTest

	call WaitCFReady
	call WaitCFReadyForCommand

	;set 20h in command register to indicate I want to read
	ld c, $37
	ld a, $20
	out (c), a
	;ld hl, step5
	;call printStatusTest

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
		call smallDelay
		call readDataRegisterUntilFinished

		;check if the number of re-read attempts is a really high number or not
		ld hl, $96E6
		ld a, (hl)
		inc a
		ld (hl), a
		cp $0F 					;maximum amount of retry attempts
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

	;ld hl, CFnumretries
	;call VPrintString
	;ld hl, $96E6
	;ld a, (hl)
	;call aToScreenHex
	;call VdpInsertEnter
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
		;push de
		;call smallDelay
		;pop de
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
		
		;push de
		;give the capacitors a few hundred extra nanoseoncds to charge up for the next read
		;doesn't make too much of a difference but the results are ~slightly~ better when I do this
		;call smallDelay
		;pop de

		call WaitCFTransferReady

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
			;this is also required for the counter in the loop that calls this function to determine if the cf card performed a valid read or not
			;the visual print subroutines can be commented out but not the stuff before it
			ld hl, $96E7
			ld a, e
			ld (hl), a
			inc hl
			ld a, d
			ld (hl), a
			;call smallDelay
			;call print16BitDecimal


			;ld hl, CFbytescopied
			;call VPrintString
			;call VdpInsertEnter

ret

;todo- make this into a multipurpose "hex to screen decimal" type function later
;printBytesTransferred:
;whatever's in the de register gets printed to screen as a 5 digit decimal number
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
	ld hl, $96C6
	ld (hl), a

	call CDivD
	add 48
	ld hl, $96C5
	ld (hl), a

	call CDivD
	add 48
	ld hl, $96C4
	ld (hl), a

	ld hl, $96C7
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
	ld e, $FF
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

	;this just does what the commented out code belkow does. I made it into a subroutine to save memory since other functions need to use that same block of code
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
;$967B: 32bit cluster number of root directory and therefore the upper-most file level
;$967A: 32bit cluster number of root directory and therefore the upper-most file level
;$9679: 32bit cluster number of root directory and therefore the upper-most file level
;$9678: 32bit cluster number of root directory and therefore the upper-most file level
;yeah yeah its stored in 2 places im too lazy to reorganize this so imma leave it how it is
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

	ld hl, $213C
	ld de, $9678
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

	;$96cd-$96d0 - cluster of root directory - need to add (this number - 2)*sectors per cluster to the calculated lba
	
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

	;$9681: filesystem depth high byte
	;$9680: how many chains deep in the filesystem (0 if at root directory)
	;update the filesystem depth counter to reflect the fact that it's at the root directory
	ld hl, $9681
	ld a, 0
	ld (hl), a
	dec hl
	ld (hl), a

	;$967F: LBA27-24 of root directory
	;$967E: LBA23-16 of root directory
	;$967D: LBA15-08 of root directory
	;$967C: LBA07-00 of root directory
	;update the lba address linked list - put the lba address of the root directory in position #0
	ld hl, $96AB
	ld de, $967F
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
;	$2006: sector countdown for file explorer
	;first, save the number of clusters into 96
	ld hl, $96DC
	ld a, (hl)
	ld hl, $2006
	ld (hl), a

	printAllFilesInSectorLoop1:

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

	;now that it's at the end of the sector, check if it's at end then advance to next
	atEndOfSector:
		;I just realized I don't have to worry about what to do if the directory has more than 1 cluster of entries since my system only has 26 lines of text. 1 cluster can store 64 files. stonks
		;I guess I should probably still do it with a "press any key to continue" prompt at the end though
		ld hl, $2006
		ld a, (hl)
		dec a
		ld (hl), a
		cp 0
		jr z, printAllFilesInSectorGTFO

		;add 1 to the lba address
		ld hl, $96EC
		ld de, $96A0
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

		;add 1 to the current lba address
		ld hl, $96A4
		ld a, 1
		ld (hl), a
		ld a, 0
		inc hl
		ld (hl), a
		inc hl
		ld (hl), a
		inc hl
		ld (hl), a

		call add32BitNumber

		;move the result from math output address to readCFSector next address
		ld hl, $96A8
		ld de, $96EC
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

		call readCFSector

		;reset address pointer so it doesnt try to print random bytes from ram as files
		ld hl, $96B0
		ld a, $10
		ld (hl), a
		inc hl
		ld a, $21
		ld (hl), a

		jp printAllFilesInSectorLoop1

		;should probably program it to be able to print the entire directory if it spams multiple fat blocks but i'll do that later
		;code for that will go under this comment

	printAllFilesInSectorGTFO:


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

;searches for a provided file in a directory. If the file is found, its starting cluster number gets copied into $2000-$2003
searchFileInDirectory:

	;	$2006: sector countdown for file explorer
	;first, save the number of clusters into 96
	ld hl, $96DC
	ld a, (hl)
	ld hl, $2006
	ld (hl), a

	searchAllFilesInSectorLoop1:

	;first, set the address pointer to the start of the sector in ram
	ld hl, $96B0
	ld a, $10
	ld (hl), a
	inc hl
	ld a, $21
	ld (hl), a

	searchFileskeepCheckingStuff:

		;replace file parameter 2 comparison after each iteration
		ld hl, $9690
		ld c, 11
		ld e, $20
		call fillRangeInRam

		call checkFile

		ld hl, $9684
		ld de, $9690
		ld b, 7
		call areStringsEqual
		ld a, 1
		cp c
		jp z, searchAllFilesInSectorGTFOFoundMatch
	
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
		jr nz, searchFileskeepCheckingStuff
		ld a, b
		cp d

		jr nz, searchFileskeepCheckingStuff

	;now that it's at the end of the sector, check if it's at end then advance to next
	searchAtEndOfSector:
		;I just realized I don't have to worry about what to do if the directory has more than 1 cluster of entries since my system only has 26 lines of text. 1 cluster can store 64 files. stonks
		;I guess I should probably still do it with a "press any key to continue" prompt at the end though
		ld hl, $2006
		ld a, (hl)
		dec a
		ld (hl), a
		cp 0
		jr z, searchAllFilesInSectorGTFO

		;add 1 to the lba address
		ld hl, $96EC
		ld de, $96A0
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

		;add 1 to the current lba address
		ld hl, $96A4
		ld a, 1
		ld (hl), a
		ld a, 0
		inc hl
		ld (hl), a
		inc hl
		ld (hl), a
		inc hl
		ld (hl), a

		call add32BitNumber

		;move the result from math output address to readCFSector next address
		ld hl, $96A8
		ld de, $96EC
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

		call readCFSector

		;reset address pointer so it doesnt try to print random bytes from ram as files
		ld hl, $96B0
		ld a, $10
		ld (hl), a
		inc hl
		ld a, $21
		ld (hl), a

		jp searchAllFilesInSectorLoop1

		;should probably program it to be able to print the entire directory if it spams multiple fat blocks but i'll do that later
		;code for that will go under this comment
	searchAllFilesInSectorGTFOFoundMatch:
		jr searchAllFilesInSectorGTFOExit

	searchAllFilesInSectorGTFO:
		;be sure to copy zeros to $2000-$2003 to indicate that no file was found
		ld hl, $2000
		ld a, 0
		ld (hl), a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),a

	searchAllFilesInSectorGTFOExit:


ret

;sees if the file starting at location pointed to by $96B0-96B1 has the same name as the string at $9684-$968F
;$9684-$968F: file or folder name to search for in file/folder search function
;$9690-$969B: file or folder name in the current file search comparison query
;if the file is found, the cluster number of the file gets copied into $2000-$2003
;if the file is not found, $00000000 gets copied to $2000-$2003
;$969C: the location that the file attribute byte gets copied to if the file was found
checkFile:

	ld hl, $96B0
	ld e, (hl)
	inc hl
	ld d, (hl)
	dec hl
	ex de, hl

	;if the first byte is a zero, that means there is no file there
	ld a, (hl)
	cp 0
	jp z, checkDirectoryEnd

	;if byte 0b of the entry is 0f, that means it's a vfat entry which I'm going to ignore for now
	ld bc, $000B
	add hl, bc
	ld a, (hl)
	cp $0F
	jp z, checkDirectoryEnd

	;if it got this far, that means there is a valid file entry at the specified location

	;set the offset back to zero
	ld hl, $96B0
	;address of pointer is now loaded into hl
	;now, get address that the pointer is pointing to to be in de
	ld e, (hl)
	inc hl
	ld d, (hl)
	;now put that address into hl
	ex de, hl

	;address of place to save string to goes in IX
	ld de, $96B2
	ld b,0
	;I will want to run this loop 11 times using b as the counter

	checkNameLoop:
		ld a, b
		cp 11
		jr z, checkNameLoopEnd
		checkNameLoopContinue:

		ld a, (hl)
		inc hl
		inc b
		;cp $20
		;jr z, checkNameLoop
		ex de, hl
		ld (hl), a
		inc hl
		ex de, hl
		ld a, b
		cp 8
		jr nz, checkNameLoop
		checkNameLoopEnd:

	;put a null character at the last location in the string address so it will print properly
	;ld a, 0
	;ex de, hl
	;ld (hl), a
	;now print the string that starts at location $96B2
	;ld hl, $96B2
	;call VPrintString

	;ex de, hl

	;add 0B (the file attributes byte offset) to find out if it's a file or a folder
	ld bc, $000B
	add hl, bc
	ld a, (hl)

	push hl
		ld hl, $969C 		;save the file type attribute to the attribute byte
		ld (hl), a
	pop hl

	call fileAddressPointerToHl

	ld bc, $0014
	add hl, bc
	ld de, $2002
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress

	call fileAddressPointerToHl
	ld bc, $001A
	add hl, bc
	ld de, $2000
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress

	;$2000-$2003 should now contain the requested file's 32 bit cluster number


	;copy the filename at $96B2 into $9690
	ld hl, $96B2
	ld de, $9690
	ld b, 12
		copyFilenameLoop:
			call addressToOtherAddress
			inc hl
			inc de
			dec b
			ld a, b
			cp 0
			jr nz, copyFilenameLoop
	;filename is now copied

	jp checkDirectoryEnd

	checkDirectoryEnd:

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

;enters whatever directory starts at the cluster number stored in $2000-$2003, increments the file depth at $9680-$9681 and updates the cluster number of the current directory variable
;$9681: filesystem depth high byte
;$9680: how many chains deep in the filesystem (0 if at root directory)
;$967F: LBA27-24 of root directory
;$967E: LBA23-16 of root directory
;$967D: LBA15-08 of root directory
;$967C: LBA07-00 of root directory
;
;$967B: 32bit cluster number of root directory and therefore the upper-most file level
;$967A: 32bit cluster number of root directory and therefore the upper-most file level
;$9679: 32bit cluster number of root directory and therefore the upper-most file level
;$9678: 32bit cluster number of root directory and therefore the upper-most file level
;
;$9677: 32bit cluster number of next directory down
;$9676: 32bit cluster number of next directory down
;$9675: 32bit cluster number of next directory down
;$9674: 32bit cluster number of root directory down
;
; and so on and so fourth for:
;($967B-(current depth*4)): 32bit cluster number of current working directory
;($967A-(current depth*4)): 32bit cluster number of current working directory
;($9679-(current depth*4)): 32bit cluster number of current working directory
;($9678-(current depth*4)): 32bit cluster number of current working directory
enterDirectoryAtLocation:
	
	;increment directory depth counter
	call incrementDirectoryDepth

	call clusterEntryToHl

	;hl now contains the address of the high-most entry of the cluster entry we want
	;copy the cluster number from $2000-$2003 into the correct cluster entry
	ex de, hl
	ld hl, $2003
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

	;now, execute the update directory function
	call updateDirectoryFromData

ret

;uses current directory depth and the correct cluster number entry to jump to the requested cluster then copy the first sector of the cluster into ram at $2110
updateDirectoryFromData:
	
	;step 1. take the cluster entry then multiply it by the amount of sectors per cluster ($96DC)
	;step 2. add that number to the start lba address of the first non-fat sector ($967C-$967F)
	;step 3. write the result of that calculation into $96EC-$96EF being sure the bytes at $96EF has the correct mode bits set
	;step 4. run the readCFSector subroutine
	
	;copy cluster number into math parameter 1
	call clusterEntryToHl
	ld de, $96A3
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

	ld hl, $96A4
	ld a, 2
	ld (hl), a
	ld a, 0
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a

	;subtract the cluster by 2 because in fat filesystems, the first 2 don't count sort of
	call subtract32BitNumber

	;put the result of that calculation into math parameter 1
	call putResultInParameter1

	;copy number of sectors per cluster into math parameter 2
	ld hl, $96DC
	ld de, $96A4
	call addressToOtherAddress
	ld hl, $96A5
	ld a, 0
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a

	;multiply the desired cluster number by the amount of sectors per cluster
	call ramTomul32Do
	call mul32

	;get ready to add (cluster number * sectors per cluster) and lba of file area start

	;copy result of last calculation into math parameter 1
	call putResultInParameter1

	;copy the lba address of file area start into math parameter 2
	ld hl, $967C
	ld de, $96A4
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

	;add the 2 values to achieve the lba address of the desired cluster to load
	call add32BitNumber

	;you have to subtract this by $10 (2 * sectors per cluster)
	;call putResultInParameter1

	;ld hl, $96A4
	;ld a, $10
	;ld (hl), a
	;ld a, 0
	;inc hl
	;ld (hl), a
	;inc hl
	;ld (hl), a
	;inc hl
	;ld (hl), a

	;subtract derived lba by $10
	;call subtract32BitNumber

	;put the calculated result into the cf next read address variable
	ld hl, $96A8
	ld de, $96EC
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress
	inc hl
	inc de
	call addressToOtherAddress
	inc hl
	ld a, (hl)
	or %11100000
	ld hl, $96EF
	ld (hl), a

	;address is set up. Now, read the sector and copy it into ram starting at $2110
	call readCFSector

ret


;uses the cluster number variable to calculate the position of the bottom-most and therefore current subdirectory
;puts that address into hl
;address that ends up in hl is the high byte of the address 
clusterEntryToHl:

	;calculate (current depth*4) using the 16 bit multiplication function
	ld hl, $9680
	ld a, (hl)
	ld hl, $96A0
	ld (hl), a

	ld hl, $9681
	ld a, (hl)
	ld hl, $96A1
	ld (hl), a

	ld hl, $96A2
	ld a, 4
	ld (hl), a
	inc hl
	ld a, 0
	ld (hl), a

	;execute the 16 bit multiplication
	call load16bitvaluesFromRam
	call mul16
	call loadmul16IntoRam

	;load the result of the calculation into bc
	ld hl, $96A8
	ld c, (hl)
	inc hl
	ld b, (hl)

	;load the address of the high-most entry of the first subdirectory cluster entry into hl
	ld hl, $967B

	;$967B- (current depth * 4)
	sbc hl, bc

ret

;increments whatever 16 bit value is at $9680
incrementDirectoryDepth:

	ld hl, $9680
	ld e, (hl)
	inc hl
	ld d, (hl)

	inc de
	ld hl, $9680
	ld (hl), e
	inc hl
	ld (hl), d

ret

;decrements whatever 16 bit value is at $9680
decrementDirectoryDepth:

	ld hl, $9680
	ld e, (hl)
	inc hl
	ld d, (hl)

	dec de
	ld hl, $9680
	ld (hl), e
	inc hl
	ld (hl), d

ret

;change directory to the parent directory of where ever you are
;will do nothing if already at root directory
goUp1Directory:

	;first make sure it's not already at the root directory
	ld hl, ($9680)
	ld a, h
	cp 0
	jr nz, goUp1DirectoryContinue
	ld a, l
	cp 0
	jr z, goUp1DirectoryGTFO
	goUp1DirectoryContinue:

		;set the counter to 1 less than whatever it's at right now
		call decrementDirectoryDepth

		;now do all the magical things that it needs to be able to load the parent directory of whatever the child was
		call updateDirectoryFromData

	goUp1DirectoryGTFO:

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
clustersinglefat: db "cluster is a single fat block",0
clusterNOsinglefat: db "cluster is not a single fat block",0
clusterIsInvalidError: db "Invalid block (starts with $F7)",0