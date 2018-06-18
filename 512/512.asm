; Author: Andy Cox V
; Programming Language: NASM Assembly Language for the x86
; Date: 12/5/2016 - 12/19/2016
; Arguments: nasm 512.asm -fbin -o512.asm
; Notes:
; This program is a game is executed as its own operating system that fits inside the first 512 bytes (hence the name).
; This program must be loaded in the MBR inorder to work.
; Virtual machines respond faster than real machines.
; The goal of the game is to collect as many tokens as possible without crossing your old path.
; WASD is used to move. 
; This program is ment to run on anything IBM PC compatable that can support an Intel 8086 and up.
; BIOS inturrupts were used to get system time, and keyboard input.
; These functions could have been implemented without inturrupts, but game space is limited.

; http://muruganad.com/8086/8086-assembly-language-program-to-play-sound-using-pc-speaker.html
;       Note 	Frequency 	Frequency #
;       C 	130.81 		9121
;       C# 	138.59 		8609
;       D 	146.83 		8126
;       D# 	155.56 		7670
;       E 	164.81 		7239
;       F 	174.61 		6833
;       F# 	185.00 		6449
;       G 	196.00 		6087
;       G# 	207.65 		5746
;       A 	220.00 		5423
;       A# 	233.08 		5119
;       B 	246.94 		4831
;       MidC 	261.63	 	4560
;       C# 	277.18 		4304
;       D 	293.66 		4063
;       D# 	311.13 		3834
;       E 	329.63 		3619
;       F 	349.23 		3416
;       F# 	369.99 		3224
;       G 	391.00 		3043
;       G# 	415.30 		2873
;       A 	440.00 		2711
;       A# 	466.16 		2559
;       B 	493.88 		2415
;       C 	523.25 		2280
;       C# 	554.37 		2152
;       D 	587.33 		2031
;       D# 	622.25 		1917
;       E 	659.26 		1809
;       F 	698.46 		1715
;       F# 	739.99 		1612
;       G 	783.99 		1521
;       G# 	830.61 		1436
;       A 	880.00 		1355
;       A# 	923.33 		1292
;       B 	987.77 		1207
;       C 	1046.50 	1140

        bits 16 ; The 8086 is a 16 bit CPU.
        cpu 8086 ; Check code to make sure this CPU 8086 can support it.
        org 0x7c00 ; MBR is loaded to here.
        
        global start
        
        PLAYER_TOTAL equ 0x1f02 ; Player Sprite then color.
        TOKEN_SPRITE equ 3
        BACKGROUND_SPRITE equ 0x20
        UP_BLOCK_SPRITE equ 0x18
        DOWN_BLOCK_SPRITE equ 0x19
        RIGHT_BLOCK_SPRITE equ 0x1a
        LEFT_BLOCK_SPRITE equ 0x1b
        BLOCK_COLOR equ 0x40
        BACKGROUND_COLOR equ 0x99 ; 0x99 to block out the cursor.
        TOKEN_COLOR equ 0x9e
        MAX_WINDOW equ 3998
        WINDOW_LOOP equ 4000 ; Set loop for the window.
        
start:
    
        xor bx, bx
        lea si, [Animation_String]
        mov cx, 18 ; Size of credits string to print
        
animation_loop:

        push cx
        
        lodsb
        xchg cx, ax
        mov ch, 0x1e
        call print
        
        pop cx
        
        loop animation_loop

        xor ax, ax
        int 0x16
    
run:

        call clear_screen
        
        call RTC_Seconds
        
        and bx, 0x0e3e

        mov word [Character_Location], bx
        
        call print_player ; Player spawn here so token does not get over written!
        
        call spawn_token
        
        lea si, [Beep_Start]
        call beep
        
player_move: ; Use WASD to move in the respected directions.
        
        call check_move
        
        call print_player
        
        xor ax, ax
        int 0x16
        
        inc word [Moves_Count] ; Increase the player moves counter.
        
        cmp al, 'w'
        je move_up
        
        cmp al, 'a'
        je move_left
        
        cmp al, 's'
        je move_down
        
        xor al, 'd'
        jz move_right
        
        jmp short player_move
        
move_up:

        mov cl, UP_BLOCK_SPRITE
        call make_block
        
        sub word [Character_Location], 160 ; Currurent Location - (80*2)
        
        jmp short player_move

move_down:

        mov cl, DOWN_BLOCK_SPRITE
        call make_block

        add word [Character_Location], 160 ; Current Location + (80*2)
        
        jmp short player_move

move_left:

        mov cl, LEFT_BLOCK_SPRITE
        call make_block
        
        sub word [Character_Location], 2 ; Current Location + 2
        
        jmp short player_move

move_right:
        
        mov cl, RIGHT_BLOCK_SPRITE
        call make_block
        
        add word [Character_Location], 2 ; Current Location - 2
        
        jmp short player_move
        
; --- Procedures ---
        
; *** print_player ***
; This procedure simply prints the player sprite.

print_player:

        mov cx, PLAYER_TOTAL
        mov bx, word [Character_Location]
        call print
        
        retn

; *** check_move ***
; This procedure checks the players moves.
; If the player runs into a block then game over.
; If the player goes up or down past the screen the player is re-looped.

check_move:

        mov bx, word [Character_Location]

        cmp bx, MAX_WINDOW ; Check to see if the player is above screen boundies.
        jg un_down
        
        cmp bx, 0 ; Check to see if the player is below screen boundies.
        jl un_up
        
motion_check:

        mov bx, word [Character_Location] ; This is used again for un_up, and un_down.

        call video_check
        
        cmp dh, TOKEN_SPRITE
        je token_found
        
        cmp dh, UP_BLOCK_SPRITE ; Has a block been crossed?
        jge up_crossed
        
        retn
        
up_crossed:

        cmp dh, LEFT_BLOCK_SPRITE ; Has a block been crossed?
        jle game_over
        
        retn
        
un_up: ; Jump down to the other side.

        add word [Character_Location], WINDOW_LOOP
        
        jmp short motion_check
        
un_down: ; Jump up to the other side.

        sub word [Character_Location], WINDOW_LOOP
        
        jmp short motion_check
        
token_found: ; Spawn another token and increment score.

        inc word [Token_Count]

        lea si, [Beep_Token]
        call beep

        call spawn_token

        retn
        
; *** RTC_Seconds ***
; This will return the value in seconds in both bh, and bx.
; It is used for simplified random number generation.
; OUT: bx - Time in seconds bx = blbl.

RTC_Seconds:

        cli     ; Read time from CMOS RTC. 0x7(REGISTER) to disable NMI.
        xor ax, ax
        out 0x70, al ; Register 0x00, for time seconds.
        in al, 0x71 ; Aquire time in seconds.
        xchg bl, al
        mov bh, bl ; Copy contents of bl to bh. In turn bx = blbl
        sti
        
        retn
        
; --- THIS IS NOT A PROCEDURE ---
; The reasoning for this placed here is so that jump instructions can be short and not standard jumps.
; This simply prints out player stats, ever token collected is printed using the TOKEN_SPRITE.
; Every move made by the plater is printed using the PLAYER_SPRITE.
        
game_over:

        lea si, [Beep_End]
        call beep

        call clear_screen ; xor bx, bx to not clear the scren, but still print.
        
        mov cx, word [Token_Count]
        
loop_tokens: ; Print the tokens.

        push cx
        
        mov cx, 0x1e03
        call print
        
        pop cx
        
        loop loop_tokens

        mov word [Token_Count], cx ; Clear the token count, cx is set to zero because of loop.
        
        mov cx, word [Moves_Count]
        
loop_moves: ; Print the number of moves.

        push cx
        
        mov cx, PLAYER_TOTAL
        call print
        
        pop cx
        
        loop loop_moves

        mov word [Moves_Count], cx ; Clear the moves count, cx is set to zero because of loop.
        
        xor ax, ax ; Wait for keypress.
        int 0x16
        
        jmp run ; New game.
        
; *** spawn_token ***
; This procedure spawns tokens by the use of the Real Time Clock (CMOS) and a small random number generator.
; If the original number is invalid then a psuedo random number generation tequnique will be used to shell
; out 65535 (0xffff) numbers. If all of the numbers shelled out are invalid (0xffff is used to keep from lagging)
; then a BACKGROUND_SPRITE search routine will be used. If not BACKGROUND_SPRITEs can be found then game over.

spawn_token:
        
        call RTC_Seconds ; Call the Real Time Clock (CMOS) for time in seconds.

        cmp bx, MAX_WINDOW
        jng token_rand_good

        and bx, 0x0e3e ; Fit roughly into boundries if greater than MAX_WINDOW (will not accept last 176 sopots).
        
token_rand_good:
        
        call video_check ; Aquire ASCII character set at location set by bx.
        
        xor dh, BACKGROUND_SPRITE
        jz print_token

        mov ax, bx
        or cx, 0xffff ; Preform 0xffff loops, so game wont lag if BACKGROUND_SPRITE not found.
        
psuedorand_loop: ; Random number generation, to shove as many numbers out as fast as possible.

        xor ax, cx
        sub bx, ax
        xor bx, ax

        cmp bx, MAX_WINDOW
        jng psuedorand_next

        and bx, 0x0e3e
        
psuedorand_next:
        
        call video_check
        
        xor dh, BACKGROUND_SPRITE
        jz print_token
        
        loop psuedorand_loop
        
; Check for the existance of a background sprite, THIS IS LAST RESORT MEASURE!
; bx is the value of the BACKGROUND_SPRITE in video.
; If BACKGROUND_SPRITE is not found then no BACKGROUND_SPRITEs are avaiable therefore the game is over.
        
        mov bx, 4000 ; MAX_WINDOW + 2
        
check_for_existance_loop:

        sub bx, 2
        
        call video_check

        xor dh, BACKGROUND_SPRITE
        jz print_token ; BACKGROUND_SPRITE found then print.
        jnz check_for_existance_loop
        
        jmp short game_over ; Token not found then quit.
        
print_token:
        
        cmp bx, 0 ; Is bx set to a space below zero, if so reprint?
        jl spawn_token
        
        ; --- RESTORE IN CASE OF CODE FAILURE TO SPAWN TOKEN WITHIN BOUNDRIES. ---
        ;cmp bx, MAX_WINDOW
        ;jng continue_print_token
        
        ;and bx, 0x0e3e If bx is set above the window size then cut down on bx.
        
continue_print_token:
        
        mov cx, 0x9e03 ; TOKEN_SPRITE + TOKEN_COLOR
        call print
        
        retn

; *** make_block ***
; This procedure will print the blocks to make the player's uncrossable path.

make_block:

        mov bx, word [Character_Location]
        mov ch, BLOCK_COLOR
        call print
        
        retn

; *** beep ***
; This procedure will beep the internal PC speaker, with a string of three tones set to play at 110 milliseconds.
; It helps if inturrupts are halted.
; Int 0x1a is used to get amount of ticks since system boot.
; Ticks update every 18.2hz or 55 milliseconds.
; The PIC is programmed to create the PC speaker to beep, Channel two to be exact.
; IN: si - Three words to generate a tone.

beep:

        cli

        mov al, 0xb6 ; Prepair internal PC speaker/buzzer.
        out 0x43, al
        
        mov cx, 0x03 ; Number of notes to irritate through.
        
beep_loop:

        push cx
        
        lodsw ; Load the tone to play.
        
        out 0x42, al ; Play the upper byte.
        xchg al, ah
        out 0x42, al ; Play the lower byte.
        
        in al, 0x61 ; Turn on the PC Speaker with notes.
        or al, 0x03
        out 0x61, al
        
        mov cx, 2 ; Change this value to 18 to make it sound normal on Bochs virtual machines.
                  ; cx helps act like a time multiplier.
        
millisecond_delay_55:
        
        push cx
        
        xor ax, ax ; Aquire amount of ticks (a tick occurs every 18.2hz) since system startup stored at 0x40:0x6c, had trouble loading time so int 0x1a is used.
        int 0x1a
        xchg dx, bx
       
millisecond_loop_Change_Check:

        xor ax, ax ; Aquire another tick.
        int 0x1a
       
        xor dx, bx ; Check for a change in ticks. To note 18.2hz is roughly 55 milliseconds.
        jz millisecond_loop_Change_Check
        
        pop cx
        
        loop millisecond_delay_55 ; Loop until time multiplier set by cx is zero.
        
        pop cx
        
        loop beep_loop ; Aquire another note until zero.
        
silent_beep:

        in al, 0x61 ; Aquire current note
        and al, 0xfc ; Set last two bits to zero.
        out 0x61, al ; Resend new note for silents.

        sti
        
        retn
        
; *** video_check ***
; IN: bx - Location to aqurire ASCII character.
; OUT: dh - ASCII character at location specified by bx.

video_check:

        push ds
        
        mov ax, 0xb800 ; Move data segment offset to video memory.
        mov ds, ax

        mov dh, byte [bx] ; Aquire ASCII character at location bx.
        
        pop ds
        
        retn
        
; *** print ***
; This procedure will print a ASCII character to the screen.
; To note the reason why this does not print strings is because typically only a single ASCII character will be printed.
; cx, bx, and si will be destroyed.
; IN: cl - register is used for the single ASCII character.
; IN: bx - video memory offset pointer, 0 = upper left hand corner.
; IN: ch - color upper nibble background, lower nibble foreground color.

print:

        push ds
        
        mov ax, 0xb800 ; Move data segment offset to video memory.
        mov ds, ax
        xchg dx, ax ; Use dx to temporarily store video memory offset.
        
        mov word [bx], cx ; Character and color.

        add bx, 2
        
        pop ds ; Restore original code segment.
        
        retn

; *** clear_screen ***
; This procedure will clear the screen using space characters 0x20.
; The cursor will be reset at position 0, upper left corner.
; To note characters displayed on the screen are 2 bytes long.

clear_screen:

        mov cx, 2000 ; Whole screen = (80*25) = 2000
        xor bx, bx ; Set the screen offset at zero.
        
clear_screen_loop:
        
        push cx
        
        mov cx, 0x9920 ; BACKGROUND_SPRITE + BACKGROUND_COLOR
        call print ; bx will be returned with the new value
        
        pop cx
        
        loop clear_screen_loop ; Not as fast as dec cx, jnz..., but saves more space.
        
        xor bx, bx ; Reset screen to top left corner.
        
        retn

        Character_Location dw 0
        Moves_Count dw 0
        Token_Count dw 0
        
        Animation_String db "512", TOKEN_SPRITE, "GAME", 2, "APCV", TOKEN_SPRITE ,"2016" ; 2 = Player Sprite
        
        ; These words are the frequencies of specific notes.
        ; The table for the notes can be found at the beginning of this program.
        Beep_Start dw 2711, 1292, 7239
        Beep_Token dw 9121, 4560, 1140
        Beep_End dw 1140, 7239, 9121
        
        times 510 - ($-$$) db 0 ; Pad bootloader with nulls.
        dw 0xaa55 ; Used to denote as bootable medium.