randData: equ $9279

print1st32bitNum:

	ld hl, $96A3
	ld a, (hl)
	call aToScreenHex
	ld hl, $96A2
	ld a, (hl)
	call aToScreenHex
	ld hl, $96A1
	ld a, (hl)
	call aToScreenHex
	ld hl, $96A0
	ld a, (hl)
	call aToScreenHex

ret


print2nd32bitNum:

	ld hl, $96A7
	ld a, (hl)
	call aToScreenHex
	ld hl, $96A6
	ld a, (hl)
	call aToScreenHex
	ld hl, $96A5
	ld a, (hl)
	call aToScreenHex
	ld hl, $96A4
	ld a, (hl)
	call aToScreenHex

ret

print32bitresultanswer:

	ld hl, $96AB
	ld a, (hl)
	call aToScreenHex
	ld hl, $96AA
	ld a, (hl)
	call aToScreenHex
	ld hl, $96A9
	ld a, (hl)
	call aToScreenHex
	ld hl, $96A8
	ld a, (hl)
	call aToScreenHex

ret

;puts whatever is in the arithmatic result variable into the parameter 1 ram location
putResultInParameter1:

	ld hl, $96AB
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

ret

;this needs to be run right before the DEHL_Div_C subroutine
stupidDivisionPre:

;load all the values from ram into the correct registers
	ld hl, $96A0
	ld c, (hl)
	ld hl, $96A1
	ld b, (hl)
	ld hl, $96A2
	ld e, (hl)
	ld hl, $96A3
	ld d, (hl)
	ld l, c
	ld h, b
	push hl
		ld hl, $96A4
		ld c, (hl)
	pop hl
	;the registers are now loaded

ret

;math parameter 1 (32 bit) ($96A0-$96A3) / math parameter 2 (8 bit) ($96A4) = math result variable (32 bit) ($96A8-$96AB). remainder goes in $96AC and is an 8 bit number
;Inputs:
;     DEHL is a 32 bit value where DE is the upper 16 bits
;     C is the value to divide DEHL by
;Outputs:
;    A is the remainder
;    B is 0
;    C is not changed
;    DEHL is the result of the division
;
DEHL_Div_C:
   xor	a
   ld	b, 32

_loop:
   add	hl, hl
   rl	e
   rl	d
   rla
   jr	c, $+5
   cp	c
   jr	c, $+4

   sub	c
   inc	l
   
   djnz	_loop
   
   ret

;run this after DEHL_Div_C. won't work if you modify to subrountine at all. No idea why
stupidDivisionPost:

	;now load the calculation results into the correct places in ram
   ;load the remainder which is in the a register into $96AC
   ld b, h
   ld c, l
   ld hl, $96AC
   ld (hl), a

   ;load calculation result which is in DEHL into $96A8-$96AB
   ld hl, $96A8
   ld (hl), c
   ld hl, $96A9
   ld (hl), b
   ld hl, $96AA
   ld (hl), e
   ld hl, $96AB
   ld (hl), d
   ;done

ret

;	$96A0-$96A1: low byte for first value of 32 bit add
;	$96A2-$96A3: high byte for first value of 32 bit add
;	$96A4-$96A5: low byte for second value of 32 bit add
;	$96A6-$96A7: high byte for second value of 32 bit add
;
;	$96A8-$96A9: low byte for result of a 32 bit arithmatic operation
;	$96AA-$96AB: high byte for result of a 32 bit arithmatic operation

load32bitValuesFromRam:

	ld hl, $96A2
	ld e, (hl)
	ld hl, $96A3
	ld d, (hl)

	ld hl, $96A6
	ld c, (hl)
	ld hl, $96A7
	ld b, (hl)

	ld h, b
	ld l, c
	

	;ld hl, $96A0 	;value 1 low 16 bits
	;ld de, $96A4 	;value 2 low 16 bits
	exx

	ld hl, $96A0
	ld e, (hl)
	ld hl, $96A1
	ld d, (hl)


	ld hl, $96A4
	ld c, (hl)
	ld hl, $96A5
	ld b, (hl)

	ld h, b
	ld l, c

ret
add32BitNumber:
	call load32bitValuesFromRam

	add hl, de
	exx
	adc hl, de
	exx

	ex de, hl

	ld hl, $96A8
	ld (hl), e
	ld hl, $96A9
	ld (hl), d

	ex de, hl
	exx
	ex de, hl

	ld hl, $96AA
	ld (hl), e
	ld hl, $96AB
	ld (hl), d


ret

subtract32BitNumber:
	or a
	ld hl, ($96A0)
	ld de, ($96A4)
	sbc hl, de
	ld ($96A8), hl

	ld hl, ($96A2)
	ld de, ($96A6)
	sbc hl, de
	ld ($96AA), hl

ret

;	$96A0-$96A1: 16 bit parameter #1
;	$96A2-$96A3: 16 bit parameter #2
;
;	$96A8-$96A9: low byte for result of a 32 bit arithmatic operation
;	$96AA-$96AB: high byte for result of a 32 bit arithmatic operation

;this is meant to be used before mul16
load16bitvaluesFromRam:

	ld hl, $96A0
	ld c, (hl)
	ld hl, $96A1
	ld b, (hl)


	ld hl, $96A2
	ld e, (hl)
	ld hl, $96A3
	ld d, (hl)

ret

;this is meant to be used after mul16 in order to put the values into ram
loadmul16IntoRam:
	;DEHL needs to be saved into $96A8-$96AB in little endian
	ld b, h
	ld c, l

	ld hl, $96A8
	ld (hl), c
	ld hl, $96A9
	ld (hl), b
	ld hl, $96AA
	ld (hl), e
	ld hl, $96AB
	ld (hl), d

ret

;=====================================
;i got this from:
;http://z80-heaven.wikidot.com/advanced-math#toc18
;====================================
;This was made by Runer112
;Tested by jacobly
mul16:
;BC*DE --> DEHL
; ~544.887cc as calculated in jacobly's test
;min: 214cc  (DE = 1)
;max: 667cc
;avg: 544.4507883cc   however, deferring to jacobly's result as mine may have math issues ?
;177 bytes
	ld	a,d
	ld	d,0
	ld	h,b
	ld	l,c
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit14
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit13
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit12
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit11
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit10
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit9
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit8
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit7
	ld	a,e
 	and	%11111110
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit6
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit5
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit4
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit3
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit2
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit1
	add	a,a
	jr	c,Mul_BC_DE_DEHL_Bit0
	rr	e
	ret	c
	ld	h,d
	ld	l,e
	ret

Mul_BC_DE_DEHL_Bit14:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit13
	add	hl,bc
	adc	a,d
Mul_BC_DE_DEHL_Bit13:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit12
	add	hl,bc
	adc	a,d
Mul_BC_DE_DEHL_Bit12:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit11
	add	hl,bc
	adc	a,d
Mul_BC_DE_DEHL_Bit11:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit10
	add	hl,bc
	adc	a,d
Mul_BC_DE_DEHL_Bit10:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit9
	add	hl,bc
	adc	a,d
Mul_BC_DE_DEHL_Bit9:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit8
	add	hl,bc
	adc	a,d
Mul_BC_DE_DEHL_Bit8:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit7
	add	hl,bc
	adc	a,d
Mul_BC_DE_DEHL_Bit7:
	ld	d,a
	ld	a,e
	and	%11111110
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit6
	add	hl,bc
	adc	a,0
Mul_BC_DE_DEHL_Bit6:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit5
	add	hl,bc
	adc	a,0
Mul_BC_DE_DEHL_Bit5:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit4
	add	hl,bc
	adc	a,0
Mul_BC_DE_DEHL_Bit4:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit3
	add	hl,bc
	adc	a,0
Mul_BC_DE_DEHL_Bit3:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit2
	add	hl,bc
	adc	a,0
Mul_BC_DE_DEHL_Bit2:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit1
	add	hl,bc
	adc	a,0
Mul_BC_DE_DEHL_Bit1:
	add	hl,hl
	adc	a,a
	jr	nc,Mul_BC_DE_DEHL_Bit0
	add	hl,bc
	adc	a,0
Mul_BC_DE_DEHL_Bit0:
	add	hl,hl
	adc	a,a
	jr	c,Mul_BC_DE_DEHL_FunkyCarry
	rr	e
	ld	e,a
	ret	nc
	add	hl,bc
	ret	nc
	inc	e
	ret	nz
	inc	d
	ret

Mul_BC_DE_DEHL_FunkyCarry:
	inc	d
	rr	e
	ld	e,a
	ret	nc
	add	hl,bc
	ret	nc
	inc	e
	ret

;this puts $96A0-$96A3 into DEHL and $96A4-$96A7 into BCIX
ramTomul32Do:

	ld IX, ($96A0)

	ld hl, $96A2
	ld c, (hl)
	ld hl, $96A3
	ld b, (hl)

	ld hl, $96A6
	ld e, (hl)
	ld hl, $96A7
	ld d, (hl)

	push bc
	ld hl, $96A4
	ld c, (hl)
	ld hl, $96A5
	ld b, (hl)
	ld l, c
	ld h, b
	pop bc
	

	;ld hl, $96A0 	;value 1 low 16 bits
	;ld de, $96A4 	;value 2 low 16 bits
	;exx

	;ld hl, $96A2
	;ld b, (hl)
	;ld hl, $96A3
	;ld c, (hl)

	;ld d, c
	;ld e, b

	;ld hl, $96A6
	;ld b, (hl)
	;ld hl, $96A7
	;ld c, (hl)

	;ld h, c
	;ld l, b

ret
; You will need to define z32_0, which is where the result is written!

mul32:
;max: 703cc  + 3*mul16
;     2704cc
;min: 655cc  + 3*mul16
;     1297cc
;avg: 673.25cc+3*mul16
;     2307.911cc
;DEHL * BCIX ==> z32_0
z32_0: equ $96A8
z32_2: equ $96AC
;z32_2 = z32_0+4
;z32_0 = 96A8

  push de
  push bc
  push hl
  push ix
  call mul16  ;DEHL
  ld (z32_2),hl
  ld (z32_2+2),de

  pop de
  pop bc
;  push bc
  push de
  call mul16  ;DEHL
  ld (z32_0),hl
  ld (z32_0+2),de

  pop de    ;low word
;  pop bc    ;low word
  pop hl
  xor a
  sbc hl,de
  jr nc,+_1
  sub l
  ld l,a
  sbc a,a
  sub h
  ld h,a
  xor a
  inc a
_1:
  ex de,hl
  pop hl
  sbc hl,bc
  jr nc,+_2
  ld b,a
  xor a
  sub l
  ld l,a
  sbc a,a
  sub h
  ld h,a
  ld a,b
  inc a
_2:
  ld b,h
  ld c,l
  push af
  call mul16
  pop af    ;holds the sign in the low bit
  rra
  jr c,mul32_add
;need to perform z0+z2-result
  push de
  push hl
  xor a
  ld hl,(z32_0)
  ld bc,(z32_2)
  add hl,bc
  ex de,hl
  ld hl,(z32_0+2)
  ld bc,(z32_2+2)
  adc hl,bc
  rla
;now need to subtract
  ex de,hl
  pop bc
  sbc hl,bc
  ex de,hl
  pop bc
  sbc hl,bc
  sbc a,0
;A:HL:DE is the result, need to add to z32_0+2
mul32_final:
  ld bc,(z32_0+2)
  ex de,hl
  add hl,bc
  ld (z32_0+2),hl
  ld hl,(z32_2)
  adc hl,de
  ld (z32_2),hl
  ld hl,z32_2+2
  adc a,(hl)
  ld (hl),a
  ret nc
  inc hl
  inc (hl)
  ret
mul32_add:
;add to the current result
  xor a
  ld bc,(z32_0)
  add hl,bc
  ex de,hl
  ld bc,(z32_0+2)
  adc hl,bc
  rla
  ex de,hl
  ld bc,(z32_2)
  add hl,bc
  ex de,hl
  ld bc,(z32_2+2)
  adc hl,bc
  adc a,0
  jp mul32_final

  ;-----> Generate a random number
; output a=answer 0<=a<=255
; all registers are preserved except: af
; $9279 (randData) = random seed (programmer gets to/has to put a 16 bit random seed here)
randomNumber:
        push    hl
        push    de
        ld      hl,(randData)
        ld      a,r
        ld      d,a
        ld      e,(hl)
        add     hl,de
        add     a,l
        xor     h
        ld      (randData),hl
        pop     de
        pop     hl
ret