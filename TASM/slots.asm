;-------------------------------------------------------------------------
;Slots - by M1nzfrischer
;
;
;       (C)2024
;
;-------------------------------------------------------------------------
;
;
;TODO:
;
;2/16:
;can save a full animated spin into slot_fin_state
;  [ ]get 2nd spin forward working
;  [ ]re-impl win check & anim
;[ ] create a more general to-draw function, that draws, not just board state, but
;       [ ] can draw from an array of coordinates that map to 
;        drawCol 1 2 3 4 5 xx  ;1 draws winBox, 0 skips
;            [ ] 0 1 0 1 0 00  ;row 1
;                1 0 1 0 1 00  
;                0 1 0 1 0 00
;
;[ ] how much does 100% largeIonSprite affect performance?
;
;[ ] re-seed the RNG with variable contents of calc (userVars etc)
;[ ] remove IONFastCopy and replace with IONFastCopy(if IONFastCopy isn't modified).  Modified?  N                  
;[ ] add	a,(64/2)-(32/2) ;self modification division to solve symbol ratio performance()
;[ ] all lines marked with ##, FIX for 16byte accuracy.(when L > $FF, requiring full HL addr.)
;[ ] self mod HL, BC, Offset macro?
;[ ] make sure IY usage isn't destorying system VARs.
;[ ] make sure all memory wipes are accurate (win_anim_array & win_states_)
;[ ] log symbol also in slot_win_states?     (symbol, line#, inArow) (x, y) too? so anim_wins is easier.
;[ ] how to clear stack & exit cleanly?
;[ ] FIREBALLS? 
;[ ] spin with the winner, win with the spinner
;[ ] draw line through winning payline being animated | or win box?
;[ ] turn off split screen modes to ensure lines draw correctly always
;[ ] merge ANDSrite, XORSprite & ORSprite into same routine - should take a parameter
;[ ]* move all clearable memory on-top of eachother, so we can LDIR them all in 1 command.
;[ ] sticky keys need to be handled on actual hardware, if so
;[ ] re-set all IY flags on a smart exit function (all items are ending up highlighted after exit)

;//////////////////test commands\\\\\\\\\\\\\\\\\\\\
; ei \ halt
;Pause:
;  DI                  ; disable interrupts
;  LD  A, 01           ; bit 3 = lcd status
;  OUT ($03), A        ; bit 0 = ON-interrupt status
;  EI                  ; enable interrupts
;  HALT                ; wait for ON (that's the only interrupt)
;  RET

   .nolist              ;\
   #include "ion.inc" 
   ;#include "ion8x.inc"
   ;#include "ti83plus.inc"  ; \
   .list                ;  \
#ifdef TI83P            ;   \
   .org  progstart-2    ;    | Standard Ion
   .db   $BB,$6D        ;   /  Program Header
#else                   ;  /
   .org  progstart      ; /
#endif                  ;/
   ret                  ; use xor a if libraries are not used
   jr    nc,start       ; jump to the start
                        ; of the program
   .db   "zslots by m1nzfrisher",0
COORD   .equ    8A3Ah


START:         

               LD    (startSP), SP                 ;save the originating stack pointer for debugging & clean exits
               SET   textWrite, (IY+sgrflags)      ;set flag to write text to grbuffer, not screen.
               SET   textInverse, (IY+textFlags)   ;invert text
              ; SET   0, (IY + 60)                  ;IY+60=plotflags3, b0=bufferOnly
Begin:         LD   HL,$0000
               LD   (COORD),HL
               ;turn flags off
 
               CALL updateBet

   
;turn off interrupts
               di

;Set the calc to the highest speed
               ;in a,(2)
               ;rla
               ;sbc a,a
               ;out (20h),a 
               bcall(_GrBufClr)                    ;clear graph buffer(plotSScreen)
               ;LD   HL,PLOTSSCREEN		;sets half LCD black
               ;LD   DE,PLOTSSCREEN+1
               ;LD   (HL),$FF
               ;LD   BC,64*12
               ;LDIR

               jp spin                  ;first game, no animation of spinning
;make sure there's enough money
prep_spin:       
               ld HL, (new_money)
               LD (money), HL           
               ld A, 0
               ld (cur_win_total), A
               ld (cur_win_total+1), A

;[ ] if in the middle of a current spin
;[ ] immediately stop reels & save to fin_state
;[ ] then check wins
        ;if 1, animate until next enter is pressed
        ;if 0, isWaiting = 1, spinning =0
               ld a, (bt_flags)
               ;counting and waiting = false
               and %11110011
               ;spinning is flipped
               xor %10
               ld (bt_flags), a
               and %10          
               jp z, stopSpin

update_display:
               
               LD HL, _NUM_XY_MONEY
               LD (PenCol), HL   
               LD HL, (money)     ;HL is now new money +1$  
               bcall(_setxxxxop2)          ;puts 16bit(xxxx) HL into OP2
	           bcall(_op2toop1)            ;OP2 to OP1   
	           bcall(_dispop1a)            ;write OP1 to screen, at (PenCol, PenRow)

               call resetBoardMask
               LD   HL,win_anim_array		            ;wipe animation array, for next spin
               LD   DE,win_anim_array+1
               LD   (HL),$00
               LD   BC, 24
               LDIR

               LD   HL,slot_win_states		            ;zero out the mem
               LD   DE,slot_win_states+1
               LD   (HL),$0F
               LD   BC, 43
               LDIR

               ld a, (bt_flags)
               res isWin, a
               ld HL, (money)
               ld DE, (_totalBet)
               SBC HL, DE
               ret c
               ld (money), HL
               LD (new_money), HL     
               ;all is refreshed, check if SPIN cancelled a bonus win animation
               bit isBonus, a
               ld (bt_flags), a
               jp nz, begin_BONUS
spin: 
               ;LD   HL, slot_cur_reel_state         ;set our pointer to beginning of board state
               ;LD   (data_p+8), HL                    ;hl = value@data.p
    
               LD   HL,win_anim_array  		        ;zero out the mem
               LD   DE,win_anim_array+1
               LD   (HL),$00
               LD   BC, 24
               LDIR

               LD   HL,bonus_loc 		        ;zero out the mem
               LD   DE,bonus_loc+1
               LD   (HL),$FF
               LD   BC, 13
               LDIR

               ld HL, slot_win_states    
               ld (data_p+6), HL          ;data_p6 will hold offset for storing data INTO slot_win_states 
       
               ;call draw_layer_machine                   ;machine
               call draw_mask_layer
               call draw_layer_fillbg_top                ;black out                    
               bcall(_GrBufCpy)                  ;buffer(plotSScreen) to display
      

               ; show me the money!!------------------------
               LD     HL, _TEXT_XY_CREDIT               
               LD     (PenCol), HL              ; PenCol comes before PenRow- 
              ; LD     HL, symbols+coin+_name

               ;LD hl, $0003
               ;LD de, 1000
               ;call mult
               ;ld DE, (money)
               ;add HL, DE
               LD HL, money_string
               bcall(_VPutS)

               LD HL, (money)
               bcall(_setxxxxop2)          ;puts 16bit(xxxx) HL into OP2
	           bcall(_op2toop1)            ;OP2 to OP1   
	           bcall(_dispop1a)            ;write OP1 to screen, at (PenCol, PenRow)

               call draw_rmenu             

               call genStore_15_rng
               ld a, (bt_flags)
               cp isFirstGame
               jr nz, skip_chk_win     
               ;LD a, $34
               ;LD (aO), a                   ;update offset into coordinates data for Save_state
               ;LD HL, (slot_saved_reel_state)
               ;call chk_win_prep

;have to press spin to get here
;may also be cancelling isSpinning animation of previous reel
;Purpose: drop old board 2 full iterations (20 pixels) so there is a smooth transition
;         into the new board state

;arrays should terminate with $FF
;-load sprite array offset array into data_p pointer

skip_chk_win:   
                RES isFirstGame, a 
                ld (bt_flags), a          
                ld HL, slot_cur_reel_state
                ld (data_p+8), HL
                ;ld HL, win_anim_array
                ld a, $1A               
                LD (aO), a
                jp draw_prep
                ;ld (WIN_ARRAY_OFF), A      ;0 if anim, $10 if cur_state 
from_main:      

                ld a, (bt_flags)
                bit isWaiting, a
                jp nz, MAIN_LOOP_PREP
draw_prep:      

skip_Auto_Stop:            
                ;call draw_layer_machine   
                ld a, (bt_flags)
                bit isWin, a
                call z, draw_top_layers
                call draw_sarr_at_xarr_yarr
nfwpass:        call draw_layer_fillbg_top 
      ;-----    
                ld a, (bt_flags)
                and %10000              ;iswin?
                call z, draw_layer_fillbg_low

                LD HL, _TEXT_XY_CREDIT
                LD (PenCol), HL        
                LD HL, money_string
                bcall(_VPutS)
                LD HL, _NUM_XY_MONEY               
                LD (PenCol), HL              ; PenCol comes before PenRow- 
                LD HL, (money)
                bcall(_setxxxxop2)          ;puts 16bit(xxxx) HL into OP2
	            bcall(_op2toop1)            ;OP2 to OP1   
	            bcall(_dispop1a)            ;write OP1 to screen, at (PenCol, PenRow)
                call IONFastCopy

                ld a, (bt_flags)
                bit isSpinning, a
                jp nz, advance_Spin_Anim
adv_Spin_CB:    

                ;if 
                ld a, (bt_flags)
                bit isWin, a
                jp z, MAIN_LOOP_PREP
                bit isSpinning, a
                jp nz, MAIN_LOOP_PREP            

;sudo:
;WINIMATE()
;if k>1, JP TIMERLOOP_: (whatever is on screen stays for 9 cicles max)
;L1: 
;    clear bottomLeft
;    disp P6  
;    p6++
;    k = 1   
;     
;TIMERLOOP_:
;for (; k<=10, k++)                 ;wait 10
;    skip to MoneyCounting
;display next or total? 
;if (p6[i+1]!=0),                   ;more data to display
;    update p6?(if not updated)
;    jp L1                          ;10 more with new data

;ELSE:  (no more data to display, jump to total, wait 10, reset)
;     clear bottomLeft
;     disp total
;     k = 2                     ;will run 9 iterations
;     p6 = slot_win_states       ;reset p6
;     fall
draw_flash_wins:           

               ;data_p6 holds the start of the win array here. never empty at i=0

               LD a, (cflags)
               cp $01               ;cant check against 0
               jp nz, timerloop_

               ;draw first winning text
               LD HL, _TEXT_XY_TOPBC             ;bottom of top(needs to be centered) text
               LD (PenCol), HL
               LD HL, top_win_str1
               bcall(_vPutS)
               call IONFastCopy             
dfL1:         
               call draw_layer_fillbg_low
               LD HL, _TEXT_XY_WINSTR       ;bottom left align pen
               LD (PenCol), HL
               LD HL, bot_win_clear
               bcall(_vputS)
               LD HL, _TEXT_XY_WINSTR       ;bottom left align pen
               LD (PenCol), HL

        ;display p6

               LD HL, (data_p+6)
               inc hl
               ld (data_p+6), HL
               LD A, (HL)            
               bcall(_setxxop1)            ;place A into OP1
	           bcall(_dispop1a)            ;write OP1 to screen, at (PenCol, PenRow)          
                                           ;x in a row                          
               LD HL, bot_win_str1
               bcall(_vputS)               ;"3 x "
               
               LD HL, (data_p+6)
               inc HL
               LD A, (HL)               ;symID
               inc HL                   ;1st byte of total
               LD (data_p+6), HL
               LD HL, slot_sprites
               ADD A, A                    ;E contains 1-8 result of the rng symbol
               ADD A, A                    ;(1-8)*8 = sprite offset
               ADD A, A 
               ld HL, slot_sprites
               ld (P_), HL
               call jumpAfromP_
               LD A, (penRow)
               LD L, A
               LD A, (penCol)
               call XORSPR
               LD A, (penCol)
               ADD A, $0A
               LD (penCol), A
                ;cur line win total
               LD A, '='
               bcall(_VPutMap)            
               LD A, ' '
               bcall(_VPutMap)            
               LD A, '$'
               bcall(_VPutMap)            

               LD HL, (data_p+6)            ;translate total into printable HL  
               LD A, (HL)                   ;1st byte                                                                          
               INC HL                       ;----
               LD B, (HL)                   ;2nd byte
               inc HL 
               LD (data_p+6), HL            ;update p6 next win or 0F
               LD L, A                      ;
               LD A, B                      ;
               LD H, A                      ; 

               bcall(_setxxxxop2)           ;puts 16bit(xxxx) HL into OP2
	           bcall(_op2toop1)             ;OP2 to OP1   
	           bcall(_dispop1a)             ;write OP1 to screen, at (PenCol, PenRow)
               call IONFastCopy

        ;k = 1
        ;p6 is pointed to next win item.
              ld a, 1
              ld (cflags), a
timerloop_:    
              inc a
              ld (cflags), a
              cp $40                ;timer betwixt data total displays
              jr c, NoResetWinText
                ;1st win displayed. waited 10 cycles.  what are the states?
                    ;-1st win displayed correctly on screen "3 x K = $45
                    ;-p6 points to slot_win_states[0]
             

              ;--waited 10 - next win or total
              LD HL, (data_p+6)
              LD A, (HL)
              cp $0f                ;nz = more wins exist, jump back to dfL1
              jp nz, dfL1
;             ELSE:  (no more data to display, jump to total, wait 10, reset)
dispTotal:      
        ;display total
              call draw_layer_fillbg_low
              LD HL, _TEXT_XY_WINSTR       ;bottom left align pen
              LD (PenCol), HL
              LD HL, bot_win_str2
              bcall(_vputS)
        
              LD HL, (cur_win_total)
              bcall(_setxxxxop2)          ;puts 16bit(xxxx) HL into OP2
	          bcall(_op2toop1)            ;OP2 to OP1   
	          bcall(_dispop1a)            ;write OP1 to screen, at (PenCol, PenRow)
              call IONFastCopy            
        ;k = 2
              ld a, $02
              ld (cflags), a
        ;p6 = slot_win_state
              ld HL, slot_win_states
              ld (data_p+6), HL

NoResetWinText:              
               LD HL, win_anim_array
               LD (data_p+8), HL
               ;PUSH HL
               LD A, $00
               LD (aO), A 
               ;CALL DELAY

               ;chk_win turned counting on immediately.  Keep counting until 'MoneyCounted:; is reached
               ld a, (bt_flags)    
               and %100         ;isCounting?
               CALL nz, _count_up
               ;POP HL
               ;enter with these lines to skip rng and debug custom board from state.

               ;ld hl, slot_cur_reel_state
               ;ld (data_p), hl
               ;jr draw_COL

MAIN_LOOP_PREP: 

;draw_box:               
               ;;initialize x,y
               ;LD   HL, $0008           ;x
               ;LD   (COORD), HL
               ;LD   HL, $0017           ;y
               ;LD   (COORD+1), HL
               ;CALL chk_win_prep

               ;Setup the keyboard to read from the group containing [ENTER] through [CLEAR]
               LD a,%11111101
               out (1),a

               in a,(1)
               and 40h
MAIN_LOOP:     
	            ;bcall(_GetKey)
	            ;CP kYequ
	            ;CALL Z,SINGLE_BET
	            ;CP kWindow
	            ;CALL Z,DOUBLE_BET
                ;CP kEnter
                ;CALL Z,SPIN_ENTER
                ;CP kClear
                ;jr nz, MAIN_LOOP

                ;CALL RESET_SCREEN		;recall the background in PLOTSSCREEN

                ;check if [CLEAR] is being pressed
                in a,(1)
                and 40h
                ret z
                in a,(1)
                and 08h
                CALL z,_incMult  
                in a,(1)
                and 04h
                CALL z,_decLines
                in a,(1)
                and 02h
                CALL z,_incLines                
                ;check if [ENTER] is being pressed
                in a,(1)
                and 01h
                jp z,prep_spin
 
                jp from_main
;advancing old symbols down off of the board, animating, dropping new symbols in
;---symbols are generally turned OFF at this point
;---HL = pointer to array to be drawn.

advance_Spin_Anim:

               ld a, (reelTimer)
               cp _GAMESPEED_
               jr z, copyFrozenReelToFinal
               
               ld a, (spinAnimCount)
               cp $14
               jr nc, pushBottomRowToTop

               inc A
               inc A
               inc A
               inc A
               
               ld (spinAnimCount), a 

               jp adv_Spin_CB
pushBottomRowToTop: 
                ret
              ; jp $9D95 - testexit
                ld a, 0
                LD (spinAnimCount), a
                ld a, (reelTimer)
                inc a
                ld (reelTimer), a
                ;we want to shift, draw, then save -> mandate autostop
                call rotate_5x5

                ;put bottom
 
                ld a, (reelTimer)
                cp $07            ;how many spins before reel autostops
                jp nz, adv_Spin_CB
                ;a reel has autostopped
skipNextShift:  
                ld a, (spinningReelNo)
                inc a
                ld b, a
                ld (spinningReelNo), a
                cp $05
                jp nc, quitSpinning_checkWin
                ld a, 0
                ld (reelTimer), a              

                call mpl
                LD (data_p+8), IX       ;get draw pointer to new offset mem.addr.
                ;LD HL, (data_p+8)
                ;LD (data_p), HL

                ;ANDsprite Xcoord gets shifted right 16bits
                ;so that only spinning reels get spun

                LD a, (maskXYWH)
                add a, $10
                LD (maskXYWH), a
                LD a, (maskXYWH+2)
                dec a
                dec a
                ld (maskXYWH+2), a

                jp adv_Spin_CB

;HL+(5b)->IX->(data_p+8)
;preconditions:
;   b=multiplier
;   a=0                   
copyFrozenReelToFinal:
                halt
                halt

                ld a, (spinningReelNo)
                inc a
                ld b, a
                ld a, 0
                call mpb       
                LD (P_), IX     
                LD HL, (P_)

                LD BC, $0034
                SBC HL, BC
                EX  DE, HL
                LD HL, (P_)
                LD BC, 5
                LDIR                 
                ;1st entry condition
                ;LD HL, slot_cur_reel_state
                ;LD BC, $0034
                ;SBC HL, BC
                ;EX DE, HL
                ;LD HL, slot_cur_reel_state
                ;LD DE, slot_cur_reel_state-52
                ;LD BC, 5
   
                jr skipNextShift

mpl:            add a, 5
mpb:            
                DJNZ mpl

                ;[ ] need to move the locked column into a staging area ()
                ld   HL, slot_cur_reel_state
                ld   (P_), HL
                call jumpAfromP_
                ret

stopSpin:       
                ;save rest of board over to fin_state
                ;wherever datap+8 is, copy rest
                ;it will draw the rest when we turn isSpinning off
                ld a, 0
                ld (spinAnimCount), a
                LD HL, slot_cur_reel_state+26
                LD DE, (data_p+8)
                SBC HL, DE
                ld A, L
                LD HL, (data_p+8)
                LD BC, $0034
                SBC HL, BC
                EX DE, HL
                LD HL, (data_p+8)
                ld B, 00h
                ld C, A
                LDIR
                LD HL, slot_fin_reel_state
                LD (data_p+8), HL
                call resetBoardMask         ;spin cancelled, clear board & redraw
                call draw_top_layers
                ld a, $4E
                ld (aO), a     ;offset to draw fin_state x,y's
                call draw_sarr_at_xarr_yarr
                call draw_layer_fillbg_top
                call IONFastCopy


quitSpinning_checkWin:
;isFirstGame:    .EQU     0
;isSpinning:     .EQU     1
;isCounting:     .EQU     2
;isWaiting:      .EQU     3
;isWin:          .EQU     4
                call chk_win_prep          ;the only place checkWin is invoked.  Only way to set isWin
                ld a, 0
                ld (spinningReelNo), a
                ld (reelTimer), a
                ld (spinAnimCount), a

                ld a, (bt_flags)
                res isSpinning, a
                bit isWin, a
                ld (bt_flags), a
                jp nz, nfwpass
                
noWINfo:        or %1000                    ;isWaiting = true if no win
                ld (bt_flags), a
                ;call resetBoardMask
                ;call delay
                jp draw_prep
                
resetBoardMask:
                ld a, $02
                ld (maskXYWH), a
                ld a, $16
                ld (maskXYWH+1), a
                ld a, $09
                ld (maskXYWH+2), a
                ld a, $20
                ld (maskXYWH+3), a

                ret

;take bottom 2 rows, move to top
;shift top 3 rows down 2.
rotate_5x5:     LD HL, slot_cur_reel_state+15
                LD DE, slot_saved_reel_state+15
                LD BC, 10
                LDIR
                LD HL, slot_cur_reel_state+10
                LD DE, slot_cur_reel_state+20
                LD BC, 5
                LDIR
                LD HL, slot_cur_reel_state
                LD DE, slot_cur_reel_state+10
                LD BC, 10
                LDIR
                LD HL, slot_saved_reel_state+15
                LD DE, slot_cur_reel_state
                LD BC, 10
                LDIR   
                ret

;checks win conditions against board condition for payable circumstance
;payrules[9lines][5rules]:          Each rule contains a cur_reel_state offset per payline
;cur_reel_state:                    current board spun into
;slot_cur_reel_state:  
;           1     2    3               5....                       A    B                             ;term 
;    .db    $02, $03, $04, $02, $03,   $04, $02, $03, $04, $02,    $03, $04, $02, $03, $08,    $0F
;
;pay_rules:   
;    .db    $02, $05, $08, $0B, $0E              ;pay line 1
;    .db    $01, $04, $07, $0A, $0D              ;         2-3
;
chk_win_prep:  
               ld a, 0
               ld (COORD), a    ;y axis of 2D array
CHK_WIN:   
;19EC2        
               LD HL, pay_rules
               ;jump to next row of pay rules    

               LD B, A
               cp 0            ;check if on the first line *A=slot_win_states[0], first win line#
               jp z, skip_m
               ld a, 0          
mtpl:          
               add a, 6
               djnz mtpl       
skip_m:
               LD HL, pay_rules
               LD (P_), HL
               call jumpAfromP_
               LD (data_p), IX
               LD C, 0
chk_loop:     
;19EFA
               LD A,  (IX)                      ;offset aka (rule[i])   
               DEC A                            ;offsets need to be zero index,
               LD HL, slot_chk_win_state       
               LD (P_), HL  
               call jumpAfromP_     
               LD A, (IX)            ;A holds first reel symbol to compare**correct
               cp $09                ;if bonus symbol, skip
               jr z, bon_skip
                         
chk_loop2:
;19EE7     
               ld hl, (data_p)  
               INC hl                ;point to next pay rule  
               ld (data_p), hl   
               LD B, A               ;move A temporarily for use in jumpA routine          
               LD  A, (HL)           ;next offset
               DEC A                 ;offsets need to be zero index,    
               LD HL, slot_chk_win_state
               LD (P_), HL 
               CALL jumpAfromP_
;19F03    
               LD E, (IX)   ;2nd reel to compare
               INC C
               LD A, B      ;get 1st compare symbol back into A, for comparison with E              
               cp E         
               jr z, chk_loop2
                        
               ;a no match condition has been reached.  
               ld B, A                          ;b = symbolID for saving in win_log
               ld a, c
               cp 3                             ;was a win booked before matches ended?
               call nc, win_log                 ;deal with win & return to find new wins
              
bon_skip:      ld HL, COORD                     ;COORD=(statvars)18A3A
               ld a, (HL)  
               INC A                            ;go to next set of pay_rules (Ycolumn)
               ld (COORD), A
               ld d, a
               ld a, (_lines)
               ld b, a
               ld a, d
               cp b                             ;no. of paylines
               jr c, CHK_WIN
               ;all normal wins are logged   
               call checkForBonus
               ld HL, slot_win_states        
               ld a, (HL)
               cp $0F
               call nz, classify_wins

               ret

;checks full board for a bonus condition
checkForBonus:
               ;ld a, (bonusCount)
               ld c, 0
               ld d, 1              ;counter to identify board position
               ld IX, bonus_loc     ;pay_rules[A]
               ld HL, slot_chk_win_state

               
bonC_lop_i:    ld b, 3              ;
               inc d
               inc d
               inc HL
               inc HL
bonC_lop_j:     ld a, (HL)
                cp 09h       
                jp nz, noB
                inc c 
                ld (IX), d
                inc IX             
noB:            inc HL
                inc d
                djnz bonC_lop_j
               ld a, (HL)
               cp 0fh 
               jr z, bonC_end
               jr bonC_lop_i 
bonC_end:      ld a, c
               cp $06                   ;[ ]change to 4 bonus symbols on release copy
               jr nc, thereIsABonus
               ret

               ;THERE IS A BONUS
thereIsABonus: ld a, (bt_flags)
               or %100000
               ld (bt_flags), a
               ld a, 09h        ;line number for bonus (payrule 10-1 for index)
               ld b, 09h        ;symID
               call win_log_bonus     ;log the bonus win
               ret

begin_BONUS:
    ld A, 3
    ld (heartCount), A

    call draw_layer_fillbg_low
    call draw_layer_fillbg_top
    ;draw bonus in top_lower
    ;bottom says, "press ^ to begin"
    ld HL, _TEXT_XY_TOPBC
    LD (PenCol), HL
    LD HL, top_win_BON
    bcall(_VputS)

    ld HL, _NUM_XY_MONEY
    LD (PenCol), HL
    LD HL, text_bot_expl1
    bcall(_VputS)
    call IONFastCopy

    LD a,%11111101
    out (1),a

    ;check if [^] is being pressed
    in a,(1)
    and 20h
    jp z, _BONUS
    jr begin_BONUS
_BONUS:
    call draw_mask_layer
    ;call draw_layer_machine
    call draw_layer_bonus_bg

    
_BON_GK:    
    LD a,%11111101
    out (1),a

    ;check if [^] is being pressed
    in a,(1)
    ;and 04h
    and 01h
    jp z, _BONUS_COUNTDOWN
    jr _BON_GK

_BONUS_COUNTDOWN:
    call draw_layer_fillbg_low
    ;call draw_layer_machine
    call draw_mask_layer
    ;call draw_layer_machine
    call bon_redraw 
    ld hl, _NUM_XY_MONEY
    ld a, l
    ld l, h
    ld b, 8
    ld ix, bonus_enemy1
    call ionPutSprite
    
    ld hl, _NUM_XY_BOPCNT
    dec l
    dec l
    ld (penCol), hl
    ld A, ':'
    bcall(_VputMap)
    ld A, '0'
    bcall(_VputMap)

    ;call draw_layer_fillall
    call IONFastCopy
    call delay
    jr _BONUS_LOAD_ENEMY

_BONUS_ENEMY_SCHEDULER:
        ;flip coin
        ; if true, rng1-9
        ;   spot taken? skip
        ;   not taken? place enemy on location (frame 1)
    call rng8toA
    cp 91h
    jr nc, _bonLPrep
_BONUS_LOAD_ENEMY:
    call rng8toA
    cp $1C
    jr c, rngAis8
    AND  7
    jr rngAno8
rngAis8:        
    ld A, 8
rngAno8:  
    ld b, a
    ld hl, bonusBoard
    ld (P_), hl
    call jumpAfromP_
    ld a, (IX)
    or %0
    jp nz, _bonLPrep  ;enemy already in location
    ld a, (bonusLvl)
    or %0
    jp z, lvl1enemy
    call rng8toA
    ld b, a
    cp 99h
    jr nc, lvl1enemy
    ;zxc
    ld a, (bonusLvl)
    and b 
    inc a 
    ld (IX+20), a                ;spike baddy
    jr allEnemyPrep
lvl1enemy:
    ld (IX+20), $00   ;enemy type = 0, lvl1 enemy   
allEnemyPrep:    
    ld (IX), 01h      ;no enemy in location, place new enemy @ frame1
_bonLPrep:
    ld hl, bonusBoard
    push hl
;loop through all 9 board spots(hl), 
;   is sprite done?
;       animate a miss && -1 heart
;       ret
;   is sprite at peek? ret for (enemyTimer)
;   not at peek?
;       mask whole position from upperLeft to LowerRight
;       draw sprite at current frame, in correct adjusted yPos
;       frame++
;------------SWATS--------------------------
;   zero out swatted, missed, & expired positions

;  requires a pushed bonusBoard pointer in hl
_BONUS_LOOP:
    pop hl          ;bonusBoard Pointer
    ld a, (hl)
    cp $F0
    jp z, _BONUS_ENEMY_SCHEDULER        ;reached end of BoardChecks, re-cycle
    or %0
    jr nz, _drawBonusFrame
    ;empty position, inc & skip
    inc hl
    push hl
    jr _BONUS_LOOP

;hl contains pointer to frame number of current enemy
;get xy by: 
;   (hl - bonusBoard) -> A
;   call bonusPosAtoXYinHL

_drawBonusFrame:
;has the baddie gone fully underground?
    push hl                 ;board location, holds frame#raw, for incrementing frameNo
        ld a, (hl)              ;rawFrameNo
        dec a                   ;1st frame = 0 position in frame map (1)

        ld de, bonusBoard
        sbc hl, de
        ld c, l                 ;c=board position 123,456,789 
        ld hl, bonusFrameMap
        ld (P_), hl
        call jumpAfromP_        ;(ix) = drawable frame number
        ld a, (IX)
        ld b, a
        push bc                 ;b = drawable frame number, c = board position 0-8
            ld a, c 
            call bonusPosAtoXYinHL
        pop bc
    pop de
    push de 
        push bc 
            push hl         ;xy
                ld a, b     ;drawable frame
                cp 9 
                jr nz, deleteLastBonusFrame
                ;at frame peak of 8
     
                ld a, 0Ah           ;jump 10 to get timer val
                ld (P_), de
                call jumpAfromP_
                ld a, (IX)
                dec (IX)
                ;halt
                jp nz, checkKeyAgainstFullBoard             ;skip drawing if timer is > 0
;waiting is over, descend , reset timer 
                ld a, (enemyTimerMax)
                ld (IX), a
            pop hl     ;xy 
        pop bc          
        dec b          ;update drawable frame to be 8 for smooth descent
    pop de  ;pointer
    ld a, (de)
    inc a
    ld (de), a        ;increase rawframe count
    push de         ;pointer
        push bc     
            push hl    ;xy
;not at peek frame(8)
;c = boardpos, b = drawable frame#
deleteLastBonusFrame:
                ld a, l
                dec a
                ld l, a
                ld a, h  
                dec a

                ld b, 10
                ld c, 2
                ld h, 01h  ;sprite off
                ld ix, _10x16_off     
                call largeSprite
                call IONFastCopy
            pop hl ; xy board pos
        pop bc
        push bc
            push hl
                ld a, b
                cp $F0
                jp z, late_miss    ;[]reached last frame of animation, user hasn't smashed enemy
drawCurrentBonusFrame:
            ;get to center of boardlocation
            pop hl      ;xy for boardPosition []upperLeft, lowerRight
        pop bc          ;b = drawable frame#
    pop de 
    push de
        push bc 
            push hl     ;xy
                ld a, l
                add a, 9    ;6 is height of bonus squares-- a = bottom of square
                sub b        ;a is now adjusted for current frame number
                ld l, a     ;y updated
                ld a, h     ;x
                add a, 5
                push af         ;updated x
                ld h, b 
                    push hl     ;updated b,y
                        ex de, hl
                        ld d, 00h
                        ld e, $14
                        add hl, de
                        ld a, (hl)      ;enemy id
                        ld l, a
                        ;zzc
                        ld h, 00h
                        ld d, 00h
                        ld e, 08h
                        call mult 
                        ld a, l 
                        ld hl, bonus_enemies
                        ld (P_), hl
                        call jumpAfromP_    ;ix now hold correct enemy sprite
                    pop hl 
                    ld b, h ;b
                pop af  ;x
                call ionPutSprite
                call IONFastCopy
            
checkKeyAgainstFullBoard:
                ;getCSC will return 0 if no key has been pressed since last call
                bcall(_getCSC)         ;A = KEY | CSC does not wait for keyPress | returns 0 on nokey pressed|AF/HL die 
                ld c, a
                or %0
                jp z, bGetKeyEnd        ;no key pressed
                cp 12h
                jp c, bGetKeyEnd        ;pressed some key off the number board
                cp 25h
                jp nc, bGetKeyEnd       ;pressed key off board
                ;halt
                ;pressed 1-9
                ld b, 0
                ld hl, kToSK
keyTOPosition:
                ld a, (hl)
                cp $F0
                jr z, bGetKeyEnd            ;should never reach here.  if 1-9 pressed, we should find it in ktosk
                cp c
                jr z, bktoPosFound
                inc b
                inc hl
                jr keyTOPosition
;b = position corresponding to key pressed
bktoposFound:
;check if position contains enemy
                ld a, b
                push af         ;position of pressedKey [0-8]
                    call bonusposAtoxyinhl  ;new xy for animating
                pop af 
            pop de              ;xy of board[i]
            push hl             ;replace with new xy
                ld hl, bonusBoard
                ld (P_), hl
                call jumpAfromP_
                ld a, (IX)          ;position of pressed key
                or %0               ;has enemy?
                jp z, smash_miss
                ;hit
                push ix             ;ix = bonusboard[i]
                    ;ld b, 00h
                    ;ld c, $14
                    ;add ix, bc
                    ld a, (IX+20)
                pop ix
                cp $01              ;is spikey?
                jp nz, smashed_enemy
                ld a, $0F               ;hit spikey code
                jp smash_miss
smashed_enemy:  
                ld (IX), 00h        ;reset smashed enemy
                ld (IX+20), 00h
                ld a, (enemyTimerMax)
                ld (ix+10), a        ;reset timer
                ;ld a, $0D         ;clean smash code
                jp smash        ;smash clears board first    
                ;enemy exists in pressed location            
                ;BIT   kbdSCR, (IY+kbdFlags)
bGetKeyEnd:
            pop hl    ;xy 
        pop bc        ;drawable frame #
    pop hl            ;frame pointer
    ld a, b
    cp 9
    jr z, baddieOnBreak
    inc (hl)          ;rawFrame# ++
baddieOnBreak:    
    inc hl            ;bonusBoard[i++]
    push hl           ;required by _BONUS_LOOP
        call delay    
  
        jp _BONUS_LOOP

;Sent here because user didn't smash enemy in time   
;stack: 
;   hl(xy), bc(dFrame,loc), *hl(boardPointer)
;* = need to leave at this point before jumping back into _BONUS_LOOP
late_miss:
            pop hl      ;xy
        pop bc          ;drawFrame []draw something in spot missed "TOO SLOW"
    pop ix              ;boardPT
    ld a, 0
    ld (ix), a
    ld a, (enemyTimerMax)
    ld (ix+10), a        ;reset timer
    push ix             ;required
        push bc         ;empty req for bgetkeyend
            push hl     ;xy
            ld a, (ix+20)
            cp 01h          ;is spikey guy?
            ld (ix+20), $00
            jr z, smash_hit

                ld hl, _TEXT_XY_TOPMC
                ld (penCol), hl
                ld hl, top_win_BON_2
                bcall(_VPuts)
                call IONFastCopy

                jr lose_a_heart
;f = z if miss
;f = nz if hit 
smash:  
            pop hl 
            call bonus_swing_anim    ;exits with an xy pop into hl
            push hl                  ;    push back on stack
                ;work with live hl vals
                jr smash_hit

smash_miss: 
            pop hl 
            call bonus_swing_anim    ;exits with an xy pop into hl
            push hl 
                LD HL, _TEXT_XY_TOPMC 
                LD (penCol), HL
                LD HL, top_win_BON_0
                bcall(_VPuts)   
                call IONFastCopy
lose_a_heart:    
                ld A, (heartCount)
                cp 1
                jp z, bonus_game_over
                dec a
                ld (heartCount), A
                call redrawHearts

                call IONFastCopy
                jp bGetKeyEnd
smash_hit:
                ld a, (bopCount)
                inc a
                ld (bopCount), a
                ld b, a
                ;zxc
                ld a, (nxtBonus)
                cp b
                jr nz, noLvlUp
                add a, 25
                ld (nxtBonus), a
                ld a, (bonusLvl)
                inc a 
                ld (bonusLvl), a 
                
                ld a, (enemyTimerMax)
                sub $08
                ld (enemyTimerMax), a 
                ;level up anim
                
noLvlUp:        ld hl, _NUM_XY_BOPCNT
                ld (penCol), hl
                ld h, 00h
                ld a, (bopCount)
                ld l, a
                bcall(_setxxxxop2)          ;puts 16bit(xxxx) HL into OP2
	            bcall(_op2toop1)            ;OP2 to OP1   
	            bcall(_dispop1a)            ;write OP1 to screen, at (PenCol, PenRow)

                LD HL, _TEXT_XY_TOPMC
                LD (penCol), HL
                LD HL, top_win_BON_1
                bcall(_VPuts)
            
                jp bgetkeyend            
bonus_game_over:
                ;animate bonus counting
                ld A, (bt_flags)
                SET is1stBonusRoll, A
                LD (bt_flags), A
                bcall(_GrBufClr)
                ;reset bonusboard/reset timers
                call resetBonusInitializers

                jp Begin
bonus_swing_anim:
            dec h
            dec h
            dec h
            dec l
            dec l
            dec l
            push hl
           ; call bonus_swing_anim   
                LD A, H
                LD B, 12
                LD C, 2       ;12
                LD H, 3       ;xor
                LD IX, bonus_hammer1
                call put_any_Sprite
                call IONFastCopy
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer1
                call put_any_Sprite
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer2
                call put_any_Sprite
                call IONFastCopy
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer2
                call put_any_Sprite
            pop hl
            inc h
            inc h
            inc h  
            inc l
            inc l
            inc l       
            push hl
                ld a, l
                dec a
                ld l, a
                ld a, h  
                dec a
                ld b, 10
                ld c, 2
                ld h, 01h  ;sprite off
                ld ix, _10x16_off     
                call largeSprite
                call IONFastCopy
            pop hl
            dec h
            dec h
            dec h
            dec l
            dec l
            dec l
            push hl   
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer3
                call put_any_Sprite
                call IONFastCopy
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer3
                call put_any_Sprite
            pop hl          ;xy
            push hl
           ; call bonus_swing_anim
                LD A, H
                LD B, 12
                LD C, 2       ;12
                LD H, 3       ;xor
                LD IX, bonus_hammer4
                call put_any_Sprite
                call IONFastCopy
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer4
                call put_any_Sprite
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer5
                call put_any_Sprite
                call IONFastCopy
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer5
                call put_any_Sprite
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer6
                call put_any_Sprite
                call IONFastCopy
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer6
                call put_any_Sprite
            pop hl          ;xy
            push hl
           ; call bonus_swing_anim
                LD A, H
                LD B, 12
                LD C, 2       ;12
                LD H, 3       ;xor
                LD IX, bonus_hammer7
                call put_any_Sprite
                call IONFastCopy
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer7
                call put_any_Sprite
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer8
                call put_any_Sprite
                call IONFastCopy
            pop hl
            push hl
                LD A, H
                LD B, 12
                LD C, 2       ;8x8
                LD H, 3       ;xor
                LD IX, bonus_hammer8
                call put_any_Sprite
                call IONFastCopy
            pop hl
                ret
            ;pop af              ;hit miss

;args:
;   A = a board position[0-8]
;returns:
;   HL = (h=x,l=y) coords of A
bonusPosAtoXYinHL:
    LD HL, BON_Y
    LD (P_), HL
    call jumpAfromP_
    ld l, (ix)          ;y for sprite
    ld d, 0
    ld e, 0Ah
    add ix, de
    ld a, (ix)          ;x  
    ld h, a           ;hl = x,y
    ret   


;147AD
;258BE
;369CF

;log win data into slot_win_states (a,c,b,  a,c,b  ...)
;   (COORD) temporarily holds the row of winning offsets to light up
;   a = line number of win   ;c = no. of winning symbols in line ;b = symbolID
win_log: 
               ld HL, COORD         
               ld a, (HL)               ;A = current winning payline#

win_log_bonus: ld HL, (data_p+6)        ;data_p6 holds offset for storing data INTO slot_win_states 
               ld (HL), a               ;Record winning payline# in slot_win_states db
               ;winline print
               ld a, (bt_flags)
               ;W C              ;turn win & counting on 
               or %10100
               ld (bt_flags), a

               inc hl
               ld (HL), c               ;store inArow into slot_win_states (0,1)
               inc hl
               ld (HL), b               ;symbolID-needed for printing win data
               inc hl                   ;skip to win_total
               ld (data_p+6), HL
               ld a, b                  ;get symbol id into A for _pay offset jump
               ;----------------calculate winnings->(p6[4])------------

                ld HL, sym_o
                ld (P_), HL
                ;ld b, c
                call jumpAfromP_
                ld a, (IX)
                add a, _PAY

                ld HL, symbols
                LD (P_), HL
                call jumpAfromP_
                ld a, (IX)                  ;pay 

                ld E, A
                LD D, 00h
                ld L, C
                ld H, 00h
                call mult                   ;total of current win

                ;x multiplier
                ld a, (_multiplier)
                ld e, a
                ld d, 00h
                call mult                   ;updated total

                LD A, L
                LD DE, (data_p+6)
                LD (DE), A
                INC DE
                LD A, H
                LD (DE), A
                INC DE
                LD (data_p+6), DE

            ;**we don't animate here, because we are waiting to poll all winning results
            ;**first, in the _win_anim_array - then draw them at the same time w/ draw_arr_at_arr
               ret

;fill up the win_anim_array, and prep for XORing of winning symbols               
classify_wins:
                ;while slot_win_states !=0,
                ld HL, slot_win_states
                ld (data_p+6), HL
cw_re_entry:
                ld b, (HL)     ;line number of first win
                inc B          ;line# is saved as 0 index for ease of earlier algos--reset base.
                inc hl
                ld c, (HL)     ;3,4, or 5 in a row
                inc hl         ;skip symbolID
                inc hl         ;skip total
                inc hl         ;skip 2nd byte of total
                ld (data_p+6), HL
                ld a, b
                ;get to the line number
                cp 1            ;check if on the first line *A=slot_win_states[0], first win line#

                ld a, 0
                dec B           ;get 0 indexed   
                jr z, skiplo   
jYpp:           
                add a, 6             
                djnz jYpp

;<-----------------A=offset to reach Y axis of pay_rules array.

;for (winStates[j])
;   for (xInArow)
;       slot_cur_reel_state[pay_rule[i]] -> win_anim_array[pay_rule[i]]
                           ;
skiplo:     
;19EFA 
               LD HL, pay_rules                  ;HL = (HL + DE(Offset))
               LD (P_), HL
               CALL jumpAfromP_
               LD (data_p), IX  
               LD A, (IX)                       ;pay_rule[i]

;    for(C = i)               symbolID          
;        slot_cur_reel_state[(data_p[i])] -> win_anim_array[(data_p[i])                  
               DEC A                            ;adjust offset 
               LD HL, slot_chk_win_state       ;HL = (HL + DE(Offset))
               LD (P_), HL
               CALL jumpAfromP_
               LD (data_p+2), IX                ;symbolID pointer

;      for(C = i)
;          (data_p+2) -> win_anim_array[(data_p)]
;------------------
val_to_aro:     
               ;zzz offsets are showing as 2, 5, 8, 11, 14 (wrong winning line than copied from)
               LD HL, (data_p)                  ;we pulled symbol from _state+(data_p), add to _win_anim+(data_p)
               ;DEC L                            ;adjust indexing
fill_sym2wins: LD A, (HL)                       ;A = position where symbol was from/needs to go to
               DEC A                            ;adjust indexing
               LD HL, win_anim_array            ;HL = (HL + DE(Offset))
               LD (P_), HL
               CALL jumpAfromP_
               LD (data_p+4), IX  
    
;--------------------------------------
;(data_p+2)                /////////
; symbolID  -> (data_p+4)  //
;---------------------------

                LD HL, (data_p+2)               ;(data_p+2)                             
                LD A, (HL)                      ;A = symbol to copy into win_anim_array,
                ;**Symbol correct on 1st iteration, repeats wrong after 2nd iteration.
                LD (IX), A                      ;copy symbol in position                                               
                dec C                                        
                LD HL, (data_p)                
                inc HL                          ;point to next pay_rule item
                LD (data_p), HL
                LD A, 0
                CP C
                jr nz, fill_sym2wins                ;need to jump to next pay_rule item ->

                ld HL, (data_p+6)                   ;pointing to L in H,L
                inc hl                              ;skip total

                ld a, (hl)
                LD (data_p+6), HL
                cp $0F
                jp nz, cw_re_entry                  ;jump to next pay_rule row   \/

                call get_total_win_of_spin          ;does all the math for counting & winimation
                ;reset data_p6 pointer
                LD HL, slot_win_states
                LD (data_p+6), HL

                ret
;prints B integers from HL onto the display                
print_arrayOfBytes:
pa_lp:          ld a, (HL)
                inc  HL
                push HL
                push bc
                bcall(_setxxop1)            ;place A into OP1
	            bcall(_dispop1a)            ;write OP1 to screen, at (PenCol, PenRow)
                pop HL
                pop bc
                dec b
                ld a, b
                cp 01h
                jr nz, pa_lp 
                call IONFastCopy
                ret

;animates money counting up towards new total
_count_up:      ;HL is new total, to count to
                ;DE is current balance
                LD HL, (new_money)
                LD DE, (money)
                INC DE
                LD (money), DE
                SBC HL, DE
                jr z, moneyCounted

                ret
moneyCounted:
                ld a, (bt_flags)
                res isCounting, a
                ld (bt_flags), a 
                ret     

;call this once you've classified all wins
get_total_win_of_spin:
                LD HL, slot_win_states
                LD (data_p+6), HL

g_t_l:          inc hl
                inc hl
                inc hl
                push hl
                LD A, (HL)         ;get HL 16bit total into DE
                INC HL
                LD E, A
                LD A, (HL)
                LD D, A

                LD HL, (cur_win_total)
             
                ADD HL, DE

                LD (cur_win_total), HL      ;total $ of payline win
        
                pop hl

                inc hl                      ;2nd byte
                inc hl                      ;next win item
                ld a, (HL)
                cp $0F
                jr nz, g_t_l
                
                LD    BC, _NUM_XY_MONEY
                LD    (PenCol), BC              ; PenCol comes before PenRow-  
                LD    DE, (money)
                LD    HL, (cur_win_total)
                ADD   HL, DE
                LD (new_money), HL

                ret      

;16bit multiplication routine from ZiLog
;de * hl -> hl
mult:
                ld   b, 16
                ld   c, d
                ld   a, e
                ex   de, hl
                ld   hl, 0
mloop:          srl  c
                rra
                jr   nc, noadd
                add  hl, de

noadd:          ex   de, hl
                add  hl, hl
                ex   de, hl
                djnz mloop
                ret
         
;Put large sprite
;B = height
;C = width / 8
; l=yc
; a=xc
; ix holds pointer
XORSPR_L:
              push HL
              LD HL, bonus_symbol
              LD (P_), IX
              LD DE, (P_)
              SBC HL, DE
              pop HL
              jp z, XORSPR_BONUS
              LD   B, 8
              LD   C, 1              
              CALL IonLargeSprite
              ret

XORSPR_BONUS: LD B, 10
              LD C, 2
              dec a
              dec a
              dec a
              dec a
              dec l
              CALL IonLargeSprite
              ret                   

;fully customizable sprite routine
;   any size, and/or/xor
;-----> Draw a picture
;Input:	ix->sprite
;	a=x
;	l=y
;	b=height	(in pixels)
;	c=width		(in bytes, e.g. 2 would be 16)
;   h=off/on/xor
;     (1=off/2=on/else=xor)

;Output: nothing
; All registers are destroyed except bc', de', hl'
; 
; Used for clear masks.  0's will override

;    push af   ;x coord
;     ld a, h
;      cp 01h
;      jp nz, _OnorXor
;      ld a, $A2        ;and d
;      ld (_on_off_d),a
;      inc a
;      ld (_on_off_e),a ;and e
;      jr psprite_begin
;_OnorXor:
;     ld a, h
;     cp 02h
;     jp nz, _xor_sprite
;     ld a, $B2        ;or d
;     ld (_on_off_d),a
;     inc a
;     ld (_on_off_e),a ;or e
;     jr psprite_begin
;_xor_sprite: 
;     ld a, $AA        ;xor d
;     ld (_on_off_d),a
;     inc a
;     ld (_on_off_e),a ;or e  
;psprite_begin:
;    pop af            ;og vals from caller;
;	di
;	ex	af,af'
;	ld	a,c
;	push	af
;	ex	af,af'
;	ld	e,l
;	ld	h,$00
;	ld	d,h
;	add	hl,de
;	add	hl,de
;	add	hl,hl
;	add	hl,hl
;	ld	e,a
;	and	$07
;	ld	c,a
;	srl	e
;	srl	e
;	srl	e
;	add	hl,de
;	ld	de,gbuf
;	add	hl,de
;anySpriteLoop1:
;	push	hl
;anySpriteLoop2:
;	ld	d,(ix)
;	ld	e,$00
;	ld	a,c
;	or	a
;	jr	z,anySpriteSkip1
;anySpriteLoop3:
;	srl	d
;	rr	e
;	dec	a
;	jr	nz,anySpriteLoop3
;anySpriteSkip1:
;	ld	a,(hl)
;_on_off_d:	xor	d
;	ld	(hl),a
;	inc	hl
;	ld	a,(hl)
;_on_off_e:	xor	e
;	ld	(hl),a
;	inc	ix
;	ex	af,af'
;	dec	a
;	push	af
;	ex	af,af'
;	pop	af
;	jr	nz,anySpriteLoop2
;	pop	hl
;	pop	af
;	push	af
;	ex	af,af'
;	ld	de,$0C
;	add	hl,de
;	djnz	anySpriteLoop1
;	pop	af
;	ret

;-----> Draw a sprite
; b=size of sprite
; l=yc
; a=xc
; ix holds pointer
;Output:   Sprite is XORed to the graph buffer.
;ix->next sprite
;Destroys: af bc de hl ix

XORSPR:
                LD   B,8                         ;size of the sprite
                CALL ionPutSprite
                ;CALL ionPutSprite
                RET
;------
buffer_to_backup:  
                LD   HL,PLOTSSCREEN		;save whole screen as background
                LD   DE,SAVESSCREEN
                LD   BC,768
                LDIR
                ret
backup_to_buffer:   
                LD   HL,SAVESSCREEN
                LD   DE,PLOTSSCREEN
                LD   BC,768
                LDIR
                RET

;-----> Draw a picture
;Input:	ix->sprite
;	a=x
;	l=y
;	b=height	(in pixels)
;	c=width		(in bytes, e.g. 2 would be 16)
;Output: nothing
; All registers are destroyed except bc', de', hl'
largeSprite:
	di
	ex	af,af'
	ld	a,c
	push	af
	ex	af,af'
	ld	e,l
	ld	h,$00
	ld	d,h
	add	hl,de
	add	hl,de
	add	hl,hl
	add	hl,hl
	ld	e,a
	and	$07
	ld	c,a
	srl	e
	srl	e
	srl	e
	add	hl,de
	ld	de,gbuf
	add	hl,de
largeSpriteLoop1:
	push	hl
largeSpriteLoop2:
	ld	d,(ix)
	ld	e,$00
	ld	a,c
	or	a
	jr	z,largeSpriteSkip1
largeSpriteLoop3:
	srl	d
	rr	e
	dec	a
	jr	nz,largeSpriteLoop3
largeSpriteSkip1:
	ld	a,(hl)
	xor	d
	ld	(hl),a
	inc	hl
	ld	a,(hl)
	and	e
	ld	(hl),a
	inc	ix
	ex	af,af'
	dec	a
	push	af
	ex	af,af'
	pop	af
	jr	nz,largeSpriteLoop2
	pop	hl
	pop	af
	push	af
	ex	af,af'
	ld	de,$0C
	add	hl,de
	djnz	largeSpriteLoop1
	pop	af
	ret


DELAY:         LD   B,20
LOOP1:         PUSH BC
               LD   B,255
               NOP
               ;call genStore_15_rng
LOOP2:         DJNZ LOOP2
               POP  BC
               DJNZ LOOP1
               RET
    
genStore_15_rng:  
               LD HL, slot_cur_reel_state
               LD (data_p), hl
               LD DE, slot_saved_reel_state
               LD BC, 25    
               LDIR                     ;move previous board to saved area.
               
new_num:
               CALL rng8toA             ;8bit rand -> A register, HL becomes new seed                
               ld e, 1                  ;offset counter, start at 1 instead of 0, to not overflow 
               ld HL, ratio_table    
               ;ld a, 20
               LD d, (HL)               ;first %value in the ratio table (0-40)/255->B
roll_prob:                  
               cp d
               jp c, rollz
               inc hl
               ld d, (HL)
               inc e
               jp nz, roll_prob
rollz:        
               ;ld a, e                             ;Loading 0 into A overflows _setxxop1() 
               LD  HL, (data_p)                     ;_curstate address
               INC E
               LD (HL), e                           ;new data -> indirectly into _curstate 
               INC HL                               ;HL     now points to _curstate+1 address
               LD (data_p), HL                      ;data_p now points to _curstate+1 address
               ld a, (HL)
               cp $0F
               jr nz, new_num
               

               ld hl, slot_cur_reel_state
               ld (data_p), hl
               ret 

rng8toA:
;This code snippet is 9 bytes and 43cc
;Inputs:
;   HL is the input seed and must be non-zero
;Outputs:
;   A is the 8-bit pseudo-random number
;   HL is the new seed value (will be non-zero)
                  ;opcode cc
                LD a, (rng_seed)
                LD h, a
                LD a, (rng_seed+1)
                LD l, a

                add hl,hl     ; 29    11
                sbc a,a       ; 9F     4
                and %00101101 ; E62D   7
                xor l         ; AD     4
                LD l,a        ; 6F     4
                LD a,r        ; ED5F   9
                add a,h       ; 84     4

                LD b, a
                LD a, h
                LD (rng_seed), a
                LD a, l
                LD (rng_seed+1), a
                LD a, b

                ret 

resetBonusInitializers:
               LD   HL, bonEmyKey    
               LD   DE, bonEmyKey+1
               LD   (HL),$00
               LD   BC, 7
               LDIR

               LD   HL, bonusBoard	    
               LD   DE, bonusBoard+1
               LD   (HL),$00
               LD   BC, 7
               LDIR

               LD   HL, bonusPeekTimer	    
               LD   DE, bonusPeekTimer+1
               LD    A, (enemyTimerMax)
               LD   (HL),A
               LD   BC, 7
               LDIR

               ld a, 0
               ld (bopCount), a
            
               ret
draw_layer_fillbg_top:
               LD   HL,PLOTSSCREEN		            ;top LCD black
               LD   DE,PLOTSSCREEN+1
               LD   (HL),$FF
               LD   BC,263
               LDIR
               ret

draw_layer_fillall:
               LD   HL,PLOTSSCREEN		            ;top LCD black
               LD   DE,PLOTSSCREEN+1
               LD   (HL),$FF
               LD   BC,766
               LDIR
               ret

draw_layer_fillbg_low:
               LD   HL,PLOTSSCREEN+(54*12)	            ;bottom LCD black
               LD   DE,PLOTSSCREEN+(54*12)+1
               LD   (HL),$FF
               LD   BC,160
               LDIR              
               ret
draw_layer_machine:   
               LD     HL, machine
               LD     DE, PlotSScreen+(19*12)    ;Start at nineteenth row of display (PlotSScreen is backup screen buffer)
               LD     BC, 35*12                  ;35 rows of data
               LDIR
               ret
draw_layer_bonus_bg:
                call draw_mask_layer
                ;Y + 11 between rows
                ld HL, _NUM_XY_MONEY
                LD (PenCol), HL
                LD HL, text_bot_expl2
                bcall(_VputS)

                LD HL, _NUM_XY_BO7
                LD (penCol), HL
                LD A, '7'
                bcall(_VPutMap)
                LD HL, _NUM_XY_BO8
                LD (penCol), HL
                LD A, '8'
                bcall(_VputMap)
                LD HL, _NUM_XY_BO9
                LD (penCol), HL
                LD A, '9'
                bcall(_VputMap)

                LD HL, _NUM_XY_BO4
                LD (penCol), HL
                LD A, '4'
                bcall(_VPutMap)
                LD HL, _NUM_XY_BO5
                LD (penCol), HL
                LD A, '5'
                bcall(_VputMap)

            
                LD HL, _NUM_XY_BO6
                LD A, L
                INC A
                INC A
                INC A
                LD L, H
                INC L
                INC L
                LD B, 8
                LD IX, bonus_enemy1
                call ionPutSprite
                ;LD (penCol), HL
                ;LD A, '6'
                ;bcall(_VputMap)

                LD HL, _NUM_XY_BO1
                LD (penCol), HL
                LD A, '1'
                bcall(_VPutMap)
                LD HL, _NUM_XY_BO2
                LD (penCol), HL
                LD A, '2'
                bcall(_VputMap)
                LD HL, _NUM_XY_BO3
                LD (penCol), HL
                LD A, '3'
                bcall(_VputMap)

               ;n>=1
bon_redraw:    
               LD DE, _BON_XY_HP1
               LD A, E
               LD L, D
               LD B, 8
               LD IX, bonus_heart_on
               call ionPutSprite

               LD DE, _BON_XY_HP2
               LD A, E
               LD L, D
               LD B, 8
               LD IX, bonus_heart_on
               call ionPutSprite

               LD DE, _BON_XY_HP3
               LD A, E
               LD L, D
               LD B, 8
               LD IX, bonus_heart_on
               call ionPutSprite

               ld HL, _TEXT_XY_TOPBL
               LD (PenCol), HL
               LD HL, text_top_expl
               bcall(_VputS)            

               LD BC, 24*256+42                ;1st point, X=25, Y=30
               LD DE, 88*256+42                ;2nd point, X=62, Y=50
               LD H, 01h                       ;line on
               bcall(_iline)
               LD BC, 24*256+31                ;1st point, X=25, Y=30
               LD DE, 88*256+31                ;2nd point, X=62, Y=50
               bcall(_iline)
               LD BC, 24*256+20                ;1st point, X=25, Y=30
               LD DE, 88*256+20                ;2nd point, X=62, Y=50
               bcall(_iline)
               LD BC, 24*256+9                ;1st point, X=25, Y=30
               LD DE, 88*256+9                ;2nd point, X=62, Y=50
               bcall(_iline)

; Draws a vertical line from (D, L)-(D, E)
;BON_Y: .db  $2C,$2C,$2C, $21,$21,$21, $16,$16,$16, 0fh
;BON_X: .db  $1A,$2A,$3A, $1A,$2A,$3A, $1A,$2A,$3A, 0fh
               ;LD BC, 24*256+41                 ;1st point, X=25, Y=30
               ;LD DE, 24*256+10                 ;2nd point, X=62, Y=50
               LD H, 01h                        ;line on
               ;bcall(_iline)
               LD BC, 42*256+41                 ;1st point, X=25, Y=30
               LD DE, 42*256+10                 ;2nd point, X=62, Y=50                     ;line on
               bcall(_iline)
               LD BC, 64*256+41                ;1st point, X=25, Y=30
               LD DE, 64*256+10                ;2nd point, X=62, Y=50
               bcall(_iline)
               ;LD BC, 78*256+41                ;1st point, X=25, Y=30
               ;LD DE, 78*256+10                ;2nd point, X=62, Y=50
               ;bcall(_iline)
            call IONFastCopy
 
redrawHearts:  ld A, (heartCount)
               
               cp 3
               ret nc
               cp 2 
               push af
               call z, draw1heartgone
               pop af
               cp 1
               call z, draw2heartsgone
               ret
draw1heartgone:
               LD DE, _BON_XY_HP1
               LD A, E
               LD L, D
               LD B, 8
               LD IX, bonus_heart_off
               call ionPutSprite

               ld A, (heartCount)
               cp 1
               ret nz

draw2heartsgone:
               LD DE, _BON_XY_HP2
               LD A, E
               LD L, D
               LD B, 8
               LD IX, bonus_heart_off
               call ionPutSprite
               ret

;clear out a defined chunk of gbuffer
mask_from_reel_A:
               LD   DE, $000B            ;inc each iteration
               LD IX, PLOTSSCREEN+6
msk_loop:       

               LD (data_p), IX
               LD HL, (data_p)
               INC IX
               LD (data_p), IX 
               LD DE, (data_p)
               LD (HL), $FF
               LD BC, 4
               LDIR
   
               LD DE, $000B
               LD HL,  760
               ADD IX, DE
       
               ret    
;draw a defined, box mask sprite over a defined area
;Put large sprite
;B = height
;C = width / 8
; l=yc
; a=xc
; ix holds pointer  
draw_mask_layer:

              LD HL, maskXYWH
              LD a, (HL)        ;x
              INC HL
              LD e, (HL)        ;y
              INC HL
              LD c, (HL)        ;w
              INC HL
              LD b, (HL)        ;h
              LD l, e           ;Y
              ;$0C, $17, $0A, $20
              ;ld a, $0C
              ;ld l, $17
              ;ld c, $0A
              ;ld b, $23
              ld IX, machine1
              ld h, 01h      ;AND Sprite

              call IonLargeSprite ;anysprite
              ret


; Draws a vertical line from (D, L)-(D, E)
Draw_Line:
    LD     A, E
    SUB    L
    RET    Z
    PUSH   AF        ; Find and store vertical length of line

    LD     A, D
    CALL   ionGetPixel

    POP    BC        ; Now B = number of pixels to draw
    LD     DE, 12     ; There are 12 bytes between rows
    LD     C, A       ; Save the bitmask because it will get obliterated

PlotLoop:
    LD     A, C
    OR     (HL)
    LD     (HL), A
    ADD    HL, DE
    DJNZ   PlotLoop
    RET
;Load (data_p) with the address of the array sequence to draw
draw_sarr_at_xarr_yarr:
               LD HL, (data_p+8)
               LD (data_p), HL
dsarr_loop:   
               LD HL, (data_p)            
               LD A, (HL)
               CP $0F
               ret z
               CP $00                      ;reels with no data don't get re-drawn
               INC HL
               LD (data_p), HL
               jr z, dsarr_loop             
               ld HL, draw_w_h
               cp $09                     ;if bonus symbol custom height
               ld b, (HL)                  ;sprite width, from calling def
               INC HL
               ld c, (HL)                  ;sprite height, set from caller
               
               ADD A, A                    ;E contains 1-8 result of the rng symbol
               ADD A, A                    ;(1-8)*8 = sprite offset
               ADD A, A 
               ld HL, slot_sprites
               ld (P_), HL
               call jumpAfromP_
               push IX
               ;dec IX
      ;
               ld a, (aO)
               add a, sX

               LD HL, (data_p)
               dec HL
               LD (P_), HL
               call jumpAfromP_
               ld A, (IX)
               LD BC, $001A
               ADD IX, BC
               LD L, (IX)
               
               ;add a, $1A
               ;ld (u_y+2), a
;u_x:           ld A, (IX + sX)         ;x coordinate
;u_y:           LD HL, (IX + sY)         ;y coordinate [***LOADING 0 on stopspin]
               pop IX

               ld  c, a
               LD  A, (spinAnimCount)
               add a, l
               ld  L, A
               ld  a, c
               CALL XORSPR_L

               jp dsarr_loop
;call whenever multiplier or lines is updated.
_incMult:    
             ld a, (_multiplier)
             cp 05h
             jp nz, _incM
             ld a, 1
             ld (_multiplier), a
             jr d_incM
_incM:       inc a
             ld (_multiplier), a

d_incM:        LD HL, _TEXT_XY_RMENU
               LD (PenCol), HL
               LD A, ' '
               bcall(_VPutMap)
               LD A, 78h            ;small 'x'
               bcall(_VPutMap)    

               jr preUpdateBet

_incLines:
             ld a, (_lines)
             cp 09h
             jp nz, _incL
             ld a, 1
             ld (_lines), a
             jr d_incL
_incL:       inc a
             ld (_lines), a

d_incL:        LD HL, _TEXT_XY_RMENU3
               LD (PenCol), HL
               LD A, ' '
               bcall(_VPutMap)
               LD A, 2Bh            ;small '+'
               bcall(_VPutMap)    
                                 
               jr preUpdateBet_l

_decLines:
             ld a, (_lines)
             cp 01h
             jp nz, _decL
             ld a, 9
             ld (_lines), a
             jr d_decL
_decL:       dec a
             ld (_lines), a

d_decL:        LD HL, _TEXT_XY_RMENU2
               LD (PenCol), HL
               LD A, ' '
               bcall(_VPutMap)
               LD A, 2Dh            ;small '-'
               bcall(_VPutMap)         
            
               jr preUpdateBet_l
preUpdateBet_l:
               call draw_activePayLines_mini
               ;
;highlight buttons being pressed, check $, anything else that needs to be done before update bet
preUpdateBet:
               call IONFastCopy
               call draw_rmenu
updateBet:          

            ld a, 00h
            ld h, a
            ld d, a

            ld a, (_lines)
            ld e, a
            ld a, (_multiplier)
            ld l, a
            call mult

            ld B, L
            LD DE, (money)
            LD A, E
            cp 00h
            jp nz, enmoney
            CP B
            ret c 
enmoney:    
            LD (_totalBet), HL
            ret 

draw_rmenu:
               LD HL, _TEXT_XY_RMENU
               LD (PenCol), HL
               LD A, ' '
               bcall(_VPutMap)
               LD A, 78h            ;small 'x'
               bcall(_VPutMap)       

               LD HL, _TEXT_XY_RMENU2
               LD (PenCol), HL
               LD A, ' '
               bcall(_VPutMap)
               LD A, 2Dh            ;small '-'
               bcall(_VPutMap)

               LD HL, _TEXT_XY_RMENU3
               LD (PenCol), HL
               LD A, ' '
               bcall(_VPutMap)
               LD A, 2Bh            ;small '+'
               bcall(_VPutMap)
              
               ;turn off text highlighting
               RES   textInverse, (IY+textFlags)   ;invert text
               LD HL, _NUM_XY_LNS
               LD (PenCol), HL
               LD a, (_lines)
               bcall(_setxxop1)            ;place A into OP1
	           bcall(_dispop1a)            ;write OP1 to screen, at (PenCol, PenRow)  

               LD HL, _NUM_XY_MTP
               LD (PenCol), HL
               LD a, (_multiplier)
               bcall(_setxxop1)            ;place A into OP1
	           bcall(_dispop1a)            ;write OP1 to screen, at (PenCol, PenRow)           
               SET   textInverse, (IY+textFlags)   ;invert text
               call IONFastCopy
               ret
;jumpAfromP_()
;takes an offset(A) and a pointer (P*), jumps 16bits and returns new
;location in IX.  Used for dynamic jumping
;   inputs:
;       A = offset, P* = entry point
;   output:
;       IX now points to new memory location
;   destroys:
;       HL, DE, IX 
jumpAfromP_:    
               LD E,  A
               LD D,  00h             
               LD IX, (P_)       ;HL = (HL + DE(Offset))
               ADD IX, DE
               ret
jumpEDfromP_:                 
               LD IX, (P_)       ;HL = (HL + DE(Offset))
               ADD IX, DE
               ret
draw_top_layers:
                call draw_mask_layer 
                call draw_layer_fillbg_top  
                call draw_layer_fillbg_low
                ret

draw_activePayLines_mini:  
                ld b, 8
                ld c, 2
                ld a, 4Fh
                ld l, 38h   ;bottom right panel       
                ;ld a, 2Eh
                ld IX, _8x16_on
                ld h, 02; 
                call IonLargeSprite //anysprite
                call IONFastCopy

                ld a, (_lines)
                ld c, a         ;end condition
                ld b, 1         ;start point
                LD IX, minimap

_dapl:          push ix
                push bc

                ld b, 8
                ld c, 2
                ld a, 4Fh
                ld l, 38h
                ;ld l, 2Eh
 
                call IonLargeSprite
                call IONFastCopy
                pop bc   
                pop ix 
                ld a, c
                cp b
                ret z
                inc b

                ld d, 00h
                ld e, 10h
                add ix, de 
               
                jr _dapl
                ret
;Put large sprite
;B = height
;C = width / 8
; l=yc
; a=xc
; ix holds pointer


draw_activePayLines:
;            for(i=1; i<=_lines, i++)
;                for(j=(1); slot_rules[j+1]!=$FF, j++)                 
;                   B = drawX[ i[j] ]+4
;                   C = drawY[ i[j] ]+4
;                   
;                   D = drawX[ i[j+1] ]+4
;                   E = drawY[ i[j+1] ]+4
;                   bcall(_iline)
;                   LD B, D
;                   LD C, E
    LD HL, pay_rules
    LD (data_p+6), HL       ;slot_rules[0]

    ld a, (_lines)
    ld b, a         ;j
    ld c, 1         ;start condition
    push bc
        call _gLX          ;gets X,Y -> B, C
   
_incj:      push bc
            LD HL, (data_p+6)   ;j+1
            inc HL
            LD (data_p+6), HL
            call _gLX      
            ld d, b
            ld e, c
            pop bc 
            call zi_line
            pop bc
            inc b
            ld a, b 
            cp 06h
            jr c, _noInci
            inc c               ;i++
            ld a, (_lines)
            cp c 
            ret nc              ;i >= lines? return
            ld hl, (data_p+6)
            inc hl
            ld (data_p+6), hl
_noInci:    
            push bc
            ld b, d             ;end of this line, is beginning of next line
            ld c, e             ;__
            jr _incj
_gLX:
            LD a, (HL)
            dec a               ;adj offset.  
            LD HL, draw_at_X
            LD (P_), HL
            call jumpAfromP_
            ld b, (IX)
            inc b
            inc b
            inc b
            inc b  
;getY  
            LD HL, (data_p+6)
            LD a, (HL)
            dec A               ;adj offset
            LD HL, draw_at_Y
            LD (P_), HL
            call jumpAfromP_
            ld c, (IX)
            inc c
            inc c
            inc c
            inc c
            push bc

            ;from 4,17h -> 44h, 17h                
                ld l, b 
                ld h, 00h
                ld d, 01h           ;de = 256 = $0100
                ld e, 00h
                call mult           ;x * 256
              
                pop bc              ;c = y
                ld a, 64
                sub c
                ld c, a
                ld b,  00h
                add hl, bc          ;hl = (x*256)+y
                ;hl is correct
                ld c, l
                ld b, h
                push bc             ;correct coord in bc

            ret

;draws a line through the winning payline, on display
;sb used between win animations and to indicate to the user active paylines on addition/removal
;flags
;   fullScrnDraw, (IY + apiFlg4)  = 1 to use column 95 and row 0 
;   plotLoc, (IY + plotFlags)     = 1 to draw to the display only 
;                                 = 0 to draw to display and plotSScreen buffer 
;   bufferOnly, (IY + plotFlag3)  = 1 to draw to plotSScreen buffer only
;registers 
;   BC = 1st point = B=X, C=Y
;   DE = 2nd point = D=X, E=Y
;       ex:    LD BC, 25*256+30                ;1st point, X=25, Y=30
;              LD DE, 62*256+50                ;2nd point, X=62, Y=50
;   H  = 0/1/2 = off/on/xor
;registers all preserved
;(c) Texas Instruments
zi_line:
                ;SET plotLoc, (IY+plotFlags)     ;display only
                LD H, 2                         ;signal to turn pixels off
                bcall(_iline)                   ;draw the line
                call IONFastCopy
                ret    
;p_exit:
;                EI
;                ld SP, (startSP)
;                halt
;                ret
;----------------------------------------------------------------------

aO:             .db      $00      ;$00 = win_Anim, $1A = Cur_reel_state, $34 = Save, $4E = fin
sX:             .equ     $1A
sY:             .equ     $34

bt_flags:       .db      %11001001
isFirstGame:    .EQU     0
isSpinning:     .EQU     1
isCounting:     .EQU     2
isWaiting:      .EQU     3
isWin:          .EQU     4
isBonus:        .EQU     5
is1stBonusRoll: .EQU     6
open:           .EQU     7

;                         87654321         9
bonus_enemLocs: .db      %00000000,%00000000, 0

bt_flags2:      .db     %00000000

_lines          .db      9
_multiplier     .db      1
_totalBet       .db      0

bonusCount:     .db      @0

_SHARPMEM_:         .ds                   10        ;allocate 10 contiguous bytes
startSP             =           _SHARPMEM_+0
saveGame            =           _SHARPMEM_+2

;isCounted       =          _SHARPMEM_+11
;isAutoStopping  =          _SHARPMEM_+14
;isReelSpinAnimCXLEDbySpin =_SHARPMEM_+15 
    
spinAnimCount:   .db       $00         ;keeps track of reel spinning animation frame
spinningReelNo:  .db       $00
reelTimer:       .db       $00         ;auto stops reels if not manually stopped
maskXYWH:        .db       $02, $16, $09, $20,0

;RMENU
_TEXT_XY_RMENU   .EQU      $1854        ;XY of 1st menu item in rightMenu  
_TEXT_XY_RMENU2  .EQU      $2054        ;   2nd  
_TEXT_XY_RMENU3  .EQU      $2754        ;   3rd  
                           ;y,x
_NUM_XY_MTP      .EQU      $185A
_NUM_XY_LNS      .EQU      $235A


BON_K: .db  $8F      ;[1]++ = [2] ...
BON_Y: .db  $2D,$2D,$2D, $22,$22,$22, $17,$17,$17, 0fh
BON_X: .db  $15,$2E,$44, $15,$2E,$44, $15,$2E,$44, 0fh

enemyTimerMax:    .db     $40,0

                           ; 1,  2,  3,  4,  5

bonusBoard:     .db        $00,$00,$00,$00,$00,$00,$00,$00,$00, $F0
bonusPeekTimer: .db        $40,$40,$40,$40,$40,$40,$40,$40,$40, $F0
bonEmyKey:      .db        $00,$00,$00,$00,$00,$00,$00,$00,$00, $F0
                 ;keys:    1,  2,  3,  4,  5,  6,  7,  8,  9
kTOsk:          .db        $22,$1A,$12,$23,$1B,$13,$24,$1C,$14, $F0
bonusFrameMap:  .db        1,2,3,4,5,6,7,8,9,8,7,6,5,4,3,2,1, $F0

heartCount:       .db       03h
bopCount:         .db       $00
bonusLvl:         .db       00h
nxtBonus:         .db       $19
                            ;Y,X
_NUM_XY_BO7:      .EQU      $1615
_NUM_XY_BO8:      .EQU      $162B
_NUM_XY_BO9:      .EQU      $1641
_NUM_XY_BO4:      .EQU      $2115
_NUM_XY_BO5:      .EQU      $212B
_NUM_XY_BO6:      .EQU      $2141
_NUM_XY_BO1:      .EQU      $2C15
_NUM_XY_BO2:      .EQU      $2C2B
_NUM_XY_BO3:      .EQU      $2C41

_BON_XY_HP1:      .EQU      $1609
_BON_XY_HP2:      .EQU      $2109
_BON_XY_HP3:      .EQU      $2D09

_TEXT_XY_TOPBC    .EQU      $0E20        ;XY of lowest title location, on top of disp.
_TEXT_XY_TOPBL    .EQU      $0E06
_TEXT_XY_TOPMC    .EQU      $081A


_TEXT_XY_WINSTR   .EQU      $3825        ;
_TEXT_XY_CREDIT   .EQU      $3801        ;Denomination symbol location
_NUM_XY_MONEY     .EQU      $3806        ;User's balance location on disp. 
_NUM_XY_BOPCNT    .EQU      $3912

_GAMESPEED_       .EQU      $02          ;factor to determine how long animations take

count:          .db       "0",0
money_string:   .text     "$",0
blank:          .db       " ",0
top_win_str1:   .db       "     NICE WIN!     ",0
top_win_str2:   .text     "YOU DIRTY DOG YOU! ",0
top_win_str3:   .db       "    KEEP IT UP!    ",0
top_win_str4:   .db       "     MEGA WIN!     ",0

top_win_BON:    .db       "     BONUS!!!!     ",0
top_win_BON_0:  .db       "   WHIFFFFFF#D!!   ",0
top_win_BON_1:  .db       "     OUCH ! ! ! !  ",0
top_win_BON_2:  .db       "     TOO SLOW!     ",0
top_win_BON_3:  .db       "    LEVEL UP!!!    ",0


text_top_expl:    .db       "Use keys 1-9 to SMASH EM!",0
text_bot_expl1:   .db  "           Press ^ to begin...",0
text_bot_expl2:   .db       "       SMASH him to begin!!",0

rm_lines_str:   .db       "ln:",0
rm_lines_sym_i: .db       "+",0
rm_lines_sym_d: .db       "-",0
rm_multi_sym:   .db       "x",0

bot_win_str1:   .db       " x ",0
bot_win_str2:   .db       "Total Win: $",0

bot_win_BON:    .db       "Press ^ to begin..."
bot_win_clear:  .db       "                                 ",0
money:          .db       $88,$13
new_money:      .db       $88,$13
cur_win_total:  .db       $00,$00
                          ;timer
cflags:         .db       %00000001,0

                ;         sprite   x        y                 drawArray
data_p:         .db       $00,$00, $00,$00, $00,$00, $00,$00, $00,$00                ;misc address pointers     
P_:             .db       $00,$00                                            ;pointer
                      
ratio_table:              ;F   Q    K    A    Che  Coi  Thu  Bon   
                .db       $28, $5A, $80, $A4, $C3, $DF, $F3, $FF

;symbol
;       hl*, sprite
;        16, pay
;    string, name
symbols:
sym_fun:
            .db     %0000001,0
            .db     5,0
            .db     "Fun",0
sym_queen:  
            .db     %00000010,0
            .db     10,0
            .db     "Queen",0
sym_king:
            .db     %00000011,0
            .db     15,0
            .db     "King",0  
sym_ace:
            .db     %00000100,0
            .db     20,0
            .db     "Ace",0
sym_cherry:
            .db     %00000101,0
            .db     25,0
            .db     "Cherry",0
sym_coin:
            .db     %00000111,0
            .db     30,0
            .db     "Coin",0
sym_thunder:
            .db     %00000111,0
            .db     40,0
            .db     "Thunder",0
sym_hourglass:
            .db     %00001111,0
            .db     50,0
            .db     "Hourglass",0
sym_bonus:
            .db     %00011111,0
            .db     100,0
            .db     "BONUS",0
;
;------SYMBOL ENUMS
                   ;    Q, K, A, C,Co,Th,Hr,Bo 
sym_o:      .db     0,0,8,18,27,35,46,55,67,81,0

fun:        .equ    0
queen:      .equ    8
king:       .equ    18
ace:        .equ    27
cherry:     .equ    35
coin:       .equ    46
thunder:    .equ    55
hourglass:  .equ    64
bonus:      .equ    78

;-------NAME ENUM.NAME OFFSET
_name:      .equ    4
_PAY:       .equ    2
OFFSET:     .equ    6

rng_seed:       .db     $AA,$AA

slot_sprites:                         ;19EBC
                .db     %00000000
                .db     %00000000
                .db     %00000000
                .db     %00111000
                .db     %00111000
                .db     %00000000
                .db     %00000000
                .db     %00000000

                .db     %11111111
                .db     %10000001
                .db     %10011111
                .db     %10011111
                .db     %10000011
                .db     %10011111
                .db     %10011111
                .db     %11111111

                .db     %01111110
                .db     %11111111
                .db     %11000011
                .db     %11000011
                .db     %11000011
                .db     %11100011
                .db     %01111100
                .db     %00011111

                .db     %11000111
                .db     %11000110
                .db     %11001100
                .db     %11111000
                .db     %11111000
                .db     %11001100
                .db     %11000110
                .db     %11000111

                .db     %00011000
                .db     %00111100
                .db     %01100110
                .db     %11000011
                .db     %11111111
                .db     %11111111
                .db     %11000011
                .db     %11000011

                .db     %00010000
                .db     %00001000
                .db     %00001000
                .db     %01110011
                .db     %11111101
                .db     %11111101
                .db     %11111001
                .db     %01111110
        
                .db     %00111100
                .db     %01011110
                .db     %10101111
                .db     %10100111
                .db     %10100111
                .db     %10100111
                .db     %01001110
                .db     %00111100

                .db     %11100111
                .db     %00110011
                .db     %10011001
                .db     %11001100
                .db     %01100110
                .db     %00110011
                .db     %00011001
                .db     %11000110 

                .db     %11111111
                .db     %11111111
                .db     %01000010
                .db     %00101100
                .db     %00110100
                .db     %01010110
                .db     %11111111
                .db     %11111111

bonus_symbol:                               ;16x10
                .db     $7F, $FE
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $7F, $FE
                


                .db     %11111111
                .db     %10101001
                .db     %10010101
                .db     %10101001
                .db     %10010101
                .db     %10101001
                .db     %10010101
                .db     %11111111

                .db     %01111100
                .db     %01111000
                .db     %01111000
                .db     %01100000
                .db     %01110000
                .db     %11110000
                .db     %01001000
                .db     %01000110

                .db     %00111110
                .db     %11111110
                .db     %00111110
                .db     %01111100
                .db     %11111110
                .db     %01111100
                .db     %00111100
                .db     %00111100

                ;.db     %00000001

CPYRGHT:

                .db     %01111100
                .db     %00011110
                .db     %00100000
                .db     %01010000
                .db     %01010101
                .db     %00100110
                .db     %01011000
                .db     %11111100

                .db     %11101001
                .db     %00111001
                .db     %01001000
                .db     %11000100
                .db     %01000100
                .db     %00101000
                .db     %00010100
                .db     %01111110

                .db     %00000000
                .db     %01110011
                .db     %10000101
                .db     %01000101
                .db     %00100111
                .db     %00010101
                .db     %00010101
                .db     %11100101

_8x8_on:        
                .db     %11111111
                .db     %11111111
                .db     %11111111
                .db     %11111111
                .db     %11111111
                .db     %11111111
                .db     %11111111
                .db     %11111111
_8x8_off:
                .db     %00000000
                .db     %00000000
                .db     %00000000
                .db     %00000000
                .db     %00000000
                .db     %00000000
                .db     %00000000
                .db     %00000000
_8x16_on:
                .db     %11111111,%11111111
                .db     %11111111,%11111111
                .db     %11111111,%11111111
                .db     %11111111,%11111111
                .db     %11111111,%11111111
                .db     %11111111,%11111111
                .db     %11111111,%11111111
                .db     %11111111,%11111111


_10x16_off:  
    .db  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
_8x16_off:        
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000


minimap:        
                .db     %10000000,%00000000
                .db     %10000000,%00000000
                .db     %10000000,%00000000
                .db     %11111111,%11111111
                .db     %10000000,%00000000
                .db     %10000000,%00000000
                .db     %10000000,%00000000
                .db     %11111111,%11111111
                
                .db     %00000000,%00000000
                .db     %01111111,%11111111
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000

                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %01111111,%11111111
                .db     %00000000,%00000000
                .db     %00000000,%00000000

                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00100000,%00001000
                .db     %00000000,%00000000
                .db     %00001000,%00100000
                .db     %00000000,%00000000
                .db     %00000010,%10000000
                .db     %00000000,%00000000

                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000010,%10000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00100000,%00001000
                .db     %00000000,%00000000

                .db     %00000000,%00000001
                .db     %00000011,%10000000
                .db     %01011100,%01110111
                .db     %00000000,%00000000
                .db     %00000001,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000

                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000001,%00000000
                .db     %01011110,%11110111
                .db     %00000000,%00000000

 

                .db     %01011111,%01111100
                .db     %00000011,%10000000
                .db     %00010000,%01000100
                .db     %00000000,%00000000
                .db     %01111100,%11110111
                .db     %00000001,%00000000
                .db     %00000111,%10010000
                .db     %00000000,%00000000                   

                .db     %00001000,%00100000
                .db     %00000000,%00000000
                .db     %00000100,%00010000
                .db     %00000000,%00000000
                .db     %00100000,%10000000
                .db     %00000000,%00000000
                .db     %01000001,%00000100
                .db     %00000000,%00000000      

                
win_box:                ;16x10
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF
                .db     $FF, $FF


bonus_enemies:
bonus_enemy1:
                .db     %00000000    
                .db     %00101000
                .db     %01011010
                .db     %10100101
                .db     %10101001
                .db     %10000001
                .db     %10010001
                .db     %10000011

bonus_enemy2:
                .db     %00010000 
                .db     %00111000   
                .db     %01111100
                .db     %11111110
                .db     %11101101
                .db     %11001100 
                .db     %10111111
                .db     %10111111


bonus_hammer1:   
                .db     %01111111,%11111100
                .db     %01100000,%00010100
                .db     %01100000,%00010100
                .db     %01100000,%00010100
                .db     %01111110,%11111100
                .db     %00000001,%10000000
                .db     %00000001,%10000000
                .db     %00000001,%10000000
                .db     %00000001,%10000000
                .db     %00000001,%10000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
bonus_hammer2:   
                .db     %00000001,%00000000
                .db     %00000011,%10000000
                .db     %00000111,%11000000
                .db     %00001100,%11100000
                .db     %00011000,%00110000
                .db     %00001000,%00111000
                .db     %00001100,%00011100
                .db     %00001010,%00001110
                .db     %00010101,%00010111
                .db     %00101000,%10100110
                .db     %01100000,%01101100
                .db     %11000000,%00110000 
bonus_hammer3:   
                .db     %00000000,%00000000
                .db     %00000111,%11111100
                .db     %00000011,%11111000
                .db     %00000010,%00001000
                .db     %11111110,%00001000
                .db     %11111110,%00001000
                .db     %00000000,%00001000
                .db     %00000011,%11111000
                .db     %00000011,%11111000
                .db     %00000111,%11111100
                .db     %0000010,%100000000
                .db     %0001111,%010011000
                .db     %01000000,%00100100

bonus_hammer4:
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000111,%11111100
                .db     %00000011,%11111000
                .db     %00000010,%00001000
                .db     %11111110,%00001000
                .db     %11111110,%00001000
                .db     %00000000,%00001000
                .db     %10000011,%11111001
                .db     %00000011,%11111000
                .db     %10000111,%11111100
                .db     %0100010,%111110001
                .db     %1111111,%011111111

bonus_hammer5:   
                .db     %00000001,%00000000
                .db     %00000011,%10000000
                .db     %00000111,%11000000
                .db     %00001100,%11100000
                .db     %00011000,%00110000
                .db     %00001000,%00111000
                .db     %00001100,%00011100
                .db     %00001010,%00001110
                .db     %00010101,%00010111
                .db     %00101000,%10100110
                .db     %01100000,%01101100
                .db     %11000000,%00110000 
                .db     %00111111,%11111000
                .db     %11111111,%11111111

bonus_hammer6:   
                .db     %0111111,%111111100
                .db     %01000000,%00011100
                .db     %01000000,%00011100
                .db     %01000000,%00011100
                .db     %0101111,%111111100
                .db     %01111111,%11111100
                .db     %00000110,%00000000
                .db     %00000110,%00000000
                .db     %00000110,%00000000
                .db     %00000110,%00000000
                .db     %00000001,%11110000
                .db     %00000011,%11111111

bonus_hammer7:
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00111111,%11111110
                .db     %11111111,%11111110
bonus_hammer8:
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %00000000,%00000000
                .db     %11111111,%11111110

bonus_splat1:   
                .db     %00000000,%00000000
                .db     %01101101,%01000000
                .db     %10001010,%10000000
                .db     %01100001,%10000000
                .db     %10011110,%10000000
                .db     %01011110,%01000000
                .db     %01011101,%10100000
                .db     %10101011,%10000000
                .db     %01011110,%01000000

bonus_splat2:   
                .db     %11000000,%01100000
                .db     %00000000,%00001000
                .db     %01100000,%10100000
                .db     %00000010,%01010000
                .db     %10001101,%10101000
                .db     %10011001,%11100000
                .db     %01001100,%00110000
                .db     %00000111,%11110000
                .db     %00001111,%11111000

bonus_heart_on:    
                .db     %00000000  
                .db     %01101100
                .db     %11111010
                .db     %11111010
                .db     %11111010
                .db     %01110100
                .db     %00111000
                .db     %00010000

bonus_heart_off:
                .db     %00000000  
                .db     %00000000
                .db     %01101000
                .db     %01111000
                .db     %01111000
                .db     %00110000
                .db     %00010000
                .db     %00000000
              

spin_anim:           
                .db     %00000000
                .db     %00000000
                .db     %01111110
                .db     %10000001
                .db     %10000001
                .db     %01111110
                .db     %00000000
                .db     %00000000
                .db     %00000000
                .db     %01100110
                .db     %00000000
                .db     %01111110
                .db     %01111110
                .db     %00100100
                .db     %00100100
                .db     %00000000

;tilogo:
;   .db    $00, $00, $00, $00, $00, $FE, $00, $00, $00, $00, $00, $00
;   .db    $00, $00, $00, $00, $00, $FE, $00, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $FE, $30, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $FE, $78, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $FF, $30, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $FF, $07, $E0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $FF, $77, $E0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $FF, $77, $E0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $F8, $61, $E0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $1F, $F8, $E3, $E0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $7F, $F8, $E3, $F0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $7F, $FE, $EF, $F0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $3F, $FE, $CF, $F0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $1F, $FD, $DF, $F0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $0F, $FD, $DF, $F0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $07, $FC, $1F, $F0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $07, $9C, $0F, $C0, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $03, $0E, $0F, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $0F, $FE, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $07, $F8, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $07, $F8, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $03, $F0, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $03, $F0, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $01, $F0, $00, $00, $00, $00, $00
;    .db    $00, $00, $00, $00, $00, $00, $F8, $00, $00, $00, $00, $00

machine:
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $7F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FE, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $80, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00
    .db    $00, $7F, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FE, $00

machine1:
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

draw_one_reel:  .db    $08, $05, $05, $07, $08,    $0F

slot_fin_reel_state:
slot_chk_win_state:
    .db    $02, $02, $02, $02, $02
    .db    $02, $02, $02, $02, $02    
    .db    $02, $02, $02, $02, $02
    .db    $02, $02, $02, $02, $02   
    .db    $02, $02, $02, $02, $02,    $0F
;Used to retain board state between poweroffs.
slot_saved_reel_state:
    .db    $02, $02, $02, $02, $02
    .db    $02, $02, $02, $02, $02    
    .db    $02, $02, $02, $02, $02
    .db    $02, $02, $02, $02, $02   
    .db    $02, $02, $02, $02, $02,    $0F
slot_cur_reel_state:
    .db    $02, $02, $02, $02, $02
    .db    $02, $02, $02, $02, $02    
    .db    $02, $02, $02, $02, $02
    .db    $02, $02, $02, $02, $02   
    .db    $02, $02, $02, $02, $02,    $0F
win_anim_array:
    .db    $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00 
    .db    $00, $00, $00, $00, $00
    .db    $00, $00, $00, $00, $00   
    .db    $00, $00, $00, $00, $00,    $0F
draw_at_X:
    .db    $04, $04, $04, $04, $04
    .db    $14, $14, $14, $14, $14
    .db    $24, $24, $24, $24, $24
    .db    $34, $34, $34, $34, $34
    .db    $44, $44, $44, $44, $44,    $0F
draw_at_Y:
    .db    $03, $0D, $17, $21, $2B
    .db    $03, $0D, $17, $21, $2B     
    .db    $03, $0D, $17, $21, $2B
    .db    $03, $0D, $17, $21, $2B
    .db    $03, $0D, $17, $21, $2B,    $0F


;Offsets to get to to the parallel positions from CUR_STATE
                          
;147AD
;258BE
;369CF
draw_w_h:
    .db    $08, $01 
slot_win_states:      
            ;$[ln#, xInArow, symID, winTot8,16],...
    .db       $0F, $0F, $0F, $0F, $0F, $0F
    .db       $0F, $0F, $0F, $0F, $0F, $0F
    .db       $0F, $0F, $0F, $0F, $0F, $0F
    .db       $0F, $0F, $0F, $0F, $0F, $0F
    .db       $0F, $0F, $0F, $0F, $0F, $0F
    .db       $0F, $0F, $0F, $0F, $0F, $0F
    .db       $0F, $0F, $0F, $0F, $0F, $0F
    .db       $0F, $0F, $0F, $0F, $0F, $0F
    .db       $0F, $0F, $0F, $0F, $0F, $0F, 0

;01,06,0B,10,15
;02,07,0C,11,16
;--------------
;03,08,0D,12,17
;04,09,0E,13,18
;05,0A,0F,14,19

;147AD
;258BE
;369CF
;pay_rules:
;    .db    $04, $09, $0E, $13, $18, $FF       ;(16,26 -> 47,26 -> 27,26)
;    .db    $03, $08, $0D, $12, $17, $FF       ;(16,36 -> 47,36 -> 78,36)
;
;    .db    $05, $0A, $0F, $14, $19, $FF       ;(16,16 -> 47,16 -> 78,16)
;   
;    .db    $03, $09, $0F, $13, $17, $FF       ;(16,36 -> 47,16 -> 78,36)
;    .db    $05, $09, $0D, $13, $19, $FF       ;(16,16 -> 47,38 -> 78,16)
;    
;    .db    $03, $08, $0E, $12, $17, $FF       ;(16,36 -> 31,36 -> 47,26 -> 62,36 -> 78,36)
;    .db    $05, $0A, $0E, $14, $19, $FF       ;(16,16 -> 31,16 -> 47,26 -> 62,16 -> 78,16)
;
;    .db    $03, $0A, $0D, $14, $17, $FF       ;(16,36 -> 31,16 -> 47,36 -> 62,16 -> 78,36)
;    .db    $05, $08, $0F, $12, $19, $EE       ;(16,16 -> 31,36 -> 47,16 -> 62,36 -> 78,16)
                ;payline

pay_rules:
    .db    $04, $09, $0E, $13, $18, $FF              ;pay line 1
    .db    $03, $08, $0D, $12, $17, $FF              ;         2-3

    .db    $05, $0A, $0F, $14, $19, $FF 
   
    .db    $03, $09, $0F, $13, $17, $FF              ;         3-5
    .db    $05, $09, $0D, $13, $19, $FF 
    
    .db    $03, $08, $0E, $12, $17, $FF              ;         5-7
    .db    $05, $0A, $0E, $14, $19, $FF 

    .db    $03, $0A, $0D, $14, $17, $FF              ;         8-9
    .db    $05, $08, $0F, $12, $19, $EE 
bonus_loc:
    .db       $FF,$FF,$FF,$FF,$FF
    .db       $FF,$FF,$FF,$FF,$FF
    .db       $FF,$FF,$FF,$FF,$FF,  $EE


;=============================================== 
;Top-Left reel( 0Ch(+16offset),17h(+10offset) )
;===============================================    



.end
END