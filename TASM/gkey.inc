getK_custom:
    call gkfunc1  ;-$10CA
    bit 0, a
    ld b, $CD
    adc a, h
    ld l, $7E
    ld h, e
    inc b
    call gkfunc1
    jp p, gkfunc2 ;($015A),-$3E0B  ;*p = if sign flags is set 
    call gkfunc1
    EI
    ld h, e
    ld bc, $8CCD
    ld l, 8
    ld l, l
    rlca
    call gkfunc1
    sbc a, a
    ld b, e
    rlca
    call gkfunc1
    or e
    ld e, e
    inc b
    call gkfunc1
    sbc a, b
    ld c, a
    ld (bc), a 
    call gkfunc1
    jp gkfunc3  ;($0A43) 

gkfunc12: ;($0146)
    ld a, d
    call gkfunc7 ;($20CC)
    call gkfunc8 ;($07AC)
    out ($10), a
    call gkfunc9 ;($20D6)
    call gkfunc8 ;($07AC)
gkfunc2: ;($015A)
     in a, ($11)
     ld e, a
     ld a, d
     call gkfunc7 ;($20CC)
     call gkfunc8 ;($07AC)
     out ($10), a 
     call gkfunc9 ;($20D6)
     ld a, e
     rr c
     jr c, gk_setBit0ofA__toLCD11 ;($0172)
     res 0, a
     jr gk_AtoLCD11 ;($0174)
gk_setBit0ofA__toLCD11: ;($0172)
     set 0, a
gk_AtoLCD11: ;($0174)
     call gkfunc8 ;($07AC)
     out ($11), a ;write a to LCD
     inc d
     djnz gkfunc12 ;($0146)
     ret

gkfunc13: ;($0A0C)
     ld de, $8058  ;op3EXT
     ld hl, ($8041) ;in op1 
     ld a, (de)
     add a, h
     daa
     ld (de), a
     dec de
     ld a, (de)
     adc a, l
     daa
     ld (de), a
     dec de
     ld hl, ($803F)   ;in Op1
     ld a, (de)
     adc a,h
     daa
     ld (de), a
     dec de
     ld a, (de)
     adc a, l
     daa
     ld (de), a 
     dec de
     ld hl, ($803D)   ;in OP1M?
     ld a, (de)
     adc a, h
     daa
     ld (de), a
     dec de
     ld a, (de)
     adc a, l
     daa
     ld (de), a
     dec de
     ld hl, ($803B)     ;OP1M
     ld a, (de)
     adc a, h
     daa
     ld (de), a
     dec de
     ld a, (de)
     adc a, l
     daa
     ld (de), a
     jp nc, gkfunc20 ;($0A48)
     dec de
     ex de, hl
     inc (hl)
gkfunc20: ;($0A48)
     djnz gkfunc13  ;($0A0C)
     jp gkfunc21
gkfunc3: ;($0A43)
     ld c, b
     ld a, (bc)
     dec de
     ex de, hl
     inc (hl)
     djnz gkfunc13 ;($0A0C)
gkfunc21:   ;enter here twice due to some addressing inconsistancies...check for double pop
gkfunc27: ;($0A4A)
    pop bc  
    dec b
    jp nz, gkfunc14 ;($09A9)
   pop hl
   ld a, ($8050) ;program name pointer/op3exp
   and a
   jr z, gkfunc15 ;($0A61)
gkfunc14: ;($09A9)
   ld hl, $8050  ;program name pointer/op3exp
   call gkfunc16 ;($1B55)
   RRD
  pop hl 
  dec hl
  push hl
   push bc
    ld a, (hl)
    ld c, a
    and $0F
    jr z, gkfunc24 ;($09FA)
    ld b, a
;-----same as gkfunc13: ;($0A0C)
gkfunc25: ;($09BC)
    ld de, $8058        ;OP3ext
    ld hl, ($8041)      ;somewhere in op1
    ld a, (de)
    add a, h
    daa 
    ld (de), a
    dec de
    ld a, (de)
    adc a, l
    daa
    ld (de), a
    dec de
    ld hl, ($803F)  ;somewhere in op1
    ld a, (de)
    adc a, h
    daa
    ld (de), a
    dec de
    ld a, (de)
    adc a, l
    daa
    ld (de), a 
    dec de
    ld hl, ($803D)
    ld a, (de)
    adc a, h
    daa
    ld (de), a
    dec de
    ld a, (de)
    adc a, l
    daa
    ld (de), a
    dec de
    ld hl, ($803B)
    ld a, (de)
    adc a, h
    daa
    ld (de), a
    dec de
    ld a, (de)
    adc a, l
    daa
    ld (de), a
    jp nc, gkfunc26 ;($09F8)
    dec de
    ex de, hl
    inc (hl)
gkfunc26: ;($09F8)    
    djnz gkfunc25 ;($09BC)
gkfunc24: ;($09FA)
    ld hl, $8050
    call gkfunc16 ;($1B55)
    rrd
    ld a, c
    rra 
    rra
    rra
    rra
    and $0F
    jr z, gkfunc27 ;($0A4A)
    ld b, a
    jp gkfunc13 ;($0A0C)

gkfunc15: ;($0A61)
   call gkfunc18  ;($1A50)
   bit 6, (IY+$0E)  ;unknown 
   ret nz
   jr gkfunc19   ;($0AA0)
gkfunc19: ;($0AA0)
   ld a, ($8039) ;OP1
   and $80
   ld ($8039), a ;OP1
   ld hl, $8042
   ld a, (hl)
   ld (hl), 00
   dec hl
   add a, $B0
   ret nc
   call gkfunc28;($1BF8)
   ret nc
   inc hl
   ld (hl), $10
   jp gkfunc29;($1EBB)
gkfunc22: ;($1A0A)
   ldi
   ldi
   ldi
   ldi
   ldi
   ldi
   ldi
   ldi
   ret 
gkfunc18: ;($1A50)
   ld de, $803B ;op1M
   ld hl, $8051 ;op3M
   jr gkfunc22  ;($1A0A)
gkfunc16: ;($1B55)
   xor a
   rrd
   inc hl
   rrd
   inc hl
   rrd
   inc hl
   rrd
   inc hl
   rrd
   inc hl
   rrd
   inc hl
   rrd
   inc hl
   rrd
   inc hl
   ret 

gkfunc29: ;($1EBB)
   ld hl, $803A
   inc (hl)
   ret nz
   jp gkfunc31 ;($2B6F)

gkfunc28: ;($1BF8)
   ld a, 01h
   ld b, 07h
   or a
gkfunc30: ;($1BFD)
   adc a, (hl)
   daa
   ld (hl), a
   ret nc
   dec hl
   ld a, 00
   djnz gkfunc30 ;($1BFD)
   ret
gkfunc7: ;($20CC)
      push af
       ld a, 7
       call gkfunc8 ;($07AC)
       out ($10), a
      pop af 
      ret 
gkfunc8: ;($07AC)
      push af
       inc hl
       dec hl
      pop af
      ret 
gkfunc9: ;($20D6)
      push af
       ld a, 05h
       jr gkfunc23 ;($20CF)
gkfunc23: ;($20CF)
       call gkfunc8 ;($07AC)
       out ($10), a 
      pop af
      ret
gkfunc31: ;($2B6F)
      ld a, $81
      jr gkfunc32 ;($2B75)
gkfunc32: ;($2B75)
      jr gkfunc33 ;($2BE5)
gkfunc33: ;($2BE5)
      ld ($8256), a
      ld a, $C0
      out (00), A
      res 2, (IY+$12)
      ld sp, ($8257)
      ld hl, ($930F)
     pop de
     add hl, de
     ld ($9311), hl ;9319h = PTR to start of prog/list sym table entries (they count backwards, ie 9310 = next);84fd
    pop de
    ld hl, ($930B)  ;9319h = PTR to start of prog/list sym table entries (they count backwards, ie 9310 = next)
    add hl, de
    ld ($930D), hl  ;9319h = PTR to start of prog/list sym table entries (they count backwards, ie 9310 = next) 
   pop hl
   ld ($8257), hl   ;errNo?
  pop af
  push af
   bit 4, a     
   jr z, gkfunc34 ;($2C14)
   ld a, $D0
   out (00), a
   jr gkfunc35 ;($2C18)
gkfunc34: ;($2C14)
   ld a, $C0
   out (00), a
gkfunc35:   
  pop af 
  res 4, a      ;|ack linkport or mem mapping
  out (02), a   ;|
  ld a, ($8256) ; 3 after penrow. rclQueueEnd?
  ret 
gkfunc1: ;$2E8C
 push hl
  push hl
   push af
    push de
     push hl
      ld hl, $000B
      add hl, sp
      ld d, (hl)
      dec hl
      ld e, (hl)
      in a, (02)
      ld (hl), a 
      in a, (0)
      bit 4, a   ;memory mapping mode = (02)[3]
      jr z, gkfunc4 ;$2EA3
      set 4, (hl)
gkfunc4: ;($2EA3)
      dec hl 
      ld (hl), $2E
      dec hl
      ld (hl), $CF
      dec hl
      dec hl
      ld a, (de)
      inc de
      ld (hl), a
      inc hl
      ld a, (de)
      inc de
      ld (hl), a
      ld a, (de)
      cp 08h
      jr c, gkfunc5 ;($2EC3)
      sub 08h
gkfunc5: ;($2EC3)
      or $88        ;turn on bits 3&7 (memory 256kROM to 32kRAM mapping sequence)
      out (02), a   ;
      ld a, $C0
      out (00), a   ;pull down lines & change memory mapping mode
gkfunc6: ;($2ECB)
    pop hl
   pop de 
  pop af
  ret 


       
progNamePTR:    .EQU     $8050
op3exp:         .EQU     progNamePTR