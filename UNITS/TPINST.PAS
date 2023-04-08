{***************************************************************************
*  TPInst : Diese Unit stellt verschiedene Prozeduren zur Erstellung von   *
*           Installationsprogrammen in der Art von Turbo's TINST zur Ver-  *
*           fÅgung. Wie TINST kînnen die Einstellungen direkt in die EXE-  *
*           Datei des Programms geschrieben werden. Eine Konfigurations-   *
*           wird nicht benîtigt!                                           *
**------------------------------------------------------------------------**
*  Autor             : MICHAEL TISCHER                                     *
*  entwickelt am     : 18.06.1989                                          *
*  letztes Update am : 07.09.1989                                          *
***************************************************************************}

unit TPInst;

interface

{------- Einbinden der benîtigten Units -----------------------------------}

uses Crt,Dos;                                      { Turbo Pascal CRT-Unit }


var    f_spe         : boolean;
     ExeTime         : Longint;
{-- Prozeduren und Funktionen, die fÅr andere Units zugÑnglich sind -------}

function  TPIOpenFile    ( Name : string; Offset : longint) : boolean;
procedure TPISaveChanges;
procedure TPICLoseFile;
procedure TPIGet         ( Adresse : word; Laenge : word; var Puffer );
procedure TPIPut         ( Adresse : word; Laenge : word; var Puffer );



implementation

{-- Konstanten, Typen und Variablen, die nur intern Verwendung finden -----}

const Leer = '                                                   ';

type SegmentTyp = array [ 0 .. 500 ] of byte;         { das Datensegment }

var ExeFile       : file;            { File-Var. fÅr Zugriff auf EXE-Datei }
    DataSegment   : ^SegmentTyp;                  { Platz fÅr Datensegment }
    DataSegSize   : word;               { Grî·e des Datensegments in Bytes }
    DataWriteBack : word;          { Anzahl der zurÅckzuschreibenden Bytes }
    DataSegStart  : longint;         { Start des Datensegments im EXE-File }


{***************************************************************************
*  TPIOpenFile : Erfîffnet die Arbeit mit den Routinen aus dieser Unit     *
*                und liest gleichzeitg das Datensegment aus der zu in-     *
*                stallierenden EXE-Datei ein.                              *
**------------------------------------------------------------------------**
*  Eingabe : NAME   = Name der EXE-Datei                                   *
*            OFFSET = Offset des Datensegments innerhalb der EXE-Datei     *
*  Ausgabe : TRUE, wenn Datei erfolgreich geîffnet wurde;                  *
*            FALSE, wenn die Datei nicht gefunden wurde                    *
*  Info    : Die Offsetadresse des Datensegments kann der Konstanten       *
*            DSEG_START entnommen werden, die innerhalb der von TPIC er-   *
*            stellten Konstanten-Datei aufgefÅhrt wird.                    *
***************************************************************************}

function TPIOpenFile( Name : string; Offset : longint) : boolean;

var OK : boolean;                           { Status nach ôffnen der Datei }

begin
  {-- EXE-Datei îffnen ----------------------------------------------------}

  Assign( ExeFile, Name );
  {$I-}                        { I/O PrÅfung durch Turbo Pascal abschalten }
  Reset( ExeFile, 1 );                      { Datei îffnen , SatzlÑnge = 1 }
  GetFTime(Exefile,ExeTime);
  OK := ( IOResult = 0 );
  {$I+}                { I/O PrÅfung durch Turbo Pascal wieder einschalten }

  {-- Datensegment aus der EXE-Datei in den Speicher lesen ----------------}

  if ( OK ) then                           { ôffnen der Datei erfolgreich? }
    begin                                         { Ja, Datensegment lesen }
      New( DataSegment );              { Platz fÅr Kopie des DSEG auf Heap }
      Seek( ExeFile, Offset );                 { Dateizeiger positionieren }
      BlockRead( ExeFile, DataSegment^, 65521, DataSegSize);   { und lesen }
      DataWriteBack := 0;          { grî·te bisher geÑnderte Offsetadresse }
      DataSegStart  := Offset;        { Startadr. des Datensegments merken }
    end;

  TPIOpenFile := OK;                                { Ergebnis zurÅckgeben }
  f_spe:=false;
end;

{***************************************************************************
*  TPISaveChanges : Schreibt das Datensegment inklusive der vorgenommenen  *
*                   énderungen zurÅck in die EXE-Datei                     *
**------------------------------------------------------------------------**
*  Info : Es werden nur die Bytes zwischen dem Anfang des Datensegments    *
*         und der Konstanten mit der hîchsten Offsetadrese zurÅck in die   *
*         Datei geschrieben, damit nicht unnîtig Zeit vergeudet wird.      *
***************************************************************************}

procedure TPISaveChanges;
begin
  {$I-}
  Seek( ExeFile, DataSegStart);      { Dateizeiger auf Datensegment setzen }
  if ( DataWriteBack <= DataSegSize ) then             { geÑnderten Teil   }
    BlockWrite( ExeFile, DataSegment^, DataWriteBack)  { des Datensegments }
  else                                                 { zurÅckschreiben   }
    BlockWrite( ExeFile, DataSegment^, DataSegSize);
  {$I+}
  If Ioresult=0 then  f_spe:=false
                 else f_spe:=true;
end;

{***************************************************************************
*  TPICloseFile : Schlie·t die EXE-Datei wieder, in der die Installationen *
*                 vorgenommen wurden.                                      *
***************************************************************************}

procedure TPICLoseFile;

begin
    if not f_spe then
    begin
      {$I-}
      SetFTime(ExeFile,ExeTime);
      close( ExeFile );                                  { Datei schlie·en }
      {$I+}

      If (ioresult>0) then
      begin
        f_spe:=true;
        {$I-}
        reset(ExeFile,1);
        {$I+}
      end;
      if not f_spe then
      dispose( DataSegment );       { Speicherplatz fÅr Datensegment freigeben }
    end;
end;

{***************************************************************************
*  TPIGet : Liest eine typisierte Konstante aus dem Datensegment innerhalb *
*           der EXE-Datei in eine Variable                                 *
**------------------------------------------------------------------------**
*  Eingabe : ADRESSE = Adresse der typisierten Konstante (aus TCA-Datei)   *
*            LAENGE  = Grî·e der Konstante in Bytes                        *
*            PUFFER  = Puffer/Variable zur Aufnahme der Konstanten         *
***************************************************************************}

procedure TPIGet( Adresse : word; Laenge : word; var Puffer );

begin                                          { Inhalt in Puffer kopieren }
  Move( DataSegment^[ Adresse ], Puffer, Laenge );
end;

{***************************************************************************
*  TPIPut : Schreibt eine typisierte Konstante in das Datensegment inner-  *
*           halb der EXE-Datei                                             *
**------------------------------------------------------------------------**
*  Eingabe : ADRESSE = Adresse der typisierten Konstante (aus TCA-Datei)   *
*            LAENGE  = Grî·e der Konstanten in Bytes                       *
*            PUFFER  = jetziger "Lagerort" der Konstanten                  *
***************************************************************************}

procedure TPIPut( Adresse : word; Laenge : word; var Puffer );

begin
  {-- Inhalt von Puffer in Datensegment zurÅckschreiben -------------------}

  Move( Puffer, DataSegment^[ Adresse ], Laenge );

  {-- Hîchstgrenze fÅr énderungen im Datensgement aktualisieren -----------}

  if ( Adresse + Laenge > DataWriteBack ) then
    DataWriteBack := Adresse + Laenge;
end;


begin                                             { nix zum Initialisieren }
end.
