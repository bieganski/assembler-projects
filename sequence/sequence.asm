; SO - zadanie 1
; Mateusz Bieganski mb385162

BUFF_SIZE equ 512

SYS_WRITE equ 1
SYS_READ equ 0
SYS_EXIT equ 60
SYS_OPEN equ 2
STDOUT equ 1
STDIN equ 0
O_RDWR equ 2


section .bss
    count_arr: resq 256
    buffer: resb BUFF_SIZE

section .data
    global _start
    file_desc dq 1

section .text

ERROR:
	mov rax, SYS_EXIT
	mov edi, 1
	syscall
	
SYS_open:
    mov rax, SYS_OPEN
    mov rsi, O_RDWR
    syscall
    test rax, rax ; sets sign flag if error occured
    js ERROR ; bad filename
    mov [file_desc], rax
    ret

SYS_read:
    mov rax, SYS_READ
    mov rdi, [file_desc]
    lea rsi, [buffer]
    mov rdx, BUFF_SIZE
    syscall
    ret


; 'segment' - every M-permutation in sequence
; 'ITER' - actual iteration, or just number of already read zeroes
;
; Algorithm counts occurences every of possible 256 numbers and keeps info
; about segments already read (ITER). When reading new number, there if
; it is ascii-non-zero we need to check whether it occured exactly ITER times.
; When reading ascii-zero, we finish segment, checking amount of bytes read.

; R12 - ITER
; R13 - actually processed bytes (counted from actual buffer begin)
; R14 - actual segment bytes read
; R15 - M-permutation length, set after first segment process
; RAX - number of read bytes

process_seq:
    call SYS_read ; try to fill buffer
    test rax, rax ; for ZF
    jnz process_prepare ; more than 0 bytes read
    cmp r12, 0 ; first iteration
    je finish_incorrect_seq
    test r14, r14 ; ZF if no bytes in actual segment read
    jz finish_correct_seq
    call finish_incorrect_seq
process_prepare:
    mov r13, 0 ; actually processed bytes
byte_process:
    ; in rcx we keep actually processed number
    xor rcx, rcx
    mov cl, byte [buffer + r13]
    ; and in r8 number of read occurences of rcx
    inc r13 ; next byte being processed
    mov rdi, count_arr
    mov r8, qword [rdi + 8 * rcx]
    cmp rcx, 0 ; is processed byte '0'?
    jne not_zero_process
    ; segment done, check whether actual segment size correct
    cmp r12, 0 ; if it was first iteration, there is nothing that could be wrong
    je every_iter_zero
    ; here we got zero byte and not first iteration, need check
    cmp r14, r15
    jne finish_incorrect_seq ; actual segment size differ from first one
    
every_iter_zero: ; ZERO CHARACTER HANDLING
    inc r12 ; next iteration ..
    xor r14, r14 ; .. with no elements actually read
    jmp byte_process_finish

not_zero_process: ; NON-ZERO CHARACTER HANDLING
    cmp r12, 0 ; first iteration
    jne every_iter_not_zero ; r15 (M-length) actually set properly
    inc r15
every_iter_not_zero:
    inc r14 ; actual segment next byte
    cmp r12, r8 ; iteration and rcx occurences must be equal
    jne finish_incorrect_seq
    mov rdi, count_arr
    inc qword [rdi + 8 * rcx]
byte_process_finish:
    cmp r13, rax ; should we read next portion?
    je process_seq
    jmp byte_process
    
finish_correct_seq:
    mov rax, SYS_EXIT
	mov edi, 0
	syscall
	
finish_incorrect_seq:
    mov rax, SYS_EXIT
	mov edi, 1
	syscall
	
	
_start:	
    mov rax, qword [rsp] ; argc
    cmp rax, 2 ; must be 2 args
    jnz ERROR
    mov rdi, qword [rsp+16] ; file name
    
    ; INPUT FILE HANDLING
    call SYS_open

    ; MAIN ALGORITHM
    mov r12, 0
    mov r13, 0
    mov r14, 0
    mov r15, 0
    call process_seq
; END OF PROGRAM