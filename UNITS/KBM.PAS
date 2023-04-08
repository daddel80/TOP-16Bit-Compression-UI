{***************************************************************************
*  K B M : eine Unit, die komfortable Routinen zur Abfrage von Maus und    *
*          Tastatur bereitstellt.                                          *
**------------------------------------------------------------------------**
*  Autor            : MICHAEL TISCHER                                      *
*  entwickelt am    :  1.06.1989                                           *
*  letztes Update am: 23.09.1989                                           *
***************************************************************************}

unit Kbm;

interface

uses  Dos,Crt;                                           { Units einbinden }

{== Typdeklarationen, die in Verbindung mit den îffentlichen Prozeduren ===}
{==  und Funktionen aus dieser Unit benîtigt werden.                    ===}

type  TASTE    = word;             { Tastencode, >= 256 : erweiterter Code }
      PTRVIEW  = longint;                          { Maske fÅr Maus-Cursor }

      BEREICH  = record                     { beschreibt einen Mausbereich }
                   x1,                     { Koordinaten der oberen linken }
                   y1,                     { und unteren rechten Ecke des  }
                   x2,                     { spezifizierten Bereichs       }
                   y2  : byte;
                 end;
      BERARRAY = array [0..10] of BEREICH;                { Bereichs-Array }
      BERPTR   = ^BERARRAY;                    { Zeiger auf Bereichs-Array }

      EVENT = record          { beschreibt Ereignis von Maus oder Tastatur }
                Ereignis : integer;                        { Ereignis-Code }
                Zeit     : longint;                        { Zeit in Ticks }
                CtrlCode : Taste;                   { dient zum Zwischensp.}
                case byte of                         { Tastatur oder Maus? }
                   0 : { Maus: ( EV_MOU_...) ------------------------------}
                       ( ZeileRel,              { Position des Maus-Cursor }
                         SpalteRel,             { relativ zum Bereich      }
                         ZeileAbs,              { Position des Maus-Cursor }
                         SpalteAbs,             { relativ zum ges. Bilds.  }
                         Bereich,                            { Mausbereich }
                         Buttons : byte );            { Status der Buttons }

                   1 : { Taste: ( EV_KEY_PRESSED ) ------------------------}
                       ( Key : TASTE );                  { betÑtigte Taste }

                   2 : { Taste, erzeugt keinen Code: ( EV_KEY_UNKNOWN ) ---}
                       ( ScanCode,           { zurÅckgelieferter Scan-Code }
                         Status    : byte );     { Status der Steuertasten }

                   3 : { Statustaste, kein Code ( EV_KEY_STATUS ) ---------}
                       ( StateKey : byte );
              end;

      EVENTHANDLER = procedure ( var EvRec : EVENT );

{== Deklaration der Funktionen und Prozeduren, die von einem anderen ======}
{== Programm aufgerufen werden kînnen                                ======}

procedure KbmRegisterHandler  ( Event : word; Handler : EVENTHANDLER );
procedure KbmDeRegisterHandler( Event : word );
procedure KbmGetEvent         ( var EvRec : EVENT );
procedure KbmPeekEvent        ( var EvRec : EVENT );
procedure KbClrevent;
procedure MouClrevent;
procedure KbmReleaseMode      ( Modus : byte  );
procedure KbmSetMode          ( Modus : byte  );
function  MouPtrMask          ( Zeichen, Farbe  : word ) : PTRVIEW;
function  PtrDifChar          ( Zeichen : byte ) : word;
function  PtrDifCol           ( Farbe : byte ) : word;
procedure MouDefinePtr        ( Mask : PTRVIEW );
procedure MouDefBereich       ( Anzahl : byte; BPtr : BERPTR );
procedure KbmEventWait        ( WaitEvent : integer; var EvRec : EVENT );
procedure MouShowMouse;
procedure MouHideMouse;
procedure MouSetMoveArea      ( x1, y1, x2, y2 : byte );
procedure MouSetSpeed         ( XSpeed, YSpeed : integer );
procedure MouMovePtr          ( Col, Row : byte );
procedure KbmInit             ( Spalten, Zeilen : byte );
procedure KbmEnd(ende:boolean);


{== Variablen, die einem Anwendungsprogramm zugÑnglich sind ===============}

var MouAvail : boolean;                    { ist TRUE, wenn Maus verfÅgbar }

    {-- Variablen, die mit jedem Aufruf des Maus-Handlers geladen werden --}

    AnzBereiche,                                     { Anzahl der Bereiche }
    AktBer,                                { Nummer des aktuellen Bereichs }
    AktBut,                                        { Status der Mausknîpfe }
    AktX,                             { aktuelle Position des Maus-Cursors }
    AktY  : byte;                     { in Bezug zum gesamten Bildschirm   }
    crtxmax,crtymax  : byte;                { fÅr max Bildschirmausdehnung }
    ev    : Event;                               { enthÑlt alle Ereignisse }

{== Konstanten, die einem Anwendungsprogramm zugÑnglich sind ==============}

const {------------------------------------------------- Event-Codes ------}

      EV_NO_EVENT     =    0;              { es steht kein Ereignis bereit }
      EV_MOU_MOVE     =    1;                                { Maus bewegt }
      EV_LEFT_PRESS   =    2;               { linker Mausknopf niedergedr. }
      EV_LEFT_REL     =    4;               { linker Mausknopf losgelassen }
      EV_RIGHT_PRESS  =    8;              { rechter Mausknopf niedergedr. }
      EV_RIGHT_REL    =   16;              { rechter Mausknopf losgelassen }
      EV_KEY_PRESSED  =  256;                             { Taste betÑtigt }
      EV_KEY_UNKNOWN  =  512; { Tastenkombination, die keinen Code erzeugt }
      EV_KEY_STATUS   = 1024;           { Statustaste, erzeugt keinen Code }

      EV_MOU_ALL      =   31;                           { alle Maus-Events }
      EV_KEY_ALL      = 1792;                       { alle Tastatur-Events }
      EV_ALL          = 1823;             { alle Maus- und Tastatur-Events }

      {------------------------------------- Codes der Status-Tasten ------}

      KEY_RIGHT_SHIFT =   1;
      KEY_LEFT_SHIFT  =   2;
      KEY_CTRL        =   4;
      KEY_ALT         =   8;
      KEY_SCROLL_LOCK =  16;        { auf deutschen Tastaturen: Abbr(uch)  }
      KEY_NUM_LOCK    =  32;        { Umschaltung Ziffern-Tastatur         }
      KEY_CAPS_LOCK   =  64;        { Umschaltung Gro·-/Kleinschreibung    }
      KEY_INSERT      = 128;        { INSERT, wird als Taste und nicht als }
                                    { Status-énderung zurÅckgeliefert      }

      {--------------- Konstanten zur Beschreibung des Maus-Cursors -------}

      PtrSameChar = $00ff;                    { gleiches Zeichen           }
      PtrSameCol  = $00ff;                    { gleiche Farbe              }
      PtrInvCol   = $7777;                    { Farbe invertiert           }
      PtrSameColB = $807f;                    { gleiche Farbe blinkend     }
      PtrInvColB  = $F777;                    { invertierte Farbe blinkend }

      {------------------------------------- Codes der Steuertasten -------}

      BEL       =   7;                                   { Klingelzeichen  }
      BS        =   8;                                   { Backspace-Taste }
      TAB       =   9;                                   { Tabulator-Taste }
      LF        =  10;                                   { Linefeed        }
      CR        =  13;                                   { Return-Taste    }
      ESC       =  27;                                   { Escape-Taste    }
      SPACE     =  32;                                   { Leer-Taste      }
      CTRL_A    =   1;                                   { CTRL + A        }
      CTRL_B    =   2;                                   { CTRL + B        }
      CTRL_C    =   3;                                   { CTRL + C        }
      CTRL_D    =   4;                                   { CTRL + D        }
      CTRL_E    =   5;                                   { CTRL + E        }
      CTRL_F    =   6;                                   { CTRL + F        }
      CTRL_G    =   7;                                   { CTRL + G        }
      CTRL_H    =   8;                                   { CTRL + H        }
      CTRL_I    =   9;                                   { CTRL + I        }
      CTRL_J    =  10;                                   { CTRL + J        }
      CTRL_K    =  11;                                   { CTRL + K        }
      CTRL_L    =  12;                                   { CTRL + L        }
      CTRL_M    =  13;                                   { CTRL + M        }
      CTRL_N    =  14;                                   { CTRL + N        }
      CTRL_O    =  15;                                   { CTRL + O        }
      CTRL_P    =  16;                                   { CTRL + P        }
      CTRL_Q    =  17;                                   { CTRL + Q        }
      CTRL_R    =  18;                                   { CTRL + R        }
      CTRL_S    =  19;                                   { CTRL + S        }
      CTRL_T    =  20;                                   { CTRL + T        }
      CTRL_U    =  21;                                   { CTRL + U        }
      CTRL_V    =  22;                                   { CTRL + V        }
      CTRL_W    =  23;                                   { CTRL + W        }
      CTRL_X    =  24;                                   { CTRL + X        }
      CTRL_Y    =  25;                                   { CTRL + Y        }
      CTRL_Z    =  26;                                   { CTRL + Z        }
      BACKTAB   = 271;                                   { SHIFT + TAB     }
      ALT_Q     = 272;                                   { ALT + Q         }
      ALT_W     = 273;                                   { ALT + W         }
      ALT_E     = 274;                                   { ALT + E         }
      ALT_R     = 275;                                   { ALT + R         }
      ALT_T     = 276;                                   { ALT + T         }
      ALT_Y     = 277;                                   { ALT + Y         }
      ALT_U     = 278;                                   { ALT + U         }
      ALT_I     = 279;                                   { ALT + I         }
      ALT_O     = 280;                                   { ALT + O         }
      ALT_P     = 281;                                   { ALT + P         }
      ALT_A     = 286;                                   { ALT + A         }
      ALT_S     = 287;                                   { ALT + S         }
      ALT_D     = 288;                                   { ALT + D         }
      ALT_F     = 289;                                   { ALT + F         }
      ALT_G     = 290;                                   { ALT + G         }
      ALT_H     = 291;                                   { ALT + H         }
      ALT_J     = 292;                                   { ALT + J         }
      ALT_K     = 293;                                   { ALT + K         }
      ALT_L     = 294;                                   { ALT + L         }
      ALT_Z     = 300;                                   { ALT + Z         }
      ALT_X     = 301;                                   { ALT + X         }
      ALT_C     = 302;                                   { ALT + C         }
      ALT_V     = 303;                                   { ALT + V         }
      ALT_B     = 304;                                   { ALT + B         }
      ALT_N     = 305;                                   { ALT + N         }
      ALT_M     = 306;                                   { ALT + M         }
      F1        = 315;                                   { F1-Taste        }
      F2        = 316;                                   { F2-Taste        }
      F3        = 317;                                   { F3-Taste        }
      F4        = 318;                                   { F4-Taste        }
      F5        = 319;                                   { F5-Taste        }
      F6        = 320;                                   { F6-Taste        }
      F7        = 321;                                   { F7-Taste        }
      F8        = 322;                                   { F8-Taste        }
      F9        = 323;                                   { F9-Taste        }
      F10       = 324;                                   { F10-Taste       }
      CDOWN     = 336;                                   { Cursor-Down     }
      CHOME     = 327;                                   { Cursor-Home     }
      CUP       = 328;                                   { Cursor-Up       }
      CPGUP     = 329;                                   { Cursor-Page Up  }
      CLEFT     = 331;                                   { Cursor-Left     }
      CRIGHT    = 333;                                   { Cursor-Right    }
      CEND      = 335;                                   { Cursor-Right    }
      CPGDN     = 337;                                   { Cursor-Page Dn  }
      INSERTKEY = 338;                                   { INSERT-Taste    }
      DELETEKEY = 339;                                   { DELETE-Taste    }
      SHIFT_F1  = 340;                                   { SHIFT + F1      }
      SHIFT_F2  = 341;                                   { SHIFT + F2      }
      SHIFT_F3  = 342;                                   { SHIFT + F3      }
      SHIFT_F4  = 343;                                   { SHIFT + F4      }
      SHIFT_F5  = 344;                                   { SHIFT + F5      }
      SHIFT_F6  = 345;                                   { SHIFT + F6      }
      SHIFT_F7  = 346;                                   { SHIFT + F7      }
      SHIFT_F8  = 347;                                   { SHIFT + F8      }
      SHIFT_F9  = 348;                                   { SHIFT + F9      }
      SHIFT_F10 = 349;                                   { SHIFT + F10     }
      CTRL_F1   = 350;                                   { CTRL + F1       }
      CTRL_F2   = 351;                                   { CTRL + F2       }
      CTRL_F3   = 352;                                   { CTRL + F3       }
      CTRL_F4   = 353;                                   { CTRL + F4       }
      CTRL_F5   = 354;                                   { CTRL + F5       }
      CTRL_F6   = 355;                                   { CTRL + F6       }
      CTRL_F7   = 356;                                   { CTRL + F7       }
      CTRL_F8   = 357;                                   { CTRL + F8       }
      CTRL_F9   = 358;                                   { CTRL + F9       }
      CTRL_F10  = 359;                                   { CTRL + F10      }
      ALT_F1    = 360;                                   { ALT + F1        }
      ALT_F2    = 361;                                   { ALT + F2        }
      ALT_F3    = 362;                                   { ALT + F3        }
      ALT_F4    = 363;                                   { ALT + F4        }
      ALT_F5    = 364;                                   { ALT + F5        }
      ALT_F6    = 365;                                   { ALT + F6        }
      ALT_F7    = 366;                                   { ALT + F7        }
      ALT_F8    = 367;                                   { ALT + F8        }
      ALT_F9    = 368;                                   { ALT + F9        }
      ALT_F10   = 369;                                   { ALT + F10       }
      CTRL_LF   = 371;                                   { CTRL-Left       }
      CTRL_RI   = 372;                                   { CTRL-Right      }
      CTRL_PGDN = 374;                                   { CTRL-PgUp       }
      CTRL_HOME = 375;                                   { CTRL-Home       }
      ALT_1     = 376;                                   { ALT + 1         }
      ALT_2     = 377;                                   { ALT + 2         }
      ALT_3     = 378;                                   { ALT + 3         }
      ALT_4     = 379;                                   { ALT + 4         }
      ALT_5     = 380;                                   { ALT + 5         }
      ALT_6     = 381;                                   { ALT + 6         }
      ALT_7     = 382;                                   { ALT + 7         }
      ALT_8     = 383;                                   { ALT + 8         }
      ALT_9     = 384;                                   { ALT + 9         }
      ALT_0     = 385;                                   { ALT + 0         }
      CTRL_PGUP = 388;                                   { CTRL-PgUp       }

implementation

{$L kbma}                                  { das Assembler-Modul einbinden }

{== Konstanten, modulintern ===============================================}

const KEIN_BEREICH    = 255;             { Maus-Cursor nicht in Bereich xy }
      EVQ_LEN         = 100;           { LÑnge der Maus- u. Tastatur-Queue }

{== Typdeklarationen, modulintern =========================================}

type  PTRREC   = record                        { dient dem Zugriff auf die }
                   Ofs : word;                 { Bestandteile eines belie- }
                   Seg : word;                 { bigen Pointers            }
                 end;

      PTRVREC  = record                       { dient dem Zugriff auf die  }
                   ScreenMask : word;         { Bestandteile eines PTRVIEW }
                   CursorMask : word;
                 end;

      BERBUF   = array [0..10900] of byte;                { Bereichspuffer }

      BBPTR    = ^BERBUF;                { Zeiger auf einen Bereichspuffer }

      EVQUEUE = record                               { eine Ereignis-Queue }
                  Next,                        { Zeiger auf nÑchstes Event }
                  Last  : integer;              { Zeiger auf letztes Event }
                  Queue : array [1..EVQ_LEN] of EVENT;      { Event-Puffer }
                end;

      EVQUEUEPTR  = ^EVQUEUE;                 { Zeiger auf die Event-Queue }

      EVHANDREC = record            { Element in der Event-Handler-Tabelle }
                    Call    : boolean;              { Handler installiert? }
                    Handler : EVENTHANDLER;              { Prozedur-Zeiger }
                  end;

{== globale Variablen, modulintern ========================================}

var  
     TLine,                                           { Anzahl Text-Zeilen }
     TCol     : byte;                                { Anzahl Text-Spalten }
     BufPtr   : BBPTR;          { Zeiger auf Puffer fÅr Bereichs-Erkennung }
     AktBerPtr: BERPTR;                 { Pointer auf akt. Bereichs-Vektor }
     BLen     : integer;                { LÑnge des Bereichspuffer in Byte }
     ExitOld  : pointer;               { Zeiger auf die alte Exit-Prozedur }
     HandTab  : array [1..16] of EVHANDREC;   { Tabelle mit Event-Handlern }
                                              { des Anwendungsprogramms    }

     KbQueueP,                              { Queue fÅr Tastaturereignisse }
     MouQueueP : EVQUEUEPTR;                    { Queue fÅr Mausereignisse }

     OldKbHandler : pointer;            { Adresse des alten Int09-Handlers }

     Time       : longint absolute $40:$6C;             { BIOS-Tick-ZÑhler }
     BiosKbFlag : byte absolute $40:$17;              { BIOS-Tastatur-Flag }
     AktStatus  : byte;                        { aktueller Tastatur-Status }



{== Deklaration externer Funktionen =======================================}

{$F+}                                               { die Funktion ist FAR }
procedure NewMouHandler ; external ;              { der Maus-Event-Handler }
procedure NewKbHandler  ; external ;    { neuer Tastatur-Handler (Int $09) }
{$F-}                                { FAR-Funktionen nicht mehr erzwingen }

{**************************************************************************}
{*  KbmIGetIndex : Ermittelt aus einer Event-Maske den zugehîrigen Index  *}
{*                 in die Event-Handler-Tabelle                           *}
{**-----------------------------------------------------------------------*}
{*  Eingabe: MASK = die Event-Maske                                       *}
{*  Ausgabe: Index zwischen 1 und 16                                      *}
{**************************************************************************}

function KbmIGetIndex( Mask : word ) : byte ;

var i : byte;                                        { nimmt den Index auf }

begin
  i := 1;
  while ( Mask <> 1 ) do                 { Event-Bit noch nicht in Bit 0 ? }
    begin                                                           { Nein }
      Mask := Mask shr 1;            { Mask um ein Bit nach rechts shiften }
      inc( i );                                     { Index inkrementieren }
    end;
  KbmIGetIndex := i;                                 { Index zurÅckliefern }
end;

{**************************************************************************}
{*  KbmIBufFill: speichert den Bereichscode fÅr einen Mausbereich inner-  *}
{*               halb des modulinternen Bereichsspeichers                 *}
{**----------------------------------------------------------------------**}
{*  Eingabe: x1, y1 = obere linke Ecke des Mausbereichs                   *}
{*           x2, y2 = untere rechte Ecke des Mausbereichs                 *}
{*           Code   = der Bereichscode                                    *}
{**************************************************************************}

procedure KbmIBufFill( x1, y1, x2, y2, Code : byte );

var Index   : integer;                       { zeigt auf bearbeitetes Feld }
    Spalte,                                              { SchleifenzÑhler }
    Zeile   : byte;

begin
  for Zeile:=y1 to y2 do                { die einzelnen Zeilen durchlaufen }
    begin
      Index := Zeile * TCol + x1;                 { erster Index der Zeile }
      for Spalte:=x1 to x2 do       { die Spalten in der Zeile durchlaufen }
        begin
          BufPtr^[ Index ] := Code;                       { Code speichern }
          inc( Index );                { Index auf das nÑchste Feld setzen }
        end;
    end;
end;

{**************************************************************************}
{*  KbmIGetX: ermittelt die Textspalte, in der sich der Maus-Cursor be-   *}
{*            findet                                                      *}
{**----------------------------------------------------------------------**}
{*  Ausgabe: Spalte des Maus-Cursors in Bezug auf den Textbildschirm      *}
{**************************************************************************}

function KbmIGetX : byte;

var Regs : Registers;              { Prozessorregister fÅr Interruptaufruf }

begin
  Regs.AX := $0003;                     { Fktnr.: fÅr "Get mouse position" }
  Intr( $33,  Regs );                              { Maus-Treiber aufrufen }
  KbmIGetX := Regs.CX shr 3;               { Spalte umrechnen und zurÅckl. }
end;

{**************************************************************************}
{*  KbmIGetY: ermittelt die Textzeile, in der sich der Maus-Cursor be-    *}
{*            findet                                                      *}
{**----------------------------------------------------------------------**}
{*  Ausgabe: Zeile des Maus-Cursors in Bezug auf den Textbildschirm       *}
{**************************************************************************}

function KbmIGetY : byte;

var Regs : Registers;              { Prozessorregister fÅr Interruptaufruf }

begin
  Regs.AX := $0003;                     { Fktnr.: fÅr "Get mouse position" }
  Intr( $33, Regs );                               { Maus-Treiber aufrufen }
  KbmIGetY := Regs.DX shr 3;                { Zeile umrechnen und zurÅckl. }
end;


{**************************************************************************}
{*  KbmPutQueue : HÑngt ein Event-Record an das Ende der Event-Queue an.  *}
{**-----------------------------------------------------------------------*}
{*  Eingabe: Qp    = Zeiger auf die zu bearbeitende Queue                 *}
{*           EvRec = das anzuhÑngende Event-Record                        *}
{*  Info:    ist in der Event-Queue kein Platz mehr, Åberschreibt das     *}
{*           Event das bisher letzte Event.                               *}
{**************************************************************************}

procedure KbmPutQueue( Qp : EVQUEUEPTR; EvRec : EVENT );

var NeuLast : integer;                             { neuer letzter Eintrag }

begin
  with Qp^ do                            { die angegebene Queue bearbeiten }
    begin
      Queue[ Last ] := EvRec;             { Event-Record in Queue kopieren }
      NeuLast := Last + 1;             { Nummer des neuen letzten Eintrags }
      if ( NeuLast > EVQ_LEN ) then        { Wrap-Around am Ende der Queue }
        NeuLast := 1;
      if ( NeuLast <> Next ) then                               { öberlauf }
        Last := NeuLast;                    { Nein, letzten Eintrag setzen }
    end;
end;

{**************************************************************************}
{*  KbmGetQueue : Liest das nÑchste Event aus der Maus- oder Tastatur-    *}
{*                Queue                                                   *}
{**-----------------------------------------------------------------------*}
{*  Eingabe: Qp    = Zeiger auf die zu bearbeitende Queue                 *}
{*           EvRec = Variable, die das Event-Record aufnimmt              *}
{*  Info:    Steht beim Aufruf der Funktion noch kein Event bereit, lie-  *}
{*           fert die Funktion als Ereignistyp EV_NO_EVENT zurÅck und     *}
{*           setzt gleichzeitig das Zeitfeld auf MAXLONGINT               *}
{**************************************************************************}

procedure KbmGetQueue( Qp : EVQUEUEPTR; var EvRec : EVENT );

begin
  with Qp^ do                            { die angegebene Queue bearbeiten }
    begin
      if ( Next = Last ) then                 { kein Element in der Queue? }
        begin                                                       { Nein }
          EvRec.Ereignis := EV_NO_EVENT;                   { kein Ereignis }
          EvRec.Zeit := MAXLONGINT;                       { ungÅltige Zeit }
        end
      else                     { es befindet sich ein Element in der Queue }
        begin
          EvRec := Queue[ Next ];           { Event-Record aus Queue holen }
          if ( Next = EVQ_LEN ) then Next := 1      { EvNext auf nÑchstes  }
                                else inc( Next );   { Queue-Element setzen }
        end;
    end;
end;

{**************************************************************************}
{*  KbmPeekQueue : Liest das nÑchste Event aus der Maus- oder Tastatur-   *}
{*                 Queue, ohne es allerdings aus der Queue zu entfernen   *}
{**-----------------------------------------------------------------------*}
{*  Eingabe: Qp    = Zeiger auf die zu bearbeitende Queue                 *}
{*           EvRec = Variable, die das Event-Record aufnimmt              *}
{*  Info:    Steht beim Aufruf der Funktion noch kein Event bereit, lie-  *}
{*           fert die Funktion als Ereignistyp EV_NO_EVENT zurÅck und     *}
{*           setzt gleichzeitg das Zeitfeld auf MAXLONGINT                *}
{**************************************************************************}

procedure KbmPeekQueue( Qp : EVQUEUEPTR; var EvRec : EVENT );

begin
  with Qp^ do                            { die angegebene Queue bearbeiten }
    begin
      if ( Next = Last ) then                 { kein Element in der Queue? }
        begin                                                       { Nein }
          EvRec.Ereignis := EV_NO_EVENT;                   { kein Ereignis }
          EvRec.Zeit := MAXLONGINT;                       { ungÅltige Zeit }
        end
      else                     { es befindet sich ein Element in der Queue }
        EvRec := Queue[ Next ];             { Event-Record aus Queue holen }
    end;
end;

{**************************************************************************}
{*  KbmGetEvent : Liest das nÑchste Event                                 *}
{**-----------------------------------------------------------------------*}
{*  Eingabe: EvRec = Variable, die das Event-Record aufnimmt              *}
{*  Info:    Steht beim Aufruf der Funktion noch kein Event bereit, war-  *}
{*           tet die Funktion auf den Eintritt des nÑchsten Events        *}
{**************************************************************************}

procedure KbmGetEvent( var EvRec : EVENT );

var MouEv,                                   { Ereignis aus der Maus-Queue }
    KbEv : EVENT;                        { Ereignis aus der Tastatur-Queue }

begin
  repeat             { Leseschleife, wartet auf Eintritt eines Ereignisses }
    KbmPeekQueue( MouQueueP, MouEv );                { Maus-Ereignis holen }
    KbmPeekQueue( KbQueueP, KbEv );              { Tastatur-Ereignis holen }
  until ( ( MouEv.Ereignis <> EV_NO_EVENT ) or
          ( KbEv.Ereignis  <> EV_NO_EVENT ) );

  if ( KbEv.Zeit <= MouEv.Zeit ) then      { kam Tastatur-Ereignis frÅher? }
  begin
    KbmGetQueue( KbQueueP, EvRec );           { Ja, Tastatur-Ereignis holen }
    Evrec.Ctrlcode:=Evrec.key;
  end
  else                                         { Nein, Maus-Ereignis holen }
  begin
    KbmGetQueue( MouQueueP, EvRec );
    Evrec.Ctrlcode:=0;
  end;
end;


{**************************************************************************}
{*  KbmPeekEvent : Liest das nÑchste Event aus der Event-Queue, ohne es   *}
{*                 allerdings aus der Queue zu entfernen.                 *}
{**----------------------------------------------------------------------**}
{*  Eingabe: EvRec = Variable, die das Event-Record aufnimmt              *}
{*  Info:    Steht beim Aufruf der Funktion noch kein Event bereit, lie-  *}
{*           fert die Funktion im Feld EREIGNIS den Wert EV_NO_EVENT      *}
{*           zurÅck.                                                      *}
{**************************************************************************}

procedure KbmPeekEvent( var EvRec : EVENT );

var MouEv,                                   { Ereignis aus der Maus-Queue }
    KbEv : EVENT;                        { Ereignis aus der Tastatur-Queue }

begin
  KbmPeekQueue( MouQueueP, MouEv );                  { Maus-Ereignis holen }
  KbmPeekQueue( KbQueueP, KbEv );                { Tastatur-Ereignis holen }

  if ( KbEv.Zeit <= MouEv.Zeit ) then      { kam Tastatur-Ereignis frÅher? }
    EvRec := KbEv                    { Ja, Tastatur-Ereignis zurÅckliefern }
  else                                 { Nein, Maus-Ereignis zurÅckliefern }
    EvREc := MouEv;
end;

{**************************************************************************}
{*  KbHandler : wird vom neuen Int-09-Handler (NewKbHandler im Assembler- *}
{*              Modul) bei der BetÑtigung einer Taste aufgerufen          *}
{**----------------------------------------------------------------------**}
{*  Eingabe: KbPort = Code, der vom Tastaturport 60h gelesen wurde        *}
{**************************************************************************}

procedure KbHandler( KbPort : byte );

var EvRec  : EVENT;                         { zu erstellender Event-Record }
    Regs   : Registers;                                { Prozessorregister }
    NewKbS : byte;                                 { neuer Tastatur-Status }


begin
  EvRec.Zeit := Time;                                  { Uhrzeit ermitteln }
  Regs.AH := 1;                      { feststellen, ob Taste in Tastencode }
  intr( $16, Regs );                 { umgesetzt wurde                     }
  if ( Regs.Flags and FZERO = 0 ) then
    begin                            { Ja, Zeichen jetzt im Tastaturpuffer }
      Regs.AH := 0;                            { Zeichen Åber BIOS aus dem }
      intr( $16, Regs );                       { Tastaturpuffer laden      }
      if ( Regs.AL = 0 ) then EvRec.Key := Regs.AH + 256
                         else EvRec.Key := Regs.AL;

      EvRec.Ereignis := EV_KEY_PRESSED;                { Event-Code setzen }
      KbmPutQueue( KbQueueP, EvRec );             { Event in Queue bringen }
    end
  else                       { Tastendruck resultierte nicht in Tastencode }
    begin
      NewKbS := BiosKbFlag;            { Status der Steuertasten ermitteln }
      if ( AktStatus <> NewKbS ) then                    { StatusÑnderung? }
        begin
          if ( AktStatus < NewKbS ) then          { wurde ein Bit gesetzt? }
            begin                                { Ja, Ereignis festhalten }
              EvRec.StateKey := AktStatus xor NewKbS;     { Flag isolieren }
              if ( EvRec.StateKey <> KEY_INSERT ) then     { nicht INSERT? }
                begin                               { Nein, EVENT erzeugen }
                  EvRec.Ereignis := EV_KEY_STATUS;
                  KbmPutQueue( KbQueueP, EvRec );        {  Event in Queue }
                end;
            end
        end
      else                                    { Nein, keine StatusÑnderung }
        if ( KbPort < 128 ) then                              { Make-Code? }
          begin                                       { Ja, Event erzeugen }
            EvRec.Ereignis := EV_KEY_UNKNOWN;           { unbekannter Code }
            EvRec.ScanCode := KbPort;                { Scan-Code Åbergeben }
            EvRec.Status   := NewKbs;       { Status in Event-Record laden }
            KbmPutQueue( KbQueueP, EvRec );       { Event in Queue bringen }
          end;
      AktStatus := NewKbS;                  { neuen Tastatur-Status merken }
    end;
end;

{**************************************************************************}
{*  MouEventHandler: Wird vom Maustreiber Åber die Assembler-Routine      *}
{*                   AssHand aufgerufen, sobald ein Ereignis in Verbin-   *}
{*                   dung mit der Maus eintritt                           *}
{**----------------------------------------------------------------------**}
{*  Eingabe: EvFlags  = die Event-Mask                                    *}
{*           ButState = aktueller Status der Mausknîpfe                   *}
{*           X, Y     = die aktuelle Position des Maus-Cursors in Bezug   *}
{*                      auf den Textbildschirm                            *}
{**************************************************************************}

procedure MouEventHandler( EvFlags, ButState, x, y : integer );

var NeuS,                               { neue Koordinate des Maus-Cursors }
    NeuZ,                               { relativ zum neuen Bereich        }
    NeuBer : byte;                             { Nummer des neuen Bereichs }
    EvData : EVENT;                            { das eingetretene Ereignis }
    Ticks  : longint;                     { nimmt die aktuelle Uhrzeit auf }
    i,                                                   { SchleifenzÑhler }
    Mask   : integer;                                          { Bit-Maske }

begin
  Ticks := Time;                                              { Zeit holen }
  NeuBer  := BufPtr^[ y * TCol + x ];                      { Bereich holen }
  if ( NeuBer = KEIN_BEREICH ) then                    { nicht in Bereich? }
    begin                        { Ja, Bezugspunkt ist gesamter Bildschirm }
      NeuZ := y;
      NeuS := x;
    end
  else                    { Nein, Bezugspunkt ist obere linke Bereichsecke }
    begin
      NeuZ := y - AktBerPtr^[ NeuBer ].y1;
      NeuS := x - AktBerPtr^[ NeuBer ].x1;
    end;

{----- Die einzelnen Ereignisse separat als ein EVENT-Record erfassen ------}

  Mask := 1;                                    { mit Event-Bit 0 beginnen }
  with EvData do                                   { Event-Record erzeugen }
    begin
      Zeit      := Ticks;                { Daten in das Event-Record laden }
      Buttons   := ButState;
      Bereich   := NeuBer;
      ZeileRel  := NeuZ;
      SpalteRel := NeuS;
      ZeileAbs  := y;
      SpalteAbs := x;
   end;

  for i:=0 to 4 do             { die einzelnen Bits in EvFlags durchlaufen }
    begin
      if not((EvFlags and Mask = 0) or
             ((Mask = EV_MOU_MOVE) and ((x = AktX) and (y = AktY)))) then
        begin
         EvData.Ereignis := Mask;                { Ereignis-Code speichern }
         KbmPutQueue( MouQueueP, EvData );  {Event-Record in der Queue abl.}
       end;
      Mask := Mask shl 1;                 { nÑchstes Event-Bit verarbeiten }
    end;

  {-- neue Mausdaten in globalen Variablen merken -------------------------}

  AktX := x;                                           { neue Mausposition }
  AktY := y;
  AktBut := ButState;                       { Status der Mausknîpfe merken }
  AktBer := NeuBer;                             { neuen Mausbereich merken }
end;

{**************************************************************************}
{*  KbmEventWait: wartet auf den Eintritt eines bestimmten Ereignisses in *}
{*                Verbindung mit der Maus oder der Tastatur               *}
{**----------------------------------------------------------------------**}
{*  Eingabe: WAIT_EVENT = Bitmaske, die die zu erwartenden Ereignisse     *}
{*                        spezifiziert                                    *}
{*           EV_REC     = Event-Record, in dem Informationen Åber das     *}
{*                        eingetretene Ereignis zurÅckgeliefert werden.   *}
{*  Info:    - WAIT_EVENT kann durch ODER VerknÅpfung der verschie-       *}
{*             denen Konstanten wie EV_MOU_MOVE, EV_LEFT_PRESS etc.       *}
{*             erstellt werden                                            *}
{*           - Die Prozedur kehrt erst zum Aufrufer zurÅck, wenn eines    *}
{*             der angegebenen Ereignisse eingetreten ist. Ereignisse,    *}
{*             die in der Zwischenzeit eintreten, aber nicht erwartet     *}
{*             werden, werden verworfen.                                  *}
{*           - Diese Funktion darf rekursiv aufgerufen werden, so da·     *}
{*             sich ein innerhalb dieser Funktion aufgerufener Event-     *}
{*             Handler des Anwendungsprogramms wiederum dieser Funktion   *}
{*             bedienen kann.                                             *}
{**************************************************************************}

procedure KbmEventWait( WaitEvent : integer; var EvRec : EVENT );

var AktEvent : EVENT;                       { nimmt das aktuelle Event auf }
    Index    : byte;                  { Index in die Event-Handler-Tabelle }
    TestEvent: Event;

begin
  {AktEvent:=Evrec;
  KbmPeekEvent(Testevent);}
  {If (AktBut = 0) or (Testevent.ereignis>0) then
  begin}
    repeat                                   { auf passendes Ereignis warten }
      KbmGetEvent( AktEvent );                              { Ereignis holen }
      {-- Handler des Anwendungsprogramms aufrufen --------------------------}

      Index := KbmIGetIndex( AktEvent.Ereignis );    { Index in Tabelle erm. }
      if ( HandTab[ Index ].Call ) then               { Handler installiert? }
        HandTab[ Index ].Handler( AktEvent );                  { Ja, aufrufen }

      {If Aktbut >0 then delay(50);}
    until ( AktEvent.Ereignis and WaitEvent <> 0 );
  {end; else
    delay(50);}
  EvRec := AktEvent;                         { Event an Aufrufer Åbergeben }
end;

{**************************************************************************}
{*  KbmRegisterHandler : registriert einen Handler des Anwendungspro-     *}
{*                       gramms fÅr ein bestimmtes Ereignis               *}
{**-----------------------------------------------------------------------*}
{*  Eingabe: EVENT   = die Event-Maske                                    *}
{*           HANDLER = der aufzurufende Handler                           *}
{**************************************************************************}

procedure KbmRegisterHandler( Event : word; Handler : EVENTHANDLER );

var i : byte;                             { Index in Event-Handler-Tabelle }

begin
  i := KbmIGetIndex( Event );                            { Index ermitteln }
  HandTab[ i ].Call := TRUE;                            { Handler aufrufen }
  HandTab[ i ].Handler := Handler;          { Zeiger auf Handler speichern }
end;

{**************************************************************************}
{*  KbmDeRegisterHandler : entfernt einen Handler des Anwendungsprogramms *}
{*                         fÅr ein bestimmtes Ereignis wieder             *}
{**-----------------------------------------------------------------------*}
{*  Eingabe: EVENT = die Event-Maske                                      *}
{**************************************************************************}

procedure KbmDeRegisterHandler( Event : word );

begin
  HandTab[ KbmIGetIndex( Event ) ].Call := FALSE;     { Handler nicht mehr }
end;                                                  { aufrufen           }

{**************************************************************************}
{*  MouPtrMask: fÅgt die Cursor- und Screen-Mask aus einer Bitmaske fÅr   *}
{*              das Zeichen und die Farbe zusammen                        *}
{**----------------------------------------------------------------------**}
{*  Eingabe: Zeichen = Bitmaske fÅr die Cursor- und Screen-Mask in Bezug  *}
{*                     auf das Zeichen                                    *}
{*           Farbe   = Bitmaske fÅr die Cursor- und Screen-Mask in Bezug  *}
{*                     auf die Farbe des Zeichens                         *}
{*  Ausgabe: die Cursor- und die Screen-Mask als ein Wert vom Typ PTRVIEW *}
{*  Info:    fÅr Zeichen und Farbe kînnen die Konstanten PtrSameChar,     *}
{*           PtrSameCol, PtrSameColB, PtrInvCol und PtrInvColB sowie die  *}
{*           Ergebnisse der Funktionen PtrDifChar und PtrDifCol Åbergeben *}
{*           werden                                                       *}
{**************************************************************************}

function MouPtrMask( Zeichen, Farbe  : word ) : PTRVIEW;

var Mask : PTRVIEW;             { die zu erstellen Cursor- und Screen-Mask }

begin
  PTRVREC( Mask ).ScreenMask := ( ( Farbe and $ff ) shl 8 ) +
                                ( Zeichen and $ff );
  PTRVREC( Mask ).CursorMask := ( Farbe and $ff00 ) + ( Zeichen shr 8 );
  MouPtrMask := Mask;                    { Maske an Aufrufer zurÅckliefern }
end;

{**************************************************************************}
{*  PtrDifChar: erstellt den Zeichenteil der Cursor- und Screen-Mask in   *}
{*              Bezug auf das Zeichen                                     *}
{**----------------------------------------------------------------------**}
{*  Eingabe: ASCII-Code des Zeichens, das den Maus-Cursor bilden soll     *}
{*  Ausgabe: Cursor- und Screen-Mask fÅr dieses Zeichen                   *}
{*  Info:    das Funktionsergebnis sollte mit Hilfe der Funktion          *}
{*           MouPtrMask weiterverarbeitet werden                          *}
{**************************************************************************}

function PtrDifChar( Zeichen : byte ) : word;

begin
  PtrDifChar := Zeichen shl 8;
end;

{**************************************************************************}
{*  PtrDifCol: erstellt den Zeichenteil der Cursor- und Screen-Mask in    *}
{*             Bezug auf die Farbe des Maus-Cursors                       *}
{**----------------------------------------------------------------------**}
{*  Eingabe: Farbe des Zeichens, das den Maus-Cursor bilden soll          *}
{*  Ausgabe: Cursor- und Screen-Mask fÅr diese Farbe                      *}
{*  Info:    das Funktionsergebnis sollte mit Hilfe der Funktion          *}
{*           MouPtrMask weiterverarbeitet werden                          *}
{**************************************************************************}

function PtrDifCol( Farbe : byte ) : word;

begin
  PtrDifCol := Farbe shl 8;
end;

{**************************************************************************}
{*  MouDefinePtr: öbergibt dem Maustreiber die Cursor- und Screen-Mask,   *}
{*                die fortan das Erscheinungsbild des Maus-Cursors be-    *}
{*                estimmen soll                                           *}
{**----------------------------------------------------------------------**}
{*  Eingabe: Mask = die Cursor- und Screen-Mask als ein Paramter vom      *}
{*                  Typ PTRVIEW                                           *}
{*  Info:    - der Parameter Mask sollte mit Hilfe der Funktion           *}
{*             MouPtrMask erstellt worden sein                            *}
{*           - die hîherwertigen 16-Bit von Mask reprÑsentieren die       *}
{*             Screen-Mask, die niederwertigen 16 Bit die Cursor-Mask     *}
{**************************************************************************}

procedure MouDefinePtr( Mask : PTRVIEW );

var Regs : Registers;              { Prozessorregister fÅr Interruptaufruf }

begin
  Regs.AX := $000a;                   { Fktnr. fÅr "Set text pointer type" }
  Regs.BX := 0;                               { Software-Cursor einstellen }
  Regs.CX := PTRVREC( Mask ).ScreenMask;           { Lo-Word ist AND-Maske }
  Regs.DX := PTRVREC( Mask ).CursorMask;           { Hi-Word ist XOR-Maske }
  Intr( $33, Regs);                                { Maus-Treiber aufrufen }
end;

{**************************************************************************}
{*  MouDefBereich: erlaubt die Registrierung verschiedener Bildschirmbe-  *}
{*                 reiche, die als unterschiedliche Mausbereiche erkannt  *}
{*                 werden                                                 *}
{**----------------------------------------------------------------------**}
{*  Eingabe: Anzahl = Anzahl der Bildschirmbereiche                       *}
{*           BPtr   = Zeiger auf das Array, in dem die einzelnen          *}
{*                    Bereiche als jeweils eine Struktur vom Typ          *}
{*                    BEREICH beschrieben werden                          *}
{*  Info:    - den freibleibenden Bildschirmbereichen wird der Code       *}
{*             KEIN_BEREICH zugeordnet                                    *}
{**************************************************************************}

procedure MouDefBereich( Anzahl : byte; BPtr : BERPTR );

var AktBer,                                { Nummer des aktuellen Bereichs }
    Bereich : byte;                                      { SchleifenzÑhler }

begin
  AktBerPtr^ := BPtr^;                          { Pointer auf Vektor und An- }
  AnzBereiche := Anzahl;                      { zahl der Bereiche merken   }
  FillChar( BufPtr^, BLen, KEIN_BEREICH );    { alle Elemente=KEIN_BEREICH }
  for Bereich:=0 to anzahl-1 do       { die einzelnen Bereiche durchlaufen }
   with BPtr^[ Bereich ] do
     KbmIBufFill( x1, y1, x2, y2, Bereich );

  AktBer := BufPtr^[ AktY * TCol + AktX ];        { akt. Bereich ermitteln }
end;

{**************************************************************************}
{*  MouShowMouse: bringt den Maus-Cursor auf den Bildschirm               *}
{**----------------------------------------------------------------------**}
{*  Info: die Aufrufe von MouShowMouse und MouHidemOuse mÅssen ausbala-   *}
{*        ciert sein, damit sie Wirkung zeigen                            *}
{**************************************************************************}

procedure MouShowMouse;

var Regs : Registers;              { Prozessorregister fÅr Interruptaufruf }

begin
  Regs.AX := $0001;                             { Fktnr.: fÅr "Show Mouse" }
  Intr( $33, Regs );                               { Maus-Treiber aufrufen }
end;

{**************************************************************************}
{*  MouHideMouse: entfernt den Maus-Cursor vom Bildschirm                 *}
{**----------------------------------------------------------------------**}
{*  Info: die Aufrufe von MouShowMouse und MouHideMouse mÅssen ausbalan-  *}
{*        ciert sein, damit sie Wirkung zeigen                            *}
{**************************************************************************}

procedure MouHideMouse;

var Regs : Registers;              { Prozessorregister fÅr Interruptaufruf }

begin
  Regs.AX := $0002;                              { Fktnr. fÅr "Hide Mouse" }
  Intr( $33, Regs);                                { Maus-Treiber aufrufen }
end;

{**************************************************************************}
{*  MouSetMoveArea: legt den Bewegungsbereich fÅr den Maus-Cursor fest    *}
{**----------------------------------------------------------------------**}
{*  Eingabe:  x1, y1 = Koordinate der oberen linken Bereichsecke          *}
{*            x2, y2 = Koordinate der unteren rechten Bereichsecke        *}
{*  Info:    - Die Ordinaten beziehen sich auf den Textbildschirm und     *}
{*             nicht auf den virtuellen Grafikbildschirm des Maustreibers *}
{**************************************************************************}

procedure MouSetMoveArea( x1, y1, x2, y2 : byte );

var Regs : Registers;              { Prozessorregister fÅr Interruptaufruf }

begin
  Regs.AX := $0008;                     { Fktnr. fÅr "Set vertical Limits" }
  Regs.CX := integer( y1 ) shl 3;               { Umrechnung in virtuellen }
  Regs.DX := integer( y2 ) shl 3;               { Mausbildschirm           }
  Intr( $33, Regs );                               { Maus-Treiber aufrufen }
  Regs.AX := $0007;                   { Fktnr. fÅr "Set horizontal Limits" }
  Regs.CX := integer( x1 ) shl 3;               { Umrechnung in virtuellen }
  Regs.DX := integer( x2 ) shl 3;               { Mausbildschirm           }
  Intr( $33, Regs );                               { Maus-Treiber aufrufen }
end;

{**************************************************************************}
{*  MouSetSpeed: legt das VerhÑltnis zwischen der Mausbewegung und der    *}
{*               daraus resultierenden Bewegung des Maus-Cursors fest     *}
{**----------------------------------------------------------------------**}
{*  Eingabe: XSpeed = Geschwindigkeit in X-Richtung                       *}
{*           YSpeed = Geschwindigkeit in Y-Richtung                       *}
{*  Info:    - Beide Parameter beziehen sich auf die Einheit Mickey/8 Px. *}
{**************************************************************************}

procedure MouSetSpeed( XSpeed, YSpeed : integer );

var Regs : Registers;              { Prozessorregister fÅr Interruptaufruf }

begin
  Regs.AX := $000f;                  { Fktnr. "Set mickeys to pixel ratio" }
  Regs.CX := XSpeed;
  Regs.DX := YSpeed;
  Intr( $33, Regs);                                { Maus-Treiber aufrufen }
end;

{**************************************************************************}
{*  MouMovePtr: bewegt den Maus-Cursor an eine neue Bildschirmposition    *}
{**----------------------------------------------------------------------**}
{*  Eingabe: COL = die neue Bildschirmspalte des Maus-Cursors             *}
{*           ROW = die neue Bildschirmzeile des Maus-Cursors              *}
{*  Info:    - Die Ordinaten beziehen sich auf den Textbildschirm und     *}
{*             nicht auf den virtuellen Grafikbildschirm des Maustreibers *}
{**************************************************************************}

procedure MouMovePtr( Col, Row : byte );

var Regs   : Registers;            { Prozessorregister fÅr Interruptaufruf }
    NeuBer : byte;                  { Bereich, in den die Maus bewegt wird }

begin
  Regs.AX := $0004;                  { Fktnr. "Set mouse pointer position" }
  AktX := col;                                    { Koordinate in globalen }
  AktY := row;                                    { Variablen speichern    }
  Regs.CX := integer( col ) shl 3;          { Koordinaten umrechnen und in }
  Regs.DX := integer( row ) shl 3;          { globalen Variablen speichern }
  Intr( $33, Regs );                               { Maus-Treiber aufrufen }

  AktBer := BufPtr^[ Row * TCol + Col ];         { neuen Bereich ermitteln }
end;


procedure KbClrevent;
begin
  KbQueueP^.Next := 1;                      { noch kein Event in der Queue }
  KbQueueP^.Last := 1;
  ev.Ereignis:=0;
end;

procedure MouClrevent;
begin
  MouQueueP^.Next := 1;                     { noch kein Event in der Queue }
  MouQueueP^.Last := 1;
  ev.Ereignis:=0; AktBut:=0;
end;


{**************************************************************************}
{*  KbmReleaseMode : Lîscht einen der Tastatur-Modi SCROLL-LOCK, NUM-LOCK *}
{*                   oder CAPS-LOCK                                       *}
{**-----------------------------------------------------------------------*}
{*  Eingabe: Modus = einer der Codes KEY_SCROLL_LOCK, KEY_CAPS_LOCK oder  *}
{*                   KEY_NUM_LCOK                                         *}
{*  Info   : Nur bei ATs und 386ern wird durch den Aufruf dieser Prozedur *}
{*           auch automatisch das entsprechende Tastatur-LED abgeschaltet.*}
{*           Bei XTs ist dies nicht mîglich.                              *}
{**************************************************************************}

procedure KbmReleaseMode( Modus : byte  );

var Regs : Registers;              { Prozessorregister fÅr Interruptaufruf }

begin
  BiosKbFlag := BiosKbFlag and ( Modus xor $FF );         { Bit ausblenden }
  Regs.AH := $02;                   { BIOS-Tastatur-Status abfragen, damit }
  intr( $16, Regs );                { das BIOS den neuen Status erkennt    }
end;

{**************************************************************************}
{*  KbmSetMode : Schaltet einen der Tastatur-Modi SCROLL-LOCK, NUM-LOCK   *}
{*               oder CAPS-LOCK an                                        *}
{**-----------------------------------------------------------------------*}
{*  Eingabe: Modus = einer der Codes KEY_SCROLL_LOCK, KEY_CAPS_LOCK oder  *}
{*                   KEY_NUM_LCOK                                         *}
{*  Info   : Nur bei ATs und 386ern wird durch den Aufruf dieser Prozedur *}
{*           auch automatisch das entsprechende Tastatur-LED angeschaltet.*}
{*           Bei XTs ist dies nicht mîglich.                              *}
{**************************************************************************}

procedure KbmSetMode( Modus : byte  );

var Regs : Registers;              { Prozessorregister fÅr Interruptaufruf }

begin
  BiosKbFlag := BiosKbFlag or Modus;                      { Bit einblenden }
  Regs.AH := $02;                   { BIOS-Tastatur-Status abfragen, damit }
  intr( $16, Regs );                { das BIOS den neuen Status erkennt    }
end;




{**************************************************************************}
{*  KbmEnd: wird zur Beendigung der Arbeit mit den Funktionen und Proze-  *}
{*          duren aus dem Maus-Modul aufgerufen                           *}
{**----------------------------------------------------------------------**}
{*  Info:   - Die Prozedur mu· vom Anwendungsprogramm nicht explizit auf- *}
{*            gerufen werden, da die Funktion KbmInit sie als Exit-Proze- *}
{*            dur definiert                                               *}
{**************************************************************************}

{$F+}               { mu· FAR sein, damit Aufruf als Exit-Prozedur mîglich }


procedure KbmEnd(ende:boolean);

var Regs : Registers;              { Prozessorregister fÅr Interruptaufruf }

begin
  MouHideMouse;                     { Maus-Cursor vom Bildschirm entfernen }
  Regs.AX := 0;                                  { Reset des Maus-Treibers }
  Intr( $33, Regs);                                { Maus-Treiber aufrufen }

  Dispose( KbQueueP );                    { Tastatur-Queue wieder auflîsen }
  Dispose( MouQueueP );                       { Maus-Queue wieder auflîsen }

  FreeMem( BufPtr, BLen );         { allokierten Speicher wieder freigeben }
  FreeMem( AktBerptr, SizeOf( Berarray )+1);
  SetIntVec( $09, OldKBHandler );    { alten Tastatur-Handler restaurieren }
  If ende then
    ExitProc := ExitOld;          { wieder alte Exit-Prozedur installieren }
end;


{$F-}                                          { keine FAR-Prozeduren mehr }

{**************************************************************************}
{*  KbmInit: leitet die Arbeit mit den verschiedenen Funktionen und Pro-  *}
{*           zeduren des Maus-Moduls ein und initialisiert die verschie-  *}
{*           denen Variablen                                              *}
{**------------------------------------------------------------------------}
{*  Eingabe: Spalten = Anzahl der Bildschrimspalten                       *}
{*           Zeilen  = Anzahl der Bildschirmzeilen                        *}
{**************************************************************************}

procedure KbmInit( Spalten, Zeilen : byte );

var Regs   : Registers;            { Prozessorregister fÅr Interruptaufruf }
    i    : byte;                    { SchleifenzÑhler als Index in HandTab }

begin

  {-- neuen Tastatur-Handler installieren----------------------------------}

  AktStatus := BiosKbFlag;                    { BIOS-Tastatur-Status laden }

  GetIntVec( $09, OldKBHandler );      { Adresse des Int-09-Handlers holen }
  SetIntVec( $09, @NewKbHandler );            { neuen Handler installieren }

  TLine := Zeilen;                         { Anzahl Zeilen- und Spalten in }
  TCol  := Spalten;                        { globalen Variablen speichern  }

  {-- Puffer fÅr Maus-Bereiche allokieren und fÅllen ----------------------}

  BLen := TLine * TCol;                 { Anzahl der Zeichen im Bildschirm }
  GetMem( BufPtr, BLen );            { internen Bereichs-Puffer allokieren }
  KbmIBufFill( 0, 0, TCol-1, TLine-1, KEIN_BEREICH );

  Regs.AX := 0;                             { Mouse-Treiber initialisieren }
  Intr( $33, Regs );                               { Maus-Treiber aufrufen }
  MouAvail := ( Regs.AX = $ffff );                       { Maus verfÅgbar? }

  AktBer := KEIN_BEREICH;                  { Maus-Cursor in keinem Bereich }
  AktX   := TCol + 1;                 { Position au·erhalb des Bildschirms }
  {new(AktBerptr);}
  GetMem( AktBerptr, SizeOf( Berarray )+1);
  {-- die Maus- und Tastatur-Queue anlegen und initialisieren -------------}

  New( KbQueueP );                           { die Tastatur-Queue erzeugen }
  KbQueueP^.Next := 1;                      { noch kein Event in der Queue }
  KbQueueP^.Last := 1;

  New( MouQueueP );                              { die Maus-Queue erzeugen }
  MouQueueP^.Next := 1;                     { noch kein Event in der Queue }
  MouQueueP^.Last := 1;

  for i := 1 to 16 do       { noch kein Anwender-Event-Handler installiert }
   HandTab[ i ].Call := FALSE;

  if ( MouAvail ) then                        { ist eine Maus installiert? }
    begin                                                             { Ja }
      MouSetMoveArea( 0, 0, TCol-1, TLine-1 );    { Bewegunsbereich setzen }

      AktX     := KbmIGetX;                     { aktuelle Mausposition in }
      AktY     := KbmIGetY;                     { globale Variablen laden  }

      {-- den Maus-Event-Handler NewMouHandler installieren ---------------}

      Regs.AX := $000C;                   { Fktnr. fÅr "Set Mouse Handler" }
      Regs.CX := EV_MOU_ALL;                           { Event-Maske laden }
      Regs.DX := Ofs( NewMouHandler );        { Offsetadresse des Handlers }
      Regs.ES := Seg( NewMouHandler );       { Segmentadresse des Handlers }
      Intr( $33,  Regs );                          { Maus-Treiber aufrufen }
    end;
end;

{**----------------------------------------------------------------------**}
{** Startcode der Unit                                                   **}
{**----------------------------------------------------------------------**}

begin
  CrtXMax := Succ(lo(WindMax));
  CrtYMax := Succ(hi(WindMax));
  KbmInit( CrtXmax, CrtYmax );                     { die Unit intialisieren }
  ExitOld := ExitProc;                  { Adresse der Exit-Prozedur merken }
  ExitProc := @KbmEnd;               { KbmEnd als Exit-Prozedur definieren}
end.
