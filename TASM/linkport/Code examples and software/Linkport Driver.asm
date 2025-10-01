; AShell83 1.0 Program

#include "ti83asm.inc"
#include "tokens.inc"

#define tiptoggle 8265h
#define ringtoggle 8266h

.org $9327

	nop
	jr prog_start
	.dw	$0000
	.dw	prog_description
	.dw	prog_icon
prog_start:

;*********************** Menu

	ld a,1
	ld (tiptoggle),a
	ld (ringtoggle),a
	call _clrLCDFull
	call _homeup
	ld hl,choosetxt
	call _puts
	call _getkey
	cp 143
	jp z,calcA
	cp 144
	jp z,calcB
	ret

;*********************** Calc A routine

calcA:				; Calc A!
	call _clrLCDFull
	ld a,1
	call drawcable

calcAlus:
	ld a,0ffh			; Scan for Exit
	out (1),a
	ld a,0fdh
	out (1),a
	in a,(1)
	cp 191
	ret z

	ld a,0ffh			; Scan for 1 pressed
	out (1),a
	ld a,0efh
	out (1),a
	in a,(1)
	cp 253
	jp z,toggletip

	ld a,0ffh			; Scan for 2 pressed
	out (1),a
	ld a,0f7h
	out (1),a
	in a,(1)
	cp 253
	jp z,togglering

	jp calcAlus

toggletip:
	ld a,(tiptoggle)		; Compare tipstatus
	cp 0
	jp z,sethigh
	ld a,0			; 1? => status wordt 0,
	ld (tiptoggle),a
	jp setportsright
sethigh:
	ld a,1			; 0? => status wordt 1
	ld (tiptoggle),a
	jp setportsright

togglering:
	ld a,(ringtoggle)		; Compare ringstatus
	cp 0
	jp z,sethighring
	ld a,0			; 1? => status wordt 0,
	ld (ringtoggle),a
	jp setportsright
sethighring:
	ld a,1			; 0? => status wordt 1
	ld (ringtoggle),a
;	jp setportsright

setportsright:
	ld a,1
	call drawcable
	ld a,(tiptoggle)
	cp 0
	jp z,tipislow
	ld a,(ringtoggle)
	cp 0
	jp z,tiphighringlow
	jp setbothhigh
tipislow:
	ld a,(ringtoggle)
	cp 0
	jp z,setbothlow
	jp tiplowringhigh

setbothhigh:
	ld a,0D0h			; 11000000
	jp setport
tiplowringhigh:
	ld a,0D1h			; 11000001
	jp setport
tiphighringlow:
	ld a,0D2h			; 11000001 (ring = low)
	jp setport
setbothlow:
	ld a,0D3h			; 11000011
;	jp setport
setport:
	out (bport),a		; set poort
	call scan_keys
	jp calcAlus

;*********************** Calc B rountine

calcB:				; Calc B!
	call _clrLCDFull

calcBlus:
	ld a,2
	call drawcable

	ld a,0ffh			; Scan for Exit
	out (1),a
	ld a,0fdh
	out (1),a
	in a,(1)
	cp 191
	ret z

	in a,(bport)
	and 0Ch			; 00001100
	cp 0Ch
	jp z,bothhigh
	cp 4				; 00000100
	jp z,ringlow
	cp 8				; 00001000
	jp z,tiplow
	cp 0				; 00000000
	jp z,bothlow
	jp calcBlus

bothhigh:
	ld a,1
	ld (tiptoggle),a
	ld a,1
	ld (ringtoggle),a		; set vars
	jp calcBlus			; and return
tiplow:
	ld a,0
	ld (tiptoggle),a
	ld a,1
	ld (ringtoggle),a
	jp calcBlus
ringlow:
	ld a,1
	ld (tiptoggle),a
	ld a,0
	ld (ringtoggle),a
	jp calcBlus
bothlow:
	ld a,0
	ld (tiptoggle),a
	ld a,0
	ld (ringtoggle),a
	jp calcBlus

;*********************** routines

drawcable:
	call _homeup
	ld hl,linkcable1
	call _puts
	call _newline

	ex af,af'		; store a
	ld a,(tiptoggle)
	cp 0			; tip low?
	call z,low		; yes= disp low
	call nz,high	; no = disp high/number
;	call nz,cableB
	call _puts
	call _newline

	ld hl,linkcable3
	call _puts
	call _newline

	ld a,(ringtoggle)
	cp 0
	call z,low
	call nz,high2
;	call nz,cableB
	call _puts
	call _newline

	ld hl,linkcable5
	call _puts
;	ld b,20
;	call delay
	ret
high:
	ex af,af'
	cp 1
	jp z,cableAtip
	jp nz,cableB
	ret
high2:
	ex af,af'
	cp 1
	jp z,cableAring
	jp nz,cableB
	ret
cableAtip:
	ld hl,linkcable4_1
	ex af,af'
	ret
cableAring:
	ld hl,linkcable4_2
	ex af,af'
	ret
cableB:
	ld hl,linkcable2_1
	ex af,af'
	ret
low:
	ld hl,linkcable2_2
	ret

;delay:
;	inc hl
;	dec hl
;	djnz delay
;	ret

scan_keys:		; Thanks to Randy Gluvna's romdump!
        di
scan_loop:
        xor a	; ld a,0
        out (1),a
        in a,(1)
        cp $FF
        jr nz,scan_loop
        ei
        ret

;*********************** vars

linkcable1:
	;    1234567890123456
	.db "  ",5Fh,0
linkcable2_1:
	.db " | |  +5V",0
linkcable2_2:
	.db " |*|  +0V",0
linkcable3:
	.db " )-(",0
linkcable4_1:
	.db " | |  1. ",0
linkcable4_2:
	.db " | |  2. ",0
linkcable5:
	.db " )-(            ",
	.db " | |            ",
	.db " | |            ",
	.db 0C1h,1Ah,1Ah,1Ah,"]",0

choosetxt:
	;    1234567890123456
	.db "    Timendus",$27,"   ",
	.db "Linkport  Driver",
	.db "                ",
	.db "   1. Calc A    ",
	.db "   2. Calc B    ",0

prog_description:
	.db "Linkport Driver",0
prog_icon:
.db $00
.db $77
.db $55
.db $77
.db $77
.db $77
.db $22
.db $1C

.end
END
