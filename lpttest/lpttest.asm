; Author: Andy Cox V
; Date: 8-16-2016
; lptkey.asm --> lptkey.com
; Description:
;   This program is used as a demo to test a 8-bit mono DAC to the LPT port.

Org     0x0100
Bits    16
CPU     8086

    section .data
    
    welcome     DB  0x0D, 0x0A, "Andy Cox V - 8/16/2016 - lpttest.com - v1.0", 
                DB  0x0D, 0x0A, "Writing to port 0x378, press 'q' to quit.", 0x0D, 0x0A, '$'
    
    section .text
    global  start
    
start:

    Mov     ax, 0x0900
    Lea     dx, [welcome]
    Int     0x21

    Xor     bx, bx
    
run:

    Mov     dx, 0x378
    Inc     bl
    Mov     al, bl
    Out     dx, al

    Mov     ax, 0x0100
    Int     0x16
    
    Jz      run
    
    Xor     ax, ax
    Int     0x16
    
    Cmp     al, 'q'
    Jne     run
    
    Mov     dx, 0x378
    Xor     ax, ax
    Out     dx, al
    
    Int     0x20