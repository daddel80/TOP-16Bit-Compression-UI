;******************************************************
;		   TPCOMP.ASM 4.03
;	       String handling routines
;	 Copyright (c) TurboPower Software 1987.
; Portions copyright (c) Sunny Hill Software 1985, 1986
;     and used under license to	TurboPower Software
;		 All rights reserved.
;******************************************************

;******************************************************	Data

DATA	SEGMENT	WORD PUBLIC

	EXTRN	LetterValues : BYTE	;Table of letter values

DATA	ENDS

;******************************************************	Code

CODE	SEGMENT	BYTE PUBLIC

	ASSUME	CS:CODE,DS:DATA

	PUBLIC	Soundex, MakeLetterSet,	CompareLetterSets

	EXTRN	UpCase : FAR

;******************************************************	Soundex

;  function Soundex(s :	string)	: string;
;    {-Return 4	character soundex of input string}

;256 byte lookup table ASCII ==> soundex code
SoundExTable label byte
    db	 65 dup(0)
;	 A  B	C   D  E  F   G	 H I  J	  K   L	  M   N	 O  P	Q   R	S   T  U  V  W	X  Y  Z
    db	 0,'1','2','3',0,'1','2',0,0,'2','2','4','5','5',0,'1','2','6','2','3',0,'1',0,'2',0,'2'
    db	 6 dup(0)
;	 a  b	c   d  e  f   g	 h i  j	  k   l	  m   n	 o  p	q   r	s   t  u  v  w	x  y  z
    db	 0,'1','2','3',0,'1','2',0,0,'2','2','4','5','5',0,'1','2','6','2','3',0,'1',0,'2',0,'2'
    db   102 dup(0)
;        á      behandle á wie S
    db   '2'
    db	 30 dup(0)

;Parameter and function	result
    Result EQU DWORD PTR [BP+10]
    Input  EQU DWORD PTR [BP+6]

Soundex	PROC FAR

	PUSH   BP
	MOV    BP,SP
	PUSH   DS
	CLD

	LES    DI,Result		;ES:DI => function result
	MOV    AL,4
	STOSB				;Result	will be	4 characters long
	MOV    BX,DI			;Store output position in BX
	XOR    AX,AX			;Store four '0's in output
	STOSW
	STOSW				;Initialize to zeros
	MOV    DI,BX			;Reset output position

	LDS    SI,Input			;DS:SI => Input	string
	LODSB				;Length	byte into AL
	MOV    CX,AX			;Length	into CX
	JCXZ   SXDone			;We're done if null string
	LODSB				;Get first character of	input
	PUSH   AX
        CALL   UpCase			;Uppercase it
	STOSB				;Store first output character
	DEC    CX			;One input character used
	JCXZ   SXDone			;Done if one character string

	MOV    AH,AL			;Save previous character
	MOV    DX,0401h			;DL has	output length, DH max output length
	XOR    BH,BH			;Prepare BX for	indexing

SXNext:
	LODSB				;Next character	into AL
	MOV    BL,AL			;Set up	base register
	MOV    AL,CS:SoundexTable[BX]	;Get soundex code into AL
	OR     AL,AL			;Null soundex code?
	JZ     SXNoStore		;Don't store it
	CMP    AH,AL			;Code same as previous output?
	JZ     SXNoStore		;Don't store it
	STOSB				;Store to output
	INC    DL			;Output	length increased by one
	CMP    DL,DH			;Check output length
	JAE    SXDone			;Stop at four chars of output
	MOV    AH,AL			;Store previous	output character

SXNoStore:
	LOOP   SXNext

SXDone:
	POP    DS
	POP    BP
	RET    4			;Leave result pointer on stack

Soundex	ENDP

;******************************************************	MakeLetterSet

;function MakeLetterSet(S : string) : LongInt;
;Return	a bit-mapped long storing the individual letters contained in S.

MLSstr	EQU	DWORD PTR SS:[BX+4]

MakeLetterSet	PROC FAR

	MOV	BX,SP				;Set up	stackframe
	PUSH	BP				;Save BP
	PUSH	DS				;Save DS
	XOR	DI,DI				;DI = 0
	MOV	AX,DI				;AX = 0
	CLD					;Go forward
	LDS	SI,MLSstr			;DS:SI => string
	LODSB					;AX = Length(S)
	MOV	CX,AX				;CX = Length(S)
	MOV	BX,DI				;DI:BX = 0
	JCXZ	MLSexit				;Done if CX is 0

MLSnext:
	MOV	AH,0				;AH = 0
	LODSB					;AL has	next char in S
	PUSH	AX
        Call    UpCase
        CMP     AX,142                          ;Check Ž
        JNE     MLSF1
        MOV     AX,26
        JMP     MLSFound
MLSF1:  CMP     AX,153                          ;Check ™
        JNE     MLSF2
        MOV     AX,27
        JMP     MLSFound
MLSF2:  CMP     AX,154                          ;Check š
        JNE     MLSF3
        MOV     AX,28
        JMP     MLSFound
MLSF3:  CMP     AX,225                          ;Check á
        JNE     MLSF4
        MOV     AX,29
        JMP     MLSFound
MLSF4:
	SUB	AX,'A'				;Convert to bit	number
	CMP	AX,'Z'-'A'			;Was char in range 'A'..'Z'?
	JA	MLSskip				;Skip it if not

MLSFound:
	XCHG	CX,AX				;CX = bit #, AX	= loop count
	XOR	DX,DX				;DX:AX = 1
	MOV	BP,1
	JCXZ	MLSnoShift			;don't shift if CX is 0

MLSshift:					;DX:BP = 1 shl BitNumber
	SHL	BP,1				;shift low word
	RCL	DX,1				;shift high word
	LOOP	MLSshift			;repeat

MLSnoshift:
	OR	DI,DX				;DI:BX = DI:BX or DX:BP
	OR	BX,BP
	MOV	CX,AX				;Restore CX from AX

MLSskip:
	LOOP	MLSnext				;Get next character

MLSexit:
	MOV	DX,DI				;DX:AX = DI:BX
	MOV	AX,BX
	JMP	SHORT SXDONE
;	POP	DS				;Restore DS
;	POP	BP				;Restore BP
;	RET	4				;Remove	parameter and return

MakeLetterSet	ENDP

;******************************************************	CompareLetterSets

;function CompareLetterSets(Set1, Set2 : LongInt) : Word;
;Returns the sum of the	values of the letters common to	Set1 and Set2.

Set1	EQU	DWORD PTR SS:[BX+4]
Set2Hi	EQU	WORD PTR SS:[BX+6]
Set2Lo	EQU	WORD PTR SS:[BX+8]

CompareLetterSets	PROC FAR

	MOV	BX,SP				;Set up	stack frame
	PUSH	BP				;Save BP

	LES	DI,Set1				;Set1 in ES:DI
	MOV	SI,ES				;Set1 in SI:DI
	AND	DI,Set2Lo			;SI:DI = Set1 and Set2
	AND	SI,Set2Hi

	XOR	BP,BP				;BP = 0
	MOV	CX,('Z'-'A')+1+4		;Loop count (incl. Umlaute)

CLSnext:
	MOV	BX,CX				;save CX in BX
	XOR	DX,DX				;DX:AX = 1
	MOV	AX,1
	DEC	CX				;subtract 1 to get bit number
	JZ	CLSnoShift			;don't shift if CX is 0

CLSshift:					;DX:AX = 1 shl BitNumber
	SHL	AX,1				;shift low word
	RCL	DX,1				;shift high word
	LOOP	CLSshift			;repeat

CLSnoshift:
	MOV	CX,BX				;restore CX from BX
	AND	AX,DI				;DX:AX = DX:AX and SI:DI
	AND	DX,SI
	OR	AX,DX				;DX:AX = 0?
	JNZ	CLSadd				;if not, add letter value
	LOOP	CLSnext				;else, next element
	JMP	SHORT CLSexit			;done

CLSadd:
						;AX has	value of the letter
	MOV	AX,CX				;AL = loop count
	DEC	AX				;convert to index into table
	MOV	BX,Offset LetterValues		;DS:BX points to LetterValues
	XLAT					;AL has	value of the letter
	ADD	BP,AX				;add to	result
	LOOP	CLSnext				;next element

CLSexit:
	MOV	AX,BP				;Function result into AX
	POP	BP				;Restore BP
	RET	8				;Remove	parameters and return

CompareLetterSets	ENDP


CODE	ENDS

	END
