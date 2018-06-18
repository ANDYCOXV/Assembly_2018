; Remember PSP executes when the program executes.
; To test run pspread.com with random command line arguments following.
; pspread HELLO! will return 07 HELLO!
; pspread alone will return 00
; Also this program specifically only reads the command line arguments only.

Org     0x0100
Bits    16
Cpu     8086

	section .text
	global start

start:
	
    Mov     ax, 0x6200  ; MS-DOS find PSP.
    Int     0x21
    
    Mov     ds, bx      ; Load PSP address.
    Mov     bx, 0x0081
    Mov     si, bx      ; Load command line part of PSP.
    Mov     ax, 0x0E00
    Xor     bx, bx
    
read:                   ; Print PSP.
	
    Lodsb
    Int     0x10
    
	Xor     al, 0x0D
    Jnz     read
    
    Int     0x20        ; Terminate Program.