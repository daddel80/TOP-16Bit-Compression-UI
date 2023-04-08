;******************************************************
;		   HBCASE.ASM V 1.0
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

	PUBLIC	Upcase, Locase, UpString, LoString


UpUmlaut LABEL BYTE
        DB      20h,'AZŽ™š'
LoUmlaut LABEL BYTE
        DB      0E0h,'az„”'
Umlaut2 LABEL BYTE
	DB      20h,'AZŽ™š'
AnzUmlaut       EQU     LoUmlaut-UpUmlaut

;****************************************************** Upcase

;funktion UpCase(c:Char);

C	EQU	[BP+8]

Upcase	proc	far
	PUSH	DI
	MOV	DI,Offset LoUmlaut+1

Case:	PUSH	BP
	MOV	BP,SP
	PUSH	ES
	PUSH	CS
	POP	ES
	MOV	AL,C
	CLD
	SCASB
	JB      NoChange
	SCASB
	JA      UmlautChange
	ADD     AL,ES:[DI-3]
        JMP     SHORT NoUmlaut1

NoChange:
	INC	DI
UmlautChange:
        PUSH    CX
	MOV	CX,AnzUmlaut-3                          ;Wieviel ??
	REPNE	SCASB
        JNE     NoUmlaut
        MOV     AL,ES:[DI+AnzUmlaut-1]
NoUmlaut:
        POP     CX
NoUmlaut1:
	POP	ES
	POP	BP
	POP	DI
	RET	2
UpCase  ENDP

;****************************************************** Locase

;funktion LoCase(c:Char);

Locase	proc	far
	PUSH	DI
	MOV	DI,Offset UpUmlaut+1
	JMP	SHORT Case
Locase  ENDP


;******************************************************	StUpcase

;function UpString(S : string) : string;
;Convert lower case letters in string to upper case.

UpString	PROC FAR
	MOV	DX,OFFSET Upcase

UP_LO:
	MOV	BX,SP				;set up	stack frame
	CLD					;go forward
	PUSH	DS				;Save DS
	LDS	SI,SS:[BX+4]			;DS:SI => S
	LES	DI,SS:[BX+8]			;ES:DI => function result
	LODSB					;AL = Length(S)
	STOSB					;Set length of result
	MOV	CH,0				;CH = 0
	MOV	CL,AL				;CX = Length(S)
	JCXZ	SUDone				;Done if CX is 0
SUNext:
	LODSB					;Next char into	AL
	PUSH	AX
	PUSH	CS
	CALL	DX
	STOSB					;Store char in result
	LOOP	SUNext				;repeat
SUDone:
	POP	DS				;Restore DS
	RET	4				;remove	parameter and return

UpString	ENDP

;******************************************************	StLocase

;function LoString(S : string) : string;
;Convert upper case letters in string to lower case

LoString	PROC FAR
	MOV	DX,OFFSET Locase
	JMP	SHORT UP_LO
LoString	ENDP


CODE	ENDS

	END
