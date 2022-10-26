section .text

%macro pusha 0  ; push all registers onto the stack
    push rax
    push rcx
    push rdx
    push rbx
    push rsp
    push rbp
    push rsi
    push rdi
    push r9
    push r10
    push r11
%endmacro

%macro popa 0   ; restore register values
    pop r11
    pop r10
    pop r9
    pop rdi
    pop rsi
    pop rbp
    pop rsp
    pop rbx
    pop rdx
    pop rcx
    pop rax
%endmacro


write:              ; make write system call
    pusha

    mov rax, 1      ; write system call number (1)
    mov rdx, rsi    ; number of bytes to print (second argument)
    mov rsi, rdi    ; buffer (first argument)
    mov rdi, 1      ; stdout file descriptor
    syscall         ; call kernel

    popa
    ret


read:               ; make read system call      
    pusha

    mov rax, 0      ; read system call number (0)
    mov rsi, buffer ; buffer
    mov rdx, 1      ; bytes count
    mov rdi, 0      ; stdin file descriptor
    syscall         ; call kernel

    popa
    xor rax, rax
    mov al, [buffer]
    ret


multiply:           ; multiply two 8bit numbers
    pusha

    xor rax, rax
    xor rdx, rdx
    mov al, dil     ; first argument - first factor
    mul sil         ; multiply by second argument (second factor)

    mov [buffer], al

    popa
    xor rax, rax
    mov al, [buffer]
    ret


read_input:
    pusha

    mov rdi, msg_option
    mov rsi, msg_option_len
    call write

    call read
    mov byte [option], al
    call read

    mov rdi, msg_line
    mov rsi, msg_line_len
    call write

    call read
    sub al, '0'
    mov byte [line], al
    call read

    mov rdi, msg_column
    mov rsi, msg_column_len
    call write

    call read
    sub al, '0'
    mov byte [column], al
    call read

    popa
    ret


exit:             ; make exit system call
    mov rax, 60   ; exit system call number (60)
    mov rdi, 0    ; no error code
    syscall

    ret


print_char:       ; print a character to stdout
    pusha

    mov byte [print_buffer], dil
    mov rdi, print_buffer
    mov rsi, 1
    call write

    popa
    ret


modulo:         ; return remainder of division between two given argumentss
    pusha       ; rdi - dividend (first argument), rsi - divisor(second argument)

    xor rdx, rdx
    mov ax, di
    div sil

    shr rax, 8
    mov [buffer], al

    popa
    xor rax, rax
    mov al, [buffer]

    ret


divide:         ; return quotient of division between two given arguments
    pusha       ; rdi - dividend (first argument), rsi - divisor(second argument)
    
    xor rdx, rdx
    mov ax, di
    div sil
    
    mov [buffer], al

    popa
    xor rax, rax
    mov al, [buffer]
    ret


print_matrix:    ; print a given matrix to stdout
    pusha

    mov rcx, 0
    mov rdx, 0
    mov rax, rdi

print_lines:
    mov rsi, 0

print_columns:
    xor rdi, rdi
    mov dil, byte [rax + rdx]
    call print_char

    mov rdi, 32         ; space ASCII code
    call print_char

    inc rdx
    inc rsi
    cmp rsi, 10
    jl print_columns

    mov rdi, 10         ; newline ASCII code
    call print_char

    inc rcx
    cmp rcx, 10
    jl print_lines

    popa
    ret


get_random_digit:      ; return a random digit between 1-9
    pusha

    mov rax, 318       ; getrandom system call number (318)
    mov rdi, buffer
    mov rsi, 1         ; bytes count
    mov rdx, 0         ; no flags
    syscall

    mov al, byte [buffer]  ; store the randomly generated byte in al and
    and al, byte [mask]    ; normalize it to be in range 1-9
 
    cmp al, 9
    jle continue
    sub al, 9

continue:
    cmp al, 0
    jg valid
    add al, 1

valid:
    mov [buffer], al
    popa
    mov al, [buffer]
    ret


print_int:          ; print an integer value (32 bits)
    pusha

    mov rdx, rdi

    mov rsi, 10
    call modulo

    mov cl, al         ; get the last digit   

    mov rdi, rdx
    mov rsi, 10
    call divide

    cmp al, 0
    je continue_print_int

    mov rdi, rax
    call print_int

continue_print_int:
    mov dil, cl
    add dil, '0'
    call print_char

    popa
    ret


print_flag_message:
    pusha

    mov rdi, msg_flag
    mov rsi, msg_flag_len
    call write

    mov dil, [remaining_flags]
    call print_char

    mov rdi, '/'
    call print_char

    mov dil, [total_flags]
    call print_char

    mov rdi, 10
    call print_char

    popa
    ret


print_cleared_message:
    pusha

    mov rdi, msg_cleared
    mov rsi, msg_cleared_len
    call write

    xor rdi, rdi
    mov dil, [cleared]
    call print_int

    mov dil, '/'
    call print_char    

    xor rdi, rdi
    mov dil, [clear_total]
    call print_int

    mov dil, 10
    call print_char

    popa
    ret