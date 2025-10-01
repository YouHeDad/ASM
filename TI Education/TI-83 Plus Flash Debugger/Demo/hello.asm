;A Simple Application Example - Hello
;This example just prints the word "HELLO" on the display and exits

;Include file needed to access system routines
 include "ti83plus.inc"

EXT_APP equ 1   ;This definition is required of all apps
cseg            ;This linker directive is required of all apps.

;This is the application header definition area required for all apps.
 db 080h,0Fh    ;Field: Program length
 db   00h,00h,00h,00h ;Length=0 (N/A for unsigned apps)
 db 080h,012h    ;Field: Program type
 db   01h,04h  ;Type= Shareware, TI-83Plus
 db 080h,021h    ;Field: App ID
 db   01h       ;Id = 1
 db 080h,031h    ;Field: App Build
 db   01h       ;Build = 1
 db 080h,048h    ;Field: App Name
 db 048h,065h,06ch,06ch,06fh,020h,020h,020h ;Name = "Hello   " must be 8 characters
 db 080h,081h    ;Field: App Pages
 db 01h         ;App Pages = 1
 db 080h,090h    ;No default splash screen
 db 03h,026h ,09h,04h, 04h,06fh,01bh,80h     ;Field: Date stamp- 5/12/1999
 db 02h,0dh,040h                             ;Dummy encrypted TI date stamp signature
 db 0a1h ,06bh ,099h ,0f6h ,059h ,0bch ,067h 
 db 0f5h ,085h ,09ch ,09h ,06ch ,0fh ,0b4h ,03h ,09bh ,0c9h 
 db 03h ,032h ,02ch ,0e0h ,03h ,020h ,0e3h ,02ch ,0f4h ,02dh 
 db 073h ,0b4h ,027h ,0c4h ,0a0h ,072h ,054h ,0b9h ,0eah ,07ch 
 db 03bh ,0aah ,016h ,0f6h ,077h ,083h ,07ah ,0eeh ,01ah ,0d4h 
 db 042h ,04ch ,06bh ,08bh ,013h ,01fh ,0bbh ,093h ,08bh ,0fch 
 db 019h ,01ch ,03ch ,0ech ,04dh ,0e5h ,075h 
 db 80h,7Fh      ;Field: Program Image length
 db   0,0,0,0    ;Length=0, N/A
 db   0,0,0,0    ;Reserved
 db   0,0,0,0    ;Reserved
 db   0,0,0,0    ;Reserved
 db   0,0,0,0    ;Reserved
 
;End of header data

StartApp:                 ;The app starts here

  B_CALL ClrLCDFull        ;Clear the screen
  xor a                    ;A=0
  ld (curCol),a          ;Will start printing in left column
  ld a, 3
  ld (curRow),a          ;Will start printing on 4th row
  ld hl, SHello            ;HL points to null-terminated string in ROM
  ld de, OP1               ;DE points to a ram buffer named OP1
  B_CALL StrCopy           ;Copy the string to ram
  ld hl, OP1               ;HL points to null-terminated string in RAM
  B_CALL PutS              ;Print the hello string from RAM
  B_CALL GetKey            ;Wait for a keypress
  B_JUMP JForceCmdNoChar   ;Exit the application

SHello .asciz "HELLO"       ;Null-terminated string
