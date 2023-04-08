;******************************************************
;		HBBINARY.ASM  V 1.0
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

	PUBLIC	Binary

;--------------------------------------------------------
;FUNCTION Binary(L : LongInt; Bits : Byte) : String;
;  {-Die in BITS angegebene Anzahl Bits (Rechts beginnend) werden
;   im String dargestellt}
Binary	PROC	FAR			;BEGIN
	POP	SI			;      Rckkehradresse vom Stack nehmen
	POP	AX
;** Parameterbernahme **
	POP	CX			;      CX    := Bits
	MOV	CH,0
	POP	BX			;      DX:BX := L
	POP	DX
	POP	DI			;      ES:DI := @Output String
	POP	ES
	PUSH	ES
	PUSH	DI
	PUSH	AX			;      Ruckkehradresse zurckspeichern
	PUSH	SI

	MOV	ES:[DI],CL		; Binary[0] := char(Bits);
	JCXZ	BinE			; FOR I := Bits DOWNTO 1 DO BEGIN
	STD				;      Richtung fr STOSB = Rckw„ts
	ADD	DI,CX			;      DI = Zeiger auf letztes Zeichen
Bin1:	SHR	DX,1
	RCR	BX,1			;   L:=L SHR 1 => CY;
	MOV	AL,30H SHR 1
	RCL	AL,1
	STOSB				;   Binary[I] := char((L AND 1)+$30);
	LOOP	Bin1			; END;
BinE:	RET				;END;
Binary	ENDP
;--------------------------------------------------------

CODE	ENDS

	END
