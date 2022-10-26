%include "utils.asm"

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
mask db 00001111b

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
    call init_table

    mov rdi, table
    call print_matrix

    call print_flag_message

    call init_bombs

    call init_values

    mov dil, 10
    call print_char

loop_game:
    call read_input

    call alter_table

    mov rdi, table
    call print_matrix

    call print_flag_message

    call print_cleared_message

    cmp byte [lost], 1
    je lose

    cmp byte [cleared], 72
    jne loop_game

    mov rdi, msg_win
    mov rsi, msg_win_len
    call write

    jmp end_game

lose:
    mov rdi, msg_lose
    mov rsi, msg_lose_len
    call write

end_game:
    call exit
    ret