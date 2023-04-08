unit TkView;

Interface

uses Crt,TKsaa,Kbm,Tkstream,Tkstring,TKwin,TKvideo;



const Scrollfo : Byte = yellow;
      Scrollba : Byte = green;

      Balkenback : Byte = black;

      ActSelfo : Byte = white;
      ActSelba : Byte = black;
      Selfo    : Byte = black;

      yCol     : Byte = yellow;
      wCol     : Byte = white;

Type
  OutString = String[90];
  HeapString= ^OutString;

  HeapLine=  ^HeapLT;
  HeapLT  =  Record
               S            : HeapString;
               Mark         : Boolean;
               Jump         : Word;
               X, length    : byte;
               PPred, PNext : HeapLine;
             End;

  CrossLine= ^CrossLT;
  CrossLT  = Record
                X            : byte;
                Y            : word;
                length       : byte;
                jump         : word;
                PPred, PNext : CrossLine;
             End;


  {---------- Objekt fÅr Laufleiste ---------------}
 LaufLeiste= Object
               Balkenf,
               Balkenb     : Byte;              {Balkenattribut}
               PosX, PosY  : Byte;              {Position oben}
               PosY2       : Byte;              {Y-Position unten}
               IndexPos    : Byte;              {BsPos. in der Laufleiste}
               LaufPos     : Byte;              {Pos in der Laufleiste}
               Lines       : Word;              {Anz. der Textzeilen}
               Mouse       : boolean;
               Constructor Init(XMin, YMin, YMax : Byte);
               Procedure   SetLines(L : Word);
               Procedure   OutLaufleiste;       {Aufbau d. Laufleiste}
               Procedure   SetLaufindex(L : Word); {setzen Schieberegler}
               Function    GetPos: Word; Virtual;  {Ret.akt. Zeile nach Maus-
                                                  event in der Laufleiste}
               Destructor  Done;
              End{Object LaufLeiste};

  {---------- Objekt zur Listenausgabe ------------}
  ListView0 = Object(LaufLeiste)
                Scrollf,Scrollb : Byte;
                StartLine   : HeapLine;          {Heapkette der Zeilen}
                PS, PSLast  : HeapLine;          {Anf. BS-Seite}
                AktLine     : Word;              {Nr. der aktuellen Zeile}
                X1,Y1,X2,Y2 : Byte;              {Koordinaten Ausgabefenster}
                OK          : Boolean;           {False ==> Fehler}
                CtrlCode    : Word;
                Constructor Init(XMin,YMin,XMax,YMax : Byte);
                Procedure AppendLine(S : OutString; X,leng : byte; jump: word); Virtual;
                Procedure   SortListe(Pos :byte); Virtual;
                Procedure OutLine(P: HeapLine; Y, Attr : Byte); {intern}
                Procedure   OutListe; Virtual;   {Ausg. aktuelle Seite}
                Procedure   LineUp;   Virtual;
                Procedure   LineDown; Virtual;
                Procedure   LinePgUp; Virtual;
                Procedure   LinePgDn; Virtual;
                Procedure   LineTop;  Virtual;
                Procedure   LineLast; Virtual;
                Procedure   SetLinePS(L : Word); Virtual;
                Procedure   CtrlLines;  Virtual;
                Procedure   ViewLines; Virtual;  {Anzeige. mit Rollen}
                Function    IsOK : Boolean;      {Fehlertest + Reset OK}
                Function    GetLine(L:Word) : OutString; Virtual;
                Function    GetLineNumber : Word; {Ret.Nr.d.selektierten Z.}
                Procedure   ClrLine (L:Word);
                Procedure   ClrListe; Virtual;   {Heapkette lîschen}
                Destructor  Done;
              End{Object ListView0};


  {--------- Objekt zur Auswahl aus einer Liste ----------}

  SelectView0 = Object(Listview0)
                 SetBalken  : Boolean;

                 DKlick,
                 SelEnde    : Boolean;
                 SelectPtrOld,
                 SelectPtr  : HeapLine;          {Ptr. auf ausgew. Zeile}
                 MarkActive : boolean;
                 SelectLineOld,
                 SelectLine : Word;              {Nr.d.ausgew. Zeile,
                                                  0 ==> Keine ausgew.}
                 Constructor Init(XMin,YMin,XMax,YMax,Scrba : Byte);
                 Procedure OutLine(P: HeapLine; Y:byte; sel:boolean); {intern}
                 Procedure OutListe;  Virtual;
                 Procedure OutBalken; Virtual;
                 Procedure LineUp;    Virtual;
                 Procedure LineDown;  Virtual;
                 Procedure LineTop;   Virtual;
                 Procedure LineLast;  Virtual;
                 Procedure LinePgUp;  Virtual;
                 Procedure LinePgDn;  Virtual;
                 Procedure SetLinePS(L : Word); Virtual;
                 Procedure CtrlLines; Virtual;
                 Procedure ViewLines; Virtual;   {Anzeige. mit Rollbalken}
                 Procedure SetMarkMode(A: Boolean);
                 Procedure Mark;
                 Procedure WrXY(X,Y: byte; S: string; sele : boolean);
                 Procedure AppendHelp(S: OutString; jump: word);
                 Function  GetJumpNumber : Word; {Ret.Jump.d.selektierten Z.}
                 Function  GetLineNumber : Word; {Ret.Nr.d.selektierten Z.}
                 Function  GetSelLine    : OutString;{Ret. selektierte Zeile}
                 Procedure DelLine;
                 Procedure ClrListe;  Virtual;
                 Destructor Done;
              End{SelectView0};

   Selectview1=Object(Selectview0)
                Procedure AppendStr (S : OutString);
                Function  GetLine(L:Word) : OutString; Virtual;
                Function  GetSelLine : Outstring;
      End{SelectView1};
{---------- Funktion zum Erkennen eines Doppelklick mit der Maus -----}
Function DoppelKlick : Boolean;

Implementation
{==============================================================}
const ti : longint =0;                {Variablen fÅr Doppelklick}
      ze : word    =0;


Function DoppelKlick : Boolean;
Begin
  Doppelklick:=false;
  If ev.ereignis=EV_Left_Press then
  begin
    If ((ev.Zeit-ti)<7) and (ev.zeilerel=ze) then
    begin
      Doppelklick:=true;
    end;
    ti:=ev.Zeit;
    ze:=ev.zeilerel;
  end;
end;


{------------------ Laufleiste ------------------------}

Constructor LaufLeiste.Init(XMin, YMin, YMax : Byte);
Begin
  PosX := XMin; PosY := YMin; PosY2 := YMax;
  IndexPos := 0; LaufPos:=1; Lines := 0;
End;


Procedure   LaufLeiste.SetLines(L : Word);
Begin
  Lines := L;
End;


Procedure LaufLeiste.OutLaufleiste;
Var
  I : Word;
Begin
   textcolor(Balkenf); textbackground(Balkenb);
   WriteXY(PosX, PosY, #24);
   For I := PosY+1 To PosY2-1 Do
     If I <> IndexPos+PosY then
       WriteXY(PosX, I, #177);
     {EndIF}
   {EndFor}
   WriteXY(PosX, PosY2, #25);
   SetLaufindex(LaufPos);
End;


Procedure LaufLeiste.SetLaufindex(L : Word);
Var
  I, MaxIX : Real;
  I2       : LongInt;
  diff     : byte;
Begin
    textcolor(Balkenf); textbackground(Balkenb);
    {----- neue Position berechnen -----}
    IF (Pred(Lines) > (PosY2-PosY)) and (Lines>0) Then Begin
      If (Lines-L) < (PosY2 - PosY) then
        diff := (PosY2 - PosY) -(Lines-L)
        else diff:=0;
      MaxIX := PosY2 - PosY - 2;
      I := ((MaxIX * Pred(L)) / Pred(Lines-(PosY2-PosY)+diff)) + 1;
    End
    Else
      I := 0
    {EndIF};
    I2 := Round(I);
    IF IndexPos <> I2 Then Begin
      {----- alten Laufindex lîschen -----}
      IF IndexPos <> 0 Then
        WriteXY(PosX, PosY+IndexPos, #177);
      {EndIF}
      IndexPos := I2;
      {----- neuen Laufindex setzen -----}
      IF IndexPos <> 0 Then
        WriteXY(PosX, PosY+IndexPos, #254);
      {EndIF}
    End{IF};
    LaufPos:=L;
End;


Function  LaufLeiste.GetPos : Word;
Var
  X, Y : Word;
  I, L, MaxIX : real;
  L2   : LongInt;
  OldIX: Byte;
  Label  Ende;
Begin
  GetPos := 0;
  {----- Mausklick in der Laufleiste -----}
  IF MouseEventInBox(EV_LEFT_PRESS, PosX, PosY, PosX, PosY) Then Begin
    Ev.CtrlCode := CUp; Mouse:=true; Goto Ende;
  End{IF};
  IF MouseEventInBox(EV_LEFT_PRESS, PosX, PosY2, PosX, PosY2) Then Begin
    Ev.CtrlCode := CDown; Mouse:=true; Goto Ende;
  End{IF};
  IF MouseEventInBox(EV_LEFT_PRESS, PosX, PosY+1, PosX, IndexPos+PosY-1) Then Begin
    Ev.CtrlCode := CPgUp; Mouse:=true; Goto Ende;
  End{IF};
  IF MouseEventInBox(EV_LEFT_PRESS, PosX, IndexPos+PosY+1, PosX, PosY2-1) Then Begin
    Ev.CtrlCode := CPgDn; Mouse:=true; Goto Ende;
  End{IF};
  {----- Laufindex mit der Maus ziehen ? -----}
  IF MouseEventinBox(EV_LEFT_PRESS, PosX, IndexPos+PosY, PosX, IndexPos+PosY)
  Then Begin
    While AktBut=1 Do Begin
      X := AktX+1; Y:=AktY+1;
      IF (X = PosX+lo(WindMin)) and (Y > PosY+hi(WindMin)) and
         (Y < PosY2+hi(WindMin)) Then Begin
        I := Y - hi(WindMin) - PosY-1;
        MaxIX := PosY2 - PosY - 2;
        L := ((I * Pred(Lines-(PosY2-PosY))) / MaxIX) + 1;
        L2 := Round(L);
        SetLaufindex(L2);
        GetPos := L2;
      End{IF};
    End{While};
  End;
  Ende :
End;


Destructor LaufLeiste.Done;
Begin
End;

{---------- Methoden Objekt zur Listenausgabe ------------}
Constructor ListView0.Init(XMin, YMin, XMax, YMax : Byte);
Begin
  LaufLeiste.Init(XMax, YMin, YMax);
  StartLine := NIL; PS := NIL; PSLast := NIL;
  AktLine := 0; OK := True; Scrollf:=Scrollfo; Scrollb:=Scrollba;
  X1 := XMin; Y1 := YMin; X2 := XMax; Y2 := YMax;
End;


Procedure ListView0.AppendLine(S : OutString; X,leng : byte; jump: word);
const AR : Acceptrec = ('  OK  ','','');
Var
  P, P1 : HeapLine;
  SH    : HeapString;
  Scut  : Outstring;
  CtrlAnz   : byte;
Begin
  Scut := S; CtrlAnz:=0;
  while pos('^',Scut) > 0 do
  begin
    delete(Scut,pos('^',Scut),2);
    inc(CtrlAnz);
  end;
  IF Length(Scut) >= (X2-X1) Then Begin             {Zeile zu lang ?}
  begin
    S[0] := Char(X2-X1-1+2*CtrlAnz);
    S[X2-X1+2*CtrlAnz] := #26;
  end;
  End{IF};
  SH := StringToHeap(S);
  New(P);                                        {Zeile ==> Heap}
  IF (P <> NIL) and (SH <> NIL) Then Begin       {Heap Error ?}
    P^.S := SH; P^.Mark  := False;
    P^.X := X;  P^.length:= leng; P^.jump:=jump;
    P^.PPred := NIL; P^.PNext := NIL; PSLast:=NIL;
    IF StartLine = NIL Then Begin                {1. Zeile ?}
      StartLine := P; PS := P;
      Lines := 1; AktLine := 1;
    End
    Else Begin
      P1 := StartLine;
      While P1^.PNext <> NIL Do P1 := P1^.PNext;
      P1^.PNext := P; P^.PPred := P1;
      Inc(Lines);
    End{IF};
  End
  Else Begin
    OK := False;
    IF P <> NIL Then Dispose(P);
    DisposeString(SH);
    IF IO_Error('Fehler bei Anzeige:', 'IOERROR.MSG',203,AR)=1 Then;
  End{IF};
End;



Procedure ListView0.SortListe (Pos : byte);
Var
  P    : HeapLine;
  SH   : HeapString;
  B    : Boolean;
  I,J  : Word;
  S1,S2: string;
Begin
  IF (StartLine <> NIL) and (StartLine^.PNext <> NIL)
  Then Begin
    For I:=1 To Pred(Lines) Do Begin
      P := StartLine;
      For J:=1 To Lines-I Do Begin
        S1:=StringFromHeap(P^.PNext^.S); delete(S1,1,Pos);
        S2:=StringFromHeap(P^.S);        delete(S2,1,Pos);
        IF CompUCString(S1, S2) = Less
        Then Begin
          SH := P^.PNext^.S; B := P^.PNext^.Mark;
          P^.PNext^.S := P^.S; P^.PNext^.Mark := P^.Mark;
          P^.S := SH; P^.Mark := B;
        End{IF};
        IF P^.PNext^.PNext <> NIL Then P := P^.PNext;
      End{For};
    End{For};
  End{IF};
End;


Procedure ListView0.OutLine(P: HeapLine; Y, Attr : Byte); {intern}
Var
  OAttr : Byte;
Begin
  OAttr := TextAttr; TextAttr := Attr;
  IF (P <> NIL) Then Begin
    IF P^.Mark Then WriteXY(X1, Y, '˚') Else WriteXY(X1, Y, ' ');
    WriteXY(X1+1, Y, Pad(StringFromHeap(P^.S), Pred(X2-X1)));
  End
  Else
    WriteXY(X1, Y, Pad('', X2-X1));
  {EndIF}
  TextAttr := OAttr;
End;


Procedure ListView0.OutListe;
Var
  PW : HeapLine;
  I  : Byte;
Begin
  IF (PS <> PSLast) or (PSLast = NIL) Then Begin
    PW := PS;
    For I := Y1 To Y2 Do Begin                   {von 1. letzte BS-Zeile}
      OutLine(PW, I, Scrollf);
      IF PW <> NIL Then PW:=PW^.PNext;
    End{FOR};
    PSLast := PS;
  End{IF};
End;


Procedure ListView0.LineUp;
Begin
  IF (StartLine <> NIL) and (PS^.PPred <> NIL) Then Begin
    PS := PS^.PPred; Dec(AktLine);
  End{IF};
End;


Procedure ListView0.LineDown;
Begin
  IF (StartLine <> NIL) and (PS^.PNext <> NIL) and (Lines>AktLine+Y2-Y1) Then Begin
    PS := PS^.PNext; Inc(AktLine);
  End{IF};
End;


Procedure Listview0.LinePgUp;
var z : byte;
begin
  For z:=Y1+1 To Y2 do Listview0.LineUp;
end;


Procedure Listview0.LinePgDn;
var z: byte;
begin
  For z:=Y1+1 To Y2 do Listview0.LineDown;
end;

Procedure ListView0.LineTop;
Begin
  PS := StartLine;
  IF StartLine <> NIL Then
  begin
    Laufpos:=1; AktLine := 1;
  end;
End;


Procedure ListView0.LineLast;
Var
  I : Byte;
Begin
  IF StartLine <> NIL Then
    For I:=AktLine to Lines do ListView0.LineDown;
  {EndIf}
End;


Procedure ListView0.SetLinePS(L : Word);
Begin
  IF L > 0 Then Begin
    ListView0.LineTop;
    While (AktLine < L) Do ListView0.LineDown;
  End{IF};
End;


Procedure Listview0.CtrlLines;
var ev2: Event;
begin
  Mouse :=False;
  CtrlCode:=0;
     {----- Balken mit Maus direkt bewegen -----}
          case ev.Buttons of
          1   : begin
                  IF MouseEventInBox(EV_LEFT_PRESS, X1, Y1, X2, Pred((Y2-Y1+1) Div 2) + Y1) or
                     MouseEventInBox(EV_MOU_Move, X1, Y1, X2, Pred((Y2-Y1+1) Div 2) + Y1) Then
                  begin
                    Ev.CtrlCode := CUp; Mouse:=true;
                  end;
                  If MouseEventInBox(EV_LEFT_PRESS, X1, Y2-Pred((Y2-Y1+1) Div 2), X2, Y2) or
                     MouseEventInBox(EV_MOU_Move, X1, Y2-Pred((Y2-Y1+1) Div 2), X2, Y2) Then
                  begin
                    Ev.CtrlCode := CDown; Mouse:=true;
                  end;
                  {EndIF}
                end;
           End{Case};

   SetLinePS(GetPos);

   If Mouse then
   begin
       ev2.Ereignis:=0;               { Mausetaste gedrÅckt halten }
       while ev2.Ereignis=0 do
       begin
         KbmPeekEvent( ev2 );
         If ev2.Ereignis<>0 then
           break;
         delay(80);
         Case Ev.CtrlCode OF
           CUp   : LineUp;
           CDown : LineDown;
           CPgUp : LinePgUp;
           CPgDn : LinePgDn;
         End{Case};
         OutLaufLeiste;
         OutListe;
         SetLaufindex(AktLine);
      end;{While}
   end else
   begin
     Case Ev.CtrlCode OF
       CUp    : LineUp;
       CDown  : LineDown;
       CPgUp  : LinePgUp;
       CPgDn  : LinePgDn;
       CHome  : LineTop;
       CEnd   : LineLast;
     End{Case};
   end{IF};
end;


Procedure ListView0.ViewLines;
{Anzeige des Textes mit Rollen und BlÑttern}
Begin
  OutLaufLeiste;
  OutListe;
  SetLaufindex(AktLine);
End;


Function ListView0.IsOK : Boolean;
Begin
  IsOK := OK; OK := True;
End;


Function ListView0.GetLineNumber : Word;
var P: HeapLine;
    Z: word;
begin
  Z:=0; P:=StartLine;
  while (P^.PPred<>PS) and (P<>NIL) do
  begin
    inc(z);
    P:=P^.PNext;
  end;
  GetLineNumber:=Z;
end;



Function ListView0.GetLine(L:Word) :Outstring;
var P: HeapLine;
    Z: word;
begin
  GetLine:='';
  Z:=0; P:=StartLine;
  while (P<>NIL) and (Z<L) do
  begin
    inc(z);
    If Z=L then
      GetLine:=StringFromHeap(P^.S);
    P:=P^.PNext;
  end;
end;


Procedure ListView0.ClrListe;
Var
  P : HeapLine;
Begin
  While StartLine <> NIL Do Begin
    P := StartLine; StartLine := P^.PNext;
    DisposeString(P^.S);
    Dispose(P);
  End{While};
  SetLines(0);
  StartLine := NIL; PS := NIL; PSLast := NIL;
  AktLine := 0; OK := True;
End;


Destructor ListView0.Done;
Begin
  Laufleiste.Done;
  ClrListe;
End;


{--------- Methoden fuer Objekt zur Auswahl aus einer Liste -----}

Procedure  SelectView0.AppendHelp(S : OutString; jump: word);
var Scut   : string;
    X,leng : byte;
begin
  Scut := S;
  If pos('^c',Scut) > 0 then
  begin
    while pos('^',Scut) < pos('^c',Scut) do
      delete(Scut,pos('^',Scut),2);
    X := pos('^c',Scut)+1;
    delete(Scut,pos('^c',Scut),2);
    while pos('^',Scut) < pos('^c',Scut) do
      delete(Scut,pos('^',Scut),2);
    leng := pos('^c',Scut)-X;
    X:=X+X1-2;
  end;
  AppendLine (S ,X ,leng, jump);
end;

Constructor SelectView0.Init(XMin,YMin,XMax,YMax,Scrba: Byte);
begin
  ListView0.Init(XMin, YMin, XMax, YMax);
  SetBalken := True; MarkActive:=false;
  SelectPtrOld := NIL; SelectLineOld := 0;
  SelectPtr := NIL; SelectLine := 0;
  Balkenf := Scrba; Balkenb:=Balkenback;
  Scrollb:=Scrba;
end;

Procedure SelectView0.WrXY(X,Y: byte; S: string; sele : boolean);   { Mehrfarbige Ausgabe eines Str}
const Statusanz = 2;
var OAttr        : Byte;
    Xpos         : byte;
    MStat        : char;
    Status       : array [1..Statusanz] of char;
    Zst,z        : byte;
    Scut         : string;
    vor          : boolean;

begin
    OAttr:=Textattr;
    Xpos:=X;  Zst := 0; textcolor(Scrollf); textbackground(Scrollb);
    repeat
       Scut:=S;
       while (pos('^',S) = 1) do
       begin
         MStat:=S[2];                     { Status einlesen }
         If Zst>0 then                    { öberprÅfen . ob St vorhanden }
         begin
           for z:=1 to Zst do
             If Status[z]=Mstat then
             begin
               vor:=true; break;
             end else
               vor:=false;
             {End IF}
           {End For}
          End else
            vor:=false;
          {End IF}
          If  not vor and (zst<=Statusanz) then
          begin                                  { Alles setzen }
            inc(Zst); Status[Zst]:=Mstat;
            case Status[Zst] of
               'c' : If sele then
                     begin
                       textcolor(ActSelfo); textbackground(ActSelba);
                     end else
                     begin
                       textcolor(Selfo); textbackground(Scrollb);
                     end;
               'y' : textcolor(yCol);
               'w' : textcolor(wCol);
               'W' : textbackground(wCol);
             End{Case};
           end else
           begin                                  { Alles zurÅcksetzen }
             case Status[Z] of
               'c' : begin
                       textcolor(Scrollf); textbackground(Scrollb);
                     end;
               'y' : textcolor(Scrollf);
               'w' : textcolor(Scrollf);
               'W' : textbackground(Scrollb);
             End{Case};
             Status[z]:=Status[Zst]; dec(Zst);
           end;
           delete(S,1,2); Scut:=S;
       end{While};
       If pos('^',S) > 0 then
       begin
         delete(S,1, pos('^',S)-1);
         delete(Scut,pos('^',Scut),length(Scut));
       end else
       begin
         delete(S,1, length(S));
       end;
       writeXY(Xpos,Y,Scut); inc(Xpos,length(Scut));
    until length(S) = 0;
    Textattr:=OAttr;
end;





Procedure SelectView0.OutLine(P: HeapLine; Y: byte; sel :boolean);
var SH,Scut      : string;
    CtrlAnz      : byte;
Begin
  CtrlAnz:=0;
  IF (P <> NIL) Then Begin
    IF P^.Mark Then WrXY(X1, Y, '˚', sel )
      Else WrXY(X1, Y, ' ', sel);
    Sh   := StringFromHeap(P^.S);
    Scut := SH;
    while pos('^',Scut) > 0 do
    begin
      delete(Scut,pos('^',Scut),2);
      inc(CtrlAnz);
    end;
    WrXY(X1+1, Y, Pad(SH, Pred(X2-X1)+CtrlAnz*2), sel);
  End
  Else
    WrXY(X1, Y, Pad('', X2-X1), sel);
  {EndIF}
end;

Procedure SelectView0.OutListe;
Var
  PW : HeapLine;
  I  : Byte;
Begin
  IF SelectPtr = NIL Then LineTop;
  IF (PS <> PSLast) or (PSLast = NIL) Then Begin
    PW := PS;
    For I := Y1 To Y2 Do Begin                   {von 1. letzte BS-Zeile}
      If (SelectPtr = PW) and (SelectPtr<>nil) then
         OutLine(PW, I, true) else
         OutLine(PW, I, false);
      IF PW <> NIL Then PW:=PW^.PNext;
    End{FOR};
    PSLast := PS;
  End{IF};
End;

Procedure SelectView0.Outbalken;
begin
  IF StartLine = NIL Then Exit;
  IF (SelectLine <> SelectLineOld) or (SelectPtr <> SelectPtrOld) or
     SetBalken
  Then Begin
    IF (SelectLineOld >= AktLine) and (SelectLineOld <= AktLine+(Y2-Y1))
    Then
      OutLine(SelectPtrOld, Y1+SelectLineOld-AktLine, false);
    {EndIF}
    IF (SelectLine >= AktLine) and (SelectLine <= AktLine+(Y2-Y1))
    Then
      OutLine(SelectPtr, Y1+SelectLine-AktLine, true);
    {EndIF}
    SetBalken := False;
    SelectLineOld := SelectLine; SelectPtrOld := SelectPtr;
  End{IF};
end;



Procedure SelectView0.LineUp;
var SelPtrCount           : HeapLine;
    SelCount,SelLineOld   : Word;
begin
  IF (StartLine <> NIL) Then
  Begin
    SelCount:=SelectLine; SelLineOld:=SelectLine;
    SelPtrCount:=SelectPtr;
    while ((SelectPtr^.Jump = 0) or (SelectLine = SelLineOld)) and
          (SelCount >= AktLine) and (SelPtrCount^.PPred <>NIL) do
    begin
      SelPtrCount:=SelPtrCount^.PPred; Dec(SelCount);
      If (SelPtrCount^.Jump > 0) then
      begin
        SelectPtr:=SelPtrCount; SelectLine:=SelCount;
      end;
    end;{While}
    If (SelectLine = SelLineOld) or (SelectLine < AktLine) Then
      ListView0.LineUp;
  End{IF};
end;




Procedure SelectView0.LineDown;
var SelCount,SelLineOld   : Word;
    SelPtrCount           : HeapLine;
begin
  IF (StartLine <> NIL) Then
  Begin
    SelCount:=SelectLine; SelLineOld:=SelectLine;
    SelPtrCount:=SelectPtr;
    while ((SelectPtr^.Jump = 0) or (SelectLine = SelLineOld)) and
           (SelCount <= AktLine+Y2-Y1) and (SelPtrCount^.PNext <> NIL) do
    begin
      SelPtrCount:=SelPtrCount^.PNext; Inc(SelCount);
      If (SelPtrCount^.Jump > 0) then
      begin
        SelectPtr:=SelPtrCount; SelectLine:=SelCount;
      end;
    end;{While}
    SelEnde :=(Selcount = Lines);
    If (SelectLine = SelLineOld) or (SelectLine>AktLine+Y2-Y1) Then
      ListView0.LineDown;
  End{IF} else
    Selende:=true;
end;



Procedure SelectView0.LinePgUp;
var SelCount    : Word;
    SelPtrCount : HeapLine;
    z : word;
begin
 If AktLine=1 then
 begin
   Selectview0.LineTop; exit;
 end;
 For z:=Y1+1 To Y2 do Listview0.LineUp;
 IF (StartLine <> NIL) and (SelectPtr^.PPred <> NIL) and (SelectLine>AktLine) Then
 Begin
    SelCount:=SelectLine; SelPtrCount := SelectPtr;
    repeat
      SelPtrCount:=SelPtrCount^.PPred; Dec(SelCount);
      If (SelPtrCount^.Jump > 0) then
      begin
        SelectPtr:=SelPtrCount; SelectLine:=SelCount;
      end;
    until ((SelectPtr^.Jump >0) and (SelectLine <= AktLine+Y2-Y1)) or (SelCount <= AktLine) or
          (SelPtrCount^.PPred = NIL);
 End{IF};
end;





Procedure SelectView0.LinePgDn;
var SelCount    : Word;
    SelPtrCount : HeapLine;
    z : word;
begin
 If AktLine+Y2-Y1>=Lines then
 begin
   Selectview0.LineLast; exit;
 end;
 For z:=Y1+1 To Y2 do Listview0.LineDown;
 IF (StartLine <> NIL) and (SelectPtr^.PNext <> NIL) and (SelectLine<AktLine) Then
 Begin
    SelCount:=SelectLine; SelPtrCount := SelectPtr;
    repeat
      SelPtrCount:=SelPtrCount^.PNext; Inc(SelCount);
      If (SelPtrCount^.Jump > 0) then
      begin
        SelectPtr:=SelPtrCount; SelectLine:=SelCount;
      end;
    until ((SelectLine >= AktLine) and (SelectPtr^.Jump >0)) or (SelCount>AktLine+Y2-Y1) or
          (SelPtrCount^.PNext = NIL);
 End{IF};
end;








Procedure SelectView0.LineTop;
var SelCount    : Word;
    SelPtrCount : HeapLine;
begin
  ListView0.LineTop;
  SelectPtr := StartLine; SelectLine := 1;
  IF (StartLine <> NIL) and (SelectPtr^.Jump=0) and (SelectPtr^.PNext <> NIL) Then
  begin
    SelCount:=SelectLine; SelPtrCount := SelectPtr;
    repeat
      SelPtrCount:=SelPtrCount^.PNext; Inc(SelCount);
      If (SelPtrCount^.Jump > 0) then
      begin
        SelectPtr:=SelPtrCount; SelectLine:=SelCount;
      end;
    until (SelectPtr^.Jump > 0) or (SelCount = Lines) or (SelectPtr^.PNext = NIL);
  end{IF};
end;

Procedure SelectView0.LineLast;
begin
  repeat LineDown; until Selende;
end;







Procedure SelectView0.SetLinePS(L : Word);
var z: word;
begin
  IF L > 0 Then Begin
    ListView0.SetLinePS(L);
    SelectPtr := PS; SelectLine := AktLine;
    SetBalken := True;
    repeat
       If (SelectPtr^.PNext <> NIL) and (SelectPtr^.Jump = 0) then
       begin
          SelectPtr := SelectPtr^.PNext; Inc(SelectLine);
       end;
     until (SelectPtr^.Jump > 0) or (SelectLine = AktLine+Y2-Y1) or (SelectPtr^.PNext = NIL);
  End{IF};
end;


Procedure SelectView0.CtrlLines;
Const
   MarkUp  = 254;
Var
  X, Y   : Word;
  I      : Byte;
  ev2    : Event;

  Function BalkenToMouse : Boolean;
  Var
    SelectLineOld, AktLineOld : Word;
    SelectPtrOld, PSOld       : HeapLine;
  Begin
    BalkenToMouse := False;
    IF Ev.zeilerel+1-Y1+AktLine <= Lines Then Begin
      SelectLineOld := SelectLine; SelectPtrOld := SelectPtr;
      AktLineOld := AktLine; PSOld := PS;
      SelectLine := AktLine; SelectPtr := PS;
      Selende:=false;
      While (SelectLine < Ev.zeilerel+1-Y1+AktLine) and
            (AktLine = AktLineOld) and (not Selende) Do LineDown;
      Selende:=false;
      IF (SelectLine = Ev.zeilerel+1-Y1+AktLine) and
         (SelectPtr^.X-1 < Ev.spalterel) and
         (SelectPtr^.X+SelectPtr^.length+1 > Ev.spalterel) and
         (SelectPtr^.Jump > 0) and (AktLine = AktLineOld)
      Then
        BalkenToMouse := True
      Else Begin
        SelectLine := SelectLineOld; SelectPtr := SelectPtrOld;
        AktLine := AktLineOld; PS := PSOld;
      End{IF};
    End{IF};
  End;

Begin
  DKlick:=False;
  Mouse :=False;
  CtrlCode:=0;
     {----- Balken mit Maus direkt bewegen -----}
          case ev.Buttons of
           1  : begin
                  IF MouseEventInBox(EV_LEFT_PRESS, X1, Y1, X2-1, Y2) or
                     MouseEventInBox(EV_Mou_Move, X1, Y1, X2-1, Y2) Then
                  Begin
                    IF BalkenToMouse Then
                    Begin
                      OUtBalken;
                      DKlick := DoppelKlick;
                      If DKlick then
                      begin
                        CtrlCode :=CR;
                      end;
                    End{IF};
                  End{IF};
                  IF MouseEventInBox(EV_LEFT_PRESS, X1, Y1-1, X2, Y1-1) or
                     MouseEventInBox(EV_Mou_Move, X1, Y1-1, X2, Y1-1)  Then
                  begin
                    Ev.CtrlCode := CUp; Mouse:=true;
                  end;
                  IF MouseEventInBox(EV_LEFT_PRESS, X1, Y2+1, X2, Y2+1) or
                     MouseEventInBox(EV_Mou_Move, X1, Y2+1, X2, Y2+1) Then
                  begin
                    Ev.CtrlCode := CDown; Mouse:=true;
                  end;
                  {EndIF}
                end;
            2 : begin
                  IF MarkActive Then
                   Begin
                     IF MouseEventInBox(EV_Right_PRESS, X1, Y1, X2-1, Y2) or
                        MouseEventInBox(EV_Mou_Move, X1, Y1, X2-1, Y2) Then
                     Begin
                       IF BalkenToMouse Then
                       begin
                         Mark;
                       end;
                     End{IF};
                     IF MouseEventInBox(EV_RIGHT_PRESS, X1, Y1-1, X2, Y1-1) or
                        MouseEventInBox(EV_Mou_Move, X1, Y1-1, X2, Y1-1)Then
                     begin
                       Ev.CtrlCode := MarkUp;  Mouse:=true;
                     end;
                     IF MouseEventInBox(EV_RIGHT_PRESS, X1, Y2+1, X2, Y2+1) or
                        MouseEventInBox(EV_Mou_Move, X1, Y2+1, X2, Y2+1) Then
                     begin
                       Ev.CtrlCode := InsertKey; Mouse:=true;
                     end;
                   End{IF};
                end;
           End{Case};

   SetLinePS(GetPos);

   If Mouse then
   begin
       ev2.Ereignis:=0;               { Mausetaste gedrÅckt halten }
       while ev2.Ereignis=0 do
       begin
         KbmPeekEvent( ev2 );
         If ev2.Ereignis<>0 then
           break;
         delay(80);
         Case Ev.CtrlCode OF
           CUp       : LineUp;
           CDown     : LineDown;
           CPgUp     : LinePgUp;
           CPgDn     : LinePgDn;
           MarKup    : begin
                         If Markactive then
                         begin
                           Mark; LineUp;
                         end;
                       end;
           Insertkey : begin
                         If Markactive then
                         begin
                           Mark; LineDown;
                         end;
                       end;
         End{Case};
         OutLaufLeiste;
         OutListe;
         SetLaufindex(AktLine);
         OutBalken;
      end;{While}
   end else
   begin
     Case Ev.CtrlCode OF
       CUp       : LineUp;
       CDown     : LineDown;
       CPgUp     : LinePgUp;
       CPgDn     : LinePgDn;
       CHome     : LineTop;
       CEnd      : LineLast;
       MarKup    : begin
                     If Markactive then
                     begin
                       Mark; LineUp;
                     end;
                   end;
       Insertkey : begin
                      If Markactive then
                      begin
                        Mark; LineDown;
                      end;
                   end;
     End{Case};
   end{IF};
end;

Procedure SelectView0.SetMarkMode(A: Boolean);
Begin
  MarkActive := A;
End;

Procedure SelectView0.Mark;
Begin
  SelectPtr^.Mark := not SelectPtr^.Mark; SetBalken := True;
End;


Procedure SelectView0.ViewLines;
begin
  OutLaufLeiste;
  OutListe;
  SetLaufindex(AktLine);
  OutBalken;
end;


Function  SelectView0.GetJumpNumber : Word;
begin
  If (SelectPtr <> NIL) then
    GetJumpNumber:= SelectPtr^.Jump else GetJumpNumber:= 0;
end;

Function SelectView0.GetLineNumber : Word;
var P: HeapLine;
    Z: word;
begin
  Z:=0; P:=StartLine;
  while (P^.PPred<>SelectPtr) and (P<>NIL) do
  begin
    If (P^.Jump > 0) then
      inc(z);
    P:=P^.PNext;
  end;
  GetLineNumber:=Z;
end;

  {If (SelectPtr <> NIL) and (SelectPtr^.Jump > 0) then
    GetLineNumber := SelectLine
  else
    GetLineNumber := 0;}

Function  SelectView0.GetSelLine : OutString;
begin
  GetSelLine := '';
  IF (SelectPtr <> NIL) and (SelectPtr^.Jump > 0) Then
    GetSelLine := StringFromHeap(SelectPtr^.S)
end;


Procedure ListView0.ClrLine(L :Word);
Var P,P1    : HeapLine;
    Z    : Word;
    Next : Pointer;
Begin
  Z:=0; P:=StartLine;
  While (P <> NIL) and (L>Z) Do Begin
    inc(Z);
    If (Z=L) and (P<>NIL) then
    begin
      If PS=P then
      begin
        If L>1 then
        begin
          PS:=P^.PPred; dec(AktLine);
        end
        else
          PS:=P^.PNext;
      end;
      If L>1 then
      begin
        If P^.PPred<>NIL then
          P^.PPred^.PNext:=P^.PNext;
        If P^.PNext<>NIL then
          P^.PNext^.PPred:=P^.PPred;
      end else
      begin
        StartLine:=P^.PNext;
        If P^.PNext<>NIL then
          P^.PNext^.PPred:=NIL;
      end;
      DisposeString(P^.S);
      Dispose(P); PSlast:=NIL; SetLines(pred(Lines));
    end;
    P := P^.PNext;
  End{While};
End;



Procedure SelectView0.DelLine;
begin
  If (StartLine = NIL) then exit;
  Listview0.ClrLine(GetLineNumber);
  If (StartLine = NIL) then SelectPtr:=NIL;
  If SelectPtr<>NIL then
  begin
    If SelectPtr^.PPred<>NIL then
    begin
      SelectPtr:=SelectPtr^.PPred;
      dec(SelectLine);
    end else
    If SelectPtr^.PNext<>NIL then
      SelectPtr:=SelectPtr^.PNext else
     SelectPtr:=nil;
  end;
  SelectPtrOld:=NIL; SelectLineOld:=0;
  SetBalken := True;
end;


Procedure SelectView0.ClrListe;
begin
  ListView0.ClrListe;
  SetBalken := True; MarkActive:=false;
  SelectPtrOld := NIL; SelectLineOld := 0;
  SelectPtr := NIL; SelectLine := 0;
end;

Destructor SelectView0.Done;
begin
  Listview0.Done;
end;

{----------- Weitere Auswahlmethoden --------------------------}

Procedure   SelectView1.AppendStr(S : OutString);
begin
  Selectview0.AppendHelp(concat('^c',pad(S,X2-X1-2),'^c'),1);
end;

Function  SelectView1.GetLine(L:Word) : OutString;
var S :Outstring;
begin
  S:=Listview0.GetLine(L);
  delete(S,1,2); delete(S,length(S)-1,2);
  GetLine:=trim(S);
end;


Function Selectview1.GetSelLine :OutString;
var S : Outstring;
begin
  S:=Selectview0.GetSelLine;
  delete(S,1,2); delete(S,length(S)-1,2);
  GetSelLine:=trim(S);
end;





begin
end.

