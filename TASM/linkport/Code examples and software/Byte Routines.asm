; ***********
; Send the value in a trough the linkport

Write:
	ld c,a			; Store byte
	ld d,1			; Create bitmask
	ld e,$D1		; Init linkport value
Write_go:
	ld a,c			; Retrieve byte
	and d			; and with bitmask
	or a
	call z,Set_ring_low
	call nz,Set_ring_high	; Set data line (ring) according to bit
	rlc d			; rotate bitmask
	ld a,e			; retrieve linkport value
	out (0),a		; Set linkport
	xor 1			; invert clockstate
	ld e,a			; store linkport value
	ld b,6
Delay_loop:
	djnz Delay_loop	; Short delay
	ld a,d			; bitmask back to original?
	cp 1
	jr nz,Write_go		; No: Next bit
	ret			; Yes: Done
Set_ring_high:
	res 1,e
	ret
Set_ring_low:
	set 1,e
	ret

; ***********
; Receive one byte from the linkport in a

Read:
	ld b,0			; reset variables (b = byte,
	ld d,1			; d = bitmask, e = clockstate)
	in a,(0)		; Get byte and check tip
	bit 2,a
	call z,State_zero
	call nz,State_one
Read_go:
	in a,(0)		; Is clockstate changed?
	bit 2,a
	ld a,e
	jr z,Clock_is_low
	or a
	jr z,Clockchanged	; Yes (High)
	jr Read_go		; No
Clock_is_low:
	or a
	jr z,Read_go		; No  (Low)
Clockchanged:			; Yes
	in a,(0)		; Get value from port
	bit 2,a
	call z,State_zero	; Store new clockstate
	call nz,State_one
	bit 3,a
	call nz,Or_byte	; Or them, depending on state of ring
	rlc d
	ld a,d
	cp 1
	jr z,Stop_read		; Yes: quit
	jr Read_go		; No, next bit
Or_byte:
	ld a,b
	or d
	ld b,a
	ret
State_zero:
	ld e,0
	ret
State_one:
	ld e,1
	ret
Stop_read:
	ld a,b
	ret
