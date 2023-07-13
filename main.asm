%include "lib.inc"
%include "words.inc"

section .data
buffer: times 255 db 0
no_space: db "No space, length is too long!", 0
wrong_key: db "Such key does not exist!", 0

section .text
global _start
extern find_word

_start:
        mov rdi, buffer
        mov rsi, 255
	call read_word
       	test rax, rax
        jz .overflow
        mov rdi, rax
        mov rsi, NEXTONE
        push rdx
        call find_word
        pop rdx
        test rax, rax
        jz .not_found
        mov rdi, rax
        add rdi, 8
        add rdi, rdx
        inc rdi
        call print_string
        call print_newline
        xor rdi, rdi
        jmp .finish
.overflow:
	mov rdi, no_space
	jmp .error
.not_found:
	mov rdi, wrong_key
.error:
	call print_err
	call print_newline
	mov rdi, 1
.finish:
	jmp exit
