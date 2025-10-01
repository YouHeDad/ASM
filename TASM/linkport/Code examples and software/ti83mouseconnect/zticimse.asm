.nolist
#include "DoorsCS.inc"
#DEFINE		outCHDH		$d0
#DEFINE		outCLDH		$d1
#DEFINE		outCHDL		$d2
#DEFINE		outCLDL		$d3
#DEFINE		ClockMask	$4
.list
	.org $0000
SEStart:
	.db $AB,$31,$87,$50
	.dw SELoad-SEStart
	.dw SEMouse-SEStart
	.dw SEUnload-SEStart
SELoad:
	call _newline
	ld hl,SETxt1-SELoad+$8265
	call _puts
	ld a,127
	ld (CmdShadow+127),a
SELoad1:
	call _getk
	or a
	jr z,SELoad1
	ld a,$ff
	call ps2sendbyte-SELoad+$8265
	call ps2getbyte-SELoad+$8265
	cp $FA
	ret nz
	call ps2getbyte-SELoad+$8265
	cp $AA
	ret nz
	call ps2getbyte-SELoad+$8265
	or a
	ret nz
	ld a,$E8
	call ps2sendbyte-SELoad+$8265
	call ps2getbyte-SELoad+$8265
	cp $FA
	ret nz
	xor a
	call ps2sendbyte-SELoad+$8265
	call ps2getbyte-SELoad+$8265
	cp $FA
	ret nz
	ld a,$F0
	call ps2sendbyte-SELoad+$8265
	call ps2getbyte-SELoad+$8265
	cp $FA
	ret nz
	ld a,126
	ld (CmdShadow+127),a
	ret
SETxt1:
	.db "Connect mouse",0
SEMouse:
	ld a,(CmdShadow+127)
	sub 126
	ret nz
	ld a,(CmdShadow+126)
	dec a
	jr z,SEMouseGo
	xor a
	ld (CmdShadow+126),a
	ld a,$EB
	call ps2sendbyte-SEMouse+$8265
	call ps2getbyte-SEMouse+$8265
	ld (CmdShadow+123),a
	push af
	call ps2getbyte-SEMouse+$8265
	ld (CmdShadow+124),a
	call ps2getbyte-SEMouse+$8265
	ld (CmdShadow+125),a
	ld d,1
	pop af
	sub 8
	ret z
	dec a
	ret z
	dec a
	ret z
	sub 14d
	ret z
	sub $10
	ret z
	xor a
	ld (CmdShadow+126),a
	ret
SEMouseGo:
	xor a
	ld (CmdShadow+126),a
	ld a,(CmdShadow+123)
	ld hl,$8265+37d				;MseX or MseY-1
	ld d,2
	sub 9
	jr z,ClickLeft
	dec a
	jr z,ClickRight
	sub 14d
	jr z,MouseLeft
	sub $10
	jr z,MouseDown
	ld a,(CmdShadow+125)
	or a
	jr nz,MouseUp
MouseRight:
	dec (hl)
	ret
MouseLeft:
	inc (hl)
	ret
MouseUp:
	inc hl
	dec (hl)
	ret
MouseDown:
	inc hl
	inc (hl)
	ret
ClickLeft:
	ld d,3
	ret
ClickRight:
	ld d,4
	ret
ps2sendbyte:
    ld c,a
    ld a,outCLDH		;clock (tip) low for 100 us
    out (0),a			;done
inhibit:    
    ld b,45
Pause100us:
    djnz Pause100us
    ld a,outCLDL
    out (0),a
    nop
    ld a,outCHDL
    out (0),a
    nop
    nop                    
    ld b,8
waitforclocklow:
    in a,(0)
    and ClockMask
    or a
    jr nz,waitforclocklow
    ld a,c
    and 1
    dec a
    call z,send_one
    call nz,send_zero
    rrc c
waitforclockhigh:
    in a,(0)
    and ClockMask
    sub $4
    jr nz,waitforclockhigh
    djnz waitforclocklow
waittosendparity:
    in a,(0)
    and ClockMask
    or a
    jr nz,waittosendparity
    call send_one
endparity:
    in a,(0)
    and ClockMask
    sub $4
    jr nz,endparity
    ld a,outCHDH
    out (0),a  
waitforlows:
    in a,(0)
    and $0c
    or a
    jr nz,waitforlows
waitforhighs:
    in a,(0)
    and $0c
    cp $0c
    jr nz,waitforhighs  ;keep waiting
    ret                 ;done with entire byte send!!!!
send_one:
    ld a,outCHDH
    out (0),a
    ret
send_zero:
    ld a,outCHDL
    out (0),a
    ret
;----------------------------------------------------------------
ps2getbyte:
    ld b,8
    ld a,outCHDH
    out (0),a
    ld d,$0c
waitforstartbit:
    in a,(0)
    and d      ;sets the flags, no need for 'or a'
    jr nz,waitforstartbit 
    nop        ;not sure why, but you have it, so...
               ;also, may need more due to the above?
waitclockhigh:
    in a,(0)
    rrca
    rrca
    rrca
    jr nc,waitclockhigh   ;the bit was clear
waitclocklow:
    in a,(0)
    rrca
    rrca
    rrca
    jr c,waitclocklow     ;the bit was set
    ld b,1
Pause5us:			;31 cycles (5.1 useconds)
    djnz Pause5us
    or a
    in a,(0)
    rrca
    rrca
    rrca
    rrca
    rr e
    djnz waitclockhigh
waitforparitybit:
    in a,(0)
    rrca
    rrca
    rrca
    jr nc,waitforparitybit
waitforparitydata:
    in a,(0)
    rrca
    rrca
    rrca
    jr c,waitforparitydata
    ld a,e
    ret
SEUnload:
	call _newline
	ld hl,SETxt2-SEUnload+$8265
	call _puts
SEUnload1:
	call _getk
	or a
	jr z,SEUnload1
	ret
SETxt2:
	.db "Unplug mouse",0
.end
END