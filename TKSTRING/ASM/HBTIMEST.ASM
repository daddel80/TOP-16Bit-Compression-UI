;******************************************************
;		HBTIMEST.ASM  V 1.0
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

	PUBLIC	TimeStr

;--------------------------------------------------------
;FUNCTION TimeStr(TimeMS:LongInt; hmsh:Byte) : String;
;  {-Gibt TimeMs (Zeit in Millisekunden) formatiert aus
;    hmsh=1: nur Stunden
;         2: HH:MM
;         3: HH:MM:SS
;	  4: HH:MM:SS.hh }
TimeStr	PROC	FAR
	PUSH	BP				;BEGIN {FUNCTION TimeStr}
	MOV	BP,SP

;** ParameterÅbernahme **
	MOV	AL,[BP+6]			;    CL := HMSH
	LES	BX,[BP+8]			;    DX:BX := TimeMS
	MOV	DX,ES
	LES	DI,[BP+12]			;    ES:DI := @Output-String

;** PrÅfung des Parameters HMSH
	CLD
	CMP	AL,4
	JBE	TS2
	MOV	AL,0
TS2:	MOV	CL,AL
	SHL	AL,1
	ADD	AL,CL
	JZ	TS1
	DEC	AX
TS1:	STOSB					;    TimeStr[0]:=StringlÑnge
	JZ	TEnd

;** Stunden berechnen **
	XOR	AX,AX				;    AX = StundenzÑhler
	MOV	SI,0EE80H
SB1:	INC	AX
	SUB	BX,SI
	SBB	DX,0036H
	JNC	SB1
	ADD	BX,SI
	ADC	DX,0036H
	DEC	AX
	PUSH	BX
	MOV	CH,':'
	CALL	TUP1
	POP	AX

;** Minuten berechen **
	MOV	BX,60000
	CALL	TUP

;** Sekunden berechnen **
	MOV	BX,1000
	MOV	CH,'.'
	CALL	TUP

;** Hundertstel berechnen **
	MOV	BX,10
	CALL	TUP

TEnd:	MOV	DI,[BP+12]
	INC	DI
	CMP	BYTE PTR ES:[DI],'0'
	JNE	SB2
	MOV	AL,' '
	STOSB
SB2:	MOV	SP,BP
	POP	BP
	RET	6

TUP	PROC	NEAR
	DIV	BX
	CALL	TUP1
	MOV	AX,DX
	XOR	DX,DX
	RET
TUP	ENDP

TUP1	PROC	NEAR
	MOV	BH,10
	DIV	BH
	OR	AX,3030H
	STOSW
	DEC	CL
	JZ	TEnd
	MOV	AL,CH
	STOSB
	RET
TUP1	ENDP

TimeStr	ENDP


CODE	ENDS

	END
