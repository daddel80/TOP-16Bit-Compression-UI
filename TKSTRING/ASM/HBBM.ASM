;******************************************************
;		    HBBM.ASM  V. 1.0
;	       String handling routines
;	 Copyright (c) Heiko Becker HB-Soft 1991.
;		 All rights reserved.
;******************************************************

;******************************************************	Data

DATA	SEGMENT	WORD PUBLIC

DATA	ENDS

;******************************************************	Code

CODE	SEGMENT	BYTE PUBLIC

	ASSUME	CS:CODE,DS:DATA

	PUBLIC	BMMakeTable, BMSearch, BMSearchUC

	EXTRN	UpCase : FAR

;****************************************************** UpC

UC	EQU	Byte PTR SS:[BP-2]

Upc	Proc   Near                           ;UpCase	character in AL
	CMP	UC,1
	JNE	Up_End
	PUSH	AX
	CALL	UpCase
Up_end:	ret
UPC     ENDP

;******************************************************	BMMakeTable

;  procedure BMMakeTable(MatchString : string; var BT :	BTable);
;    Build Boyer-Moore link table
;    BTable is array[0..255] of	byte;

MString	EQU    DWORD PTR SS:[BX+8]
BTable	EQU    DWORD PTR SS:[BX+4]

BMMakeTable   PROC   FAR

	MOV    BX,SP			;Set up	stack frame
	PUSH   DS			;Save DS
	CLD				;Go forward

	LDS    SI,MString		;DS:SI => MatchString
	LES    DI,BTable		;ES:DI => BTabel
	MOV    BX,DI			;Save DI in BX
	LODSB				;AL = length(MatchString)
	MOV    AH,AL			;Copy it to AH
	MOV    CX,128			;Number	of words in BT
	REP    STOSW			;Fill BT with length(MatchString)
	CMP    AL,1			;Is length(MatchString)	<= 1?
	JBE    MTDONE			;Yes, we're done

	MOV    DI,BX			;Restore base of table from BX
	MOV    BH,CH			;BH = 0
	MOV    CL,AL			;CX = length(MatchString)
	DEC    CX			;CX = length(MatchString)-1

MTnext:	LODSB				;AL = MatchString[i]
	MOV    BL,AL			;BL = MatchString[i]
	MOV    ES:[BX+DI],CL		;BTable[char] =	length(MatchString)-i
	LOOP   MTnext			;Repeat	for all	characters in MatchString

MTDone:	POP    DS			;Restore DS from Stack
	RET    8			;Remove	parameters and return

BMMakeTable   ENDP

;******************************************************	BMSearch

;  function BMSearch(var Buffer;
;		     BufLength : Word;
;		     BT	: BTable;
;		     MatchString : string) : Word;
;    Search Buffer for MatchString
;    Return FFFF for failure
;    Else return number	of bytes searched to find MatchString

MString	EQU    DWORD PTR [BP+6]
BTable	EQU    DWORD PTR [BP+10]
BufSize	EQU    WORD PTR	[BP+14]
Buffer	EQU    DWORD PTR [BP+16]
BufOfs	EQU    WORD PTR	[BP+16]

BMSearch   PROC	  FAR
	MOV    AL,0
	JMP    SHORT Search

BMSearch   ENDP

;***************************************************** BMSearchUC

;  function BMSearchUC(var Buffer;
;		       BufLength : Word;
;		       BT : BTable;
;		       MatchString : string) : Word;
;    Case-insensitive search of	Buffer for MatchString
;    Return FFFF for failure
;    Else return number	of bytes searched to find MatchString
;    Assumes MatchString is already raised to uppercase

BMSearchUC   PROC   FAR
	MOV    AL,1
Search:	PUSH   BP
	MOV    BP,SP
	PUSH   AX			;BP-0 UpCase
	PUSH   DS			;Will wipe out DS

	MOV    CX,BufSize		;CX = Buffer size
	LES    DI,Buffer		;ES:DI => Buffer
	LDS    BX,BTable		;DS:BX => BTable
	MOV    AX,DS			;Keep BTable segment in	AX a moment
	LDS    SI,MString		;DS:SI => MatchString
	PUSH   AX			;Keep BTable segment in	SS:BP-4

	XOR    AX,AX			;AX = 0
	MOV    DX,AX			;DX = 0
	MOV    DL,[SI]			;DL = length(MatchString)
	OR     DL,DL			;Check for trivial case
	JZ     BMSUnotFound		;Fail for empty	string

BMSUinit:
	DEC    DX			;DX = length(MatchString)-1
	ADD    SI,DX			;DS:SI => MatchString[length(MatchString)-1]
	ADD    CX,DI			;CX = offset of	last char in buffer
	ADD    DI,DX			;ES:DI => first	position to search
	MOV    DH,[SI+1]		;DH = MatchString[length(MatchString)]
	STD				;Go backwards
	JMP    SHORT BMSUcomp		;Skip link table first time

BMSUnext:
	PUSH   DS			;Save DS a moment
	MOV    DS,SS:[BP-6]		;Get segment of	link table
	XLAT				;Get size of link at DS:[BX+AL]
	POP    DS			;Restore DS
	ADD    DI,AX			;Compute next place to search

BMSUcomp:
	CMP    DI,CX			;At end	of buffer?
	JAE    BMSUnotFound		;Done if so
	MOV    AL,ES:[DI]		;AL = next char	to try
        CALL   Upc			;Raise it to uppercase
	CMP    DH,AL			;Does it match the end of MatchString?
	JNE    BMSUnext			;If not	same, go back and try again

	PUSH   CX			;Save end of buffer position
	DEC    DI			;Start comparing one character before
	MOV    CL,DL			;Compare length(MatchString)-1 characters
	MOV    CH,AH			;CH = 0
	JCXZ   BMSUfound		;Completely matched if CX = 0

BMSUcomp2:
	LODSB				;Next match character in AL
        MOV    AH,AL
	MOV    AL,ES:[DI]		;Next buffer character in AH
	DEC    DI			;Decrement buffer index
        CALL   Upc			;Uppercase it
	CMP    AH,AL			;A match?
	LOOPE  BMSUcomp2		;Loop while AH=AL and CX<>0
	JE     BMSUfound		;Matched!

	XOR    AH,AH			;Restore SI,DI,AX
	MOV    AL,DL
	SUB    AL,CL
	ADD    SI,AX
	ADD    DI,AX
	INC    DI
	MOV    AL,DH			;Put matched char back in AL
	POP    CX			;Restore end of	buffer
	JMP    SHORT BMSUnext		;Try again

BMSUfound:				;DI points to start of match
	INC    SP			;End of	buffer off stack
	INC    SP
	SUB    DI,BufOfs		;Subtract buffer start address
	MOV    AX,DI
	INC    AX			;Return	0 if found in first byte
	JMP    SHORT BMSUDone2		;We're done

BMSUnotFound:
	MOV    AX,0FFFFh		;Result	= FFFF
BMSUDone:				;Result	returned in AX
BMSUDone2:
	CLD
	POP    DS
	MOV    SP,BP
	POP    BP
	RET    14

BMSearchUC   ENDP

CODE	ENDS

	END
