
outCHDH:    .EQU		$d0
outCLDH:	.EQU    	$d1
outCHDL:	.EQU    	$d2
outCLDL:	.EQU    	$d3
ClockMask:	.EQU        $04

ps2sendbyte:
    ld c,a
    ld a,outCLDH		;clock (tip) low for 100 us
    out (0),a			;done
inhibit:    
    call Pause100us
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
    jp nz,waitforhighs  ;keep waiting
    ret                 ;done with entire byte send!!!!
send_one:
    ld a,outCHDH
    out (0),a
    ret
send_zero:
    ld a,outCHDL
    out (0),a
    ret
Pause100us:
    ld b,44
Pause100usLoop:
    djnz Pause100usLoop
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
    call Pause5us
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
Pause5us:
    nop
    ret