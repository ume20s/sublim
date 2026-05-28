name	sublim
title	深層
;
;	『 深 層 』
;

INT0AH	equ	0ah
LF	equ	0ah
CR	equ	0dh
;

CODE	segment
	assume	cs:CODE,ds:CODE
;
;	PSP領域 (0ch～0ffh)
;
	org	2ch
envseg	dw	?
	org	80h
argc	db	?
argv	db	127 dup (?)

stktop	label	word

;
;---------------------------------------------------------------------
;
	org	100h

start:	jmp	initial

;
;	垂直同期割り込み処理（常駐本体）
;

ss_reg	dw	?
sp_reg	dw	?

count	dw	300

buf1	dw	?
buf2	dw	?
buf3	dw	?
buf4	dw	?
buf5	dw	?
buf6	dw	?
buf7	dw	?
buf8	dw	?
buf9	dw	?
buf10	dw	?
buf11	dw	?
buf12	dw	?
buf13	dw	?
buf14	dw	?

new0a	proc
	mov	cs:[ss_reg],ss
	mov	cs:[sp_reg],sp
	push	cs
	pop	ss
	mov	sp,offset stktop
	
	irp	reg,<ax,bx,si,ds,es>
		push reg
	endm
	
	dec	cs:[count]
	jz	st_1
	jmp	exit2
	
st_1:	mov	ax,0a000h
	mov	ds,ax
	mov	si,1984
	
	mov	ax,ds:[si+ 0]
	mov	cs:[buf1],ax
	mov	ax,ds:[si+ 2]
	mov	cs:[buf2],ax
	mov	ax,ds:[si+ 4]
	mov	cs:[buf3],ax
	mov	ax,ds:[si+ 6]
	mov	cs:[buf4],ax
	mov	ax,ds:[si+ 8]
	mov	cs:[buf5],ax
	mov	ax,ds:[si+10]
	mov	cs:[buf6],ax
	mov	ax,ds:[si+12]
	mov	cs:[buf7],ax
	mov	ax,ds:[si+14]
	mov	cs:[buf8],ax
	mov	ax,ds:[si+16]
	mov	cs:[buf9],ax
	mov	ax,ds:[si+18]
	mov	cs:[buf10],ax
	mov	ax,ds:[si+20]
	mov	cs:[buf11],ax
	mov	ax,ds:[si+22]
	mov	cs:[buf12],ax
	mov	ax,ds:[si+24]
	mov	cs:[buf13],ax
	mov	ax,ds:[si+26]
	mov	cs:[buf14],ax
	
	mov	ds:[si+ 0],2204h
	mov	ds:[si+ 4],4a04h
	mov	ds:[si+ 8],3f04h
	mov	ds:[si+12],4f04h
	mov	ds:[si+16],2c19h
	mov	ds:[si+20],212ah
	mov	ds:[si+24],4004h
	
	nop
	nop
	
	mov	ax,cs:[buf1]
	mov	ds:[si+ 0],ax
	mov	ax,cs:[buf2]
	mov	ds:[si+ 2],ax
	mov	ax,cs:[buf3]
	mov	ds:[si+ 4],ax
	mov	ax,cs:[buf4]
	mov	ds:[si+ 6],ax
	mov	ax,cs:[buf5]
	mov	ds:[si+ 8],ax
	mov	ax,cs:[buf6]
	mov	ds:[si+10],ax
	mov	ax,cs:[buf7]
	mov	ds:[si+12],ax
	mov	ax,cs:[buf8]
	mov	ds:[si+14],ax
	mov	ax,cs:[buf9]
	mov	ds:[si+16],ax
	mov	ax,cs:[buf10]
	mov	ds:[si+18],ax
	mov	ax,cs:[buf11]
	mov	ds:[si+20],ax
	mov	ax,cs:[buf12]
	mov	ds:[si+22],ax
	mov	ax,cs:[buf13]
	mov	ds:[si+24],ax
	mov	ax,cs:[buf14]
	mov	ds:[si+26],ax
	
	mov	cs:[count],300
	
exit2:	mov	al,20h
	out	00h,al
	out	64h,al
	
	irp	reg,<es,ds,si,bx,ax>
		pop	reg
	endm
	
	mov	sp,cs:[sp_reg]
	mov	ss,cs:[ss_reg]
	
jmpold:	iret
	
old0ah	dd	?
	
new0a	endp

breakadr label	byte

;
;---------------------------------------------------------------------
;
;	初期化部分
;

initial:
	cmp	[argc],0
	jz	argend
	mov	si,offset argv
arglp:	call	getarg
	cmp	al,CR
	je	argend
	cmp	al,'R'		;常駐解除
	je	argr
;知らぬオプション
unknown:
	mov	dx,offset unk$
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h

argend:
	mov	ax,3500h+INT0AH
	int	21h
	call	chkmem
	jz	exist
	mov	word ptr cs:[old0ah],bx
	mov	word ptr cs:[old0ah+2],es
	mov	ax,2500h+INT0AH
	mov	dx,offset new0a
	int	21h
;
;	環境変数の解放
;
	mov	es,[envseg]
	mov	ah,49h
	int	21h
	mov	[envseg],0
;
;	常駐処理
;
	mov	dx,offset reside$
	mov	ah,09h
	int	21h
	
	cli
	in	al,02h
	and	al,0fbh
	out	02h,al
	sti
	out	64h,al
	
	lea	dx,[breakadr+0fh]
	mov	cl,4
	shr	dx,cl
	mov	ax,3100h
	int	21h

;実は既に常駐していた
exist:	mov	dx,offset exist$
	mov	ah,09h
	int	21h
	out	64h,al
	mov	ax,4c01h
	int	21h
;
;	常駐解放
;
argr:
	mov	ax,3500h+INT0AH
	int	21h
	call	chkmem
	jnz	notexist
	push	ds
	lds	dx,es:[old0ah]
	mov	ax,2500h+INT0AH
	int	21h
	pop	ds
	mov	ah,49h
	int	21h
	jc	relerr
	mov	dx,offset rel$
	mov	ah,09h
	int	21h
	mov	ax,4c00h
	int	21h
;解放失敗
relerr:
	mov	dx,offset relerr$
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h
;実は常駐していなかった
notexist:
	mov	dx,offset notex$
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h
;
;	メモリ常駐確認
;
chkmem	proc
	mov	si,offset new0a
	mov	di,offset new0a
	mov	cx,(offset exit2 - offset new0a)
	cld
	repe	cmpsb
	ret
chkmem	endp

;
;	引数取得
;
getarg	proc
	lodsb
	cmp	al,' '
	jz	getarg
	cmp	al,09h
	jz	getarg
	cmp	al,','
	jz	getarg
	cmp	al,'-'
	jz	getarg
	cmp	al,'/'
	jz	getarg
	cmp	al,'a'
	jb	getarge
	cmp	al,'z'
	ja	getarge
	sub	al,'a'-'A'
getarge:
	ret
getarg	endp

unk$	db	"usage : sublim [-r]",CR,LF,"$"
reside$	db	"常駐した",CR,LF,"$"
exist$	db	"既に常駐している",CR,LF,"$"
rel$	db	"解除した",CR,LF,"$"
relerr$	db	"解除できない",CR,LF,"$"
notex$	db	"まだいない",CR,LF,"$"

CODE	ends
	end	start
