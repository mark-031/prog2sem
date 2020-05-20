.model tiny
.code
locals @@
org 100h

Start:		

		ret


;================================================
; In:    ES:[DI] - Start string of bytes
;        CX      - Number of bytes to be analyzed
;        AL      - Value to be located
; Out:   ES:[DI] = first include  if found
;                  last symbol    else
; Destr: DI, CX, DF
;================================================

MemChr		proc

		cld

		repne scasb
		dec di

		ret
		endp


;================================================
; In: ES:[DI] - Start string of bytes
;     AL      - Value to be set
;     CX      - Number of bytes to be set
; Destr: DI, CX, DF
;================================================
MemSet		proc

		cld

		rep stosb

		ret
		endp


;================================================
; In: ES:[DI] - Start string of bytes to copy to
;     DS:[SI] - Start string of bytes to copy from
;     CX      - Number of bytes to be copied
; Destr: DI, SI, CX, DF
;================================================
MemCpy		proc
		
		cld

		rep movsb

		ret
		endp


;================================================
; In:    ES:[DI] - Start string of symbols
; Out:   CX = Length of string
;        AL = 0
; Destr: CX, DI, AL, DF
;================================================
StrLen		proc

		xor al, al
		xor cx, cx
		dec cx
		
		cld

		repne scasb

		not cx

		dec cx

		ret
		endp


;================================================
; In:    DS:[SI] - Start string of symbols
;        AH      - Value to be found
; Out:   DS:[SI] = first include or end of string
; Destr: DI, CX
;================================================
StrChr		proc

@@Loop1:	lodsb

		cmp al, 00h
		je @@Exit

		cmp al, ah
		jne @@Loop1

@@Exit:		dec si
		ret
		endp


;================================================
; In:    ES:[DI] - Start string of symbols
;        AL      - Value to be found
; Out:   ES:[DI] = last include or start of string
; Destr: AL, BX, CX, DI, DF
;================================================
StrrChr		proc

		mov bx, ax
		call StrLen
		mov ax, bx

		dec di
		dec di

		std

		repne scasb

@@Exit:		ret
		endp


;================================================
; In:    ES:[DI] - Start string of symbols to copy to
;        DS:[SI] - Start string of symbols to copy from
; Destr: AL, DI, SI, DF
;================================================
StrCpy		proc

		cld

@@cpyLoop:	lodsb
		cmp al, 00h
		je @@Exit

		stosb
		jmp @@cpyLoop

@@Exit:		ret
		endp

;================================================
; In:    ES:[DI] - Start first string of symbols
;        DS:[SI] - Start second string of symbols
; Out:   AL = 1  if ES:[SI] > DS:[DI]
;           = -1 if ES:[SI] < DS:[DI]
;           = 0  else
; Destr: DI, SI, DF
;================================================
StrCmp		proc

		cld

@@cmpLoop:	cmp es:[di], 00h
		je @@alOne

		cmpsb
		je @@cmpLoop
		jl @@alMOne

@@alOne:	xor al, al
		inc al
		ret

@@alMOne:	xor al, al
		dec al
		ret

@@alZero:	xor al, al 
		ret
		endp

end Start