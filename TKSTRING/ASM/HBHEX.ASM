;******************************************************
;		   HBHEX.ASM  V 1.0
;	       String handling routines
;	 Copyright (c) HB-Soft 1991.
;		 All rights reserved.
;******************************************************


;******************************************************	Data

DATA	SEGMENT	WORD PUBLIC

DATA	ENDS

;******************************************************	Code

CODE	SEGMENT	BYTE PUBLIC

	ASSUME	CS:CODE,DS:DATA

	PUBLIC	HexB, HexW, HexL, HexPtr

;--------------------------------------------------------
;FUNCTION HexW(W : Word) : String;
HexW	PROC	FAR
	MOV	AL,4
HexW1:	MOV	BX,8
	CALL	HexUP
	RET	2
HexW	ENDP

;--------------------------------------------------------
;FUNCTION HexPtr(P : Pointer) : String;
HexPtr	PROC	FAR
	MOV	AL,9
HexP1:	MOV	BX,10
	CALL	HexUP
	RET	4
HexPtr	ENDP

;------------------------------------------------------
;FUNCTION HexB(B : Byte) : String;
HexB	PROC	FAR
	MOV	AL,2
	JMP	SHORT HexW1
HexB	ENDP

;--------------------------------------------------------
;FUNTION HexL(L : LongInt) : String;
HexL	PROC	FAR
	MOV	AL,8
	JMP	SHORT HexP1
HexL	ENDP

;--------------------------------------------------------
HexUP	PROC	NEAR
	ADD	BX,SP			;BX = Pointer auf Parameter
	LES	DI,SS:[BX]		;ES:DI := Adresse Output-String
HexUPB:	CLD				;Stringoperationen vorw„rts
	STOSB				;Stringl„nge => Output-String
	MOV	CH,AL			;CH: z„hlt auszugebende Hex-Digits
	CMP	AL,2			;HexB ?
	JNZ	HexUP0
	DEC	BX			; ja => Pointer-1
HexUP0:	CMP	CH,5			;IF  HexPtr ?
	JNZ	HexUP3			; THEN
	MOV	AL,':'			;  ':' ausgeben
	STOSB
	DEC	CH
HexUP3:	DEC	BX			;Pointer-1
	MOV	AL,SS:[BX]		;zu konvertierendes Byte lesen
	MOV	AH,AL
	MOV	CL,4
	SHR	AH,CL			;AH := h”herwertigem Halbbyte
	AND	AL,0FH			;AL := niederwertigem Halbbyte
	OR	AX,3030H		;AH u. AL in Zeichen wandeln
	CMP	AL,'9'			;AL > '9' ?
	JBE	HexUP1
	ADD	AL,'A'-3AH		; ja => in Zeichen von 'A' bis 'F'
HexUP1:	XCHG	AL,AH
	CMP	AL,'9'			;AH > '9' ?
	JBE	HexUP2
	ADD	AL,'A'-3AH		; ja => in Zeichen von 'A' bis 'F'
HexUP2:	STOSW
	SUB	CH,2
	JNZ	HexUP0			;Byte-Anz = 0 ?, ja=>Ende, nein=>weiter
	RET
HEXUP	ENDP

CODE	ENDS

	END
