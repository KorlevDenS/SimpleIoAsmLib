%define NEWLINE_SYMBOL 0xA
%define SPACE_SYMBOL 0x20
%define TAB_SYMBOL 0x9

section .data

newline_char: db 10
varchar: db 0

section .text

; Принимает код возврата и завершает текущий процесс
exit:
	mov rax, 60
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
	push rdi
	call string_length
	pop rdi
	mov rdx, rax
	mov rsi, rdi
	mov rax, 1
	mov rdi, 1
	syscall
	ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
    mov rdi, NEWLINE_SYMBOL
; Принимает код символа и выводит его в stdout
print_char:
	mov [varchar], di
	mov rdi, varchar
	jmp print_string

; Выводит беззнаковое 8-байтовое число в десятичном формате
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
	mov rax, rdi ;install numder
	mov rdi, 10 ;divisor
	mov r8, rsp ;save stack pointer
	dec rsp
    mov byte[rsp], 0
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
	mov rdi, '-'
	call print_char
	pop rdi
	jmp print_uint

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
	xor rcx, rcx
.loop:
    mov al, byte[rsi]
    cmp byte[rdi], al
    jne .finish
    inc rsi
    inc rdi
    cmp byte[rsi-1], 0
    jne .loop
    mov rax, 1
    ret
.finish:
    mov rax, 0
    ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
	mov rax, 0 ;stdin
	mov rdi, 0
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
	cmp rax, 0
	jz .finish
	cmp rsi, rcx
	je .overflow
	mov byte[rdi+rcx], al
	inc rcx
	jmp .loop
.overflow:
	mov rax, 0
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
    mov rax, 0
    mov rcx, 0
    mov rdx, 0

parse_uint_loop:
.loop:
    mov dl, byte[rdi + rcx]
    cmp dl, '0'
    js .finish
    cmp dl, '9'
    ja .finish
    sub dl, '0'
    imul rax, 10
    add rax, rdx
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

; Если не удаётся прочитать, rdx = 0 установит функция parse_uint
parse_int:
	cmp byte [rdi], '-'
	je .minus
	jmp parse_uint
.minus:
	inc rdi
	call parse_uint
	neg rax
	inc rdx
	ret

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
	xor rcx, rcx
	push rdi
	push rsi
	push rdx
	push rcx
	call string_length
	pop rcx
	pop rdx
	pop rsi
	pop rdi
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
	mov rax, 0
	ret
