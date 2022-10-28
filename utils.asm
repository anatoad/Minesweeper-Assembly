section .text

%macro pusha 0  ; push registers onto the stack
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


write:                          ; make write system call
    pusha

    mov rax, 1                  ; write system call number (1)
    mov rdx, rsi                ; number of bytes to print (second argument)
    mov rsi, rdi                ; buffer (first argument)
    mov rdi, 1                  ; stdout file descriptor
    syscall                     ; call kernel

    popa
    ret


read:                           ; make read system call      
    pusha

    mov rax, 0                  ; read system call number (0)
    mov rdi, 0                  ; stdin file descriptor
    mov rsi, buffer             ; buffer (first argument)
    mov rdx, 1                  ; bytes count (second argument)
    syscall                     ; call kernel

    popa
    xor rax, rax
    mov al, [buffer]
    ret


exit:                           ; make exit system call
    mov rax, 60                 ; exit system call number (60)
    mov rdi, 0                  ; no error code
    syscall

    ret


multiply_8bit:                  ; multiply two 8bit integers
    pusha

    xor rax, rax
    xor rdx, rdx
    mov al, dil                 ; first argument (first factor)
    mul sil                     ; multiply by second argument (second factor)

    mov [buffer], al

    popa
    xor rax, rax
    mov al, [buffer]            ; return result in al
    ret


read_input:                     ; read from standard input (option, line and column)
    pusha

    mov rdi, msg_option
    mov rsi, msg_option_len
    call write                  ; print message to request option from user

    call read                   ; read a character symbolizing the option selected
    mov byte [option], al       ; by user ('f' - flag or 'c' - clear)
    call read                   ; read line separator (and ignore it)

    mov rdi, msg_line
    mov rsi, msg_line_len
    call write                  ; print message to request line from user

    call read                   ; read a digit symbolizing the line number
    sub al, '0'                 ; subtract '0' from the ascii code to save the index
    mov byte [line], al         ; save line index in global variable line
    call read                   ; read line separator

    mov rdi, msg_column
    mov rsi, msg_column_len
    call write                  ; print message to request column from user

    call read                   ; read a digit symbolizing the column number
    sub al, '0'
    mov byte [column], al       ; save column index in global variable column
    call read

    popa
    ret


print_char:                     ; print a character to stdout
    pusha

    mov [print_buffer], dil     ; store character in a buffer
    mov rdi, print_buffer
    mov rsi, 1                  ; number of bytes to print (1)
    call write                  ; make write system call

    popa
    ret


modulo_8bit:                    ; return remainder of division between two 8bit integers
    pusha                       ; rdi - dividend, rsi - divisor

    xor rdx, rdx
    mov ax, di
    div sil                     ; perform division

    shr rax, 8                  ; remainder is stored in ah
    mov [buffer], al

    popa
    xor rax, rax
    mov al, [buffer]            ; return remainder in al

    ret


divide_8bit:                    ; return quotient of division between two 8bit integers
    pusha                       ; rdi - dividend, rsi - divisor
    
    xor rdx, rdx
    mov ax, di
    div sil                     ; perform division
    
    mov [buffer], al            ; quotient is stored in al

    popa
    xor rax, rax
    mov al, [buffer]            ; return remainder in al
    ret


print_matrix:                   ; print a given matrix to stdout
    pusha

    mov rcx, [matrix_size]      ; number of lines to print
    mov rdx, 0                  ; index in the matrix
    mov rax, rdi                ; the matrix address (first argument)

print_lines:
    mov rsi, 0

print_columns:
    mov dil, byte [rax + rdx]   ; print character from matrix
    call print_char
    inc rdx                     ; go to the next character in matrix

    mov dil, 32                 ; space ASCII code
    call print_char             ; print space character

    inc rsi
    cmp rsi, 10
    jl print_columns

    mov dil, 10                 ; newline ASCII code
    call print_char             ; print newline character

    loop print_lines

    popa
    ret


get_random_digit:               ; return a random digit between 1-9
    pusha

    mov rax, 318                ; getrandom system call number (318)
    mov rdi, buffer
    mov rsi, 1                  ; bytes count
    mov rdx, 0                  ; no flags
    syscall

    mov al, byte [buffer]       ; store the randomly generated byte in al

    and al, byte [mask]         ; normalize number to be in range 1-9
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
    mov al, [buffer]            ; return random digit in al
    ret


print_int:                      ; print an integer value (32 bits)
    pusha

    mov rdx, rdi                ; store integer in rdx

    mov rsi, 10
    call modulo_8bit
    mov cl, al                  ; get the current last digit in cl

    mov rdi, rdx
    mov rsi, 10
    call divide_8bit            ; divide the number by 10

    cmp al, 0                   ; if quotient is zero stop
    je continue_print_int

    mov rdi, rax
    call print_int              ; continue printing the rest of the digits

continue_print_int:
    mov dil, cl
    add dil, '0'                ; get the ascii code of the current last digit
    call print_char             ; print the last digit

    popa
    ret


print_flag_message:             ; print flag message in a specific format
    pusha

    mov rdi, msg_flag
    mov rsi, msg_flag_len
    call write

    mov dil, [remaining_flags]
    call print_char             ; print the number of remaining flags

    mov rdi, '/'                ; / slash ASCII code
    call print_char             ; print '/' character

    mov dil, [total_flags]
    call print_char             ; print the number of total flags

    mov rdi, 10                 ; newline ASCII code
    call print_char             ; print newline character

    popa
    ret


print_cleared_message:          ; print cleared message in a specific format
    pusha

    mov rdi, msg_cleared
    mov rsi, msg_cleared_len
    call write

    xor rdi, rdi
    mov dil, [cleared]
    call print_int              ; print the number of cleared cells in the matrix

    mov dil, '/'
    call print_char    

    xor rdi, rdi
    mov dil, [clear_total]
    call print_int

    mov dil, 10
    call print_char

    popa
    ret
