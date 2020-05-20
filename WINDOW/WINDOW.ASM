.model tiny
.code
locals @@
org 100h

;================================================
; In:    ES:[DI]  - Start string of bytes
;        LEFTLN   - Left item of line
;        CENTERLN - Center item of line
;        RIGHTLN  - Right item of line
;        DL       - Length of center part of the line
;        CX       - Number of bytes to be set
;
; Out:   ES:[DI] = First word after printed line
;
; Destr: DI, CX, DF
;================================================
.PrintLine	macro

		mov al, LEFTLN
		xor cx, cx
		inc cx
		call MemWSet

		mov al, CENTERLN
		mov cl, dl
		xor ch, ch
		call MemWSet

		mov al, RIGHTLN
		xor cx, cx
		inc cx
		call MemWSet

		endm


;================================================
; In:    BH - Y-cord
;        BL - X-cord
;
; Out:   DI = Offset
; Destr: DI, AX
;================================================
.CalcOffset	macro
		
		xor di, di

		mov al, DOSWIDTH * 2d
		mul bh

		add di, ax

		mov al, 2d
		mul bl

		add di, ax

		endm

;================================================
; In:    DL - Line length (<= 80)
;
; Out:   bx = After print offset
; Destr: BX, AX
;================================================
.CalcAPOffset	macro
		
		mov bx, DOSWIDTH
		sub bl, dl

		xor ax, ax
		inc ax
		inc ax

		mul bl

		mov bx, ax

		endm


;================================================
; In:    TrgtReg = Byte reg
;        [BX]    = Word of 2-digit number
;        
; Out:   TrgtReg = Number
;        BX     += 3
; Destr: AX, BX, CX, TrgtReg
;================================================
.ReadNum	macro TrgtReg

		mov cx, [bx]
		sub cx, '00'

		mov ax, 10d
		mul cl
		xor cl, cl
		add al, ch

		mov TrgtReg, al

		add bx, 3d

		endm


;================================================
; In:    item - Item to be even
;
; Out:   item = item OR item - 1
; Destr: item
;================================================
.ToEven		macro item

		and item, 0FFFFh - 1

		endm


;================================================
; In:     recip  - Item to copy to
;         sender - Item to copy from
;         agent  - Copy intermediary
;
; Out:    recipt = sender
;         agent  = sender
; Destr:  recip, agent
;================================================
.AgentCpy	macro recip, sender, agent
		
		mov agent, sender
		mov recip, agent

		endm


;================================================
; In:    CX = Length of string
;        DL = Window width
;        BL = Window X-cord
;
; Out:   AX = Width offset
; Destr: AX
;================================================
.CalcWOffset	macro

		mov al, dl

		sub al, cl
		.ToEven al
		add al, bl
		add al, bl

		xor ah, ah

		endm


;================================================
; In:    DH = Window height
;        BH = Window Y-cord
;
; Out:   AX = Height offset
; Destr: AX, CX
;================================================
.CalcHOffset	macro

		mov cl, dh

		.ToEven cl
		add cl, bh
		add cl, bh

		mov al, DOSWIDTH
		xor ah, ah
		mul cl

		endm

;------------------------------------------------
DOSWIDTH	equ 80d
DOSHEIGH	equ 25d
VIDEOSEG	equ 0B800h
COLOR 		equ 28h
PRESETLEN	equ 7d
ARGSLN		equ 82h
LEFTLN		= 'L'
CENTERLN	= 'C'
RIGHTLN		= 'R'
;------------------------------------------------


Start:		mov bx, ARGSLN

		.ReadNum dh
		.ReadNum dl
		
		push dx

		.ReadNum dh
		.ReadNum dl
		
		push dx
		
		.ReadNum dh

		mov si, offset Preset
		
		mov ax, PRESETLEN
		mul dh

		add si, ax

		pop dx

		pop bx

		.AgentCpy es, cs, cx
		mov ds, cx
		mov di, offset Msg

		call StrLen

		.CalcWOffset

		push ax

		.CalcHOffset

		push ax

		mov ah, [Preset]

		call PrintBox
	
		pop bx
		pop cx

		add bx, cx
		mov di, bx
		mov si, offset Msg

		call PrintText
	
		ret

Msg: db 'Test!', 00h

;Help		color,  -   , |   , LU  , RU  , LD  , RD
Preset		db 28h, 0CDh, 0BAh, 0C9h, 0BBh, 0C8h, 0BCh
		db 38h, '-' , '|' , '+' , '+' , '+' , '+'

;================================================
; In:    BH - Y-cord
;        BL - X-cord
;        DH - Height (> 2d)
;        DL - Width  (> 2d)
;        AH - Color of the box
;        SI - Pointer on first bite of preset
; Destr: AL, BX, CX, DX, DI, DF, ES
;================================================
PrintBox	proc

		push ax

		.CalcOffset

		.AgentCpy es, VIDEOSEG, bx

		.CalcAPOffset

		dec dl
		dec dl

		dec dh
		dec dh

		pop ax

		LEFTLN   = [si + 3];0C9h
		CENTERLN = [si + 1];0CDh
		RIGHTLN  = [si + 4];0BBh

		.PrintLine

		cmp dh, 00h
		je @@EndCntrPrnt

@@cntrPrnt:	add di, bx

		LEFTLN   = [si + 2];0BAh
		CENTERLN = ' '
		RIGHTLN  = [si + 2];0BAh

		.PrintLine

		dec dh
		jne @@cntrPrnt

@@EndCntrPrnt:	add di, bx

		LEFTLN   = [si + 5];0C8h
		CENTERLN = [si + 1];0CDh
		RIGHTLN  = [si + 6];0BCh

		.PrintLine


		ret
		endp


;================================================
; In:    ES:[DI] - Start of line to copy to
;        DS:[SI] - Start of string to copy from
;        AH      - Color
; Destr: AL, DI, SI, DF
;================================================
PrintText	proc

		cld

@@Loop1:	lodsb
		cmp al, 00h
		je @@End

		stosw

		jmp @@Loop1

@@End:		ret
		endp


;================================================
; In:    ES:[DI] - Start string of bytes
;        AX      - Value to be set
;        CX      - Number of bytes to be set
;
; Destr: DI, CX, DF
;================================================
MemWSet		proc

		cld

		rep stosw

		ret
		endp

;================================================
; In:    ES:[DI] - Start string of symbols
; Out:   CX = Length of string
; Destr: CX, DI, AL, DF
;================================================
StrLen		proc

		xor al, al
		xor cx, cx
		dec cx

		repne scasb

		not cx

		dec cx

		ret
		endp

end Start