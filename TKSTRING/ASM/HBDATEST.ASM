;******************************************************
;		HBDATEST.ASM  V 1.0
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

	PUBLIC	DateStr

;--------------------------------------------------------
;FUNCTION DateStr : String;

DateStr	PROC	FAR
	MOV	BX,SP

;** ParameterÅbernahme **
	LES	DI,SS:[BX+4]			;ES:DI := @Output-String
	CLD

	MOV	AL,8
	STOSB					;DateStr[0] := StinglÑnge

;** Datum Åber DOS ermitteln **
	MOV	AH,2AH
	INT	21H

;** Werte in Zeichkette wandeln **
;** DL = Tage, DH = Monat, CX = Jahr
	MOV	AL,DL
	CALL	DateUP
	MOV	AL,'.'
	STOSB
	MOV	AL,DH
	CALL	DateUP
	MOV	AL,'.'
	STOSB
	MOV	AX,CX
	MOV	BL,100
	DIV	BL
	MOV	AL,AH
	CALL	DateUP

	RET


DateUP	PROC	NEAR
	MOV	AH,0
	MOV	BL,10
	DIV	BL
	OR	AX,3030H
	STOSW
	RET
DateUP	ENDP

DateStr	ENDP


CODE	ENDS

	END
