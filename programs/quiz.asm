VdpWriteToStandardRegister: equ $B01C
ClearScreen: equ $B014
initializeVideo: equ $B018
waitChar: equ $B024
VdpInsertEnter: equ $B008
VPrintString: equ $B004
VdpPrintChar: equ $B000
RowsColumnsToCursorPos: equ $B028
RowsColumnsToVram: equ $B02C
print16BitDecimal: equ $B030
print8bitDecimal: equ $B038
print2DigitDecimal: equ $B034

org $3000

ld hl, $2FFF
ld a, 0
ld (hl), a

call VdpInsertEnter
ld hl, introString
call VPrintString
call waitChar

call VdpInsertEnter
ld hl, standardPrompt
call VPrintString
call VdpInsertEnter


doQuestion1:
	ld hl, question1
	call VPrintString
	call VdpInsertEnter

	ld hl, question1a1
	call VPrintString
	call VdpInsertEnter

	ld hl, question1a2
	call VPrintString
	call VdpInsertEnter

	ld hl, question1a3
	call VPrintString
	call VdpInsertEnter

	ld hl, question1a4
	call VPrintString
	call VdpInsertEnter

	ld hl, standardPrompt
	call VPrintString
	;do this so that the blinking cursor will be in the correct place
	call RowsColumnsToCursorPos
	call RowsColumnsToVram

	call waitForValidInput

	push af
		cp "1"
		call z, add3Points
		cp "2"
		call z, addAPoint
		cp "3"
		call z, add2Points
		cp "4"
		call z, add2Points
	pop af

	call VdpPrintChar
	call VdpInsertEnter
	call VdpInsertEnter

doQuestion2:
	ld hl, question2
	call VPrintString
	call VdpInsertEnter

	ld hl, question2a1
	call VPrintString
	call VdpInsertEnter

	ld hl, question2a2
	call VPrintString
	call VdpInsertEnter

	ld hl, question2a3
	call VPrintString
	call VdpInsertEnter

	ld hl, question2a4
	call VPrintString
	call VdpInsertEnter

	ld hl, standardPrompt
	call VPrintString
	;do this so that the blinking cursor will be in the correct place
	call RowsColumnsToCursorPos
	call RowsColumnsToVram

	call waitForValidInput

	push af
	cp "1"
	call z, addAPoint
	cp "2"
	call z, addAPoint
	cp "3"
	call z, add2Points
	cp "4"
	call z, add3Points
	pop af

	call VdpPrintChar
	call VdpInsertEnter
	call VdpInsertEnter

doQuestion3:
	ld hl, question3
	call VPrintString
	call VdpInsertEnter

	ld hl, question3a1
	call VPrintString
	call VdpInsertEnter

	ld hl, question3a2
	call VPrintString
	call VdpInsertEnter

	ld hl, question3a3
	call VPrintString
	call VdpInsertEnter

	ld hl, question3a4
	call VPrintString
	call VdpInsertEnter

	ld hl, standardPrompt
	call VPrintString
	;do this so that the blinking cursor will be in the correct place
	call RowsColumnsToCursorPos
	call RowsColumnsToVram

	call waitForValidInput

	push af
	cp "1"
	call z, add3Points
	cp "2"
	call z, add2Points
	pop af

	call VdpPrintChar
	call VdpInsertEnter
	call VdpInsertEnter

doQuestion4:
	ld hl, question4
	call VPrintString
	call VdpInsertEnter

	ld hl, question4a1
	call VPrintString
	call VdpInsertEnter

	ld hl, question4a2
	call VPrintString
	call VdpInsertEnter

	ld hl, question4a3
	call VPrintString
	call VdpInsertEnter

	ld hl, question4a4
	call VPrintString
	call VdpInsertEnter

	ld hl, standardPrompt
	call VPrintString
	;do this so that the blinking cursor will be in the correct place
	call RowsColumnsToCursorPos
	call RowsColumnsToVram

	call waitForValidInput

	push af
	cp "1"
	call z, addAPoint
	cp "2"
	call z, add3Points
	cp "3"
	call z, add3Points
	cp "4"
	call z, add2Points
	pop af

	call VdpPrintChar
	call VdpInsertEnter
	call VdpInsertEnter

doQuestion5:
	ld hl, question5
	call VPrintString
	call VdpInsertEnter

	ld hl, question5a1
	call VPrintString
	call VdpInsertEnter

	ld hl, question5a2
	call VPrintString
	call VdpInsertEnter

	ld hl, question5a3
	call VPrintString
	call VdpInsertEnter

	ld hl, question5a4
	call VPrintString
	call VdpInsertEnter

	ld hl, standardPrompt
	call VPrintString
	;do this so that the blinking cursor will be in the correct place
	call RowsColumnsToCursorPos
	call RowsColumnsToVram

	call waitForValidInput

	push af
	cp "1"
	call z, addAPoint
	cp "2"
	call z, add2Points
	cp "3"
	call z, add2Points
	cp "4"
	call z, add3Points
	pop af

	call VdpPrintChar
	call VdpInsertEnter
	call VdpInsertEnter

;pretend it's a negative number
ld hl, yourScore1
call VPrintString

;print the actual score stored in ram in decimal format
ld hl, $2FFF
ld c, (hl)
call print2DigitDecimal

;add 2 zeros at the end of that number
ld a, "0"
call VdpPrintChar
ld a, "0"
call VdpPrintChar

;print the second part of the score introString
ld hl, yourScore2
call VPrintString

call VdpInsertEnter
ld hl, yourRank
call VPrintString
;print the user's rank
;4 = the lowest possible number of points
;15 = the higest possible number of points

ld hl, $2FFF
ld a, (hl)
cp 4
jr z, scoreRank1
cp 7
jr c, scoreRank2
cp 11
jr c, scoreRank3
cp 14
jr c, scoreRank4
jr scoreRank5

scoreRank1:
	ld hl, result1
	jr scoreRankEnd
scoreRank2:
	ld hl, result2
	jr scoreRankEnd
scoreRank3:
	ld hl, result3
	jr scoreRankEnd
scoreRank4:
	ld hl, result4
	jr scoreRankEnd
scoreRank5:
	ld hl, result5
	jr scoreRankEnd

scoreRankEnd:
call VPrintString

ret

waitForValidInput:

	call waitChar
	cp $2F
	jr c, waitForValidInput
	cp "5"
	jr nc, waitForValidInput

ret

;you get more points for choosing the wrong answer
;the more wrong the answer, the more points you get
;most questions do not have a correct answer
addAPoint:

	ld hl, $2FFF
	ld a, (hl)
	inc a
	ld (hl), a

ret

add2Points:

	call addAPoint
	call addAPoint

ret

add3Points:

	call addAPoint
	call addAPoint
	call addAPoint

ret


introString: db "Welcome to the intelligence quiz. Press any key to get started!",0

standardPrompt: db "Please enter the number of your choice: ",0
yourScore1: db "You scored: -",0
yourScore2: db " points.",0
yourRank: db "Your rank: ",0


question1: db "What is the meaning of life?",0
question1a1: db "1. haha 69 so funny cuz sex number",0
question1a2: db "2. To eat lots of potato chips",0
question1a3: db "3. bruh",0
question1a4: db "4. at least 20",0

question2: db "Did you know?",0
question2a1: db "1. Yes",0
question2a2: db "2. No",0
question2a3: db "3. Maybe",0
question2a4: db "4. All of the above",0

question3: db "Which of the following is NOT a type of bird?",0
question3a1: db "1. Penguins",0
question3a2: db "2. Tits",0
question3a3: db "3. Oh shit the urinal is clogged again",0
question3a4: db "4. Windows 95",0

question4: db "How many fingers and I holding up?",0
question4a1: db "1. Six",0
question4a2: db "2. a^2 + b^2 = c^2",0
question4a3: db "3. bruh",0
question4a4: db "4. more than 10",0

question5: db "What time is it?",0
question5a1: db "1. high noon",0
question5a2: db "2. yesterday",0
question5a3: db "3. 69 o-clock",0
question5a4: db "4. poopy buttholes",0

result1: db "Actually not that big of an idiot",0
result2: db "Idiot",0
result3: db "Supreme Idiot",0
result4: db "The Idiot King: Ruler of Dumbasses",0
result5: db "HOLY FUCCC EP12CX TROLL",0