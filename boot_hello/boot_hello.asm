; Author: Andy Cox V
; Programming Language: NASM Assembly Language for the x86
; Minimum Supported Processor: 8086 in read mode
; Date: 11/6/2016
; Arguments: nasm boot_hello.asm -fbin -oboot_hello.img
; Notes:
;   * 0xB800 is the start of the text screen video memory.
;   * Typically short jumps can be used, but for expandability the regular jmp is used.

    bits 16
    cpu 8086
    org 0x7c00  ; Offset to load program.
    
    section .text
    
    global Start
    
Start:

    jmp End_Program ; Load all variables into memory.

Run:

    mov cx, 4000 ; whole screen = (80*25)*2 = 4000
    mov word [Video_Offset], 0

clear_screen:

    lea si, [Box_Special]
    mov bx, [Video_Offset]
    mov ch, 0x02
    call Print

    add word [Video_Offset], 2
    
    loopnz clear_screen

    lea si, [Hello_String]
    xor bx, bx ; Variables will be off once ds is set to different location (so load var into bx).
    mov ch, 0x1e    ; Color
    call Print
    
    ; Save print position --> mov word [Video_Offset], bx ; Save the most recent location of the print position.
    lea si, [Next_String]
    mov bx, 160 ; Row 1 = (80*1)*2 = 160
    mov ch, 0xe1    ; Color
    call Print
 
; Print the American Flag!
; To note this American Flag is not to scale when it comes to the stripes, because the bars are slightly
;   offset that is how 13 stripes can fit without it looking weird, inorder for this flag to look
;   somewhat normal it is nessessary to expand the amount of stripes the flag has.
; !ALSO! Make note that this is not the most effecient and even sligtly complicated way of printing the
;   American Flag.

    ; Print stripes of american flag
    
    mov word [Video_Offset], 480 ; Row 3 = (80*3)*2 = 480
    mov cx, 15
    
box_print_3:
    push cx
    mov cx, 80
    
    xor byte [color], 0xbb ; red, xor so colors can alternate 0xff xor 0xbb = 0x44.
    
box_loop_3:
    
    push cx
    lea si, [Box_Special]
    mov bx, [Video_Offset]
    mov ch, byte [color]
    call Print
    pop cx
    
    add word [Video_Offset], 2
    
    loopnz box_loop_3
    
                ; Would reset here, but 160 - 160 + 160 = 160 = new line.
    pop cx
  
    loopnz box_print_3
    
    ; Print box of american flag rows with 6 stars
    
    mov word [Video_Offset], 480 ; Row 3 = (80*3)*2 = 480
    mov cx, 5
    
box_print:
    push cx
    mov cx, 6
    
box_loop:
    
    push cx
    lea si, [Box]
    mov bx, [Video_Offset]
    mov ch, 0x1f
    call Print
    pop cx
    
    add word [Video_Offset], 4
    
    loopnz box_loop
    
    sub word [Video_Offset], 24 ; Reset to start of row after printing 6, 4 positioned characters.
    add word [Video_Offset], 320 ; Advance two rows.
    pop cx
  
    loopnz box_print
    
    ; Print box of american flag rows with 5 stars
    
    mov word [Video_Offset], 640 ; Row 4 = (80*5)*2 = 640
    mov cx, 4
    
box_print_2:
    push cx
    
    push cx
    lea si, [Box_Special]
    mov bx, [Video_Offset]
    mov ch, 0x1f
    call Print
    pop cx
    
    add word [Video_Offset], 2 ; Don't increse by one to change characters increase by two.
    
    mov cx, 5
    
box_loop_2:
    
    push cx
    lea si, [Box]
    mov bx, [Video_Offset]
    mov ch, 0x1f
    call Print
    pop cx
    
    add word [Video_Offset], 4
    
    loopnz box_loop_2
    
    add word [Video_Offset], 2
    
    push cx
    lea si, [Box_Special]
    mov bx, [Video_Offset]
    mov ch, 0x1f
    call Print
    pop cx
    
    sub word [Video_Offset], 24 ; Reset to start of row after printing 5, 4 positioned characters with extra 2 blank 2 position.
    add word [Video_Offset], 320 ; Advance two rows.
    pop cx
  
    loopnz box_print_2
    
    lea si, [NO_BIOS]
    mov bx, 3414    ; Middle of 21st row, with middle of string KEEP NUMBERS EVEN!
    mov ch, 0xe0
    call Print
    
    hlt ; Endless looping from here on out.
    jmp $
    
; This procedure will print a string to the console in text mode without BIOS inturrupts
; To use:
;   lea si, [byte_array/string] must be null terminating.
;   Move the location to start writing into bx, ex: 0 = top left corner.
;   Move a byte into ch, the upper nibble will be background, while lower nibble is letter color.
; Notes:
;   At the end inorder to store the location of the print position mov the value of bx into a variable.
;   Print position is always last character +1 in location.
;   Unlike TTY mode 0x0A, 0x0D, 0x07, etc... print out their assigned ASCII character they do not alter the console.

Print:

    push ds

    mov ax, 0xb800
    mov ds, ax
    mov dx, ax
    
Print_Loop:

    pop ds
    lodsb
    push ds
    push ax
    mov ax, dx
    mov ds, ax
    pop ax
    
    or al, 0
    jz Print_Break
    
    mov [bx], al
    inc bx
    mov [bx], ch
    inc bx
    
    jmp short Print_Loop

Print_Break:

    pop ds
    
    Ret
    
    Video_Offset dw 0
    NO_BIOS db "!NO BIOS Interrupts used!", 0
    Hello_String db "Hello World!", 0
    Next_String db 0x01, "There are 10 kinds of people those who understand binary and those who don't!!", 0x01, 0
    Box db ' * ', 0
    Box_Special db ' ', 0
    color db 0xff ; American Flag White
    
End_Program:    ; Keep in mind that string instructions are code make sure not to make them executable, jump here.
    
    jmp Run

    times 510 - ($-$$)  db  0    ; Pad bootloader with nulls. $ Address of current line, $$ Address of first instruction.
    dw  0xaa55  ; x86 is little endian, this is the word used to denote that this is a bootloader.
