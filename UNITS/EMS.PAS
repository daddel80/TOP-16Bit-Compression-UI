{***************************************************************************
*  E M S : eine Unit, die als Schnittstellte zwischen einem Programm und   *
*          dem Expanded Memory Manager (EMM) fungiert und dadurch die      *
*          Mîglichkeit zum Zugriff auf den EMS-Speicher bietet.            *
**------------------------------------------------------------------------**
*  Autor            : MICHAEL TISCHER                                      *
*  entwickelt am    :  9.06.1989                                           *
*  letztes Update am:  9.06.1989                                           *
***************************************************************************}

unit Ems;

interface
uses Dos;

{-- Deklaration der Funktionen und Prozeduren, die von einem anderen ------}
{-- Programm aufgerufen werden kînnen                                ------}

function  EmsGetFreePage   : integer;
function  EmsGetPtr        ( PhysPage : byte ) : pointer;
function  EmsAlloc         ( Anzahl : integer ) : integer;
procedure EmsMap           ( Handle, LogPage : integer; PhysPage : byte );
procedure EmsFree          ( Handle : integer );
procedure EmsRestoreMapping( Handle : integer );
procedure EmsSaveMapping   ( Handle : integer );

{-- Konstanten, îffentlich ------------------------------------------------}

const {--------------------------------------------- EMS-Fehlercodes ------}

      EmsErrOk        = $00;   { alles o.k., kein Fehler                   }
      EmsErrSw        = $80;   { Fehler im EMM (Software)                  }
      EmsErrHw        = $81;   { EMS-Hardware-Fehler                       }
      EmsErrInvHandle = $83;   { ungÅltiges EMS-Handle                     }
      EmsErrFkt       = $84;   { aufgerufene Funktion ungÅltig             }
      EmsErrNoHandles = $85;   { keine Handles mehr frei                   }
      EmsErrSaResMap  = $86;   { Fehler beim Sichern oder ZurÅckspeichern  }
                               { des Mappings                              }
      EmsErrToMany    = $87;   { mehr Seiten angefordert, als physikalisch }
                               { vohanden sind                             }
      EmsErrNoPages   = $88;   { mehr S. angefordert, als noch frei sind   }
      EmsErrNullPages = $89;   { Null Seiten angefordert                   }
      EmsErrLogPInv   = $8A;   { logische Seite gehîrt nicht zum Handle    }
      EmsErrPhyPInv   = $8B;   { ungÅltige physikalische Seitennummer      }
      EmsErrMapFull   = $8C;   { Mapping-Speicherbereich ist voll          }
      EmsErrMapSaved  = $8D;   { Mapping wurde bereits gesichert           }
      EmsErrMapRes    = $8E;   { ZurÅckspeichern des Mappings ohne vorher- }
                               { gehendes Sichern                          }

{-- globale Variable, die auch anderen Programmen zugÑnglich sind ---------}

var EmsInst     : boolean;         { ist TRUE, wenn EMS-Speicher verfÅgbar }
    EmsPages    : integer;                    { Gesamtanzahl der EMS-Pages }
    EmsVersion,                  { EMS-Versionsnummer (32 = 3.2, 40 = 4.0) }
    EmsError    : byte;                       { nimmt EMM-Fehlernummer auf }

implementation

{-- Konstanten, modulintern -----------------------------------------------}

const EMS_INT = $67;                { Interrupt-Vektor zum Zugriff auf EMM }

{-- globale Variablen, modulintern ----------------------------------------}

var EmsFrameSeg : word;               { Segmentadresse des EMS-Page-Frames }

{***************************************************************************
*  EmsInit : Initialisiert die Unit.                                       *
***************************************************************************}

procedure EmsInit;

type EmmName  = array [1..8] of char;       { Name des EMM im Treiber-Kopf }
     EmmNaPtr = ^EmmName;               { Zeiger auf Namen im Treiber-Kopf }

const Name : EmmName = 'EMMXXXX0'; { Name des EMS-Treibers }

var Regs  : Registers;                { Prozessorregs. fÅr Interruptaufruf }

begin
  {-- zunÑchst feststellen, ob EMS-Speicher und ein zugehîriger EMM -------}
  {-- installiert sind                                              -------}

  Regs.ax := $35 shl 8 + EMS_INT;               { Interruptvektor $67 Åber }
  msdos( Regs );                                { DOS-Funktion 35h holen   }

  EmsInst := ( EmmNaPtr(Ptr(Regs.ES,10))^ = Name ); { Treiber-Name vergl. }

  if ( EmsInst ) then                           { ist ein EMM installiert? }
    begin                                                             { Ja }

      {-- Gesamtanzahl der EMS-Pages ermitteln ----------------------------}
      Regs.AH := $42;          { Funktionsnr. fÅr "Anzahl Pages ermitteln" }
      intr( EMS_INT, Regs );                                { EMM aufrufen }
      EmsPages := Regs.DX;                 { Gesamtanzahl der Pages merken }

      {-- Segmentadresse des EMS-Page-Frames ermitteln --------------------}
      Regs.AH := $41;  {Funktionsnr. fÅr "Segmentad. des Page-Frames laden"}
      intr( EMS_INT, Regs );                                { EMM aufrufen }
      EmsFrameSeg := Regs.BX;                      { Segmentadresse merken }

      {-- Versionsnummer des EMM ermitteln --------------------------------}
      Regs.AH := $46;        { Funktionsnr. fÅr "Versionsnummer ermitteln" }
      intr( EMS_INT, Regs );                                { EMM aufrufen }
      EmsVersion := ( Regs.AL and 15 ) + ( Regs.AL shr 4 ) * 10;

      EmsError := EmsErrOk;                           { bisher kein Fehler }

    end;
end;

{***************************************************************************
*  EmsGetPtr : Liefert einen Zeiger auf eine der vier physikalischen       *
*              Pages im EMS-Page-Frame.                                    *
**------------------------------------------------------------------------**
*  Eingabe : PhysPage = Nummer der physikalischen Page                     *
*  Ausgabe : Zeiger auf diese Page                                         *
***************************************************************************}

function EmsGetPtr( PhysPage : byte ) : pointer;

begin
  EmsGetPtr := ptr( EmsFrameSeg, PhysPage shl 14 );
end;

{***************************************************************************
*  EmsGetFreePage : Ermittelt die Anzahl der noch nicht belegten EMS-      *
*                   Pages. (1 Page entspricht 16 KByte)                    *
**------------------------------------------------------------------------**
*  Ausgabe : Die Anzahl freier Pages.                                      *
***************************************************************************}

function EmsGetFreePage : integer;

var Regs : Registers;             { Prozessorregs. fÅr den Interruptaufruf }

begin
  Regs.AH := $42;              { Funktionsnr. fÅr "Anzahl Pages ermitteln" }
  intr( EMS_INT, Regs );                                    { EMM aufrufen }
  EmsGetFreePage := Regs.BX;           { Anzahl freier Pages zurÅckliefern }
end;

{***************************************************************************
*  EmsAlloc : Allokiert eine bestimme Anzahl von EMS-Pages.                *
**------------------------------------------------------------------------**
*  Eingabe : Anzahl = Anzahl zu allokierender Pages                        *
*  Ausgabe : Handle zum weiteren Zugriff auf die allokierten Pages         *
*  Info    : Tritt ein Fehler auf, enthÑlt die Variable EmsError nach dem  *
*            Funktionsaufruf einen Wert ungleich 0 und gibt damit einen    *
*            Fehlercode an.                                                *
***************************************************************************}

function EmsAlloc( Anzahl : integer ) : integer;

var Regs : Registers;             { Prozessorregs. fÅr den Interruptaufruf }

begin
  Regs.AH := $43;                    { Funktionsnr. fÅr "Pages allokieren" }
  Regs.BX := Anzahl;                   { Anzahl Pages wird in BX Åbergeben }
  intr( EMS_INT, Regs );                                    { EMM aufrufen }
  EmsAlloc := Regs.DX;                   { das Handle wird in DX Åbergeben }
  EmsError := Regs.AH;                                           { Fehler? }
end;

{***************************************************************************
*  EmsMap : Bildet ein der allokierten Pages auf eine der 4 physika-       *
*           lischen Pages im EMS-Page-Frame ab.                            *
**------------------------------------------------------------------------**
*  Eingabe : Handle   = Handle, unter dem die angesprochene Page allo-     *
*                       kiert wurde.                                       *
*            LogPage  = Nummer der abzubildenen (logischen) Page           *
*            PhysPage = Nummer der physikalischen Page                     *
*  Info    : Tritt ein Fehler auf, enthÑlt die Variable EmsError nach dem  *
*            Funktionsaufruf einen Wert ungleich 0 und gibt damit einen    *
*            Fehlercode an.                                                *
***************************************************************************}

procedure EmsMap( Handle, LogPage : integer; PhysPage : byte );

var Regs : Registers;             { Prozessorregs. fÅr den Interruptaufruf }

begin
  Regs.AH := $44;            { Funktionsnr. fÅr "Map expanded Memory Page" }
  Regs.DX := Handle;                 { die Parameter in die Register laden }
  Regs.BX := LogPage;
  Regs.Al := PhysPage;
  intr( EMS_INT, Regs );                                    { EMM aufrufen }
  EmsError := Regs.AH;                                           { Fehler? }
end;

{***************************************************************************
*  EmsFree : Gibt zuvor Åber die Funktion EmsAlloc allokierte EMS-Pages    *
*            wieder frei.                                                  *
**------------------------------------------------------------------------**
*  Eingabe : Handle = Das Handle, unter dem die Pages allokiert wurden.    *
*  Info    : Tritt ein Fehler auf, enthÑlt die Variable EmsError nach dem  *
*            Funktionsaufruf einen Wert ungleich 0 und gibt damit einen    *
*            Fehlercode an.                                                *
***************************************************************************}

procedure EmsFree( Handle : integer );

var Regs : Registers;             { Prozessorregs. fÅr den Interruptaufruf }

begin
  Regs.AH := $45;                { Funktionsnr. fÅr "Release Handle & EMS" }
  Regs.DX := Handle;                 { die Parameter in die Register laden }
  intr( EMS_INT, Regs );                                    { EMM aufrufen }
  EmsError := Regs.AH;                                           { Fehler? }
end;

{***************************************************************************
*  EmsSaveMapping : Sichert die aktuelle Abbildung logischer EMS-Pages in  *
*                   die vier physikalischen Pages des EMS-Page-Frames.     *
**------------------------------------------------------------------------**
*  Eingabe : Handle = Das Handle, unter dem die Pages allokiert wurden.    *
*  Info    : Tritt ein Fehler auf, enthÑlt die Variable EmsError nach dem  *
*            Funktionsaufruf einen Wert ungleich 0 und gibt damit einen    *
*            Fehlercode an.                                                *
***************************************************************************}

procedure EmsSaveMapping( Handle : integer );

var Regs : Registers;             { Prozessorregs. fÅr den Interruptaufruf }

begin
  Regs.AH := $47;                        { Funktionsnr. fÅr "Save Mapping" }
  Regs.DX := Handle;                 { die Parameter in die Register laden }
  intr( EMS_INT, Regs );                                    { EMM aufrufen }
  EmsError := Regs.AH;                                           { Fehler? }
end;

{***************************************************************************
*  EmsRestoreMapping : Holt eine zuvor mit HIlfe der Prozedur EmsSave-     *
*                      Mapping gespeicherte Abbildung zwischen den lo-     *
*                      gischen Pages und den vier physikalischen Pages im  *
*                      EMS-Page-Frame wieder zurÅck.                       *
**------------------------------------------------------------------------**
*  Eingabe : Handle = Das Handle, unter dem die Pages allokiert wurden.    *
*  Info    : Tritt ein Fehler auf, enthÑlt die Variable EmsError nach dem  *
*            Funktionsaufruf einen Wert ungleich 0 und gibt damit einen    *
*            Fehlercode an.                                                *
***************************************************************************}

procedure EmsRestoreMapping( Handle : integer );

var Regs : Registers;             { Prozessorregs. fÅr den Interruptaufruf }

begin
  Regs.AH := $48;                     { Funktionsnr. fÅr "Restore Mapping" }
  Regs.DX := Handle;                 { die Parameter in die Register laden }
  intr( EMS_INT, Regs );                                    { EMM aufrufen }
  EmsError := Regs.AH;                                           { Fehler? }
end;

{**----------------------------------------------------------------------**}
{** Startcode der Unit                                                   **}
{**----------------------------------------------------------------------**}

begin
  EmsInit;                                        { die Unit intialisieren }
end.