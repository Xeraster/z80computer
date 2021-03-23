;this is a program file meant to be loaded into ram from a drive

;org $3000 because the system loads executable files into ram then executes a call $3000 instruction
org $3000

VdpInsertEnter: equ $B008
VPrintString: equ $B004

;print new line
call VdpInsertEnter
;print hello world message
ld hl, helloworld
call VPrintString

;return to kernel
ret

helloworld: db "Hello, world!",0