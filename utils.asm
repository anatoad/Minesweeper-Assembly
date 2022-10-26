%include "header.asm"

section .text

is_valid_index:             ; check if index is within matrix bounds
    pusha

    mov rcx, rdi            ; index to be checked
    mov byte [buffer], 1    ; assume index is correct

    cmp rcx, 11             ; check if index is on line 0 of matrix
    jl incorrect_index

    cmp rcx, 99             ; check if index excedes matrix lines
    jg incorrect_index

    mov rdi, rcx
    mov rsi, 10
    call modulo

    cmp al, 0               ; check if index is on column 0 of matrix
    je incorrect_index

    jmp exit_correct_index

incorrect_index:
    mov byte [buffer], 0

exit_correct_index:
    popa
    xor rax, rax
    mov al, [buffer]
    ret


init_table:             ; initialize the table (mark digits 1-9 on the edges)
    mov rcx, 10
    mov rdx, 90
    mov rsi, 39h

digits:
    mov byte [table + rcx - 1], sil
    mov byte [table + rdx], sil

    sub rdx, 10
    dec rsi
    loop digits

    mov byte [table], 32

    ret


init_bombs:              ; initialize bombs in the values matrix
    pusha

    mov rcx, 0
bombs:
    xor rbx, rbx

    call get_random_digit   ; get random line
    mov bl, al

    pusha
    xor rdx, rdx
    mov al, bl
    mov dl, 10
    mul dl

    mov [buffer], al
    popa

    xor rbx, rbx
    mov bl, [buffer]

    call get_random_digit   ; get random column
    add bl, al

    cmp byte [values + rbx], 35
    jne next
    jmp bombs

next:
    mov byte [values + rbx], 35
    add rcx, 1
    cmp rcx, 9
    jl bombs

    popa
    ret


init_values:        ; init values of cells adjaent to bombs
    pusha

    mov rcx, 11
compute:
    xor r9, r9
    mov r9b, byte [values + rcx]

    cmp r9b, byte [bomb_value]
    jne idle

    mov rdx, 0
iterate_adj:
    mov rbx, rcx
    add bl, byte [adj + rdx]    ; adjacent index

    xor rdi, rdi
    mov dil, bl
    call is_valid_index

    cmp rax, 0
    je skip

    mov sil, byte [values + rbx]
    cmp sil, byte [bomb_value]
    je skip

    inc sil
    mov byte [values + rbx], sil

skip:
    inc rdx
    cmp rdx, 8
    jl iterate_adj 

idle:
    inc rcx
    cmp rcx, 100
    jl compute

    popa
    ret


inc_cleared:        ; increment value of variable cleared by 1
    pusha

    xor rax, rax
    mov al, byte [cleared]
    inc al
    mov byte [cleared], al 

    popa
    ret


recursive_clear:
    pusha

    mov rdx, rdi        ; start index in dl

    cmp byte [table + rdx], 61
    jne exit_recursive_clear

continue_recursion:
    mov r9b, byte [values + rdx]    ; current value in values
    mov byte [table + rdx], r9b     ; clear value on table

    call inc_cleared
    
    xor rcx, rcx
iterate:
    mov rbx, rdx
    add bl, byte [adj + rcx]         ; new index in bl

    mov dil, bl
    call is_valid_index
    cmp al, 0
    je next_index

    mov r9b, byte [values + rbx]     ; new values

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


alter_table:
    pusha

    xor rbx, rbx
    xor rcx, rcx
    mov bl, [line]

    mov rdi, rbx
    mov rsi, 10
    call multiply

    mov cl, al
    add cl, [column]        ; cl holds the index

    mov dl, byte [values + rcx] ; dl holds the value

    cmp byte [option], 'f'
    je option_flag

    ;; option clear

    cmp dl, 'f'         ; clear wrong flag 
    je clear_flag

    cmp dl, '0'
    je zeros

    mov byte [table + rcx], dl
    
    call inc_cleared

    cmp dl, [bomb_value]
    je lost_game

zeros:
    xor rdi, rdi
    mov dil, cl
    call recursive_clear

    jmp exit_alter_table

clear_flag:
    mov byte [table + rcx], dl
    mov bl, [remaining_flags]
    inc bl
    mov byte [remaining_flags], bl
    jmp exit_alter_table


option_flag:
    mov byte [table + rcx], 'f'
    mov bl, [remaining_flags]
    dec bl
    mov byte [remaining_flags], bl
    
    jmp exit_alter_table

lost_game:
    mov byte [lost], 1

exit_alter_table:
    popa
    ret