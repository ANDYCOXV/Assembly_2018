; Author: Andy Cox V
; Date: 8-16-2016
; lptwrite.asm --> lptwrite.com
; Description:
;   This program is used to write data from a file to the parellel prot 0x378.
;   Also to note the last two bytes from a text file will make the parellel port terminate the same.

Org     0x0100
Bits    16
CPU     8086

    section .data
    
    filename    times 0x0B DB 0x00  ; MS-DOS 8.3 file name with null termination.
    buffer      DB  0x00
    counter     DB  0x00
    
    dx_size     DW  0x0000
    ax_size     DW  0x0000
    
    filestring  DB  0x0D, 0x0A, "File to load: ", '$'
    playstring  DB  0x0D, 0x0A, "Writing file to LPT port 0x378.", 0x0D, 0x0A, '$'
    errors      DB  0x0D, 0x0A, "Error opening or reading the file.", '$'
    welcome     DB  0x0D, 0x0A, "Andy Cox V - 8/16/2016 - lptwrite.com - v1.0", '$'
    
    section .text

    global  start
    
start:

    Mov     ax, 0x0900
    Lea     dx, [welcome]
    Int     0x21
    
    Mov     ax, 0x6200  ; MS-DOS find PSP.
    Int     0x21
    
    Mov     ds, bx      ; Load PSP address.
    Mov     bx, 0x0082
    Mov     si, bx
    Lea     di, [filename]
    
loadfile:               ; Copy PSP file name.

    Movsb
    
    Cmp     byte [di], 0x0D
    Jne     loadfile
    
    Mov     ax, 0x0900
    Lea     dx, [filestring]
    Int     0x21
    
    Lea     si, [filename]
    Mov     ax, 0x0E00
    
printname:

    Lodsb
    Int     0x10
    
    Cmp     al, 0x0D
    Jne     printname
    
    Dec     si
    Mov     [si], byte 0x00
    
    Mov     ax, 0x3D00      ; Open file read only.
    Lea     dx, [filename]
    Int     0x21
    
    Xchg    ax, bx
    
    Jc      readfileerror
    
    Mov     ax, 0x0900
    Lea     dx, [playstring]
    Int     0x21
    
    Mov     ax, 0x4202
    Xor     cx, cx
    Xor     dx, dx
    Int     0x21
    
    Jc      readfileerror
    
    Mov     word [dx_size], dx
    Mov     word [ax_size], ax
    
    Mov     ax, 0x4200
    Xor     cx, cx
    Xor     dx, dx
    Int     0x21
    
    Jc      readfileerror
    
readfile:
    
    Mov     ax, 0x3F00      ; Read one character at a time.
    Mov     cx, 0x0001
    Lea     dx, [buffer]
    Int     0x21
    
    Jc      readfileerror
    
    Mov     dx, 0x378       ; Write byte to parellel port.
    Mov     al, [buffer]
    Out     dx, al
    
    Mov     ax, 0x0E20
    Int     0x10
    
    Mov     ah, 0x09
    Mov     cx, 0x0001
    Int     0x10
    
    Or      word [ax_size], 0x0000
    Jz      decreasedx
    
    Dec     word [ax_size]
    
    Jmp     short readfile
    
decreasedx:

    Or      word [dx_size], 0x0000
    Jz      readfiledone
    
    Dec     word [dx_size]
    
    Jmp     short readfile
    
readfileerror:

    Mov     ax, 0x0900  ; Display error and quit.
    Lea     dx, [errors]
    Int     0x21
    
readfiledone:
    
    Mov     ax, 0x3E00  ; Close file with handle.
    Int     0x21
    
    Mov     dx, 0x378       ; Write null to parellel port.
    Xor     ax, ax
    Out     dx, al
    
    Int     0x20