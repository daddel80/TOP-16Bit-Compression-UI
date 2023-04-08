;**************************************************************************;
;*                             K B M A . A S M                            *;
;*------------------------------------------------------------------------*;
;*    Aufgabe        : Assembler-Modul fÅr die KBM-Unit                   *;
;*------------------------------------------------------------------------*;
;*    Autor          : MICHAEL TISCHER                                    *;
;*    entwickelt am  :  1.06.1989                                         *;
;*    letztes Update :  3.06.1989                                         *;
;*------------------------------------------------------------------------*;
;*    assemblieren   : TASM KBMA      oder                                *;
;*                     MASM KBMA;                                         *;
;*                     ... mit der KBM-Unit verknÅfpen                    *;
;**************************************************************************;

;== Datensegment ===========================================================

DATA   segment word public

extrn  OldKbHandler : dword       ;Adresse des alten Int-09-Handlers

DATA   ends

;== Programm ===============================================================

CODE   segment byte public        ;das Programmsegment

       assume CS:CODE             ;CS zeigt auf das Codesegment, der In-
                                  ;halt von DS, SS und ES ist unbekannt

public     NewMouHandler          ;gibt dem TP-Programm die Mîglichkeit,
public     NewKbHandler           ;die Adresse des Assembler-Handlers
                                  ;zu ermitteln

extrn     MouEventHandler : near  ;der aufzurufende TP-Event-Handler
extrn     KbHandler       : near  ;der aufzurufende Tastatur-Handler

;---------------------------------------------------------------------------
;-- NewMouHandler: Event-Handler, der zunÑchst vom Maustreiber aufgerufen
;--                wird, um seinerseits dann die TP-Prozedur MouEventHandler
;--                aufzurufen
;-- Aufruf von TP: nicht erlaubt!

NewMouHandler proc far

           push ax                ;Prozessorregister sichern
           push bx
           push cx
           push dx
           push di
           push si
           push bp
           push es
           push ds

           ;-- die Argumente fÅr den Aufruf der TP-Funktion auf den --------
           ;-- Stack bringen
           ;-- Aufruf:
           ;--   MouEventHandler (EvFlags, ButStatus, x , y : integer );

           push ax                ;Event-Flags auf den Stack bringen
           push bx                ;Status der Mausknîpfe auf den Stack

           mov  di,cx             ;horizontale Ordinate in DI merken
           mov  cl,3              ;SchiebezÑhler f. Koordinatenumr.

           shr  di,cl             ;DI (horizontale Ord.) durch 8 teilen
           push di                ;und auf den Stack bringen

           shr  dx,cl             ;DX (vertikale Ord.) durch 8 teilen
           push dx                ;und auf den Stack bringen

           mov  ax,DATA           ;Segmentadresse des Datensegments AX
           mov  ds,ax             ;in von dort in das DS-Register

           call  MouEventHandler  ;Aufruf der TP-Prozedur

           ;-- die gesicherten Register wieder vom Stack holen -------------

           pop  ds
           pop  es
           pop  bp
           pop  si
           pop  di
           pop  dx
           pop  cx
           pop  bx
           pop  ax

           ret                    ;zurÅck zum Maustreiber

NewMouHandler endp

;---------------------------------------------------------------------------
;-- NewKbHandler: neuer Tastatur-Handler, der bei Aufruf des Interrupts 09h
;--               aufgerufen wird, um seinerseits die TP-Prozedur KbHandler
;--               aufzurufen
;-- Aufruf von TP: nicht erlaubt!

NewKbHandler proc far

           sti                    ;Interruptaufrufe zulassen
           push ax                ;Prozessorregister sichern
           push bx
           push cx
           push dx
           push di
           push si
           push bp
           push es
           push ds

           in   al,60h            ;Scancode von Tastatur einlesen
           xor  ah,ah             ;und als Argument fÅr den Aufruf
           push ax                ;von KbHandler auf den Stack bringen

           mov  ax,DATA           ;Segmentadresse des Datensegments AX
           mov  ds,ax             ;in von dort in das DS-Register

           assume ds:data

           pushf                  ;Interruptaufruf des alten Interrupt-
           call [OldKbHandler]    ;Handlers simulieren

           ;-- die Argumente fÅr den Aufruf der TP-Funktion auf den --------
           ;-- Stack bringen
           ;-- Aufruf:
           ;--   KbHandler( KbPort : byte );

           call  KbHandler        ;Aufruf der TP-Prozedur

           assume ds:nothing

           ;-- die gesicherten Register wieder vom Stack holen -------------

           pop  ds
           pop  es
           pop  bp
           pop  si
           pop  di
           pop  dx
           pop  cx
           pop  bx
           pop  ax

           iret                    ;zurÅck zum unterbrochenen Prg.

NewKbHandler endp

;---------------------------------------------------------------------------

CODE       ends                   ;Ende des Codesegments
           end                    ;Ende des Programms
