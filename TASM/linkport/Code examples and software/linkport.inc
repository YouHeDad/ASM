; *************************
; CORRECT LINK PORT EQUATES
; *******By Timendus*******
;
; Usage: #include "linkport.inc"
;
; * Writing to the link port:
;
;	ld a,Set_TipLow_RingLow
;	out (Linkport),a
;
; * Reading from the link port:
;
;	in a,(Linkport)
;	and Read_Tip
;	or a		; Equal to "cp 0"
;	jr z,Tip_is_low
;	jr nz,Tip_is_high
;
; * Or:
;
;	in a,(Linkport)
;	bit Read_TipB,a
;	jr z,Tip_is_low
;	jr nz,Tip_is_high

Linkport		.EQU	$0
Set_TipHigh_RingHigh	.EQU	$D0
Set_TipLow_RingHigh	.EQU	$D1
Set_TipHigh_RingLow	.EQU	$D2
Set_TipLow_RingLow	.EQU	$D3
Read_Tip		.EQU	$4
Read_Ring		.EQU	$8
Read_Both		.EQU	$C
Read_TipB		.EQU	2
Read_RingB		.EQU	3

