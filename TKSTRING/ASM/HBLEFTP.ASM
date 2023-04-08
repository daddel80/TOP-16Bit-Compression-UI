;******************************************************
;                  HBLEFTP.ASM V 1.0
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

        PUBLIC  LeftPadCh, LeftPad

;******************************************************

LeftPad_Up	PROC	NEAR
        MOV     CL,[BP+6]              ;CL := LEN
        CLD
        LODSB                          ;S => OUTPUT STRING, AL := LENGTH(S)
	MOV	CH,0
	MOV	AH,CL		       ;AH := LEN
	XCHG	AL,AH		       ;AL := LEN, AH := LENGTH(S)	
        SUB     CL,AH		       ;CL := LEN - LENGTH(S)
        JNBE    LPADCH
        MOV     CL,0
	MOV	AL,AH
LPADCH: STOSB
	MOV	AL,BL		       ;AL := C
	REP	STOSB

	MOV	CL,AH
        REP     MOVSB

	RET
LeftPad_Up	ENDP

;****************************************************** PadCh

;function LeftPadCh(S : String; C : Char; Len : Byte) : String;

LeftPadCh   PROC    FAR
        PUSH    BP
        MOV     BP,SP
        PUSH    DS
        LES     DI,[BP+14]             ;ES:DI := OUTPUT STRING
        LDS     SI,[BP+10]             ;DS:SI := S
	MOV	BL,[BP+8]	       ;BL := C	
	CALL	LeftPad_UP
        POP     DS
        POP     BP
        RET     8
LeftPadCh   ENDP

;****************************************************** Pad

;function LeftPad(S : String; Len : Byte) : String;

LeftPad	PROC	FAR
	PUSH	BP
	MOV	BP,SP
	PUSH	DS
	LES	DI,[BP+12]		;ES:DI := Output String
	LDS	SI,[BP+8]		;DS:SI := S
	MOV	BL,' '
	CALL	LeftPad_Up
	POP	DS
	POP	BP
	RET	6
LeftPad	ENDP

CODE    ENDS

        END
