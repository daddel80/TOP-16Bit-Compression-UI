{***************************************************************************
*  S W A P : eine Unit, die eine alternative Exec-Prozedur zum Aufruf be-  *
*            liebiger Programme aus dem TP-Programm heraus zur Verf�gung   *
*            stellt. Im Gegensatz zur normalen Exec-Prozedur wird das TP-  *
*            Programm vor der Ausf�hrung des angegebenen Programms in den  *
*            EMS-Speicher oder auf Platte ausgelagert und so der Speicher  *
*            f�r die Ausf�hrung des Programms frei gemacht.                *
**------------------------------------------------------------------------**
*  Autor            : MICHAEL TISCHER                                      *
*  entwickelt am    :  9.06.1989                                           *
*  letztes Update am: 13.06.1989                                           *
***************************************************************************}

unit swap;

interface

uses DOS, Ems, Kbm;

{$F-}
{-- Deklaration der Funktionen und Prozeduren, die von einem anderen ------}
{-- Programm aufgerufen werden k�nnen                                ------}

function ExecPrg    ( Command : string ) : byte;
function ExecCommand( Command : string ) : byte;

{-- Konstanten, �ffentlich ------------------------------------------------}

const SwapPath : string[ 80 ] = 'c:\';

      {------------------------ Fehlercodes von ExecPrg & ExecCommand -----}

      SwapErrOk       = 0;                       { kein Fehler, alles o.k. }
      SwapErrStore    = 1;   { TP-Programm konnte nicht ausgelagert werden }
      SwapErrNotFound = 2;                       { Programm nicht gefunden }
      SwapErrNoAccess = 5;               { Zugriff auf Programm verweigert }
      SwapErrNoRAM    = 8;                             { zu wenig Speicher }

implementation

{$L swapa}                                     { Assembler-Modul einbinden }

{-- Deklaration der Prozeduren aus dem Assembler-Modul SWAPA --------------}

function SwapOutAndExec( Command,
                         CmdPara : string;
                         ToDisk  : boolean;
                         Handle  : word;
                         Len     : longint ) : byte ; external;

function InitSwapa : word ; external;

{-- globale Variablen, modulintern ----------------------------------------}

var Len    : longint;                     { Anzahl der auszulagernden Bytes }

{***************************************************************************
*  NewExec : Steuert die Auslagerung des aktuellen TP-Programms und den    *
*            anschlie�enden Aufruf des angegebenen Progamms.               *
**------------------------------------------------------------------------**
*  Eingabe : CmdLine = String mit dem Namen des auzurufenden Programms     *
*            CmdPara = String mit den Kommandozeilen-Parametern f�r das    *
*                      aufzurufenden Programm                              *
*  Ausgabe : Einer der Fehlercodes SwapErr...                              *
***************************************************************************}

function NewExec( CmdLine, CmdPara : string ) : byte;

var Regs,                          { Prozessorregister zum Interruptaufruf }
    Regs1    : Registers;
    SwapFile : string[ 81 ];             { Namen der tempor�ren Swap-Datei }
    ToDisk   : boolean;          { auf Platte oder EMS-Speicher auslagern? }
    Handle   : integer;                           { EMS- oder Datei-Handle }
    Pages    : integer;                  { Anzahl der ben�tigten EMS-Pages }

begin
  {-- testen, ob Auslagerung in EMS-Speicher m�glich ----------------------}
  KbmEnd(false);
  ToDisk := TRUE;                    { von Auslagerung auf Platte ausgehen }
  if ( EmsInst ) then                         { ist EMS-Speicher verf�gbar }
    begin                                                             { Ja }
      Pages  := ( Len + 16383 ) div 16384;     { ben�tigte Pages ermitteln }
      Handle := EmsAlloc( Pages );                      { Pages allokieren }
      ToDisk := ( EmsError <> EmsErrOk );        { Allokation erfolgreich? }
      if not ToDisk then
        EmsSaveMapping( Handle );                      { Mapping speichern }
    end;

  if ToDisk then                              { in EMS-Speicher auslagern? }
    begin                                               { Nein, auf Platte }

      {- tempor�re Datei im SwapPath mit Attributen SYSTEM & HIDDEN �ffnen }

      SwapFile := SwapPath;
      SwapFile[ byte(SwapFile[0]) + 1 ] := #0;  {String in DOS-Format konv.}
      Regs.AH := $5A;              { Funktionsnr.: "temp. Datei erstellen" }
      Regs.CX := Hidden or SysFile;                        { Dateiattribut }
      Regs.DS := seg( SwapFile );        { Adresse des SwapPath nach DS:DX }
      Regs.DX := ofs( SwapFile ) + 1;
      MsDos( Regs );                          { DOS-Interrupt 21h aufrufen }
      if ( Regs.Flags and FCarry = 0 ) then              { Datei er�ffnet? }
        Handle := Regs.AX                              { Ja, Handle merken }
      else                              { Nein, Funktion vorzeitig beenden }
        begin
          NewExec := SwapErrStore;   { Fehler beim Auslagern des Programms }
          exit;                                         { Funktion beenden }
        end;
    end;

    {-- Programm �ber Assembler-Routine ausf�hren -------------------------}
    SwapVectors;                         { Interrupt-Vektoren zur�cksetzen }
    NewExec := SwapOutAndExec( CmdLine, CmdPara, ToDisk, Handle, Len );
    SwapVectors;                   { Turbo-Int-Handler wieder installieren }
    if ToDisk then                         { wurde auf Platte ausgelagert? }
      begin                                                           { Ja }
        {-- tempor�re Datei schlie�en und l�schen -------------------------}

        Regs1.AH := $3E;                 { Funktionsnr.: "Datei schlie�en" }
        Regs1.BX := Regs.AX;                        { Handle nach BX laden }
        MsDos( Regs1 );                       { DOS-Interrupt 21h aufrufen }

        Regs.AH := $41;                    { Funktionsnr.: "Datei l�schen" }
        MsDos( Regs );
      end
    else                      { Nein, Auslagerung erfolgte in EMS-Speicher }
      begin
        EmsRestoreMapping( Handle );      { Mapping wieder zur�ckspeichern }
        EmsFree( Handle );     { allokierten EMS-Speicher wieder freigeben }
      end;
   KbmInit(CrtXmax,CrtYmax);
end;

{***************************************************************************
*  ExecPrg : F�hrt ein Programm, dessen Name inklusive der Dateierwei-     *
*            terung bekannt sein mu�, �ber NewExec aus.                    *
**------------------------------------------------------------------------**
*  Eingabe : Command = String mit dem Namen des auszuf�hrenden Programms   *
*                      und den Parametern, die in der Kommandozeile �ber-  *
*                      geben werden sollen.                                *
*  Ausgabe : Einer der Fehlercodes SwapErr...                              *
*  Info    : Mit Hilfe dieser Prozedur k�nnen nur EXE- und COM-Programme,  *
*            nicht aber Batch-Dateien und interne Befehle des Kommando-    *
*            prozessors ausgef�hrt werden. Dabei mu� die Dateierweiterung  *
*            des Programms und der Pfad genau angegeben werden, da nicht   *
*            im "Path" nach einem entsprechenden Programm gesucht wird.    *
***************************************************************************}

function ExecPrg( Command : string ) : byte;

const Trenner : set of char = [ ' ',#9,'-','/','>','<',#0,'|' ];

var i        : integer;                           { Index in Source-String }
    CmdLine,                                            { nimmt Befehl auf }
    Para     : string;                               { nimmt Parameter auf }

begin
  {-- den Befehl aus dem Command-String isolieren -------------------------}

  CmdLine := '';                       { den String zun�chst einmal leeren }
  i := 1;            { mit dem ersten Buchstaben im Source-String beginnen }
  while not ( (Command[i] in Trenner) or ( i > length( Command ) ) ) do
    begin                                  { Zeichen ist noch kein Trenner }
      CmdLine := CmdLine + Command[ i ];             { in String aufnehmen }
      inc( i );                  { I auf n�chstes Zeichen im String setzen }
    end;

  Para := '';                              { noch keine Parameter entdeckt }

  {-- nach dem n�chsten "nicht-Leerzeichen" suchen ------------------------}

  while (i<=length(Command)) and ( (Command[i]=#9) or (Command[i]=' ') ) do
    inc( i );

  {-- den Rest des Strings in den Para-String kopieren --------------------}

  while i <= length( Command ) do
    begin
      Para := Para + Command[ i ];
      inc( i );
    end;

  ExecPrg := NewExec( CmdLine, Para );     { Befehl �ber NewExec ausf�hren }

end;

{***************************************************************************
*  ExecCommand : F�hrt ein Programm aus, als ob sein Name innerhalb der    *
*                Benutzeroberfl�che von DOS angegeben wurde.               *
**------------------------------------------------------------------------**
*  Eingabe : Command = String mit dem Namen des auszuf�hrenden Programms   *
*                      und den Parametern, die in der Kommandozeile �ber-  *
*                      geben werden sollen.                                *
*  Ausgabe : Einer der Fehlercodes SwapErr...                              *
*  Info    : Da der Aufruf des Programms �ber den Kommandprozessor er-     *
*            folgt, k�nnen mit Hilfe dieser Prozedur auch die internen     *
*            Befehle des Kommandoprozessors (DIR etc.) sowie Batch-Dateien *
*            zur Ausf�hrung gebracht werden.                               *
***************************************************************************}

function ExecCommand( Command : string ) : byte;

var ComSpec : string;                        { Pfad des Kommandoprozessors }

begin
  ComSpec := GetEnv( 'COMSPEC' );      { Pfad des Kommandoprozessors holen }
  ExecCommand := NewExec( ComSpec, '/c'+ Command  );  {Prg/Befehl ausf�hren}
end;

{**----------------------------------------------------------------------**}
{** Startcode der Unit                                                   **}
{**----------------------------------------------------------------------**}

begin
  {-- Anzahl der jeweils auszulagernden Bytes berechnen -------------------}

  Len := ( longint(Seg(HeapEnd^)-(PrefixSeg+$10)) * 16 ) -
         InitSwapa + Ofs(HeapPtr^);
end.
