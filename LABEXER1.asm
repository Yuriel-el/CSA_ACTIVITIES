section .data
    clr_scr     db 27, '[2J', 27, '[H'
    clr_len     equ $ - clr_scr

    menu_msg    db "----------------------------------", 10
                db "MENU", 10
                db "[A]dd", 10
                db "[S]ubtract", 10
                db "[M]ultiply", 10
                db "[D]ivide", 10
                db "-----------------------------------", 10
                db "Enter your choice: "
    menu_len    equ $ - menu_msg

    prompt1     db 10, "Enter first number: "
    p1_len      equ $ - prompt1

    prompt2     db "Enter second number: "
    p2_len      equ $ - prompt2

    sum_msg     db "The sum is "
    sum_len     equ $ - sum_msg

    diff_msg    db "The difference is "
    diff_len    equ $ - diff_msg

    prod_msg    db "The product is "
    prod_len    equ $ - prod_msg

    quot_msg    db "The quotient is "
    quot_len    equ $ - quot_msg

    rem_msg     db " (Remainder: "
    rem_len     equ $ - rem_msg

    close_paren db ")", 10
    cp_len      equ $ - close_paren

    div_zero    db "Error: Cannot divide by zero!", 10
    dz_len      equ $ - div_zero

    invalid_msg db 10, "Invalid choice! Please select A, S, M, or D.", 10
    inv_len     equ $ - invalid_msg

    again_msg   db 10, "Do you want to try again (Y/N): "
    again_len   equ $ - again_msg

    newline     db 10
    minus_sign  db "-"

section .bss
    choice      resb 16
    again       resb 16
    in_buf      resb 16
    out_buf     resb 16
    num1        resd 1
    num2        resd 1
    rem_val     resd 1

section .text
    global _start

_start:
    jmp main_menu

retry_loop:
    call clear_screen

main_menu:
    call display_menu
    call get_choice

    mov al, [choice]
    
    cmp al, 'a'
    jb check_options
    cmp al, 'z'
    ja check_options
    sub al, 32

check_options:
    cmp al, 'A'
    je do_add
    cmp al, 'S'
    je do_sub
    cmp al, 'M'
    je do_mul
    cmp al, 'D'
    je do_div

    mov ecx, invalid_msg
    mov edx, inv_len
    call print_string
    jmp ask_retry

do_add:
    call get_two_numbers
    call proc_add
    jmp ask_retry

do_sub:
    call get_two_numbers
    call proc_sub
    jmp ask_retry

do_mul:
    call get_two_numbers
    call proc_mul
    jmp ask_retry

do_div:
    call get_two_numbers
    call proc_div
    jmp ask_retry

ask_retry:
    mov ecx, again_msg
    mov edx, again_len
    call print_string

    mov ecx, again
    mov edx, 16
    call read_input

    mov al, [again]
    cmp al, 'Y'
    je retry_loop
    cmp al, 'y'
    je retry_loop

    mov eax, 1
    xor ebx, ebx
    int 0x80

; ==========================================================
; ARITHMETIC PROCEDURES
; ==========================================================

proc_add:
    mov ecx, sum_msg
    mov edx, sum_len
    call print_string

    mov eax, [num1]
    add eax, [num2]
    call print_int
    call print_newline
    ret

proc_sub:
    mov ecx, diff_msg
    mov edx, diff_len
    call print_string

    mov eax, [num1]
    sub eax, [num2]
    
    cmp eax, 0
    jge print_pos
    push eax
    mov ecx, minus_sign
    mov edx, 1
    call print_string
    pop eax
    neg eax

print_pos:
    call print_int
    call print_newline
    ret

proc_mul:
    mov ecx, prod_msg
    mov edx, prod_len
    call print_string

    mov eax, [num1]
    imul eax, [num2]
    call print_int
    call print_newline
    ret

proc_div:
    mov ebx, [num2]
    cmp ebx, 0
    je div_by_zero

    mov ecx, quot_msg
    mov edx, quot_len
    call print_string

    mov eax, [num1]
    mov ebx, [num2]         
    xor edx, edx
    div ebx                 
    mov [rem_val], edx

    call print_int

    mov ecx, rem_msg
    mov edx, rem_len
    call print_string

    mov eax, [rem_val]
    call print_int

    mov ecx, close_paren
    mov edx, cp_len
    call print_string
    ret

div_by_zero:
    mov ecx, div_zero
    mov edx, dz_len
    call print_string
    ret

; ==========================================================
; I/O AND HELPER PROCEDURES
; ==========================================================

clear_screen:
    mov ecx, clr_scr
    mov edx, clr_len
    call print_string
    ret

display_menu:
    mov ecx, menu_msg
    mov edx, menu_len
    call print_string
    ret

get_choice:
    mov ecx, choice
    mov edx, 16
    call read_input
    ret

get_two_numbers:
    mov ecx, prompt1
    mov edx, p1_len
    call print_string
    call read_int
    mov [num1], eax

    mov ecx, prompt2
    mov edx, p2_len
    call print_string
    call read_int
    mov [num2], eax
    ret

print_string:
    mov eax, 4
    mov ebx, 1
    int 0x80
    ret

read_input:
    mov eax, 3
    mov ebx, 0
    int 0x80
    ret

print_newline:
    mov ecx, newline
    mov edx, 1
    call print_string
    ret

read_int:
    mov ecx, in_buf
    mov edx, 16
    call read_input

    xor eax, eax
    mov esi, in_buf
convert_loop:
    movzx ebx, byte [esi]
    cmp bl, 10
    je done_read
    cmp bl, 13
    je done_read
    cmp bl, '0'
    jb done_read
    cmp bl, '9'
    ja done_read

    sub bl, '0'
    imul eax, eax, 10
    add eax, ebx
    inc esi
    jmp convert_loop
done_read:
    ret

print_int:
    mov esi, out_buf + 15
    mov byte [esi], 0
    mov ebx, 10

extract_loop:
    xor edx, edx
    div ebx
    add dl, '0'
    dec esi
    mov [esi], dl
    test eax, eax
    jnz extract_loop

    mov ecx, esi
    mov edx, out_buf + 15
    sub edx, esi
    call print_string
    ret