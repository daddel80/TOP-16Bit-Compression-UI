;******************************************************
;                   HBPAD.ASM V 1.0
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

        PUBLIC  PadCh, Pad

;******************************************************

Pad_Up	PROC	NEAR
        MOV     CL,[BP+6]              ;CL := LEN - LENGTH(S)
        CLD
        LODSB                          ;S => OUTPUT STRING
	MOV	CH,0
        XCHG    CL,AL
        MOV     AH,AL
        SUB     AH,CL
        JNBE    PADCH1
        MOV     AH,0
PADCH1: STOSB
        REP     MOVSB

        MOV     CL,AH
        MOV     AL,BL                 ;AL := C
        REP     STOSB
	RET
Pad_Up	ENDP

;****************************************************** PadCh

;function PadCh(S : String; C : Char; Len : Byte) : String;

PadCh   PROC    FAR
        PUSH    BP
        MOV     BP,SP
        PUSH    DS
        LES     DI,[BP+14]             ;ES:DI := OUTPUT STRING
        LDS     SI,[BP+10]             ;DS:SI := S
	MOV	BL,[BP+8]	       ;BL := C	
	CALL	Pad_UP
        POP     DS
        POP     BP
        RET     8
PadCh   ENDP

;****************************************************** Pad

;function Pad(S : String; Len : Byte) : String;

Pad	PROC	FAR
	PUSH	BP
	MOV	BP,SP
	PUSH	DS
	LES	DI,[BP+12]		;ES:DI := Output String
	LDS	SI,[BP+8]		;DS:SI := S
	MOV	BL,' '
	CALL	Pad_Up
	POP	DS
	POP	BP
	RET	6
Pad	ENDP

CODE    ENDS

        END
