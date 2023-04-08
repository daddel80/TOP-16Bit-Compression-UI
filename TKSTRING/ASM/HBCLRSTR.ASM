;******************************************************
;		  HBCLRSTR.ASM V 1.0
;	       String handling routines
;	 Copyright (c) by HB-Soft 1991.
;		 All rights reserved.
;******************************************************


;******************************************************	Data

DATA	SEGMENT	WORD PUBLIC

DATA	ENDS

;******************************************************	Code

CODE	SEGMENT	BYTE PUBLIC

	ASSUME	CS:CODE,DS:DATA

	PUBLIC	ClrStr

;****************************************************** ClrStr

;procedure ClrStr(var S : String; LEN : Byte);

ClrStr	PROC	FAR
;Prozedur zum l”schen einer Zeichkette
;Zerst”rt Register AL, BX, CX, DI,ES
S	equ	ss:[BX+6]
Len	equ	ss:[BX+4]

	MOV	BX,SP
	CLD
	LES	DI,S
	XOR	CX,CX
	MOV	AL,Len
	MOV	CL,AL
	STOSB
	MOV	AL,' '
	REP	STOSB
	RET	6
ClrStr	ENDP

CODE	ENDS

	END
