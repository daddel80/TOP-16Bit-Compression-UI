;******************************************************
;		   HBCOMP1.ASM V 1.0
;	       String handling routines
;	     Copyright (c) HB-Soft 1991.
;		 All rights reserved.
;******************************************************

;******************************************************	Data

DATA	SEGMENT	WORD PUBLIC

DATA	ENDS

;******************************************************	Code

CODE	SEGMENT	BYTE PUBLIC

	ASSUME	CS:CODE,DS:DATA

	PUBLIC	CompString, CompUCString, CompStruct

	EXTRN	UpCase : FAR

;****************************************************** Comp1_UP

Comp1_UP	PROC	NEAR
	REPE	CMPSB			;Compare until no match	or CX =	0
	RET
Comp1_UP	ENDP

;****************************************************** Comp2_UP

Comp2_UP	PROC	NEAR
Start:	LODSB				;S1[?] into AL
	PUSH	AX
        Call    UpCase                  ;AL=upcase(AL)
        MOV     AH,AL

Skip1:	MOV	AL,ES:[DI]		;S2[?] into AL
	INC	DI			;Point ES:DI to	next char in S2
	PUSH	AX
        Call    UpCase

Skip2:	CMP	AH,AL			;Compare until no match
	LOOPE	Start

	RET
Comp2_UP	ENDP

;******************************************************	CompString

;  function CompString(s1, s2 :	string)	: CompareType;
;    {-Return 0, 1, 2 if s1<s2,	s1=s2, or s1>s2}

CompString  PROC FAR
	MOV	DX,OFFSET Comp1_UP
CompStr:
	MOV	BX,SP			;Set up	stack frame
	PUSH	DS			;Save DS

	CLD				;Go forward
	LES	DI,SS:[BX+4]		;ES:DI points to S2
	LDS	SI,SS:[BX+8]		;DS:SI points to S1

	MOV	AH,ES:[DI]		;AH = Length(S2)
	INC	DI			;DI points to S2[1]
	LODSB				;AL = Length(S1)
					;SI points to S1[1]

	XOR	BX,BX			;BX holds temporary result
	XOR	CX,CX			;CX holds count	of chars to compare

	MOV	CL,AL			;Length(S1) in CL
	CMP	AL,AH			;Compare lengths
	JE	EqLen			;Lengths equal ?
	JB	Comp			;Jump if S1 shorter than S2

	INC	BX			;S1 longer than	S2
	MOV	CL,AH			;Length(S2) in CL

EqLen:	INC	BX			;Equal or greater

Comp:	JCXZ	Done			;Done if either	is empty

	CALL	DX			;Call Compare Procedure

	JE	Done			;If Equal, result ready	based on length

	MOV	BL,2
	JA	Done			;S1 Greater? Return 2
	XOR	BX,BX			;Else S1 Less, Return 0

Done:	MOV	AX,BX			;Result	into AX
	POP	DS			;Restore DS
	RET	8			;Remove	parameters and return

CompString	ENDP

;******************************************************	CompUCString

;  function CompUCString(s1, s2	: string) : CompareType;
;    {-Return 0, 1, 2 if s1<s2,	s1=s2, or s1>s2}
;    {-Comparison is done in uppercase}

CompUCString  PROC FAR
	MOV	DX,OFFSET Comp2_UP
	JMP	SHORT CompStr
CompUCString	ENDP


;******************************************************	CompStruct

;  function CompStruct(var s1, s2; size	: word)	: CompareType;
;    {-Compare two fixed size structures}

CompStruct  PROC FAR

	MOV	BX,SP			;Set up	stack frame
	PUSH	DS			;Save DS
	MOV	AX,1			;BX holds temporary result (Equal)

	MOV	CX,SS:[BX+4]		;Size in CX
	JCXZ	CSDone			;Make sure size	isn't zero

	CLD				;Go forward
	LES	DI,SS:[BX+6]		;ES:DI points to S2
	LDS	SI,SS:[BX+10]		;DS:SI points to S1

	REPE	CMPSB			;Compare until no match	or CX =	0
	JE	CSDone			;If Equal, result ready	based on length

	INC	AX			;Prepare for Greater
	JA	CSDone			;S1 Greater? Return 2
	XOR	AX,AX			;Else S1 Less, Return 0

CSDone:	POP	DS			;Restore DS
	RET	10			;Remove	parameters and return

CompStruct	ENDP


CODE	ENDS

	END
