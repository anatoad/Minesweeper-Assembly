%include "utils.asm"

section .text

is_valid_index:                     ; check if index is within matrix bounds
    pusha

    mov rcx, rdi                    ; index to be checked
    mov byte [buffer], 1            ; assume index is valid

    cmp rcx, 11                     ; check if index is on line 0 of matrix
    jl incorrect_index

    cmp rcx, 99                     ; check if index exceeds matrix lines
    jg incorrect_index

    mov rdi, rcx
    mov rsi, 10
    call modulo_8bit

    cmp al, 0                       ; check if index is on column 0 of matrix
    je incorrect_index

    jmp exit_correct_index

incorrect_index:
    mov byte [buffer], 0            ; mark index as not valid

exit_correct_index:
    popa
    xor rax, rax
    mov al, [buffer]                ; return 1 if index is valid, 0 otherwise
    ret


init_table:                         ; initialize the table (mark digits 1-9 on the edges)
    mov rcx, 9                      ; 9 digits to be marked
    mov rdx, 90                     ; start with the last line
    mov rsi, 39h                    ; '9' digit ASCII code

digits:
    mov byte [table + rcx], sil     ; mark column
    mov byte [table + rdx], sil     ; mark line

    sub rdx, 10                     ; go to the next line
    dec rsi                         ; go to the next digit
    loop digits

    mov byte [table], 32            ; set line 0 column 0 as empty

    ret


init_bombs:                         ; initialize bombs in the values matrix
    pusha

    mov rcx, 9                      ; 9 bombs to be initialized
bombs:                              ; randomly generate a cell (line and column) in table
    call get_random_digit           ; get random line number

    mov dil, al
    mov sil, 10
    call multiply_8bit              ; compute line index in matrix table
    mov [buffer], al

    xor rbx, rbx
    mov bl, [buffer]

    call get_random_digit           ; get random column number
    add bl, al                      ; compute cell index in matrix table

    cmp byte [values + rbx], 35     ; if cell is a bomb
    je bombs                        ; randomly generate another cell

next:
    mov byte [values + rbx], 35     ; mark current cell as a bomb
    loop bombs

    popa
    ret


init_values:                        ; initialize values of cells adjacent to bombs
    pusha

    mov rcx, 11
compute:
    xor r9, r9
    mov r9b, byte [values + rcx]    ; get value in current cell

    cmp r9b, byte [bomb_value]      ; check if cell contains a bomb
    jne idle

    mov rdx, 0
iterate_adj:                        ; iterate through adjacent cells
    mov rbx, rcx
    add bl, byte [adj + rdx]        ; adjacent index

    xor rdi, rdi
    mov dil, bl
    call is_valid_index

    cmp rax, 0                      ; skip adjacent cell if index in not valid
    je skip

    mov sil, byte [values + rbx]
    cmp sil, byte [bomb_value]      ; check if adjacent cell is a bomb
    je skip

    inc sil                         ; increase number of adjacent bombs
    mov byte [values + rbx], sil  

skip:                               ; go to the next adjacent cell
    inc rdx
    cmp rdx, 8
    jl iterate_adj 

idle:                               ; go to the next cell in table
    inc rcx
    cmp rcx, 100
    jl compute

    popa
    ret


inc_cleared:                        ; increment value of variable cleared by 1
    pusha

    mov al, byte [cleared]
    inc al
    mov byte [cleared], al 

    popa
    ret


recursive_clear:                    ; clear all adjacent cells that are not bombs
    pusha

    mov rdx, rdi                    ; start index in dl

    cmp byte [table + rdx], 61      ; check if cell has not yet been cleared
    jne exit_recursive_clear

continue_recursion:
    mov r9b,  [values + rdx]        ; current value in values
    mov [table + rdx], r9b          ; clear value on table

    call inc_cleared
    
    xor rcx, rcx
iterate:
    mov rbx, rdx
    add bl, byte [adj + rcx]        ; new index in bl

    mov dil, bl
    call is_valid_index             ; check if new index is valid
    cmp al, 0
    je next_index

    mov r9b, byte [values + rbx]    ; new values

    mov r10b, byte [table + rbx]    ; current value in values
    cmp r10b, 61
    jne next_index

    cmp r9b, '0'
    jne alter

    xor rdi, rdi
    mov dil, bl
    call recursive_clear
    jmp next_index

alter:
    mov byte [table + rbx], r9b     ; clear positive value on table
    call inc_cleared

next_index:
    inc rcx
    cmp rcx, 8
    jl iterate

exit_recursive_clear:
    popa
    ret


alter_table:                        ; alter value in table matrix
    pusha

    xor rbx, rbx
    xor rcx, rcx
    mov bl, [line]                  ; line number

    mov rdi, rbx
    mov rsi, 10
    call multiply_8bit              ; get line index

    mov cl, al
    add cl, [column]                ; cl stores the cell index
    mov dl, byte [values + rcx]     ; dl stores the cell value

    cmp byte [option], 'f'          ; check if option is f - flag
    je option_flag

    ; option c - clear
    cmp dl, [bomb_value]
    je lost_game

    cmp byte [table + rcx], 'f'     ; clear wrong flag 
    je clear_flag

    cmp dl, '0'
    je zeros

    mov byte [table + rcx], dl
    
    call inc_cleared

zeros:                             ; if value is 0 clear recursively adjacent cells
    xor rdi, rdi
    mov dil, cl
    call recursive_clear

    jmp exit_alter_table

clear_flag:                        ; clear a wrongly placed flag
    mov [table + rcx], dl
    mov bl, [remaining_flags]
    inc bl
    mov [remaining_flags], bl
    call inc_cleared

    jmp exit_alter_table

option_flag:                       ; flag current cell
    mov byte [table + rcx], 'f'
    mov bl, [remaining_flags]
    dec bl
    mov [remaining_flags], bl
    
    jmp exit_alter_table

lost_game:                         ; mark game as lost
    mov byte [lost], 1

exit_alter_table:
    popa
    ret