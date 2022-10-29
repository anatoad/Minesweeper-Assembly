%include "functions.asm"

global _start

section .rodata
msg_flag db 'Remaining flags: '
msg_flag_len equ $-msg_flag

msg_option db 'Insert option (f - flag, c - clear): '
msg_option_len equ $-msg_option

msg_line db 'line: '
msg_line_len equ $-msg_line

msg_column db 'column: '
msg_column_len equ $-msg_column

msg_lose db 'You lost!', 10
msg_lose_len equ $-msg_lose

msg_cleared db 'cleared: '
msg_cleared_len equ $-msg_cleared

msg_win db 'You won!', 10
msg_win_len equ $-msg_win

adj db -11, -10, -9, -1, 1, 9, 10, 11
adj_len equ $-adj

clear_total db 72
bomb_value db 35
mask db 1111b
matrix_size dq 10

section .data
values times 100 db '0'
table times 100 db 61

buffer db 0
print_buffer db 0

option db 0
line db 0
column db 0
lost db 0

cleared db 0

total_flags db '9'
remaining_flags db '9'

section .text

_start:
    call init_table                     ; initialize table values

    mov rdi, table
    call print_matrix                   ; print initial table

    call print_flag_message

    call init_bombs                     ; initialize bombs randomly on the table

    call init_values                    ; initialize values of cells adjacent to bombs

    mov dil, 10                         ; newline ASCII code
    call print_char                     ; print newline character

loop_game:
    call read_input                     ; read input from the user

    call alter_table                    ; alter table based on user input

    mov rdi, table
    call print_matrix                   ; print table matrix

    call print_flag_message

    call print_cleared_message

    cmp byte [lost], 1                  ; check if game is lost
    je lose

    cmp byte [cleared], 72              ; check if all cells have been cleared
    jne loop_game

    mov rdi, msg_win
    mov rsi, msg_win_len
    call write                          ; game is won

    jmp end_game

lose:
    mov rdi, msg_lose
    mov rsi, msg_lose_len
    call write                          ; game is lost

end_game:
    call exit
    ret