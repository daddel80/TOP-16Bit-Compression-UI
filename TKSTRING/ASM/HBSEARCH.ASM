;******************************************************
;		   HBSEARCH.ASM	 V 1.0
;	       String handling routines
;	 Copyright (c) Heiko Becker, HB-Soft 1991.
;		 All rights reserved.
;******************************************************


;******************************************************	Data

DATA	SEGMENT	WORD PUBLIC

DATA	ENDS

;******************************************************	Code

CODE	SEGMENT	BYTE PUBLIC

	ASSUME	CS:CODE,DS:DATA

	PUBLIC	Search,	SearchUC

	EXTRN	UpCase : FAR

Upc	PROC	NEAR
	PUSH	AX
	CALL	UpCase
	RET
Upc	ENDP

;******************************************************	Search

;function Search(var Buffer; BufLength : Word;
;		 var Match;  MatLength : Word) : Word;

;Search	through	Buffer for Match.
;BufLength is length of	range to search.
;MatLength is length of	string to match.
;Returns number	of bytes searched to find Match, 0FFFFh	if not found.

;equates for parameters:
MatLength	EQU	WORD PTR [BP+6]
Match		EQU	DWORD PTR [BP+8]
BufLength	EQU	WORD PTR  [BP+12]
Buffer		EQU	DWORD PTR [BP+14]

Search	PROC FAR
	MOV	BL,0
	JMP	SHORT SUp
Search	ENDP

;******************************************************	SearchUC

;function SearchUC(var Buffer; BufLength : Word;
;		   var Match;  MatLength : Word) : Word;

;Search	through	Buffer for Match (CASE-INSENSITIVE)
;BufLength is length of	range to search.
;MatLength is length of	string to match.
;Returns number	of bytes searched to find Match, 0FFFFh	if not found.

SearchUC  PROC FAR
	MOV	BL,1

SUp:	PUSH	BP			;Save BP
	MOV	BP,SP			;Set up	stack frame
	PUSH	DS			;Save DS
	CLD				;Go forward

	MOV	CX,BufLength		;CX = Length of	range to scan
	MOV	DX,MatLength		;DX = Length of	match string

	LDS	SI,Match		;DS:SI => Match	buffer
	LES	DI,Buffer		;ES:DI => Buffer
	MOV	BP,DI			;BP = Ofs(Buffer)

	OR	DX,DX			;Length(Match) = 0?
	JZ	Error			;If so,	we're done

	LODSB				;AL = Match[1];	DS:SI => Match[2]
	OR	BL,BL			;IF SearchUC ?
	JZ	NotUC1
	CALL    Upc			;Uppercase it
	MOV     AH,AL
NotUC1:
	DEC	DX			;DX = MatLength-1
	SUB	CX,DX			;CX = BufLength-(MatLength-1)
	JBE	Error			;No match if BufLength is less

;Search	for first character in Match
Next:	OR	BL,BL			;IF SearchUC (BL<>0)
	JZ	NotUC2
SUCNext:MOV	AL,ES:[DI]		;Get next character of buffer
	INC	DI			;To next position
	CALL    Upc			;Uppercase it
	CMP	AH,AL			;A match?
	LOOPNE	SUCNext			;Loop while CX<>0 and AH<>AL
	JMP	SHORT Next1
NotUC2:	REPNE	SCASB			;Search forward for Match[1]
Next1:	JNE	Error			;Done if not found
	OR	DX,DX			;If Length = 1 (DX = 0)	...
	JZ	Found			; the "string" was found

	;Search	for remainder of Match

	PUSH	AX			;Save AX
	PUSH	CX			;Save CX
	PUSH	DI			;Save DI
	PUSH	SI			;Save SI

	MOV	CX,DX			;CX = Length(Match) - 1

	OR	BL,BL			;IF SearchUC (BL<>0) ?
	JZ	NotUC3
SUCNextM:
	LODSB				;Next match character in AL
	CALL    Upc			;Uppercase it
	MOV     AH,AL
	MOV	AL,ES:[DI]		;Next buffer character in AH
	INC	DI			;Increment index
	CALL    Upc			;Uppercase it
	CMP	AH,AL			;A match?
	LOOPE	SUCNextM		;Loop while AH=AL and CX<>0
	JMP	SHORT Next2
NotUC3:	REPE	CMPSB

Next2:	POP	SI			;Restore SI
	POP	DI			;Restore DI
	POP	CX			;Restore CX
	POP	AX			;Restore AX

	JNE	Next			;Try again if no match

;Calculate number of bytes searched and	return
Found:	DEC	DI			;DX = Offset where found
	MOV	AX,DI			;AX = Offset where found
	SUB	AX,BP			;Subtract starting offset
	JMP	SHORT Done		;Done

;Match was not found
Error:	XOR	AX,AX
	DEC	AX			;Return	FFFF

Done:	POP	DS			;Restore DS
	POP	BP
	RET	12

SearchUC  ENDP


CODE	ENDS

        END
