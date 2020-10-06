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