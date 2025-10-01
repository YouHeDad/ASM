; #########################################
; ## "All the Keys v1.0" by John Wyrwas  ##
; ##       20002016 - 20002019           ##
; #########################################
;
; Includes the Getkey keys values, Getcsc (getk), and Direct Input 
; key values.  They start with Gk, G, and K respectively and most contain
; the writing on the key.
;
; To use, unzip in your tasm directory and use #include keyval.inc 
;
;
; #################
; ## Getkey Keys ##
; #################
; (the TI-OS does NOT recognize values from lowercase letter input- all are 0FC)
;
;Numbers
Gk0		.equ 8Eh
Gk1		.equ 8Fh
Gk2		.equ 90h
Gk3		.equ 91h
Gk4		.equ 92h
Gk5		.equ 93h
Gk6		.equ 94h
Gk7		.equ 95h
Gk8		.equ 96h
Gk9		.equ 97h
; Uppercase Letters
GkA		.equ 9Ah
GkB		.equ 9Bh
GkC		.equ 9Ch
GkD		.equ 9Dh
GkE		.equ 9Eh
GkF		.equ 9Fh
GkG		.equ 0A0h
GkH		.equ 0A1h
GkI		.equ 0A2h
GkJ		.equ 0A3h
GkK		.equ 0A4h
GkL		.equ 0A5h
GkM		.equ 0A6h
GkN		.equ 0A7h
GkO		.equ 0A8h
GkP		.equ 0A9h
GkQ		.equ 0AAh
GkR		.equ 0ABh
GkS		.equ 0ACh
GkT		.equ 0ADh
GkU		.equ 0AEh
GkV		.equ 0AFh
GkW		.equ 0B0h
GkX		.equ 0B1h
GkY		.equ 0B2h
GkZ		.equ 0B3h
; Other Keys
GkMode		.equ 45h
GkIns		.equ 0Bh
GkDel		.equ 0Ah
GkRight		.equ 01h
GkLeft		.equ 02h
GkUp		.equ 03h
GkDown		.equ 04h
GkXTN		.equ 0B4h
GkLink		.equ 41h
GkStat		.equ 31h
GkList		.equ 3Ah
GkMath		.equ 32h
GkTest		.equ 33h
GkApps		.equ 2Ch
GkAngle		.equ 39h
GkPrgm		.equ 2Dh
GkDraw		.equ 2Fh
GkVars		.equ 35h
GkDistr		.equ 38h
GkClear		.equ 09h
GkX1		.equ 0B6h
GkMatrix	.equ 37h
GkSin		.equ 0B7h
GkSin1		.equ 0B8h
GkCos		.equ 0B9h
GkCos1		.equ 0BAh
GkTan		.equ 0BBh
GkTan1		.equ 0BCh
GkPower		.equ 84h
GkPi		.equ 0B5h
GkX2		.equ 0BDh
GkRoot		.equ 0BEh
GkComma		.equ 8Bh
GkEE		.equ 98h

GkRightPar	.equ 86h
GkLeftPar	.equ 85h

GkDivide	.equ 83h
GkMultiply	.equ 82h
GkSubtract	.equ 81h
GkAdd		.equ 80h
GkEnter		.equ 05h

GkLittleE	.equ 0EFh
GkLeftBracket	.equ 87h
GkRightBracket	.equ 88h
GkMem		.equ 36h
GkEntry		.equ 0Dh
GkQuotes	.equ 0CBh
GkSolve		.equ 05h


GkLog		.equ 0C1h
GkLn		.equ 0BFh
GkSto		.equ 8Ah
Gk10X		.equ 0C2h
GkeX		.equ 0C0h
GkRcl		.equ 0Ch

GkLittleU 	.equ 0F9h
GkLittleV	.equ 0FAh
GkLittleW	.equ 0FBh
GkLittleI	.equ 0EEh

GkL1		.equ 0F3h
GkL2		.equ 0F4h
GkL3		.equ 0F5h
GkL4		.equ 0F6h
GkL5		.equ 0F7h
GkL6		.equ 0F8h
 
GkCatalog	.equ 3Eh
GkAns		.equ 0C5h
GkSpace		.equ 99h
GkColon		.equ 0C6h
GkQuestion	.equ 0CAh
GkPeriod	.equ 8Dh
GkNegative	.equ 8Ch

GkF1		.equ 49h
GkF2 		.equ 48h
GkF3		.equ 2Eh
GkF4		.equ 5Ah
GkF5		.equ 44h

GkStatPlot	.equ 30h
GkTblset	.equ 4Bh
GkFormat	.equ 57h
GkCalc		.equ 3Bh
GkTable		.equ 4Ah


;############################
;##     Getcsc/Getk Keys   ##
;############################

GF1		.equ 35h
GF2		.equ 34h
GF3		.equ 33h
GF4		.equ 32h
GF5		.equ 31h

G2nd		.equ 36h
GMode		.equ 37h
GDel		.equ 38h

GDown		.equ 01h
GLeft		.equ 02h
GRight		.equ 03h
GUp		.equ 04h

GAlpha		.equ 30h
GXTN		.equ 28h
GStat		.equ 20h
GMath		.equ 2Fh
GApps		.equ 27h
GPrgm		.equ 1Fh
GVars		.equ 17h
GClear		.equ 0Fh
GX1		.equ 2Eh
GSin		.equ 26h
GCos		.equ 1Eh
GTan		.equ 16h
GPower		.equ 0Eh
GX2		.equ 2Dh
GComma 		.equ 25h
GLeftPara	.equ 1Dh
GRightPara	.equ 15h

GDivide		.equ 0Dh
GMultiply	.equ 0Ch
GSubtract	.equ 0Bh
GAdd		.equ 0Ah
GEnter		.equ 09h
GLog		.equ 2Ch
GLn		.equ 2Bh
GSto		.equ 2Ah

G0		.equ 21h
G1		.equ 22h
G2		.equ 1Ah
G3		.equ 12h
G4		.equ 23h
G5		.equ 1Bh
G6		.equ 13h
G7		.equ 24h
G8		.equ 1Ch
G9		.equ 14h

GPeriod 	.equ 8Dh
GNegative	.equ 8Ch

;#######################
;## Direct Input Keys ##
;#######################

;Group 1
KeyRow_Pad	.equ 0feh
KDown		.equ 254 
KLeft		.equ 253 
KRight		.equ 251 
KUp		.equ 247 

;Group 2
KeyRow_5 	.equ 0fdh
KEnter		.equ 254 
KPlus		.equ 253 
KMinus		.equ 251 
KMul		.equ 247 
KDiv		.equ 239 
KPower		.equ 223 
KClear		.equ 191 

;Group 3
KeyRow_4 	.equ 0fbh
KMinus2		.equ 254 
KThree		.equ 253 
KSix		.equ 251 
KNine		.equ 247 
KRbracket	.equ 239 
KTan		.equ 223 
KVars		.equ 191 

;Group 4
KeyRow_3	.equ 0f7h
KPoint		.equ 254 
KTwo		.equ 253 
KFive		.equ 251
KEight		.equ 247
KLbracket	.equ 239
KCos		.equ 223
KPrgm		.equ 191
KStat		.equ 127 

;Group 5
KeyRow_2 	.equ 0efh
KZero		.equ 254
KOne		.equ 253
KFour		.equ 251
KSeven		.equ 247
KComma		.equ 239
KSin		.equ 223
KMatrx		.equ 191
KX		.equ 127 

;Group 6
KeyRow_1 	.equ 0dfh
KSto		.equ 253
KLn		.equ 251
KLog		.equ 247
kX2		.equ 239
kX-1		.equ 223
kMath		.equ 191
kAlpha		.equ 127 

;Group 7
KeyRow_Top 	.equ 0bfh
KGraph		.equ 254
KTrace		.equ 253
KZoom		.equ 251
KWindow		.equ 247
KY		.equ 239
k2nd		.equ 223
kMode		.equ 191
kDel		.equ 127

