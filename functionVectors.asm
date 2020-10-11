;this is a vector table made so that externally loaded programs can easily access functions on the rom
;$B000
call VdpPrintChar
ret

;$B004
call VPrintString
ret

;$B008
call VdpInsertEnter
ret

;$B00C
call VdpBackspace
ret

;$B010
call VdpInsertTab
ret

;$B014
call ClearScreen
ret

;$B018
;if you do anything to change the video mode, run this when you're done to put things back to the way they were
call initializeVideo
ret

;$B01C
;d should contain register data
;a should contain register number
call VdpWriteToStandardRegister
ret

;$B020
; a register needs to contain palette register number you want to write to (0-15)
; d register needs to contain first palette byte
; e register needs to contain second palette byte
;note that the pointer value in register 16 auto increments each time you do this
call VdpWriteToPaletteRegister
ret

;$B024
;this function waits for the user to input a key. Once a keyboard key has been pressed, it loads the a register with the respective ascii code
call waitChar
ret

;$B028
call RowsColumnsToCursorPos 	;update the cursor position
ret

;$B02C
call RowsColumnsToVram 
ret

;$B030
call print16BitDecimal
ret

;$B034
call print2DigitDecimal
ret

;$B038
call print8bitDecimal
ret