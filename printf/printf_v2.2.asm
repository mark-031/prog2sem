%macro _setOne 1
	xor %1, %1
	inc %1
%endmacro

%macro .addPrintfConvSpec 2
	db %1
	dq %2
%endmacro

%define stkrem(n) add rsp, n * StackElemSize
%define stkadd(n) sub rsp, n * StackElemSize

%macro printf 0-*

	%rep %0
		%rotate -1
		push %1
	%endrep

	call Printf

	stkrem(%0)

%endmacro

;------------------------------------------------
PrntfConvSpecSize	equ 9
StackElemSize	equ 8
NumBufferSize	equ 20
;------------------------------------------------


section .text

global _start

_start:
	mov r10, Msg

	printf 5, 32, 3802, 'k', SubMsg, 481516
	
	mov r10, MsgModel

	printf

	mov rax, 0x3C
	xor rdi, rdi
	syscall

	ret

;================================================
; In:    RAX = 1
;        RDI = 1
;        RDX = 1
;        R9  = Number
;        CL  = Degree of two
;
; Destr: BL, RCX, RSI, R11, R12B, R13
;================================================
PrintBinaryLike:
	mov rsi, r9 		; RSI  = R9
	xor r12b, r12b 		; R12B = 0

	_setOne r13 		;|
	shl r13, cl 		;| R13 = 2^(CL) - 1
	dec r13 		;|

;while(R10)	{
.numLen:
	add r12b, cl 		; R12B += CL;
	shr rsi, cl 		; RSI >>= CL

	jne .numLen
;}
	
	mov bl, cl

;while(R12B)	{
.printSymbol:
	sub r12b, bl 		; R12B -= BL;
	mov rsi, r9 		; RSI = R9
	mov cl, r12b 		; CL = R12B
	shr rsi, cl 		; RSI >>= CL
	and rsi, r13 		; RSI &= R13
	add rsi, Nums 		; RSI += Nums

	syscall

	cmp r12b, 0x00

	jne .printSymbol
;}

	ret

;================================================
; In:    RAX = Number
;        R11 = Divisor
; Destr: RAX, RCX, RDX, RSI, R11, R12
;================================================
PrintNum:
	mov r12, NumBufferSize
	_setOne rdi

;while(RAX != 0){
.fillBuffer:
	dec r12 		; --R12

	xor rdx, rdx 		; RDX = 0
	div r11 		; RDX:RAX / R11

	mov BYTE [NumBuffer + r12], '0'
	add [NumBuffer + r12], dl

	cmp rax, 0 		; if(RAX != 0)
	jne .fillBuffer 	;     goto PrintNum.fillBuffer
;}

	mov rsi, NumBuffer 	; RSI = NumBuffer
	add rsi, r12 		; RSI += R12

	mov rdx, NumBufferSize	;|
	sub rdx, r12 		;| RDX = NumBufferSize - r12

	inc rax 		; RAX = 1

	syscall

	ret


;================================================
; In:    R10 = Start of line
; Destr: RAX, BL, RCX, RDX, RSI, RDI, R10, R11, R12B, R13, R15
;================================================
Printf:
	mov r14, rsp		; R14 = RSP
	stkrem(1)		; --RSP;

	_setOne rax 		; RAX = 1
	_setOne rdi 		; RDI = 1

	xor rdx, rdx

;while([R10+RDX] != 0){
.main:
	mov bl, [r10 + rdx]
	cmp bl, 0x00
	je .exit

	cmp bl, '%'
	je .convSpecProcess

	inc rdx
	jmp .main
;}

.mainRestart:
	inc r10
	xor rdx, rdx
	jmp .main

.convSpecProcess:
	mov rsi, r10
	syscall

	_setOne rax

	add r10, rdx
	inc r10

	xor r12, r12

;while([R10] != [R12])
.convSpecSearch:
	mov bl, [PrintfConvSpecers + r12]
	cmp bl, [r10]
	jne .nextConvSpec

	jmp [ConvSpecersJumpTable + r12 * 8]

.nextConvSpec:
	inc r12
	jmp .convSpecSearch

.exit:
	mov rsi, r10
	syscall

	mov rsp, r14
	ret


.b:
	pop r9
	_setOne rdx
	_setOne cl

	call PrintBinaryLike

	jmp .mainRestart

.o:
	pop r9
	_setOne rdx
	mov cl, 3

	call PrintBinaryLike

	jmp .mainRestart

.h:
	pop r9
	_setOne rdx
	mov cl, 4

	call PrintBinaryLike

	jmp .mainRestart

.s:
	pop r9
	_setOne rdx
	xor rcx, rcx
	dec rcx

	dec rax
	mov rdi, r9
	repne scasb

	not rcx
	dec rcx
	mov rdx, rcx
	mov rsi, r9

	inc rax
	mov rdi, rax
	syscall

	_setOne rax
	
	mov rsi, r10

	jmp .mainRestart

.percent:
	_setOne rdx
	mov rsi, r10
	syscall

	_setOne rax

	jmp .mainRestart

.d:
	pop r9
	mov rax, r9
	mov r11, 10

	call PrintNum

	_setOne rax

	jmp .mainRestart

.c:
	_setOne rax
	_setOne rdx
	mov rsi, rsp
	syscall

	pop r9

	jmp .mainRestart



section .data

Msg	db 'Printf: Just test %b %o %h %%%c %s ', 10, 'My_num = %d', 10, 0x00
MsgModel db 'Model:  Just test 101 40 EDA %%k [SUBSTRING] ', 10, "My_num = 481516", 10, 0x00

SubMsg	db '[SUBSTRING]', 0x00

Nums	db '0123456789ABCDEF'

NumBuffer times NumBufferSize db '0'

PrintfConvSpecers	db 'bohs%dc'
ConvSpecersJumpTable	dq Printf.b, Printf.o, Printf.h, Printf.s, Printf.percent, Printf.d, Printf.c