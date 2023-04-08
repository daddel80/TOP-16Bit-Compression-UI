{***************************************************************************
*  S W A P : eine Unit, die eine alternative Exec-Prozedur zum Aufruf be-  *
*            liebiger Programme aus dem TP-Programm heraus zur VerfÅgung   *
*            stellt. Im Gegensatz zur normalen Exec-Prozedur wird das TP-  *
*            Programm vor der AusfÅhrung des angegebenen Programms in den  *
*            EMS-Speicher oder auf Platte ausgelagert und so der Speicher  *
*            fÅr die AusfÅhrung des Programms frei gemacht.                *
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
{-- Programm aufgerufen werden kînnen                                ------}

function ExecPrg    ( Command : string ) : byte;
function ExecCommand( Command : string ) : byte;

{-- Konstanten, îffentlich ------------------------------------------------}

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
*            anschlie·enden Aufruf des angegebenen Progamms.               *
**------------------------------------------------------------------------**
*  Eingabe : CmdLine = String mit dem Namen des auzurufenden Programms     *
*            CmdPara = String mit den Kommandozeilen-Parametern fÅr das    *
*                      aufzurufenden Programm                              *
*  Ausgabe : Einer der Fehlercodes SwapErr...                              *
***************************************************************************}

function NewExec( CmdLine, CmdPara : string ) : byte;

var Regs,                          { Prozessorregister zum Interruptaufruf }
    Regs1    : Registers;
    SwapFile : string[ 81 ];             { Namen der temporÑren Swap-Datei }
    ToDisk   : boolean;          { auf Platte oder EMS-Speicher auslagern? }
    Handle   : integer;                           { EMS- oder Datei-Handle }
    Pages    : integer;                  { Anzahl der benîtigten EMS-Pages }

begin
  {-- testen, ob Auslagerung in EMS-Speicher mîglich ----------------------}
  KbmEnd(false);
  ToDisk := TRUE;                    { von Auslagerung auf Platte ausgehen }
  if ( EmsInst ) then                         { ist EMS-Speicher verfÅgbar }
    begin                                                             { Ja }
      Pages  := ( Len + 16383 ) div 16384;     { benîtigte Pages ermitteln }
      Handle := EmsAlloc( Pages );                      { Pages allokieren }
      ToDisk := ( EmsError <> EmsErrOk );        { Allokation erfolgreich? }
      if not ToDisk then
        EmsSaveMapping( Handle );                      { Mapping speichern }
    end;

  if ToDisk then                              { in EMS-Speicher auslagern? }
    begin                                               { Nein, auf Platte }

      {- temporÑre Datei im SwapPath mit Attributen SYSTEM & HIDDEN îffnen }

      SwapFile := SwapPath;
      SwapFile[ byte(SwapFile[0]) + 1 ] := #0;  {String in DOS-Format konv.}
      Regs.AH := $5A;              { Funktionsnr.: "temp. Datei erstellen" }
      Regs.CX := Hidden or SysFile;                        { Dateiattribut }
      Regs.DS := seg( SwapFile );        { Adresse des SwapPath nach DS:DX }
      Regs.DX := ofs( SwapFile ) + 1;
      MsDos( Regs );                          { DOS-Interrupt 21h aufrufen }
      if ( Regs.Flags and FCarry = 0 ) then              { Datei erîffnet? }
        Handle := Regs.AX                              { Ja, Handle merken }
      else                              { Nein, Funktion vorzeitig beenden }
        begin
          NewExec := SwapErrStore;   { Fehler beim Auslagern des Programms }
          exit;                                         { Funktion beenden }
        end;
    end;

    {-- Programm Åber Assembler-Routine ausfÅhren -------------------------}
    SwapVectors;                         { Interrupt-Vektoren zurÅcksetzen }
    NewExec := SwapOutAndExec( CmdLine, CmdPara, ToDisk, Handle, Len );
    SwapVectors;                   { Turbo-Int-Handler wieder installieren }
    if ToDisk then                         { wurde auf Platte ausgelagert? }
      begin                                                           { Ja }
        {-- temporÑre Datei schlie·en und lîschen -------------------------}

        Regs1.AH := $3E;                 { Funktionsnr.: "Datei schlie·en" }
        Regs1.BX := Regs.AX;                        { Handle nach BX laden }
        MsDos( Regs1 );                       { DOS-Interrupt 21h aufrufen }

        Regs.AH := $41;                    { Funktionsnr.: "Datei lîschen" }
        MsDos( Regs );
      end
    else                      { Nein, Auslagerung erfolgte in EMS-Speicher }
      begin
        EmsRestoreMapping( Handle );      { Mapping wieder zurÅckspeichern }
        EmsFree( Handle );     { allokierten EMS-Speicher wieder freigeben }
      end;
   KbmInit(CrtXmax,CrtYmax);
end;

{***************************************************************************
*  ExecPrg : FÅhrt ein Programm, dessen Name inklusive der Dateierwei-     *
*            terung bekannt sein mu·, Åber NewExec aus.                    *
**------------------------------------------------------------------------**
*  Eingabe : Command = String mit dem Namen des auszufÅhrenden Programms   *
*                      und den Parametern, die in der Kommandozeile Åber-  *
*                      geben werden sollen.                                *
*  Ausgabe : Einer der Fehlercodes SwapErr...                              *
*  Info    : Mit Hilfe dieser Prozedur kînnen nur EXE- und COM-Programme,  *
*            nicht aber Batch-Dateien und interne Befehle des Kommando-    *
*            prozessors ausgefÅhrt werden. Dabei mu· die Dateierweiterung  *
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

  CmdLine := '';                       { den String zunÑchst einmal leeren }
  i := 1;            { mit dem ersten Buchstaben im Source-String beginnen }
  while not ( (Command[i] in Trenner) or ( i > length( Command ) ) ) do
    begin                                  { Zeichen ist noch kein Trenner }
      CmdLine := CmdLine + Command[ i ];             { in String aufnehmen }
      inc( i );                  { I auf nÑchstes Zeichen im String setzen }
    end;

  Para := '';                              { noch keine Parameter entdeckt }

  {-- nach dem nÑchsten "nicht-Leerzeichen" suchen ------------------------}

  while (i<=length(Command)) and ( (Command[i]=#9) or (Command[i]=' ') ) do
    inc( i );

  {-- den Rest des Strings in den Para-String kopieren --------------------}

  while i <= length( Command ) do
    begin
      Para := Para + Command[ i ];
      inc( i );
    end;

  ExecPrg := NewExec( CmdLine, Para );     { Befehl Åber NewExec ausfÅhren }

end;

{***************************************************************************
*  ExecCommand : FÅhrt ein Programm aus, als ob sein Name innerhalb der    *
*                BenutzeroberflÑche von DOS angegeben wurde.               *
**------------------------------------------------------------------------**
*  Eingabe : Command = String mit dem Namen des auszufÅhrenden Programms   *
*                      und den Parametern, die in der Kommandozeile Åber-  *
*                      geben werden sollen.                                *
*  Ausgabe : Einer der Fehlercodes SwapErr...                              *
*  Info    : Da der Aufruf des Programms Åber den Kommandprozessor er-     *
*            folgt, kînnen mit Hilfe dieser Prozedur auch die internen     *
*            Befehle des Kommandoprozessors (DIR etc.) sowie Batch-Dateien *
*            zur AusfÅhrung gebracht werden.                               *
***************************************************************************}

function ExecCommand( Command : string ) : byte;

var ComSpec : string;                        { Pfad des Kommandoprozessors }

begin
  ComSpec := GetEnv( 'COMSPEC' );      { Pfad des Kommandoprozessors holen }
  ExecCommand := NewExec( ComSpec, '/c'+ Command  );  {Prg/Befehl ausfÅhren}
end;

{**----------------------------------------------------------------------**}
{** Startcode der Unit                                                   **}
{**----------------------------------------------------------------------**}

begin
  {-- Anzahl der jeweils auszulagernden Bytes berechnen -------------------}

  Len := ( longint(Seg(HeapEnd^)-(PrefixSeg+$10)) * 16 ) -
         InitSwapa + Ofs(HeapPtr^);
end.
