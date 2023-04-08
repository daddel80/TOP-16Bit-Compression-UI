;**************************************************************************;
;*                           S W A P A . A S M                            *;
;*------------------------------------------------------------------------*;
;*    Aufgabe        : Assembler-Modul fÅr die SWAP-Unit                  *;
;*------------------------------------------------------------------------*;
;*    Autor          : MICHAEL TISCHER                                    *;
;*    entwickelt am  :  1.06.1989                                         *;
;*    letztes Update :  3.06.1989                                         *;
;*------------------------------------------------------------------------*;
;*    assemblieren   : TASM /MX SWAPA                                     *;
;*                     ... mit der SWAP-Unit verknÅfpen                   *;
;**************************************************************************;

;== Konstanten =============================================================

STACK_LEN  equ 64                 ;Anzahl der Words in internem Stack

;== Strukturen =============================================================

ExecStruc struc                   ;Datenstruktur fÅr EXEC-Funktion

EsSegEnv  dw ?                    ;Segmentadresse des Environment-Blocks
EsCmdPAdr dd ?                    ;Pointer auf die Kommandozeilen-Parameter
EsFCB1Adr dd ?                    ;Pointer auf FCB #1
EsFCB2Adr dd ?                    ;Pointer auf FCB #2

ExecStruc ends

;== Datensegment ===========================================================

DATA   segment word public

extrn  PrefixSeg : word           ;Segmentadresse des PSP in Turbo-Variable

DATA   ends

;== Programm ===============================================================

CODE       segment byte public    ;das Programmsegment

public     SwapOutAndExec         ;gibt dem TP-Programm die Mîglichkeit,
                                  ;die Adresse des Assembler-Handlers
                                  ;zu ermitteln
public     InitSwapa              ;Initialisierungs-Prozedur
;== Variablen im Codesegment ===============================================

CodeStart  equ this byte          ;hier beginnt der Code, der an den Anfang
                                  ;des TP-Programms kopiert wird

;-- Variablen, die zum Up- und DownLoaden der Swap-Routinen benîtigt -------
;-- werden

CoStAddr   dd ?                   ;urspr. Adresse von PARA(CodeStart)
CoStLen    dw ?                   ;Anzahl geswappter Words ab CoStAddr
StackPtr   dw ?                   ;nimmt alten Stackpointer auf
StackSeg   dw ?                   ;nimmt altes Stacksegment auf
TurboSeg   dw ?                   ;Segmentadresse des Turbo-Codesegments

;-- Variablen, die wÑhrend des Auslagerns des Programms und der Aus- -------
;-- fÅhrung des Åbergebenen Befehls benîtigt werden

NewStack   dw STACK_LEN dup (?)   ;neuer Stack
EndStack   equ this word          ;Ende des Stacks

Command    dd ?                   ;Zeiger auf Befehl
CmdPara    dd ?                   ;Zeiger auf Kommandozeilen-Parameter
ToDisk     db ?                   ;True, wenn Swapping auf Disk erfolgt
Handle     dw ?                   ;Disk oder EMS-Handle
Len        dd ?                   ;Anzahl zu sichernder Bytes

FCB1       db  16 dup ( 0 )       ;FCB #1 fÅr PSP
FCB2       db  16 dup ( 0 )       ;FCB #2 fÅr PSP
CmdBuf     db 128 dup ( 0 )       ;Kommandozeilen-Befehle hiner Prg.-Name
PrgName    db  64 dup ( 0 )       ;Programmname
ExecData   ExecStruc < 0, CmdBuf, FCB1, FCB2 >   ;Datenstruktur fÅr EXEC

OldPara    dw ?                   ;Anzahl bisher reservierter Paragraphen
FrameSeg   dw ?                   ;Segmentadresse des EMS-Page-Frames
FehlerCode db 0                   ;FehlerCode fÅr Aufrufer
TerMes     db 13,10,13,10
           db "…ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕª",13,10
           db "∫     Das ausgelagerte Programm konnte nicht mehr   ∫",13,10
           db "∫     zurÅck in den Speicher geladen werden.        ∫",13,10
           db "∫     Die ProgrammausfÅhrung wurde beendet !        ∫",13,10
           db "»ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕº"
           db 13,10,13,10,"$"

;---------------------------------------------------------------------------
;-- StartSwap : koordiniert das Auslagern des TP-Programms

StartSwap  proc far

           assume cs:code, ds:nothing

           ;-- aktuellen Stack sichern und neuen Stack installieren --------

           cli                    ;Interrupts unterdrÅcken
           mov   StackPtr,sp      ;aktuellen Stack merken
           mov   StackSeg,ss
           push  cs               ;neuen Stack installieren
           pop   ss
           mov   sp,offset EndStack - 2
           sti                    ;Interrupts wieder zulassen

           push  cs               ;DS auf CS setzen
           pop   ds
           assume cs:code, ds:code
           ;-- nicht benîtigten Speicher wegschreiben ----------------------

           cmp   ToDisk,0         ;in EMS-Speicher schreiben?
           je    Ems              ;Ja ---> Ems

           call  Write2File       ;Nein, in Datei schreiben
           jnc   ShrinkMem        ;kein Fehler ---> ShrinkMem

           mov   FehlerCode, 1    ;Fehler bei Ausgabe in Datei
           jmp   short GetBack    ;zurÅck zu Turbo

Ems:       mov   ah,41h           ;Segmentadresse des Page-Frames ermitteln
           int   67h              ;EMM aufrufen
           mov   FrameSeg,bx      ;Resultat in Variablen merken

           call  Write2Ems        ;Programm in EMS-Speicher auslagern

           ;-- Anzahl aktuell allokierter Paragraphen ermitteln ------------

ShrinkMem: mov   ax,TurboSeg      ;Segmentadresse Turbo Codesegment
           sub   ax,11h           ;10 Paragraphen fÅr PSP und einen fÅr
                                  ;MCB abziehen
           mov   es,ax            ;ES zeigt jetzt auf MCB des Turbo-Progs.
           mov   bx,es:[3]        ;Anzahl allokierter Paragraphen holen
           mov   OldPara,bx       ;und in Variablen merken

           ;-- Anzahl noch benîtigter Paragraphen berechnen und Speicher- --
           ;-- bedarf auf diese Grî·e reduzieren

           inc   ax               ;AX zeigt jetzt auf PSP
           mov   es,ax            ;fÅr Funktionsaufruf nach ES
           mov   bx,CostLen       ;Anzahl fÅr Swap-Rout. benîtigter Words
           add   bx,128+7         ;PSP hinzurechnen und aufrunden
           mov   cl,3             ;durch 8 Words (pro Paragraph) teilen
           shr   bx,cl

           mov   ah,4Ah           ;Funktionsnr. fÅr "Grî·e Ñndern"
           int   21h              ;DOS-Interrupt aufrufen

           ;-- die Åbergebene Befehlszeile mit Hilfe der EXE-Funktion ------
           ;-- ausfÅhren

           mov   bp,ds            ;DS sichern

           mov   ax,cs            ;ES und DS auf CS setzen
           mov   es,ax
           mov   ds,ax

           ;-- Segmentadresse des Codesegments in die Zeiger innerhalb -----
           ;-- der EXEC-Struktur eintragen

           mov   word ptr ExecData.EsFCB1Adr + 2,ax
           mov   word ptr ExecData.EsFCB1Adr + 2,ax
           mov   word ptr ExecData.EsCmdPAdr + 2,ax

           mov   bx,offset ExecData  ;ES:BX zeigt auf Parameterblock
           mov   dx,offset PrgName   ;DS:DX zeigt auf Befehls-String

           mov   ax,4B00h         ;Funktionsnr. fÅr "EXEC"
           int   21h              ;DOS-Interrupt aufrufen
           mov   ds,bp            ;DS zurÅckholen
           jnc   ReMem            ;kein Fehler ---> ReMem

           mov   FehlerCode,ah    ;Fehlercode merken
           ;-- Speicher wieder auf alte Grî·e zurÅckfÅhren -----------------

ReMem:     mov   ax,TurboSeg      ;Segmentadresse des Turbo-Codesegments
           sub   ax,10h           ;auf Anfang des PSP setzen
           mov   es,ax            ;und nach ES laden
           mov   bx,OldPara       ;alte Anzahl Paragraphen

           mov   ah,4Ah           ;Funktionsnr. fÅr "Grî·e Ñndern"
           int   21h              ;DOS-Interrupt aufrufen
           jnc   GetBack          ;kein Fehler ---> GetBack

           jmp   Terminate        ;Fehler bei ReMem, Prg. beenden

           ;-- das Programm wieder zurÅckholen -----------------------------

GetBack:   cmp   ToDisk,0         ;in EMS-Speicher schreiben?
           je    Ems1             ;JA ---> Ems1

           call  GetFromFile      ;Nein, aus Datei zurÅckladen
           jnc   CloseUp          ;kein Fehler ---> CloseUp

           jmp   Terminate        ;Fehler bei Lesen, Prg. beenden

Ems1:      call  GetFromEms       ;TP-Programm aus EMS-Speicher zurÅckholen

           ;-- alten Stack restaurieren ------------------------------------

CloseUp:   cli                    ;Interrupts unterdrÅcken
           mov   ss,StackSeg
           mov   sp,StackPtr
           sti                    ;Interrupts wieder zulassen

           ;-- Register zum RÅcktauschen vorbereiten -----------------------

           push  cs                       ;DS auf CS setzen
           pop   ds
           assume cs:code, ds:code

           mov   cx,CoStLen               ;Anzahl zu swappender Words
           mov   di,cx                    ;Anzahl der Words nach DI
           dec   di                       ;um ein Word dekrementieren
           shl   di,1                     ;verdoppeln
           mov   si,di                    ;nach SI
           add   di,word ptr CostAddr     ;DI + Offsetadr der Swap-Routinen
           mov   es,word ptr CostAddr + 2 ;ES auf altes CS der Swap-Routinen
           mov   ds,TurboSeg              ;Segadr. des Code-Anfangs

           ret                            ;zurÅck zu SwapOutAndExec

StartSwap  endp

;---------------------------------------------------------------------------
;-- Write2Ems : Schreibt das auszulagernde Programm in den EMS-Speicher
;-- Eingabe   : BX = die Segmentadresse des EMS-Page-Frames
;--             DS = Codesegment

EMS_PLEN   equ 16384                   ;LÑnge einer EMS-Page

HiWLen     dw    ?                     ;Hi-Word verbleibende LÑnge

Write2Ems  proc near

           push  ds                    ;DS auf dem Stack sichern
           cld                         ;bei Stringbefehlen aufwÑrts zÑhlen
           mov   es,bx                 ;ES zeigt auf den Page-Frame

           mov   si,offset CodeEnd     ;hier beginnt das Swapping

           mov   bp,word ptr Len       ;Lo-Word LÑnge nach BP
           mov   ax,word ptr Len + 2   ;Hi-Word LÑnge nach AX
           mov   HiWLen,ax             ;und von dort in Variable

           mov   dx,Handle             ;EMS-Handle nach DX
           xor   bx,bx                 ;mit erster log. Page beginnen

           assume cs:code, ds:nothing

           jmp short WriECalc          ;in die Schleife springen

WriELoop:  ;-- Registerbelegung innerhalb dieser Schleife -----------------
           ;
           ;  AX        = mal dies, mal das
           ;  BX        = Nummer der zu adressierenden logischen EMS-Page
           ;  CX        = Anzahl zu kopierender Bytes in diesem Durchlauf
           ;  DX        = EMS-Handle
           ;  ES:DI     = Zeiger auf erste Page im EMS-Page-Frame (Ziel)
           ;  DS:SI     = Zeiger auf erstes zu kopierendes Word   (Start)
           ;  HiWLen:BP = Anzahl noch zu kopierender Bytes

           mov   ax,4400h              ;Funktionsnr fÅr Abbildung
           int   67h                   ;EMM aufrufen

           mov   si,offset CodeEnd     ;Offset fÅr Swapping
           xor   di,di                 ;an den Anfang der EMS-Page schreiben
           mov   ax,cx                 ;Anzahl in AX merken
           rep movsb                   ;Speicher kopieren

           sub   bp,ax                 ;RestlÑnge um geschriebene Bytes
           sbb   HiWLen,0              ;dekrementieren

           inc   bx                    ;Nummer der log. Page inkrementieren

           mov   ax,ds                 ;Startsegment nach AX
           add   ax,EMS_PLEN shr 4     ;um die geschr. Paragraphen inkr.
           mov   ds,ax                 ;und wieder nach DS

WriECalc:  mov   cx,EMS_PLEN           ;EMS_PLEN Bytes schreiben
           cmp   HiWLen,0              ;mehr als 64 KByte?
           ja    WriELoop              ;Ja ---> WriELoop
           cmp   bp,cx                 ;Nein, noch mehr als EMS_PLEN Bytes?
           jae   WriELoop              ;Ja, weiterschreiben
           mov   cx,bp                 ;Nein, Restanzahl schreiben
           or    cx,cx                 ;keine Bytes mehr zu schreiben
           jne   WriELoop              ;doch ---> WriELoop

WriERet:   pop   ds                    ;DS vom Stack zurÅckholen
           ret                         ;zurÅck zum Aufrufer

Write2Ems  endp

;---------------------------------------------------------------------------
;-- GetFromEms : Holt das ausgelagerte Programm aus dem EMS-Speicher zurÅck
;-- Eingabe : DS = Codesegment

GetFromEms proc near

           push  ds                    ;DS auf dem Stack sichern
           cld                         ;bei Stringbefehlen aufwÑrts zÑhlen

           mov   di,offset CodeEnd     ;hier beginnt das Swapping

           mov   bp,word ptr Len       ;Lo-Word LÑnge nach BP
           mov   ax,word ptr Len + 2   ;Hi-Word LÑnge nach AX
           mov   HiWLen,ax             ;und von dort in Variable

           mov   dx,Handle             ;EMS-Handle nach DX
           xor   bx,bx                 ;mit erster log. Page beginnen

           mov   ds,FrameSeg           ;DS zeigt auf den Page-Frame
           push  cs                    ;ES auf das Codesegment setzen
           pop   es

           assume cs:code, ds:nothing

           jmp short GetECalc          ;in die Schleife springen

GetELoop:  ;-- Registerbelegung innerhalb dieser Schleife -----------------
           ;
           ;  AX        = mal dies, mal das
           ;  BX        = Nummer der zu adressierenden logischen EMS-Page
           ;  CX        = Anzahl zu kopierender Bytes in diesem Durchlauf
           ;  DX        = EMS-Handle
           ;  DS:SI     = Zeiger auf erste Page im EMS-Page-Frame (Start)
           ;  ES:DI     = Zeiger auf Zieladresse im Speicher
           ;  HiWLen:BP = Anzahl noch zu kopierender Bytes

           mov   ax,4400h              ;Funktionsnr fÅr Abbildung
           int   67h                   ;EMM aufrufen

           mov   di,offset CodeEnd     ;Offset fÅr Swapping
           xor   si,si                 ;an den Anfang der EMS-Page schreiben
           mov   ax,cx                 ;Anzahl in AX merken
           rep movsb                   ;Speicher kopieren

           sub   bp,ax                 ;RestlÑnge um geschriebene Bytes
           sbb   HiWLen,0              ;dekrementieren

           inc   bx                    ;Nummer der log. Page inkrementieren

           mov   ax,es                 ;Startsegment nach AX
           add   ax,EMS_PLEN shr 4     ;um die geschr. Paragraphen inkr.
           mov   es,ax                 ;und wieder nach ES

GetECalc:  mov   cx,EMS_PLEN           ;EMS_PLEN Bytes schreiben
           cmp   HiWLen,0              ;mehr als 64 KByte?
           ja    GetELoop              ;Ja ---> GetELoop
           cmp   bp,cx                 ;Nein, noch mehr als EMS_PLEN Bytes?
           jae   GetELoop              ;Ja, weiterschreiben
           mov   cx,bp                 ;Nein, Restanzahl schreiben
           or    cx,cx                 ;keine Bytes mehr zu schreiben
           jne   GetELoop              ;doch ---> GetELoop

GetERet:   pop   ds                    ;DS vom Stack zurÅckholen
           ret                         ;zurÅck zum Aufrufer

GetFromEms endp

;---------------------------------------------------------------------------
;-- Write2File : Schreibt das auszulagernde Programm in eine Datei
;-- RÅckgabe   : Carry-Flag = 1 : Fehler

Write2File proc near

ANZ_WRITE  = 2048                      ;zu schreibende Bytes pro Durchlauf
                                       ;2er Potenz, maximal 2^16
           assume cs:code, ds:code

           push  ds                    ;DS auf dem Stack merken
           mov   bp,4000h              ;Funktionsnr. fÅr "Schreiben"
           mov   bx,Handle             ;Handle der Datei laden

WriFStart: mov   di,word ptr Len       ;Lo-Word LÑnge nach DI
           mov   si,word ptr Len + 2   ;Hi-Word LÑnge nach SI
           mov   dx,offset CodeEnd     ;Offsetadresse schreiben
           jmp   short WriFCalc        ;Anzahl zu schreibender Bytes ber.

WriFLoop:  ;-- Registerbelegung innerhalb dieser Schleife -----------------
           ;
           ;  AX        = mal dies, mal das
           ;  BX        = DOS-Datei-Handle
           ;  CX        = Anzahl der zu schreibenden/lesenden Bytes
           ;  DS:DX     = Adresse, ab der geschrieben/gelesen wird
           ;  DI:SI     = Anzahl der noch zu kopierenden Bytes
           ;  BP        = Funktionsnummer der aufzurufenden DOS-Funktion

           mov   ax,bp                 ;DOS-Funktionsnr. laden
           int   21h                   ;DOS-Interrupt aufrufen
           jc    WriFEnd               ;Fehler ---> WriFEnd
           mov   ax,ds                 ;Startsegment nach AX
           add   ax,ANZ_WRITE shr 4    ;um die geschr. Paragraphen inkr.
           mov   ds,ax                 ;und wieder nach DS
           sub   di,cx                 ;RestlÑnge um geschriebene Bytes
           sbb   si,0                  ;dekrementieren

WriFCalc:  mov   cx,ANZ_WRITE          ;ANZ_WRITE Bytes schreiben
           cmp   si,0                  ;mehr als 64 KByte?
           ja    WriFLoop              ;Ja ---> WriFLoop
           cmp   di,cx                 ;Nein, noch mehr als ANZ_WRITE Bytes?
           jae   WriFLoop              ;Ja, weiterschreiben
           mov   cx,di                 ;Nein, Restanzahl schreiben
           or    cx,cx                 ;keine Bytes mehr zu schreiben
           jne   WriFLoop              ;doch ---> WriFLoop

WriFEnd:   pop   ds                    ;DS zurÅckladen
WriFRet:   ret                         ;zurÅck zum Aufrufer

Write2File endp

;---------------------------------------------------------------------------
;-- GetFromFile : LÑdt das ausgelagerte Progamm wieder in den Speicher
;-- RÅckgabe   : Carry-Flag = 1 : Fehler

GetFromFile proc near

           assume cs:code, ds:code

           push  ds               ;DS auf dem Stack sichern

           ;-- File-Pointer an den Anfang der Datei bewegen ----------------

           mov   ax,4200h         ;DOS-Funktionsnummer
           mov   bx,Handle        ;Handle der Datei laden
           xor   cx,cx            ;CX:DX geben die Position an
           mov   dx,cx            ;(hier 0)
           int   21h              ;DOS-Interrupt aufrufen
           jc    WriFRet          ;Fehler ---> WriFRet

           ;-- Datei mit HIlfe von Write2File in den Speicher laden --------

           mov   bp,3F00h         ;Funktionsnr. fÅr "Lesen"
           jmp   WriFStart        ;in die Write2File-Proz. springen

GetFromFile endp

;---------------------------------------------------------------------------
;-- Terminate : es kann nicht mehr in das ursprÅngliche TP-Programm zurÅck-
;--             gekehrt werden. Programm mit Fehlercode beenden.

Terminate  label near

           ;-- Fehlermeldung ausgeben --------------------------------------

           push  cs               ;DS auf CS setzen
           pop   ds
           mov   dx,offset TerMes ;DS:DX zeigt jetzt auf Fehlermeldung
           mov   ah,9             ;Funktionsnr. fÅr "String ausgeben"
           int   21h              ;DOS-Interrupt ausgeben

           mov   ax,4C01h         ;Programm mit Fehlercode beenden
           int   21h

;===========================================================================

CodeEnd    equ this byte          ;bis hier hin wird der Code an den Anfang
                                  ;des TP-Programms kopiert

;---------------------------------------------------------------------------
;-- SwapOutAndExec : Lagert das aktuelle Programm in den EMS-Speicher oder
;--                  auf Platte aus und startet dann ein anderes Programm
;--                  Åber die DOS-EXEC-Funktion
;-- Aufruf von TP: SwapOutAndExec( Command,
;--                                CmdPara : string;
;--                                ToDisk  : boolean;
;--                                Handle  : word;
;--                                Len     : longint );
;-- Info         : Die Parameter Command und CmdPara mÅssen als Strings im
;--                DOS-Format vorliegen.

SwapOutAndExec proc near

ACommand   equ dword ptr [bp+16]  ;Konstanten zum Zugriff auf die
ACmdPara   equ dword ptr [bp+12]  ;Åbergebenen Argumente
AToDisk    equ  byte ptr [bp+10]
AHandle    equ  word ptr [bp+ 8]
ALen       equ dword ptr [bp+ 4]
ARG_LEN    equ 16                 ;LÑnge der Argumente

           assume cs:code, ds:data

           push  bp               ;Zugriff auf die Argumente ermîglichen
           mov   bp,sp
           ;-- Programmnamen in Puffer im Codesegment kopieren -------------

           mov   dx,ds            ;DS merken
           push  cs               ;ES auf CS setzen
           pop   es

           lds   si,ACommand      ;DS:SI zeigt auf Command-Puffer
           mov   di,offset PrgName ;ES:DI zeigt auf PrgName
           cld                    ;bei Stringbefehlen aufwÑrts zÑhlen
           lodsb                  ;LÑnge des Pascal-Strings lesen
           cmp   al,64            ;mehr als 64 Zeichen?
           jbe   CmdCopy          ;Nein ---> CmdCopy

           mov   al,64            ;Ja, maximal 64 Zeichen kopieren

CmdCopy:   xor   ah,ah            ;Hi-Byte der LÑnge auf 0 setzen
           mov   cx,ax            ;und in den Counter laden
           rep movsb              ;String kopieren

           ;-- Kommandozeile in Puffer im Codesegment kopieren -------------

           lds   si,ACmdPara      ;DS:SI zeigt auf CmdPara-Puffer
           mov   di,offset CmdBuf ;ES:DI zeigt auf CmdBuf
           lodsb                  ;LÑnge des Pascal-Strings lesen
           cmp   al,126           ;mehr als 126 Zeichen?
           jbe   ParaCopy         ;Nein ---> ParaCopy

           mov   al,126           ;Ja, maximal 126 Zeichen kopieren

ParaCopy:  stosb                  ;LÑnge als erstes Byte speichern
           xor   ah,ah            ;Hi-Byte der LÑnge auf 0 setzen
           mov   cx,ax            ;und in den Counter laden
           rep movsb              ;String kopieren

           mov   al,0dH           ;Carriage Return anhÑngen
           stosb

           ;-- Dateinamen aus der Kommandozeile in FCBs Åbertragen ---------

           push  cs               ;CS nach DS Åbertragen
           pop   ds

           mov   si,offset CmdBuf+1 ;DS:SI zeigt auf CmdBuf + 1
           mov   di,offset FCB1   ;ES:DI zeigt auf FCB #1
           mov   ax,2901h         ;Funktionsnr.: "Dateinamen in FCB Åbertr."
           int   21h              ;DOS-Interrupt aufrufen

           mov   di,offset FCB2   ;ES:DI zeigt jetzt auf FCB #2
           mov   ax,2901h         ;Funktionsnr.: "Dateinamen in FCB Åbertr."
           int   21h              ;DOS-Interrupt aufrufen

           mov   ds,dx            ;DS wieder mit alten Wert laden

           ;-- die Åbrigen Parameter in Variablen Åbertragen ---------------

           les   ax,ALen          ;LÑnge bearbeiten
           mov   word ptr Len + 2,es
           mov   word ptr Len,ax

           mov   al,AToDisk       ;Disk-Flag bearbeiten
           mov   ToDisk,al

           mov   ax,AHandle       ;Handle bearbeiten
           mov   Handle,ax
           push  ds               ;DS auf dem Stack merken

           ;-- die Variablen und dem Programmcode zwischen den Labels ------
           ;-- CosdeStart und CodeEnd mit dem Inhalt des Codesegments hinter
           ;-- dem PSP vertauschen

           mov   ax,PrefixSeg             ;ES:DI zeigt auf TP-Programm-
           add   ax,10h                   ;Anfang hinter PSP
           mov   TurboSeg,ax              ;Adr. des TP-Codesegments merken
           mov   es,ax
           xor   di,di

           push  cs                       ;DS auf CS setzen
           pop   ds
           assume cs:code, ds:code

           mov   si,offset CodeStart      ;DS:SI zeigt auf CodeStart
           and   si,0FFF0h                ;auf Paragraphen-Start abrunden

           mov   cx,CostLen               ;Anzahl zu swappender Words holen
           mov   word ptr CoStAddr,si     ;Adresse von PARA(CodeStart)
           mov   word ptr CoStAddr + 2,ds ;merken

           mov   dx,es            ;Zielsegment in DX merken
           cld                    ;bei Stringbefehlen SI/DI inkrementieren

           ;-- Tausch-Schleife ---------------------------------------------

dl_loop:   mov   ax,[si]          ;ein Word aus dem Ass-Modul laden
           mov   bx,es:[di]       ;ein Word aus TP-Programm laden
           stosw                  ;das Word aus Ass-Modul in TP-Prg. schr.
           mov   [si],bx          ;das Word aus TP-Prg. in Ass-Modul schr.
           inc   si               ;SI auf nÑchstes Word setzen
           inc   si               ;(DI wurde durch STOSW inkrementiert)
           loop  dl_loop          ;alle Words abarbeiten
           ;-- Segmentadresse des Codesegments vor Aufruf der StartSwap- ---
           ;-- Prozedur so anpassen, da· sich die Variablenreferenzen auf
           ;-- das Codesegment nicht Ñndern

           mov   ax,offset CodeStart ;Anzahl der Paragraphen zwischen
           mov   cl,4                ;CodeStart und dem Anfang des Segments
           shr   ax,cl               ;berechnen und von Segmentadresse in
           sub   dx,ax               ;DX abziehen

           push  cs                  ;RÅcksprungadresse beim Label BACK
           mov   ax,offset back      ;auf den Stack legen
           push  ax

           push  dx                  ;Segmentadresse auf den Stack
           mov   ax,offset StartSwap ;Offsetadresse auf den Stack legen
           push  ax

           retf                      ;mir FAR-RET zu StartSwap springen

back:      ;----------------------------------------------------------------
           ;-- An diese Stelle kehrt das Programm erst zurÅck, nachdem der
           ;-- Speicher ausgelagert, das angegebene Programm ausgefÅhrt
           ;-- und der Speicher wieder eingeladen wurde.
           ;-- Die einzelnen Register haben dann folgenden Inhalt:
           ;--   DS:SI = Ende des Assembler-Codes hinter dem PSP
           ;--   ES:DI = Ende des Turbo Codes in der SWAP-Unit
           ;--   CX    = Anzahl der Words
           ;----------------------------------------------------------------

           assume cs:code, ds:nothing

           std                    ;Stringbefehle dekrementieren SI/DI

           ;-- RÅcktausch-Schleife -----------------------------------------

ul_loop:   mov   bx,es:[di]       ;Byte aus altem Speicherber. holen
           mov   ax,[si]          ;Byte aus akt. Speicherber. holen
           mov   [si],bx          ;Byte aus altem in akt. Speicherber.
           dec   si               ;SI auf vorhergehendes Wort setzen
           dec   si
           stosw                  ;Byte aus akt. in alten Speicherber.
           loop  ul_loop          ;wiederholen, bis Speicherber. vertauscht
           pop   ds               ;DS vom Stack zurÅckholen
           assume ds:data

           pop   bp               ;BP zurÅckholen

           ;-- hier mu· nicht MOV SP,BP angegeben werden, weil SP nicht
           ;-- verÑndert wurde

           xor   ah,ah            ;Fehlercode in AX zurÅckliefern
           mov   al,FehlerCode

           ret ARG_LEN            ;zurÅck zum Aufrufer, dabei Argumente vom
                                  ;Stack putzen

SwapOutAndExec endp

;---------------------------------------------------------------------------
;-- InitSwapa : berechnet die Anzahl der Bytes bzw. Words, die Swap nach dem
;--             Auslagern des Programms am Anfang des TP-Programms im Spei-
;--             cher belegt
;-- Eingabe      : keine
;-- Ausgabe      : die Anzahl der Bytes
;-- Aufruf von TP: function InitSWapa : word;
;-- Info         : Diese Prozedur mu· vor dem ersten Aufruf von
;--                SwapOutAndExec aufgerufen werden!

InitSwapa  proc near

           assume cs:code, ds:data

           mov   bx,offset CodeStart      ;AX zeigt auf Anfang des Codes
           and   bx,0FFF0h                ;auf Paragraphen-Start abrunden
           mov   ax,offset CodeEnd        ;BX zeigt auf Endes des Codes
           sub   ax,bx                    ;Anzahl Bytes berechnen
           inc   ax                       ;CX in Words umwandeln
           shr   ax,1
           mov   CoStLen,ax               ;Anzahl zu swappender Words merken
           shl   ax,1                     ;wieder in Bytes umwandeln

           ;-- der Inhalt von AX wird als Funktionsergebnis zurÅckgeliefert

           ret                            ;zurÅck zum Aufrufer

InitSwapa  endp

;---------------------------------------------------------------------------

CODE       ends                   ;Ende des Codesegments
           end                    ;Ende des Programms
