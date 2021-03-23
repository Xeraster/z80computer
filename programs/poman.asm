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

;2FFC = player position x
;2FFB = player position y

;2FFA = bad guy 6 position x
;2FF9 = bad guy 6 position y
;2FF8 = time until player sprite gets changed
;2FF7 = player sprite number
;2FF6 = how many more frames of jumping the player has

;2FF5 = bad guy 1 position x
;2FF4 = bad guy 1 position y
;2FF3 = frames until bad guy moves

;2FF2 = potato position x
;2FF1 = potato position y
;2FF0 = turd position x
;2FEF = turd position y

;2FED = angel of death position x
;2FEC = angel of deat position y
;2FEB = frames until angel of death sprite changes
;2FEA = sprite number to use for angel
;2FE9 = number of lives the player has
;2FE8 = frames until the angel of death moves again

;2FEE = score

keyPressByteLocation: equ $2FE6

org $3000
	;clear controls buffer
	ld hl, keyPressByteLocation
	ld a, 0
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

	;make sprites double sized
	ld d, %01000001
	ld a, 1
	call VdpWriteToStandardRegister

	;set score to zero
	ld hl, $2FEE
	ld a, 0
	ld (hl), 0

	;set player lives to 3
	ld hl, $2FE9
	ld a, 5
	ld (hl), a

	;set up moving bad guy's position
	ld hl, $2FF5
	ld a, 105
	ld (hl), a
	ld hl, $2FF4
	ld a, 134
	ld (hl), a
	ld hl, $2FF3
	ld a, 1
	ld (hl), a

	ld a, 35
	ld hl, $2FFC
	ld (hl), a
	ld a, 134
	dec hl
	ld (hl), a
	ld hl, $2FF8
	ld a, 10
	ld (hl), a
	ld hl, $2FF7
	ld a, 2
	ld (hl), a

	;initialize angel of death position
	ld hl, $2FED 	;position x
	ld a, 0
	ld (hl), a
	ld hl, $2FEC 	;position y
	ld a, 230
	ld (hl), a
	ld hl, $2FEB 	;time til sprite change (the death angel has 2 sprites for animation)
	ld a, 30
	ld (hl), a
	ld hl, $2FE8 	;i want to make the angel move 1 pixel every 3 frames
	ld a, 2
	ld (hl), a

	;set up initial potato position
	ld hl, $2FF1 	;potato position y
	ld a, 64
	ld (hl), a
	inc hl 			;potato position x
	ld a, 50
	ld (hl), a
	ld d, 50
	ld e, 64
	ld a, 0
	ld l, 0
	call changeSpriteSettings

	;set up the turd position
	ld hl, $2FF0 	;turd position x
	ld a, 99
	ld (hl), a
	ld a, 64
	dec hl 			;turd position y
	ld (hl), a
	;draw a stationary turd
	ld a, 1
	ld d, 99
	ld e, 64
	ld l, 1
	call changeSpriteSettings


	;set number of remaining frames of jumping to zero
	ld hl, $2FF6
	ld a, 0
	ld (hl), a

	;set the position in ram of bad guy 6
	ld a, 99
	ld hl, $2FFA
	ld (hl), a
	dec hl
	ld a, 62
	ld (hl), a

	;draw the floor graphics
	ld b, 0
	ld c, 150
	ld d, 255
	ld e, 10
	ld a, 8
	call drawRectangleFilled

	ld b, 0
	ld c, 80
	ld d, 150
	ld e, 10
	ld a, 8
	call drawRectangleFilled

	ld b, 170
	ld c, 80
	ld d, 85
	ld e, 10
	ld a, 8
	call drawRectangleFilled

	;draw outer part of ladder
	ld b, 155
	ld c, 60
	ld d, 10
	ld e, 90
	ld a, 5
	call drawRectangle

	;draw the ladder steps
	ld b, 155
	ld c, 60
	ld d, 165
	ld e, 60
	ld a, 5
	ld l, 18
	drawLadderStepsLoop:
		push bc
		push de
		push hl
			ld a, 5
			call drawLine
		pop hl
		pop de
		pop bc
		ld a, e
		add 5
		ld e, a
		ld a, c
		add 5
		ld c, a
		dec l
		ld a, l
		cp 0
		jr nz, drawLadderStepsLoop

	call copySpritesToVram

	ld hl, $2007 ;text x position / 2
 	ld a, 0
	ld (hl), a
	ld hl, $2008 ;y position / 2
	ld a, 0
	ld (hl), a
	ld hl, score
	;$B090
	call G4PrintString

	;call softwareSpriteToVramCompressed

	;draw each sprite on the screen in a quick and dirty way just so I can look at them
	;copy the sprite info to the attribute table at $7000
	;ld a, 14
	;ld d, %00000001 	;bits a16, a15 and a14
	;call VdpWriteToStandardRegister
	;ld a, %00000000 	;bits a0-a7
	;out (c), a
	;ld a, %01110110 	;bits a8-a13. bit 6 is r/w. bit 7 should stay zero
	;out (c), a

	;get ready to start writing to port 0 - the vram access port
	;ld b, $A0
	;ld c, $20

	;sprite 0
	;ld a, 134
	;out (c), a
	;call smallDelay
	;ld a, 15
	;out (c), a
	;call smallDelay
	;ld a, 0
	;out (c), a
	;call smallDelay
	;ld a, 0
	;out (c), a
	;call smallDelay

	;sprite 1
	;ld a, 134
	;out (c), a
	;call smallDelay
	;ld a, 25
	;out (c), a
	;call smallDelay
	;ld a, 1
	;out (c), a
	;call smallDelay
	;ld a, 0
	;out (c), a
	;call smallDelay

	;sprite 2
	;ld a, 134
	;out (c), a
	;call smallDelay
	;ld a, 35
	;out (c), a
	;call smallDelay
	;ld a, 2
	;out (c), a
	;call smallDelay
	;ld a, 0
	;out (c), a
	;call smallDelay

	;sprite 3
	;ld a, 134
	;out (c), a
	;call smallDelay
	;ld a, 45
	;out (c), a
	;call smallDelay
	;ld a, 3
	;out (c), a
	;call smallDelay
	;ld a, 0
	;out (c), a
	;call smallDelay

	;sprite 4
	;ld a, 134
	;out (c), a
	;call smallDelay
	;ld a, 55
	;out (c), a
	;call smallDelay
	;ld a, 4
	;out (c), a
	;call smallDelay
	;ld a, 0
	;out (c), a
	;call smallDelay

	;sprite 5
	;ld a, 134
	;out (c), a
	;call smallDelay
	;ld a, 65
	;out (c), a
	;call smallDelay
	;ld a, 5
	;out (c), a
	;call smallDelay
	;ld a, 0
	;out (c), a
	;call smallDelay

	;bad guy 3
	;ld a, 60
	;out (c), a
	;call smallDelay
	;ld a, 65
	;out (c), a
	;call smallDelay
	;ld a, 6
	;out (c), a
	;call smallDelay
	;ld a, 0
	;out (c), a
	;call smallDelay

	;display initial amount of player lives
	call updatePlayerLives


	;draw the initial "000" score on the screen
	ld hl, $2007
	ld a, 24
	ld (hl), a
	ld a, "0"
	call G4PrintChar
	;call softwareSpriteToVram
	ld hl, $2007
	ld a, 28
	ld (hl), a
	ld a, "0"
	call G4PrintChar
	;ld hl, letters_00
	;call softwareSpriteToVram
	ld hl, $2007
	ld a, 32
	ld (hl), a
	ld a, "0"
	call G4PrintChar
	;ld hl, letters_00
	;call softwareSpriteToVram

	;move the currently unused sprites out of the way: sprites # 3 and 6
	ld e, 230
	ld d, 0
	ld a, 3
	ld l, 3
	call changeSpriteSettings

	ld e, 230
	ld d, 0
	ld a, 6
	ld l, 6
	call changeSpriteSettings

	ld e, 230
	ld d, 0
	ld a, 7
	ld l, 7
	call changeSpriteSettings

	ld a, 5
	ld d, 99
	ld e, 70
	ld l, 5
	call changeSpriteSettings

	gameLoop:
	;wait until next frame before running loop
	;this keeps stuff running at a more or less constant speed (or at least more constant than leaving it out)
	call waitVblank

	;check if player is dead
	ld hl, $2FE9
	ld a, (hl)
	;if 255, that means it got to zero and rolled over because the player died and lost all lives
	cp 255
	call z, showGameOverScreen

	;make the sprite 6 bad guy just keep moving to the right by 1 pixel each frame
	ld hl, $2FFA
	ld d, (hl)
	dec d
	ld (hl), d
	dec hl
	ld e, (hl)
	ld a, 5
	ld l, 5
	call changeSpriteSettings

	call makePlayerJump
	call updatePlayerPositionAndStuff
	;call makePlayerObeyGravity

	call makeBadGuysChasePlayer

	call checkCollisions

	;wait for the user to press a key before exiting
	;call checkChar
	call getKeys
	;cp $F0
	;jr z, gameLoop

;a=1c
;s=1b
;d = $23
;w=1D
;$972B = bit 7 = esc, bit 6 = enter, bit 5 = space, bit 4 = q, bit 3 = w, bit 2 = a, bit 1 = s, bit 0 = d
	ld hl, keyPressByteLocation
	ld a, (hl)
	and %00000100
	cp %00000100
	jr z, goRight
	jr goRightGTFO
	goRight:
		ld hl, $2FFC
		ld d, (hl) 		;xpos into d
		dec d
		ld (hl), d
		;ld hl, $2FFB
		;ld e, (hl) 		;ypos into e
		;ld a, 2
		;ld l, 2
		call timeTilPlayerSpriteChange
		;call changeSpriteSettings
		;jr gameLoop
	goRightGTFO:
	;d key
	ld hl, keyPressByteLocation
	ld a, (hl)
	and %00000001
	cp %00000001
	jr z, goLeft
	jr goLeftGTFO
	goLeft:
		ld hl, $2FFC
		ld d, (hl) 		;xpos into d
		inc d
		ld (hl), d
		;ld hl, $2FFB
		;ld e, (hl) 		;ypos into e
		;ld a, 2
		;ld l, 2
		call timeTilPlayerSpriteChange
		;call changeSpriteSettings
		;jr goUpGTFO ; give right direction precedence over left (so they wont fight each other if player presses both)
	goLeftGTFO:
		;w key
		ld hl, keyPressByteLocation
		ld a, (hl)
		and %00001000
		cp %00001000
		jr z, goUp
		jr goUpGTFO
	goUp:
		ld hl, $2FFC 	;get xpos
		ld a, (hl)
		cp 150
		jr c, gameLoop
		cp 160
		jr nc, gameLoop
		ld d, a 		;increase y pos by 1 if sort of close to the ladder
		ld hl, $2FFB  	;get ypos
		ld e, (hl)
		dec e
		ld (hl), e
		;ld a, 2
		call timeTilPlayerSpriteChange
		;call changeSpriteSettings
		;jr goDownGTFO 		;give up key
	goUpGTFO:
	;s key
		ld hl, keyPressByteLocation
		ld a, (hl)
		and %00000010
		cp %00000010
		jr z, goDown
		jr goDownGTFO
	goDown:
		ld hl, $2FFC 	;get xpos
		ld a, (hl)
		cp 150
		jp c, gameLoop
		cp 160
		jp nc, gameLoop
		ld (hl), a
		ld d, a 		;increase y pos by 1 if sort of close to the ladder
		ld hl, $2FFB  	;get ypos
		ld e, (hl)
		inc e
		ld (hl), e
		;ld a, 2
		call timeTilPlayerSpriteChange
		;call changeSpriteSettings
		;jp gameLoop
	goDownGTFO:
	;space
	ld hl, keyPressByteLocation
	ld a, (hl)
	and %00100000
	cp %00100000
	jr z, guyJump
	jr guyJumpGTFO
	guyJump:
		ld b, a
		;only jump if player is standing on the floor (64 or 134)- no jedi double jumping
		ld hl, $2FFB
		ld a, (hl)
		cp 64
		jr z, guyJumpContinue
		cp 134
		jr z, guyJumpContinue
		ld a, b
		jr guyJumpGTFO
		guyJumpContinue:
		ld hl, $2FF6
		ld a, 30
		ld (hl), a
		;jp gameLoop
	guyJumpGTFO:
	;pressing esc exits the game
	ld hl, keyPressByteLocation
	ld a, (hl)
	and %10000000
	cp %10000000
	;cp $76
	jp nz, gameLoop

	;put everything back to normal
	call ClearScreen
	call initializeVideo
	call ClearScreen

	;print exit message
	ld hl, exitmessage
	call VPrintString

ret


makePlayerJump:

	ld hl, $2FF6
	ld a, (hl)
	cp 0
	jr z, makePlayerJumpGTFO
	dec a
	ld (hl), a
	;now increase the player's height by 1
	;ld hl, $2FFC 	;get xpos
	;ld a, (hl)
	;ld d, a 		;increase y pos by 1 if sort of close to the ladder
	ld hl, $2FFB  	;get ypos
	ld e, (hl)
	dec e
	ld (hl), e
	;ld a, 2
	call timeTilPlayerSpriteChange
	;call changeSpriteSettings

	jr makePlayerJumpDontDecend
	makePlayerJumpGTFO:
		call makePlayerObeyGravity
	makePlayerJumpDontDecend:

ret
;this checks to see if the player is in the air or not. If the player is in the air, make them fall
makePlayerObeyGravity:
	;if the player is higher than the height of the ladder, fall no matter what
	ld hl, $2FFB
	ld a, (hl)
	cp 44
	jr c, makePlayerObeyGravityContinue2

	;if the player is not higher than the max height of the ladder, only fall if not on ladder
	ld hl, $2FFC
	ld a, (hl)
	cp 150
	jr nc, makePlayerObeyGravityContinue1
	jr makePlayerObeyGravityContinue2
	makePlayerObeyGravityContinue1:
	cp 160
	jr c, makePlayerObeyGravityGTFO
	;jr makePlayerObeyGravityGTFO
	makePlayerObeyGravityContinue2:
	;the 2 floors are at y coordinate 142 and 72
	ld hl, $2FFB
	ld a, (hl)
	cp 64
	jr c, makePlayerObeyGravityDecend
	jr z, makePlayerObeyGravityGTFO
	cp 134
	jr c, makePlayerObeyGravityDecend
	jr z, makePlayerObeyGravityGTFO

	makePlayerObeyGravityDecend:
		ld hl, $2FFB
		ld e, (hl)
		inc e
		ld (hl), e
		;ld hl, $2FFC
		;ld d, (hl)
		;ld a, 2
		call timeTilPlayerSpriteChange
		;call changeSpriteSettings

	makePlayerObeyGravityGTFO:


ret

updatePlayerPositionAndStuff:
	ld hl, $2FFB
	ld e, (hl)
	ld hl, $2FFC
	ld d, (hl)
	;call timeTilPlayerSpriteChange
	ld hl, $2FF7
	ld a, (hl)
	ld l, a
	ld a, 2
	call changeSpriteSettings

ret

showGameOverScreen:
	;discard any keys the user pressed
	call checkChar
	call ClearScreen
	call clearMostVram

	;discard any keys the user pressed
	call checkChar

	ld hl, $2007
	ld a, 49
	ld (hl), a
	inc hl
	ld a, 0
	ld (hl), a
	ld hl, youDied1
	call G4PrintString

	ld hl, $2007
	ld a, 0
	ld (hl), a
	ld hl, $2008
	ld a, 4
	ld (hl), a
	ld hl, youDied2
	call G4PrintString

	ld hl, $2007
	ld a, 0
	ld (hl), a
	ld hl, $2008
	ld a, 8
	ld (hl), a
	ld hl, youDied3
	call G4PrintString

	ld hl, $2007
	ld a, 0
	ld (hl), a
	ld hl, $2008
	ld a, 12
	ld (hl), a
	ld hl, youDied41
	call G4PrintString

	ld hl, $2007
	ld a, 0
	ld (hl), a
	ld hl, $2008
	ld a, 16
	ld (hl), a
	ld hl, youDied4
	call G4PrintString

	ld hl, $2007
	ld a, 0
	ld (hl), a
	ld hl, $2008
	ld a, 20
	ld (hl), a
	ld hl, youDied5
	call G4PrintString

	ld hl, $2007
	ld a, 0
	ld (hl), a
	ld hl, $2008
	ld a, 24
	ld (hl), a
	ld hl, youDied6
	call G4PrintString

	ld hl, $2007
	ld a, 49
	ld (hl), a
	ld hl, $2008
	ld a, 32
	ld (hl), a
	ld hl, youDied7
	call G4PrintString

	ld hl, $2007
	ld a, 49
	ld (hl), a
	ld hl, $2008
	ld a, 36
	ld (hl), a
	ld hl, youDied8
	call G4PrintString
	
	;if the user pressed a button before realized they were dead, use this to discard that keypress
	call checkChar

	showGameOverScreenLoop:
	;wait for the player to press any button
	call waitChar

	;do this so that returning will reset the entire game
	pop hl
	ld hl, $3000
	push hl

ret

updatePlayerLives:
	;clear the background area of where the sprites are
	;this is required because software sprites go on to the background layer (there is only the background layer and the hardware sprite layer as far as the vdp is concerned)
	;tl;dr you need to use the filled rectangle function to clear behind where ever the lives sprites are
	
	;draws a non-filled in rectangle.
	;b = x position of rectangle start
	;c = y position of recangle start
	;d = size x of rectangle
	;e = size y of rectangle
	;a = color index
	ld b, 80
	ld c, 0
	ld d, 100
	ld e, 10
	ld a, 0
	call drawRectangleFilled
	;load number of lives into a register
	ld hl, $2FE9
	ld d, (hl)
	ld a, d
	cp 0
	jr z, noLivesLeft
	cp 255
	jr z, noLivesLeft

	;set initial x position of the software sprite in ram
	ld hl, $2007 	;software sprite x position / 2
	ld a, 40
	ld (hl), a
	updatePlayerLivesIconLoop:
		push de
		ld hl, $2008 	;software sprite y position / 2
		ld a, 0
		ld (hl), a
		ld hl, playerLife_00
		call softwareSpriteToVram

		;update the sprite position in ram
		ld hl, $2007 	;software sprite x position / 2
		ld a, (hl)
		add 4
		ld (hl), a
		pop de
		dec d
		ld a, d
		cp 0
		jr nz, updatePlayerLivesIconLoop
	noLivesLeft:


ret

respawnPlayer:

	ld hl, $2FFC
	ld a, 170
	ld (hl), a

	ld hl, $2FFB
	ld a, 0
	ld (hl), a

ret
;makes bad guy go in whatever direction the player is at half the player's walking speed
;2FF5 = bad guy 1 position x
;2FF4 = bad guy 1 position y
;2FFC = player position x
;2FFB = player position y
makeBadGuysChasePlayer:

	ld hl, $2FF3
	ld a, (hl)
	cp 0
	jr nz, badGuy1ExitNotZero
	ld hl, $2FF5
	ld b, (hl)
	ld hl, $2FFC
	ld a, (hl)
	cp b
	jr c, badGuy1GoLeft
	jr badGuy1GoRight
	badGuy1GoLeft:
		ld hl, $2FF5
		ld d, (hl) 		;xpos into d
		dec d
		ld (hl), d
		ld hl, $2FF4
		ld e, (hl) 		;ypos into e
		ld a, 4
		ld l, 4
		call changeSpriteSettings
		jr badGuy1Exit

	badGuy1GoRight:
		ld hl, $2FF5
		ld d, (hl) 		;xpos into d
		inc d
		ld (hl), d
		ld hl, $2FF4
		ld e, (hl) 		;ypos into e
		ld a, 4
		ld l, 4
		call changeSpriteSettings
		jr badGuy1Exit

	badGuy1ExitNotZero:
		ld hl, $2FF3
		ld a, (hl)
		dec a
		ld (hl), a
		jr makeBadGuysChasePlayerContinue
	badGuy1Exit:
		ld hl, $2FF3
		ld a, 1
		ld (hl), a

	;2FED = angel of death position x
	;2FEC = angel of death position y
	;2FEB = frames until angel of death moves again

	makeBadGuysChasePlayerContinue:

	;check if its time for the angel of death to move again
	ld hl, $2FE8
	ld a, (hl)
	cp 0
	jr nz, angelOfDeathChaseGTFONotZero

	;if it got this far, that means its time for the angel to move again
	;reset the counter
	ld hl, $2FE8
	ld a, 2
	ld (hl), a


	ld hl, $2FEC
	ld a, (hl)
	cp 230
	jr nz, angelOfDeathMaybeX
	jr angelOfDeathChaseGTFO
	;fuck it only check the y coordinate
	angelOfDeathMaybeX:
		ld hl, $2FEC ; angel y
		ld b, (hl)
		ld hl, $2FFB ;player y
		ld a, (hl)
		cp b
		jr c, angelGoUp
		jr angelGoDown
		angelGoUp:
			ld hl, $2FEC
			ld e, (hl) 		;ypos into e
			dec e 			;decrease y to go up
			ld (hl), e
		jr angelHorizCompare
		angelGoDown:
			ld hl, $2FEC
			ld e, (hl) 		;ypos into e
			inc e 			;increase y to go down
			ld (hl), e
		angelHorizCompare:
			ld hl, $2FED ; angel x
			ld b, (hl)
			ld hl, $2FFC ;player x
			ld a, (hl)
			cp b
			jr c, angelGoLeft
			jr angelGoRight
		angelGoRight:
			ld hl, $2FED
			ld a, (hl)
			inc a
			ld (hl), a
			jr drawAngel
		angelGoLeft:
			ld hl, $2FED
			ld a, (hl)
			dec a
			ld (hl), a
		drawAngel:
			ld hl, $2FED
			ld d, (hl)
			ld hl, $2FEC
			ld e, (hl)
			ld a, 6
			;ld l, 6
			call timeTilAngelSpriteChange
			call changeSpriteSettings
			jr angelOfDeathChaseGTFO
	angelOfDeathChaseGTFONotZero:
		ld hl, $2FE8
		ld a, (hl)
		dec a
		ld (hl), a

	angelOfDeathChaseGTFO:

ret

checkCollisions:

	;2FFC = player position x
	;2FFB = player position y

	;2FFA = bad guy 6 position x
	;2FF9 = bad guy 6 position y

	;2FF5 = bad guy 1 position x
	;2FF4 = bad guy 1 position y
	;2FF3 = frames until bad guy moves

	;2FF2 = potato position x
	;2FF1 = potato position y
	;2FF0 = turd position x
	;2FEF = turd position y

	;2FEE = score

	ld hl, $2FFC
	ld b, (hl)
	ld hl, $2FFB
	ld c, (hl)

	ld hl, $2FF2
	ld d, (hl)
	ld hl, $2FF1
	ld e, (hl)

	ld a, b
	sub d
	cp 5
	jr c, potatoCollisionTryY

	ld a, d
	sub b
	cp 5
	jr c, potatoCollisionTryY
	jr potatoCollisionGTFO

	potatoCollisionTryY:
		ld a, c
		sub e
		cp 5
		jr c, potatoCollision

		ld a, e
		sub c
		cp 5
		jr c, potatoCollision

		jr potatoCollisionGTFO
	potatoCollision:
		;add 1 point and replace potato
		ld hl, $2FEE
		ld a, (hl)
		inc a
		ld (hl), a

		ld hl, $2FF1
		ld a, (hl)
		cp 64
		jr nz, potatoBelow
		ld a, 134
		ld (hl), a
		jr potatoGenX
		potatoBelow:
			ld a, 64
			ld (hl), a
		potatoGenX:
			;03/11/2021 - adding in a random number generator and changing some stuff
			call randomNumber
			cp 170
			jr c, addMoreCollosionRandomBleb
			cp 16
			jr nc, subMoreCollisionRandomBleb
			jr dontAddMoreCollisionRandomBleb
			addMoreCollosionRandomBleb:
			sub 20
			jr dontAddMoreCollisionRandomBleb
			subMoreCollisionRandomBleb:
			add 20
			dontAddMoreCollisionRandomBleb:
			ld hl, $2FF2
			;ld a, (hl)
			;add 47
			ld (hl), a

		;now redraw the potato
		ld hl, $2FF1
		ld e, (hl)
		ld hl, $2FF2
		ld d, (hl)
		ld a, 0
		ld l, 0
		call changeSpriteSettings
		call updateScore

	potatoCollisionGTFO:

	ld hl, $2FFC
	ld b, (hl)
	ld hl, $2FFB
	ld c, (hl)

	ld hl, $2FF0
	ld d, (hl)
	ld hl, $2FEF
	ld e, (hl)

	ld a, b
	sub d
	cp 5
	jr c, poopCollisionTryY

	ld a, d
	sub b
	cp 5
	jr c, poopCollisionTryY
	jr poopCollisionGTFO

	poopCollisionTryY:
		ld a, c
		sub e
		cp 5
		jr c, poopCollision

		ld a, e
		sub c
		cp 5
		jr c, poopCollision

		jr poopCollisionGTFO
	poopCollision:
		;take away 1 point and replace poop
		ld hl, $2FEE
		ld a, (hl)
		cp 0
		;dont subtract a point if the player only has 1 point
		jr z, dontDeductPoint
		deductPoint:
			ld hl, $2FEE
			ld a, (hl)
			dec a
			ld (hl), a
		dontDeductPoint:

		ld hl, $2FEF
		ld a, (hl)
		cp 64
		jr nz, poopBelow
		ld a, 134
		ld (hl), a
		jr poopGenX
		poopBelow:
			ld a, 64
			ld (hl), a
		poopGenX:
			ld hl, $2FF0
			ld a, (hl)
			sub 61
			ld (hl), a

		;now redraw the poop
		ld hl, $2FEF
		ld e, (hl)
		ld hl, $2FF0
		ld d, (hl)
		ld a, 1
		ld l, 1
		call changeSpriteSettings
		call updateScore

	poopCollisionGTFO:

	;2FFA = bad guy 6 position x
	;2FF9 = bad guy 6 position y

	ld hl, $2FFC
	ld b, (hl)
	ld hl, $2FFB
	ld c, (hl)

	ld hl, $2FFA
	ld d, (hl)
	ld hl, $2FF9
	ld e, (hl)

	ld a, b
	sub d
	cp 5
	jr c, bg6CollisionTryY

	ld a, d
	sub b
	cp 5
	jr c, bg6CollisionTryY
	jr bg6CollisionGTFO

	bg6CollisionTryY:
		ld a, c
		sub e
		cp 12
		jr c, bg6Collision

		ld a, e
		sub c
		cp 12
		jr c, bg6Collision

		jr bg6CollisionGTFO
	bg6Collision:
		;take away 1 life
		ld hl, $2FE9
		ld a, (hl)
		dec a
		ld (hl), a

		call updatePlayerLives
		call respawnPlayer

	bg6CollisionGTFO:

	;2FF5 = bad guy 1 position x
	;2FF4 = bad guy 1 position y

	ld hl, $2FFC
	ld b, (hl)
	ld hl, $2FFB
	ld c, (hl)

	ld hl, $2FF5
	ld d, (hl)
	ld hl, $2FF4
	ld e, (hl)

	ld a, b
	sub d
	cp 12
	jr c, bg1CollisionTryY

	ld a, d
	sub b
	cp 12
	jr c, bg1CollisionTryY
	jr bg1CollisionGTFO

	bg1CollisionTryY:
		ld a, c
		sub e
		cp 5
		jr c, bg1Collision

		ld a, e
		sub c
		cp 5
		jr c, bg1Collision

		jr bg1CollisionGTFO
	bg1Collision:
		;take away 1 life
		ld hl, $2FE9
		ld a, (hl)
		dec a
		ld (hl), a

		call updatePlayerLives
		call respawnPlayer

	bg1CollisionGTFO:

	;2FED = angel of death position x
	;2FEC = angel of deat position y

	ld hl, $2FFC
	ld b, (hl)
	ld hl, $2FFB
	ld c, (hl)

	ld hl, $2FED
	ld d, (hl)
	ld hl, $2FEC
	ld e, (hl)

	ld a, b
	sub d
	cp 5
	jr c, angelCollisionTryY

	ld a, d
	sub b
	cp 5
	jr c, angelCollisionTryY
	jr angelCollisionGTFO

	angelCollisionTryY:
		ld a, c
		sub e
		cp 12
		jr c, angelCollision

		ld a, e
		sub c
		cp 12
		jr c, angelCollision

		jr angelCollisionGTFO
	angelCollision:
		;take away 1 life
		ld hl, $2FE9
		ld a, (hl)
		dec a
		ld (hl), a

		call updatePlayerLives
		call respawnPlayer

	angelCollisionGTFO:



ret

;decide if it's time to change the player sprite and load l with whatever sprite number the player sprite should be
timeTilPlayerSpriteChange:
push af
	ld hl, $2FF8
	ld a, (hl)
	dec a
	ld (hl), a
	cp 0
	jr z, timeTilPlayerSpriteChangeReset
	jr timeTilPlayerSpriteChangeGTFO
	timeTilPlayerSpriteChangeReset:
		ld a, 10
		ld (hl), a
		ld hl, $2FF7
		ld a, (hl)
		cp 2
		jr z, setTo3
		jr setTo2
		setTo2:
			ld hl, $2FF7
			ld a, 2
			ld (hl), a
			jr timeTilPlayerSpriteChangeGTFO
		setTo3:
			ld hl, $2FF7
			ld a, 3
			ld (hl), a
			jr timeTilPlayerSpriteChangeGTFO
	timeTilPlayerSpriteChangeGTFO:
		ld hl, $2FF7
		ld a, (hl)
		ld l, a
pop af

ret

;decide if it's time to change the angel sprite and load l with whatever sprite number the player sprite should be
;2FEB = frames until angel of death moves again
;2FEA = sprite number to use for angel
timeTilAngelSpriteChange:
push af
	ld hl, $2FEB
	ld a, (hl)
	dec a
	ld (hl), a
	cp 0
	jr z, timeTilAngelSpriteChangeReset
	jr timeTilAngelSpriteChangeGTFO
	timeTilAngelSpriteChangeReset:
		ld a, 30
		ld (hl), a
		ld hl, $2FEA
		ld a, (hl)
		cp 6
		jr z, AngelsetTo3
		jr AngelsetTo2
		AngelsetTo2:
			ld hl, $2FEA
			ld a, 6
			ld (hl), a
			jr timeTilAngelSpriteChangeGTFO
		AngelsetTo3:
			ld hl, $2FEA
			ld a, 7
			ld (hl), a
			jr timeTilAngelSpriteChangeGTFO
	timeTilAngelSpriteChangeGTFO:
		ld hl, $2FEA
		ld a, (hl)
		ld l, a
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

	ld hl, spritep1
	;ld a, (hl)
	ld d, 64

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
	ld d, 32
	sprite01ColorLoop:
		ld a, %00000011 	;3 = poop brown color
		out (c), a
		call smallDelay
		dec d
		ld a, d 
		cp 0
		jr nz, sprite01ColorLoop

	;color both sprites of the player character
	ld d, 4
	;run this loop 4 times to color both 8 pixel high player sprites (sprites get 16 pixels of height in their respective vram tables)
	colorThePlayerLoop:
		ld a, %00000001
		out (c), a 			;give him a red hat
		call smallDelay
	
		ld a, %00000011 	;poop brown colored skin 
		out (c), a
		call smallDelay
		out (c), a
		call smallDelay

		ld a, %00000010 	;green shirt
		out (c), a
		call smallDelay
		out (c), a
		call smallDelay

		ld a, %00000100 	;blue pants
		out (c), a
		call smallDelay
		out (c), a
		call smallDelay
		out (c), a
		call smallDelay

		dec d
		ld a, d
		cp 0
		jr nz, colorThePlayerLoop

	ld d, 16
	colorBadGuy1Loop:
		ld a, %00001001
		out (c), a
		call smallDelay
		dec d
		ld a, d
		cp 0
		jr nz, colorBadGuy1Loop

	ld d, 16
	colorBadGuy2Loop:
		ld a, %00001110
		out (c), a
		call smallDelay
		dec d
		ld a, d
		cp 0
		jr nz, colorBadGuy2Loop

	;color bad guy 3.
	;this one has multiple colors btw
	ld d, 4
	colorBadGuy3Loop:
		ld a, %00001001
		out (c), a
		call smallDelay
		ld a, %00001101
		out (c), a
		call smallDelay

		ld a, %00000001
		out (c), a
		call smallDelay
		out (c), a
		call smallDelay
		out (c), a
		call smallDelay

		ld a, %00001101
		out (c), a
		call smallDelay
		ld a, %00001101
		out (c), a
		call smallDelay

		ld a, %00001001
		out (c), a
		call smallDelay
		dec d
		ld a, d
		cp 0
		jr nz, colorBadGuy3Loop

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

;	$2007: screen pos x offset for g4 software sprite function
;	#2008: screen pos y offset for g4 software sprite function
softwareSpriteToVram:

	ld d, 64
	ld e, 0
	;ld hl, letters_00
	softwareSpriteCopyLoopY:
	softwareSpriteCopyLoopX:
		;base address of vram
		ld a, 14
		push de
		ld d, 0
		push hl
		call VdpWriteToStandardRegister
		pop hl
		pop de
		;ld c, $21
		;ld a, d
		push de
		push hl
		push bc
		ld hl, $2007
		ld a, (hl)
		add e
		ld e, a
		ld hl, $2008
		ld bc, $0000
		ld c, (hl)
		ld a, c
		sla c
		sla c
		sla c
		sla c
		sla c
		sla c
		sla c
		and %11111110
		ld b, a
		ex de, hl
		add hl, bc
		ex de, hl
		pop bc
		out (c), e
		;ld a, e
		out (c), d
		pop hl
		pop de

		;ld hl, letters_0
		ld a, (hl)

		writeByte:
			ld b, $A0
			ld c, $20
			out (c), a
			inc e
			inc hl
			ld a, e
			and %01111111
			cp 4
			jr nz, softwareSpriteCopyLoopX
			ld a, e
			and %10000000
			ld e, a
			ex de, hl
			ld bc, 128
			add hl, bc
			ex de, hl
			ld a, d
			cp 68
			jr nz, softwareSpriteCopyLoopY

ret


rotateAndMunge:

	ld a, e
	and %01111111
	cp 0
	jr z, rotateAndMungeDis0
	cp 1
	jr z, rotateAndMungeDis1
	cp 2
	jr z, rotateAndMungeDis2
	jr rotateAndMungeDis3
	rotateAndMungeDis0:
		ld a, (hl)
		and %11000000
		srl a
		srl a
		srl a
		srl a
		srl a
		srl a
		jr rotateAndMungeContinue
	rotateAndMungeDis1:
		ld a, (hl)
		and %00110000
		srl a
		srl a
		srl a
		srl a
		jr rotateAndMungeContinue
	rotateAndMungeDis2:
		ld a, (hl)
		and %00001100
		srl a
		srl a
		jr rotateAndMungeContinue
	rotateAndMungeDis3:
		ld a, (hl)
		and %00000011
		jr rotateAndMungeContinue

	rotateAndMungeContinue:
		cp 0
		jr z, rotateAndMungeIs0
		cp 1
		jr z, rotateAndMungeIs1
		cp 2
		jr z, rotateAndMungeIs2
		jr rotateAndMungeIs3

		rotateAndMungeIs0:
			ld a, %00000000
			jr rotateAndMungeExit
		rotateAndMungeIs1:
			ld a, %00001111
			jr rotateAndMungeExit
		rotateAndMungeIs2:
			ld a, %11110000
			jr rotateAndMungeExit
		rotateAndMungeIs3:
			ld a, %11111111

		rotateAndMungeExit:

ret

updateScore:

	ld hl, $2007
	ld a, 24
	ld (hl), a
	ld hl, $2008
	ld a, 0
	ld (hl), a

	;2FED = angel of death position x
	;2FEC = angel of deat position y
	;if score is higher than 10 and angel of death is not spawned, spawn it in
	ld hl, $2FEE
	ld a, (hl)
	cp 10
	jr c, angelOfDeathCheckGTFO
	ld hl, $2FED
	ld a, (hl)
	cp 0
	jr z, angelOfDeathCheckY
	jr angelOfDeathCheckGTFO
	angelOfDeathCheckY:
		ld hl, $2FEC
		ld a, (hl)
		cp 230
		jr z, angelOfDeathCheckEnable
		jr angelOfDeathCheckGTFO
	angelOfDeathCheckEnable:
		ld hl, $2FEC
		ld a, 100
		ld (hl), a
		ld hl, $2FED
		ld a, 0
		ld (hl), a

	angelOfDeathCheckGTFO:


	ld hl, $2FEE
	ld c, (hl)
	call calc8bitDecimal

	ld hl, $96C4
	ld a, (hl)
	call G4PrintChar
	;call figureOutWhatCharToUse

	ld hl, $2007
	ld a, 28
	ld (hl), a
	ld hl, $96C5
	ld a, (hl)
	call G4PrintChar
	;call figureOutWhatCharToUse

	ld hl, $2007
	ld a, 32
	ld (hl), a
	ld hl, $96C6
	ld a, (hl)
	call G4PrintChar
	;call figureOutWhatCharToUse


ret

;c needs to contain the value of whatever you want to print as decimal
calc8bitDecimal:
	
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

	;ld hl, $90C4
	;call VPrintString

ret

CDivD:
;Inputs:
;     C is the numerator
;     D is the denominator
;Outputs:
;     A is the remainder
;     B is 0
;     C is the result of C/D
;     D,E,H,L are not changed
;
     ld b,8
     xor a
       sla c
       rla
       cp d
       jr c,$+4
         inc c
         sub d
       djnz $-8
ret

exitmessage: db "Thank you for playing Potato Man",0

;the potato sprite
spritep1: db %00011000
spritep2: db %00111100
spritep3: db %01011010
spritep4: db %01111110
spritep5: db %01011010
spritep6: db %01100110
spritep7: db %00111100
spritep8: db %00011000

;the poop sprite
spritep9: db %00001000
spritep10: db %00011000
spritep11: db %00011000
spritep12: db %00111100
spritep13: db %00111100
spritep14: db %01111110
spritep15: db %11111111
spritep16: db %11111111

;potato man 1 sprite
poman1: db %00001000
poman2: db %00011000
poman3: db %10011001
poman4: db %01111110
poman5: db %00111100
poman6: db %01100110
poman7: db %01101100
poman8: db %01101100

;potato man 2 sprite
poman9: db %00001000
poman10: db %00011000
poman11: db %10011001
poman12: db %01111110
poman13: db %00111100
poman14: db %00110110
poman15: db %01100110
poman16: db %11000110

;bad guy 1 sprite
bguy1: db %00011000
bguy2: db %00111100
bguy3: db %01011010
bguy4: db %11111111
bguy5: db %11100111
bguy6: db %01011010
bguy7: db %00111100
bguy8: db %00011000

;bad guy 2 sprite
bguy9: db %00010000
bguy10: db %00010000
bguy11: db %00011000
bguy12: db %00111111
bguy13: db %11111100
bguy14: db %00011000
bguy15: db %00001000
bguy16: db %00001000

;bad guy 3 sprite
bguy17: db %11000011
bguy18: db %01100110
bguy19: db %00111100
bguy20: db %01011010
bguy21: db %00011000
bguy22: db %01100110
bguy23: db %01100110
bguy24: db %11000011

;bad guy 3 sprite - second frame
bguy25: db %01100110
bguy26: db %00111100
bguy27: db %00111100
bguy28: db %01011010
bguy29: db %00011000
bguy30: db %01100110
bguy31: db %01100110
bguy32: db %11000011

playerLife_00: db $00, $00, $90, $00
playerLife_01: db $00, $03, $30, $00
playerLife_02: db $30, $03, $30, $03
playerLife_03: db $02, $22, $22, $20
playerLife_04: db $00, $22, $22, $00
playerLife_05: db $00, $CC, $0C, $C0
playerLife_06: db $0C, $C0, $0C, $C0
playerLife_07: db $CC, $00, $0C, $C0


;bruh wtf are these bottom 2 lines for?
;	-03/11/2020
letters_1: db %01100000, %11100000, %00100000, %00100000, %00100000, %00100000, %11111000, %00000000
letters_0: db %01110000, %10001000, %11001000, %10101000, %10011000, %10001000, %01110000, %00000000
spriteTerminate: db %00000000

score: db "Score:"
youDied1: db "You died",0
youDied2: db "All your friends are dead",0
youDied3: db "Your pets all got skinned alive",0
youDied4: db "All your potatos started rotting",0
youDied41: db "Your family was killed by a bear",0
youDied5: db "No one came to your funeral",0
youDied6: db "No one even cared that you died",0
youDied7: db "You lose",0
youDied8: db "Game over",0