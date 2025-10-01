; TachyonLink routines
;
; Copyright (C) 2003, by Michael Vincent. All rights reserved.
; See readme.txt for how you can use these in your programs.


	;Send routine
TachyonLink_Send:
	di
	ld e,a		;Byte to send
	ld a,1
	out (0),a	;clock line low
TachyonLink_Send_Wait:
	in a,(0)
	and 2
	jr nz,TachyonLink_Send_Wait
	;Both lines have gone low
	xor a
	out (0),a		;set both high
TachyonLink_Send_Wait2:
	in a,(0)
	and 2
	jr z,TachyonLink_Send_Wait2
	;Start the sending loop
	call TachyonLink_Pause
	ld b,4
TachyonLink_Send_Loop:
	;Now put a bit on the data line, clock low
	xor a
	rr e
	ccf
	rla
	sl1 a
	out (0),a
	;now pause
	call TachyonLink_Pause
	;clock high with a bit
	xor a
	rr e
	ccf
	rla
	add a,a
	out (0),a
	call TachyonLink_Pause
	djnz TachyonLink_Send_Loop
	xor a
	out (0),a
	ret



	;Receive routine:
TachyonLink_Receive:
	di
	ld e,0
TachyonLink_Receive_Wait:
	in a,(0)
	rra
	jr c,TachyonLink_Receive_Wait
	ld a,2
	out (0),a
	call TachyonLink_Pause
	xor a
	out (0),a
	ld b,4
	;Ready to receive
TachyonLink_Receive_Loop:
	in a,(0)
	rra
	jr c,TachyonLink_Receive_Loop
	;The clock went low...store data
	in a,(0)
	rra
	rra
	rr e
TachyonLink_Receive_Wait2:
	in a,(0)
	rra
	jr nc,TachyonLink_Receive_Wait2
	;The clock went high
	in a,(0)
	rra
	rra
	rr e
	djnz TachyonLink_Receive_Loop
	ld a,e
	ret
TachyonLink_Pause:
	;This pause is used by both routines, don't forget to copy it if you split them up.
	ex (sp),hl
	ex (sp),hl
	push bc
	pop bc
	ret