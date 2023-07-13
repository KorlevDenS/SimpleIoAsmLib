%include "defines.asm"

section .data

newline_char: db 10
varchar: db 0

section .text

global string_length
global exit
global print_newline
global print_string
global print_char
global print_uint
global print_int
global string_equals
global read_char
global read_word
global parse_uint
global parse_int
global string_equals
global string_copy
global print_err

; Принимает код возврата и завершает текущий процесс
exit: 
	mov rax, EXIT_SYSCALL
	syscall

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
	xor rax, rax
.loop:
	cmp byte[rdi + rax], 0
	je .end
	inc rax
	jmp .loop
.end:
	ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
	call string_length
	mov rdx, rax
	mov rsi, rdi
	mov rax, 1
	mov rdi, 1
	syscall
	ret

; Принимает код символа и выводит его в stdout
print_char:
	mov [varchar], di
	mov rdi, varchar
	call print_string
	ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
	mov di, NEWLINE_SYMBOL
	call print_char 
	ret

; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
	mov rax, rdi ;install numder
	mov rdi, DIVISOR ;divisor
	mov r8, rsp ;save stack pointer
	push 0x0 ;load null-treminator to future string
.loop:
	xor rdx, rdx ; rdx must be equal to 0, we use dl
	dec rsp
	div rdi ;quotient -> rax, repainder -> rdx
	or dl, 0x30 ;rdx to ASCII
	mov byte[rsp], dl ;char to buffer
	test rax, rax
	jnz .loop
	
	mov rdi, rsp
	call print_string
	mov rsp, r8 ;stack pointer is back
	ret

; Выводит знаковое 8-байтовое число в десятичном формате 
print_int:
	cmp rdi, 0
	jge print_uint
	neg rdi
	push rdi
	mov rdi, MINUS_SYMBOL
	call print_char
	pop rdi
	call print_uint
	ret

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
	xor rcx, rcx
.loop:
	mov al, byte[rdi+rcx]
	mov dl, byte[rsi+rcx]
	cmp al, dl
	jne .not_equal
	cmp al, 0
	je .equal
	inc rcx
	jmp .loop
.equal:
	mov rax, 1
	ret
.not_equal:
	mov rax, 0
	ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
	xor rax, rax ;stdin
	xor rdi, rdi
	mov rdx, 1 ;how many bytes
	push 0
	mov rsi, rsp ;char's address
	syscall
	pop rax
	ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор

read_word:
	xor rcx, rcx
.loop:
	push rcx
	push rdi
	push rsi
	call read_char
	pop rsi
	pop rdi
	pop rcx
	cmp rax, SPACE_SYMBOL
	je .space_symbol
	cmp rax, TAB_SYMBOL
	je .space_symbol
	cmp rax, NEWLINE_SYMBOL
	je .space_symbol
	cmp rax, NULL_TERMINATOR_SYMBOL
	jz .finish
	cmp rsi, rcx
	je .overflow
	mov byte[rdi+rcx], al
	inc rcx
	jmp .loop
.overflow:
	xor rax, rax
	ret
.space_symbol:
	cmp rcx, 0 ;skip space sybmol at the begining of the word 
	je .loop
.finish:
	mov byte[rdi+rcx], 0 ;null-terminator
	mov rax, rdi
	mov rdx, rcx
	ret

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
	xor rcx, rcx
	xor rax, rax
	mov r9, 0xA
.loop:
	mov r8, [rdi+rcx] 
	and r8, 0xff           
	cmp r8, 0             
	je .finish
	cmp r8, 0x30
	jb .finish
	cmp r8, 0x39
	ja .finish
	mul r9
	sub r8, 0x30
	add rax, r8
	inc rcx
	jmp .loop
.finish:
	mov rdx, rcx
	ret

; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
parse_int:
	cmp byte [rdi], 0x2D
	je .minus
	call parse_uint
	jmp .finish
.minus:
	inc rdi
	call parse_uint
	neg rax
	inc rdx
.finish:
	ret

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
	xor rcx,rcx
	call string_length
	cmp rax, rdx
	jae .overflow
.loop:
	mov rdx, [rdi+rcx]
	mov [rsi], rdx
	inc rcx
	inc rsi
	cmp rcx, rax
	jb .loop
	mov byte[rsi], 0
	ret
.overflow:
	xor rax, rax
	ret

; Принимает и печатает сообщение об ошибке
print_err:
	call string_length
	mov rdx, rax
	mov rsi, rdi
	mov rax, 1
	mov rdi, 2
	syscall
	ret
	
