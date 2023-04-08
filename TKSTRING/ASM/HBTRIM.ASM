;******************************************************
;                  HBTRIM.ASM V 1.0
;               String handling routines
;             Copyright (c) by HB-Soft 1991.
;                  All rights reserved.
;******************************************************


;****************************************************** Data

DATA    SEGMENT WORD PUBLIC

DATA    ENDS

;****************************************************** Code

CODE    SEGMENT BYTE PUBLIC

        ASSUME  CS:CODE,DS:DATA

        PUBLIC  LTrim, RTrim, Trim

;******************************************************

LT_UP	PROC	NEAR
;DS:SI - Quell String
;ES:DI - Ziel String
	LES	DI,[BP+6]		;ES:DI := S
	MOV	CL,ES:[DI]		;CX := LENGTH(S)
	MOV	CH,0
	INC	DI
	JCXZ	LT_UP1
	CLD
	MOV	AL,' '
	REPE	SCASB			;suchen bis kein Leerzeichen
	JE	LT_UP1
	INC	CX
	MOV	AL,CL
	DEC	DI
	MOV	SI,DI			;DS:SI := S
	PUSH	ES
	POP	DS
LT_UP1:	LES	DI,[BP+10]		;ES:DI := Output String
	MOV	AL,CL
	STOSB				;Output String := L„nge
	REP	MOVSB			;String kopieren
	RET
LT_UP	ENDP

;******************************************************

RT_UP	PROC	NEAR
	LES	DI,[BP+10]
	PUSH	DI
	MOV	CL,ES:[DI]
	MOV	CH,0
	ADD	DI,CX
	JCXZ	RT_UP1
	MOV	AL,' '
	STD
	REPE	SCASB
	JE	RT_UP1
	INC	CX
RT_UP1:	POP	DI
	MOV	ES:[DI],CL
	RET
RT_UP	ENDP

;****************************************************** LTrim

;function LTrim(S : String) : String;

LTrim   PROC    FAR
        PUSH    BP
        MOV     BP,SP
        PUSH    DS
	CALL	LT_UP
        POP     DS
        POP     BP
        RET     4
LTrim   ENDP

;****************************************************** RTrim

;function RTrim(S : String) : String;

RTrim   PROC    FAR
        PUSH    BP
        MOV     BP,SP
        PUSH    DS
	LES	DI,[BP+10]		;ES:DI := Output String
	LDS	SI,[BP+6]		;DS:SI := S
	LODSB
	MOV	CL,AL
	MOV	CH,0
	STOSB
	REP	MOVSB
	CALL	RT_UP
        POP     DS
        POP     BP
        RET     4
RTrim   ENDP

;****************************************************** Trim

;function Trim(S : String) : String;

Trim    PROC    FAR
        PUSH    BP
        MOV     BP,SP
        PUSH    DS
	CALL	LT_UP
	CALL	RT_UP
	POP	DS
        POP     BP
        RET     4
Trim    ENDP

;******************************************************


CODE    ENDS

        END
