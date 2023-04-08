unit tkwin;
Interface
uses crt,kbm,tkstring,Tkvideo;

const
      Fenanz    : byte = 0;

      Fenfo     : byte=blue;
      Fenba     : byte=cyan;

      Fen2fo    : byte=white;
      Fen2ba    : byte=red;

Type
     VEL      = record                 { beschreibt eine Zeichen-Attribut- }
                  case boolean of      { Kombination im Video-RAM          }
                    true  : ( Zeichen, Attribut : byte );
                    false : ( Inhalt            : word );
                end;

     VPTR     = ^VEL;                    { Zeiger auf ein Zeichen/Attribut }


     PTRREC   = record                         { dient dem Zugriff auf die }
                  Ofs : word;                  { Bestandteile eines belie- }
                  Seg : word;                  { bigen Pointers            }
                end;


     WinState = record
           x1,y1,x2,y2     : Byte;
           WindMin,WindMax : Word;
           WhereX, WhereY  : Byte;
           Beranz          : Byte;
           Ber             : Berarray;
     end;



    WinRecPtr = ^WinRec;            {Pointer-Typ fÅr Window}

    WinRec = record
           Next  : WinRecPtr;
           State : WinState;
           Puffer: word;
          end;



const
   linw  = 'ƒ';
   lins  = '≥';
   ole   = '⁄';
   ore   = 'ø';
   ule   = '¿';
   ure   = 'Ÿ';
   brl   = '√';
   brr   = '¥';
   bro   = '¬';
   bru   = '¡';

   dlinw  = 'Õ';
   dlins  = '∫';
   dole   = '…';
   dore   = 'ª';
   dule   = '»';
   dure   = 'º';
   dbrl   = '∆';
   dbrr   = 'µ';
   dbro   = '—';
   dbru   = 'œ';

   blinwo ='‹';
   blinwu ='ﬂ';
   blinsr ={'ﬁ'}'€';
   blinsl ={'›'}'€';

   ShadowX : byte=1;
   ShadowY : byte=1;

   VerX : byte = 0;
   VerY : byte = 1;


 var
     Topwindow: WinRecPtr;
     W        : WinRecPtr;
     Map      : Berptr;
     vioseg   : word;
 {-Schreibt einen String an eine vorgegebene X/Y-Bildschirmpos.}
PROCEDURE WriteXY(x,y:Integer; st: string);
 {-Lîscht den Bildschirm unter BerÅksichtigung der Maus}
PROCEDURE Winclrscr;
 {-Zeichnet einen einfachen oder doppelten Rahmen}
PROCEDURE WinFrame(x1,y1,x2,y2: byte; Rahmen:boolean);
 {-Restauriert den Hintergrund eines Fenster}
PROCEDURE Restwindow;
 {-Speichert den Hintergrund eines Fenster}
FUNCTION Savewin(x1,y1,x2,y2:byte) : boolean;
 {-ôffnet ein Fenster}
FUNCTION Openwindow (Lange,Breite:byte;farbevor,farbehin:byte;kopf:Message): boolean;
 {-Schlie·t ein Fenster}
PROCEDURE Closewindow;
 {-Fehlermeldung bei Heaperror}
Procedure HErrorMsg;

Implementation


{============== Fehlerbehandlung Heap-Error =============}
{$F+}
Function HError(Size : Word) : Integer;
Begin
  HError := 1;
End;
{$F-}


procedure writeXY(x,y:Integer; st: string);
var aktP  :boolean;
begin
  gotoxy(x,y);
  If (Lo(windmin)+X+length(st) > aktX+1) and
     (Lo(windmin)+X <= aktX+1) and
     (Hi(windmin)+Y = aktY+1) then
       aktP:=true
      else aktP:=false;
  If aktP then MouHideMouse; write(st);
  If aktP then MouShowMouse;
end;


procedure Winclrscr;
begin
  MouHideMouse;
  clrscr;
  MouShowMouse;
end;

procedure WinFrame(x1,y1,x2,y2: byte; Rahmen:boolean);
var i : byte;
    wlinw,wlins,
    wole,wore,wule,wure:string[1];
begin
  If Rahmen then
  begin
   wlinw:=dlinw;
   wlins:=dlins;
   wole:=dole;
   wore:=dore;
   wule:=dule;
   wure:=dure;
  end else
  begin
   wlinw:=linw;
   wlins:=lins;
   wole:=ole;
   wore:=ore;
   wule:=ule;
   wure:=ure;
  end;
  writexy(x1,y2,wule);
  writexy(x2,y1,wore);
  writexy(x1,y1,wole);
  writexy(x2,y2,wure);
  for i:=1 to (y2-y1)-1 do
  begin
    writexy(x1,y1+i,wlins);
    writexy(x2,y1+i,wlins);
  end;
  writexy(x1+1,y1,padch('',wlinw[1],(x2-x1)-1));
  writexy(x1+1,y2,padch('',wlinw[1],(x2-x1)-1));
end;


{-------------------------------------------------------------------------}
function GetVioPtr( Spalte, Zeile : byte ) : VPTR;
begin
  GetVioPtr := Ptr( VioSeg, ( Crtxmax * Zeile + Spalte ) shl 1);
end;

{-------------------------------------------------------------------------}

procedure GetScr( x1, y1, x2, y2 : byte; BufPtr : pointer );
var nbytes : integer;                      { zu kopierende Bytes pro Zeile }

begin
  MouHideMouse;
  nbytes := ( x2 - x1 + 1 ) shl 1;                       { Bytes pro Zeile }
  while y1 <= y2 do                     { die einzelnen Zeilen durchlaufen }
    begin
      Move( GetVioPtr(x1, y1)^, BufPtr^, nbytes);
      inc( PTRREC( BufPtr ).Ofs, nbytes );
      inc( y1 );                             { Y1 auf nÑchste Zeile setzen }
    end;
  MouShowMouse;
end;

{-------------------------------------------------------------------------}

procedure PutScr( x1, y1, x2, y2 : byte; BufPtr : pointer );
var nbytes : integer;                      { zu kopierende Bytes pro Zeile }

begin
  MouHideMouse;
  nbytes := ( x2 - x1 + 1 ) shl 1;                       { Bytes pro Zeile }
  while y1 <= y2 do                     { die einzelnen Zeilen durchlaufen }
    begin
      Move( BufPtr^, GetVioPtr(x1, y1)^, nbytes);
      inc( PTRREC( BufPtr ).Ofs, nbytes );
      inc( y1 );                             { Y1 auf nÑchste Zeile setzen }
    end;
  MouShowMouse;
end;

{-------------------------------------------------------------------------}

procedure WinShadow( x, y: byte);

var Attribut : byte;              { das jeweils zu manipulierende Attribut }
    i        : byte;

begin
  if OrigMode<>7 then                            { im Color-Modus? }
      begin
        Attribut := mem[schirmanfang:((y-1)*crtxmax+x)*2-1] ;    { Attribut des Zeichens holen }
        {-- die Hintergrundfarbe verÑndern ----------------------------}
        if Attribut and 128 <> 0 then            { heller Hintergrund? }
         Attribut := Attribut and 128          { Ja, Bit 7 ausblenden }
        else                              { Nein, normaler Hintergrund }
         Attribut := Attribut and 15;     { Hintergrund jetzt schwarz }
        {-- die Vordergrundfarbe verÑndern ----------------------------}
        if Attribut and 8 <> 0 then              { heller Vordergrund? }
         Attribut := Attribut and (255 - 8);   { Ja, Bit 3 ausblenden }
        mem[schirmanfang:((y-1)*crtxmax+x)*2-1]:=Attribut;
      end
     else                                          { Nein, im Monochrom-Modus }
       mem[schirmanfang:((y-1)*crtxmax+x)*2-2]:=ord( '±' );
end;

{-------------------------------------------------------------------------}

function savewin(x1,y1,x2,y2:byte) : boolean;
var  BufLen : integer;                          { LÑnge des Fenster-Puffers }

begin
   BufLen := ( (x2+ShadowX) - x1 + 3 ) * ( (y2+ShadowY) - y1 + 3 ) shl 1;
   GetMem( W, BufLen + SizeOf( Winrec ) - 1 );
   If W=NIL then
   begin
     HErrorMsg; savewin:=false; exit;
   end else
     savewin:=true;
   {EndIF}
   with W^ do
   begin
     Next:=Topwindow;
     State.x1:=x1;
     State.y1:=y1;
     State.x2:=x2;
     State.y2:=y2;
     State.WindMin:=WindMin;
     State.WindMax:=WindMax;
     State.WhereX :=WhereX;
     State.WhereY :=WhereY;
     State.Beranz :=AnzBereiche;
     State.Ber    :=Map^;
     GetScr( x1-2, y1-2, x2+ShadowX, y2+ShadowY, @Puffer );
   end;
   Anzbereiche:=1;
   TopWindow:=W;
end;


{-------------------------------------------------------------------------}
procedure restwindow;
 var
     buf    : word;
     z      : byte;
begin
   If Topwindow<>nil then
   begin
     W:=Topwindow;
     with W^ do
     begin
       PutScr( State.x1-2,State.y1-2,State.x2+ShadowX,State.y2+ShadowY, @Puffer );
       TopWindow := Next;
       Window(lo(w^.State.Windmin)+1,hi(w^.State.Windmin)+1,
              lo(w^.State.Windmax)+1,hi(w^.State.Windmax)+1 );
       gotoxy(WhereX,WhereY);
       buf:=( (State.x2+ShadowX) - State.x1 + 3)  * ( (State.y2+ShadowY) - State.y1 + 3 ) shl 1;
       Map^:=w^.State.Ber;
       MouDefBereich(w^.State.Beranz,Map);
       FreeMem( W,( (State.x2+ShadowX) - State.x1 + 3)  * ( (State.y2+ShadowY) - State.y1 + 3 )
                shl 1 + SizeOf(WINREC) - 1);
     end;
   end;

end;

{-------------------------------------------------------------------------}
procedure winopenshadow (x1,y1,x2,y2: byte);
var i,s : byte;

begin
  MouHideMouse;
  for i:=y1+ShadowY-1 to y2+ShadowY+1 do
  begin
    for s:=1 to ShadowX do
      Winshadow(x2+s+1,i);
  end;
  for i:=x1+ShadowX-1 to x2+ShadowX do
  begin
    for s:=1 to ShadowY do
      Winshadow(i,y2+s+1);
  end;
  MouShowMouse;
end;


{-------------------------------------------------------------------------}
procedure PaintRahmen(x1,y1,x2,y2: byte;farbevor,farbehin:byte;kopf:Message);
var l  :byte;

begin
  textbackground(farbehin);textcolor(farbevor);
  winframe(x1-1,y1-1,x2+1,y2+1,true);
  window(x1,y1-1,x2,y2);
  writexy((((x2-x1+3) Div 2)-(length(kopf)+2) Div 2),1,concat(' ',kopf,' '));
  window(x1,y1,x2,y2);
  winclrscr;
  gotoxy(1,1);
end;


{-------------------------------------------------------------------------}
function openwindow (Lange,Breite:byte;farbevor,farbehin:byte;kopf: Message) :boolean;
var x1,y1,x2,y2 : byte;

begin
    x1:=(Crtxmax Div 2) - (Lange Div 2)+VerX;
    x2:=x1+Lange;
    y1:=(Crtymax Div 2) - (Breite Div 2) + VerY;
    y2:=y1+Breite;
    If not savewin (x1,y1,x2,y2) then
    begin
      openwindow:=false; exit;
    end else
      openwindow:=true;
    window(1,1,CrtXmax,CrtYmax);
    PaintRahmen(x1,y1,x2,y2,farbevor,farbehin,Kopf);
    If (Crtxmax>(x2+ShadowX)) and (Crtymax>(y2+ShadowY)) then
      winopenshadow (x1,y1,x2,y2);
    window(x1,y1,x2,y2); inc(fenanz); gotoxy(1,1);
    Map^[fenanz].x1:=x1-1; Map^[fenanz].y1:=y1-1;Map^[fenanz].x2:=x2-1; Map^[fenanz].y2:=y2-1;
    MouDefBereich(fenanz+1,Map);
    {MouSetMoveArea( x1-1, y1-1, x2-1, y2-1);}
end;


{-------------------------------------------------------------------------}
procedure closewindow;
begin
  restwindow; ev.Ereignis:=0; dec(fenanz);
end;



{============== Fehlermeldung bei Heap-Error =============}
Procedure HErrorMsg;
Var
  OldWindMax, OldWindMin : Word;
  OldAttr                : Byte;
  Buffer                 : Array[1..264] of Byte;

Begin
  {---------------- Statuszeile retten -----------}
  OldWindMax := WindMax; OldWindMin := WindMin;
  OldAttr := TextAttr;
  GetScr(0,CrtYmax-1,CrtXmax-1,CrtYmax-1,@Buffer);
  {---------------- Meldung ausgeben --------------}
  Window(1, CrtYMax, CrtXMax, CrtYMax);
  TextAttr := Red*16+Yellow; MouHideMouse; ClrScr; MouShowMouse;
  WriteXY(10, 1, 'Nicht genug Speicher fÅr das Programm !          <beliebige Taste>');
  KbClrevent;  KbmEventWait( EV_KEY_ALL, ev ); KbClrevent;
  {--------- Statuszeile wiederherstellen --------------------}
  PutScr( 0, CrtYmax-1, CrtXmax-1, CrtYmax-1, @Buffer );
  TextAttr := OldAttr;
  WindMin := OldWindMin; WindMax := OldWindMax;
End;



begin
   HeapError := @HError;            {Behandlung von Heap-Fehlern}
   CheckBreak:=false;
   GetMem( Map, SizeOf( Berarray )+1);
   Map^[0].x1:=0; Map^[0].y1:=0;Map^[0].x2:=CrtXmax-1;  Map^[0].y2:=CrtYmax-1;
   MouDefBereich(1,Map);
   Vioseg:=schirmanfang;
end.