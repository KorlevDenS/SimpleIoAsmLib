

section .text

global find_word
extern string_equals

find_word:
.loop:
	push rdi
	push rsi
	add rsi, 8
	call string_equals
	pop rsi
	pop rdi
	cmp rax, 0
	jne .found
	mov rsi, [rsi]
	cmp rsi, 0
	jne .loop
	xor rax, rax
	jmp .return
.found:
	mov rax, rsi
.return:
	ret
	
