extern get_os_time

global proberen
global verhogen
global proberen_time
    
section .data
    busy    dd  0

section .text
   
proberen:
    cmp dword [rdi], esi
    jl proberen
    mov eax, esi;
    xor eax, 0xffffffff ; potrzebujemy -1 * value
    lock xadd dword [rdi], eax
    js wrong_change
    xchg dword [rdi], eax
    ret 
wrong_change: ; musimy przywrocic poprzednia wartosc
    add edi, eax ; oddajemy tyle ile zabralismy 
    lock xadd dword [rdi], edi ; 
    jmp proberen


verhogen:
    lock add dword [rdi], esi
    ret

proberen_time:
    push rdi
    push rsi
    call get_os_time
    pop rsi
    pop rdi
    push rax
    call proberen
    call get_os_time
    pop rcx
    sub rax, rcx
    ret
