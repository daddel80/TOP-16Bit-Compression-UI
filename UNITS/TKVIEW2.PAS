unit Tkview2;

Interface
uses Dos,Crt,TKsaa,Kbm,Tkstream,Tkstring,TKwin,TKvideo,Tkview;

const
      Helpba : Byte = green;
      Pullfo : Byte = black;
      Pullba : Byte = Lightgray;

type  BackJumpRec = Record
           Page      : Word;
           TopLine   : Word;
           SelectLine: Word;
        End;


Type

  {-------- Objekt zur Listenausgabe ---------------------}
  ListView1 = Object(ListView0)
                XW1, XW2,
                YW1, YW2    : Byte;              {Fensterkoordinaten}
                Frame, Title,
                Background  : Byte;
                Constructor Init(XMin,YMin,XMax,YMax : Byte);
                Procedure   ViewLines; Virtual;  {Anzeige. mit Rollen}
                Destructor  Done;
              End{Object ListView1};


  Helpview1 = Object(Selectview0)
                JumpSeek    : array [1..255] of longint;
                BackJump    : array [1..50]  of BackJumpRec;
                BackCount   : byte;
                Helpfile    : Typedstream;
                Magicheader : longint;
                Helpfehler  : boolean;
                Topic       : string;            {Topic der akt. Seite}
                Constructor Init (fname: pathstr; Ma: longint);
                Procedure   Open (Xdiff,Ydiff,ScrBa: byte);
                Procedure   Pageread   (Jump: Word);              { intern }
                Procedure   PageSelect (Jump: Word);
                Procedure   PageBack;
                Procedure   OutTopic;                             { intern }
                Procedure   ViewLines;     Virtual;
                Procedure   ViewPage(Page : Word);                { intern }
                Destructor  Done;
              End{Helpview1};

  SelectView2 = Object(Selectview1)
                Constructor Init (Xdiff,Ydiff,ScrBa: byte);
                Procedure   ViewLines;    virtual;
                Destructor  Done;
              End{SelectView2};

  Pulldown1    = Object(Selectview1)
                 Down_Bu : Button;
                 Up_Bu   : Button;
                 Open    : boolean;
                Constructor Init(XMin,YMin,XMax,YMax,Scrfo,ScrBa : Byte);
                Procedure SetPullDown;
                Procedure ViewLines;  virtual;
                Procedure CtrlLines;  virtual;
                Function  EventPulldown : boolean;
                Destructor Done;
              End{Pulldown1};

Implementation


{-------------- Objekt fÅr PulldownmenÅ --------------}
Constructor Pulldown1.Init(XMin,YMin,XMax,YMax,Scrfo,ScrBa : Byte);
var Wmin,Wmax : byte;
begin
  Selectview1.Init(XMin,YMin+1,XMax,YMax,Scrba);
  Balkenf := Scrba; Balkenb:=Balkenback;
  Scrollf:=Scrfo; Scrollb:=Scrba;
  Initbutton(Up_Bu  ,XMax,YMin,'~'+#30,72,1);  Up_Bu.Anz:=1;  Up_Bu.Schatten:=false;
  Initbutton(Down_Bu,XMax,YMin,'~'+#31,80,1);Down_Bu.Anz:=1;Down_Bu.Schatten:=false;
  Open:=false;
end;


Procedure  Pulldown1.SetPullDown;
begin
  SetButton(Down_Bu);
  textcolor(Scrollf); textbackground(Scrollb);
  writeXY(X1,Y1-1,' '+pad(GetSelline,X2-X1-2)+' ');
end;


Procedure Pulldown1.ViewLines;
begin
  CtrlCode:=0;
  Repeat
    If Open then
      SetButton(Up_Bu) else
      SetButton(Down_Bu);


    If Open then
    begin
      textcolor(Scrollf); textbackground(Scrollb);
      writeXY(X1,Y1-1,''+pad(GetSelline,X2-X1-2)+'' );
      PSLast:=Nil;
      Selectview1.ViewLines
    end else
    begin
      IndexPos:=0;
      textcolor(Scrollf); textbackground(Scrollb);
      writeXY(X1,Y1-1,''+pad(GetSelline,X2-X1-2)+'' );
    end;

    If Open then
      ActiveButton(Up_Bu) else
      ActiveButton(Down_Bu);

    If Open then
    begin
      case EventThisButton(Up_Bu) of
        1 : CtrlCode:=CR;
      end{Case};
    end else
    begin
      case EventThisButton(Down_Bu) of
        1 : CtrlCode:=CR;
      end{Case};
    end;

    If Open then
    begin
      If ((Ctrlcode=CR)  or (ev.ctrlcode=TAB)) then
      begin
        Open:=false; CtrlCode:=Cr; Restwindow;
      end;
    end else
    begin
      If (Ctrlcode=CR) then
      begin
        Open:=true; Savewin(X1,Y1,X2,Y2);
      end;
    end;

    If Open then
      CtrlLines;

  Until (Ev.Ctrlcode = ESC) or (ev.CtrlCode=TAB) or  (CtrlCode=CR) or
        ((ev.ereignis in[2,4,8,16]) and not MouseEventInBox(ev.ereignis, X1, Y1-1, X2, Y2) or not Open);
  If Open then
  begin
    CtrlCode:=Cr;
    Open:=false;
    Restwindow;
    textcolor(Scrollf); textbackground(Scrollb);
    writeXY(X1,Y1-1,' '+pad(GetSelline,X2-X1-2)+' ');
  end;
end;


Procedure Pulldown1.CtrlLines;
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


Function Pulldown1.EventPulldown : boolean;
begin
  EventPulldown:=false;
  If ((fenanz>0) and (aktber=fenanz)) then
     case ev.Ereignis of
         EV_LEFT_PRESS :
         begin
           If (ev.spalterel<X2) and (ev.spalterel+2>X1) and
              (ev.zeilerel+2=Y1) then
           begin
             EventPulldown:=true;
           end;
         end;
     end;
end;

Destructor Pulldown1.Done;
begin
  Selectview1.Done;
end;


{-------------- Objekt zur Listenausgabe -------------}
Constructor ListView1.Init(XMin, YMin, XMax, YMax : Byte);
Begin
  XW1 := XMin; YW1 := YMin; XW2 := XMax; YW2 := YMax;
  ListView0.Init(2, 2, XMax-XMin-1 , YMax-YMin-2);
  OK:=openwindow(Xmax-Xmin,Ymax-Ymin,fenfo,fenba,'Liste') and OK
End;



Procedure ListView1.ViewLines;
Var
  List_Bu : Button;
Begin
  Initbutton(List_Bu, X2 DIV 2 - 3, Y2+2,'    ~OK    '    ,Alt_O,1); List_Bu.anz:=1;
  List_Bu.FaFen:=scrollb;
  Repeat
    SetButton(List_Bu);
    Listview0.ViewLines;
    ActiveButton(List_Bu);
    ListView0.CtrlLines;
    case EventThisButton(List_Bu) of
      1 : Ev.CtrlCode:=ESC;
    end{Case};
  Until (Ev.Ctrlcode = ESC);
End;


Destructor ListView1.Done;
Begin
  ListView0.Done;
End;

{--------- Methoden fuer Objekt zur Auswahl aus einer Liste -----}

Constructor  SelectView2.Init (Xdiff,Ydiff,Scrba: byte);
begin
  OK:=openwindow (Xdiff,Ydiff,scrollf,Scrba,'Hilfe') and OK;
  Selectview1.Init( 3, 4, xdiff-1, ydiff-2,ScrBa);
end;


Procedure SelectView2.ViewLines;
var Sel_Bu : Button;
begin
  Initbutton(Sel_Bu, 3, Y2+2,'    ~OK     ',Alt_O,1);
  Initbutton(Sel_Bu,18, Y2+2,' ~Markieren ',Alt_M,2);
  Initbutton(Sel_Bu,37, Y2+2,' ~Abbruch   ',Alt_A,3); Sel_Bu.anz:=3;
  Repeat
    SetButton(Sel_Bu);
    Selectview1.ViewLines;
    ActiveButton(Sel_Bu);
    SelectView1.CtrlLines;
    case EventThisButton(Sel_Bu) of
      1 : CtrlCode:=CR;
      2 : begin end;
      3 : Ev.CtrlCode:=ESC;
    end{Case};

    If Ctrlcode=CR then
    begin
    end;

  Until (Ev.Ctrlcode = ESC);
end;

Destructor SelectView2.Done;
begin
  Selectview1.Done;
  closewindow;
end;


Constructor Helpview1.Init (fname: pathstr; Ma : longint);
const AR : AcceptRec = ('  OK  ','','');
var Mword     : word;
    Mbyte     : byte;
    Mstring   : string;
    Textcount : word;
    z,gr      : byte;

begin
  HelpFehler:=false;
  for z:=1 to 255 do JumpSeek[z]:=0;
  HelpFile.Init(fname,1 );
  HelpFile.Open; MagicHeader:=0;
  Helpfile.Read(Magicheader,0,SizeOf(Ma));
  IF Ma=Magicheader then
  begin
     While (Helpfile.OK) and (not Helpfile.EOF)  do
     begin
       Helpfile.Read(Mword,-1,2);              { Number }
       JumpSeek[Mword]:=Helpfile.pos-2;
       Helpfile.Read(Mbyte  ,-1,1);            { Topic }
       Helpfile.Read(Mstring,-1,Mbyte);
       Helpfile.Read(Textcount,-1,2);          { Textcount }
       for z:=1 to Textcount do
       begin
         Helpfile.Read(Mbyte  ,-1,1);          { Text }
         Helpfile.Read(Mstring,-1,Mbyte);
         Helpfile.read(Mword  ,-1,2);          { Jump }
         If not Helpfile.OK then begin Ma:=0; break; end;
       end;
     end;
  End{IF};
  If (Ma<>Magicheader) then
  begin
    IO_Error(' Hilfedatei:','ioerror.msg', 224, Ar); Helpfehler:=true;
  end;
end;


Procedure  Helpview1.Open (Xdiff,Ydiff,ScrBa: byte);
begin
  If HelpFehler then exit;
  OK:=openwindow (Xdiff,Ydiff,scrollfo,scrba,'Hilfe') and OK;
  Selectview0.Init( 3, 4, xdiff-1, ydiff-3,ScrBa);
  textcolor(Balkenb); textbackground(Scrba);
  Winframe( X1-1, Y1-1, X2, Y2+1, false);
end;


Procedure  Helpview1.Pageread (Jump: Word);
var Number        : word;
    Text          : string;
    Textcount,Ju  : word;
    Mbyte         : byte;
    z             : byte;
begin
   If (Jumpseek[jump] > 0) and (Jump > 0) then
   begin
     ClrListe;
     Helpfile.Seek(Jumpseek[jump]);
     Helpfile.Read(Number,-1,2);                { Number }
     Helpfile.Read(Mbyte,-1,1);
     Topic[0]:=char(Mbyte);
     Helpfile.seek(Helpfile.pos-1);
     Helpfile.Read(Topic,-1,Mbyte+1);           { Topic }
     Helpfile.Read(Textcount,-1,2);             { Textcount }
     for z:=1 to Textcount do
     begin
       Helpfile.Read(Mbyte  ,-1,1);             { Text }
       Text[0]:=char(Mbyte);
       Helpfile.seek(Helpfile.pos-1);
       Helpfile.Read(Text,-1,Mbyte+1);
       Helpfile.read(Ju  ,-1,2);                { Jump }
       AppendHelp(Text,ju);
     end;
   End{IF};
   LineTop;
end;


Procedure Helpview1.PageSelect (Jump: Word);
var z: byte;
begin
  If (Jump<>BackJump[1].Page) and (Jump>0) then
  begin
    If (Jumpseek[jump] > 0) then
    begin
      for z:=49 downto 1 do
        BackJump[z+1]:=BackJump[z];
      {EndFor};
      If BackCount < 50 then inc(BackCount);
      BackJump[1].Page      := Jump;
      BackJump[1].Topline   := Listview0.GetLineNumber;
      BackJump[1].SelectLine:= GetLineNumber;
    end{If};
    Pageread(Jump);
  end{If}
end;



Procedure Helpview1.PageBack;
var z : word;
begin
  If BackCount > 1 then
  begin
    Pageread(BackJump[2].Page);
    for z:=2 to BackJump[1].TopLine do
       Listview0.LineDown;
    for z:=2 to BackJump[1].SelectLine do
       LineDown;
    for z:=1 to 49 do
      BackJump[z]:=BackJump[z+1];
    dec(BackCount);
  end;
end;

Procedure Helpview1.OutTopic;
begin
  WrXY(X1+2,Y1-2, pad(Topic,X2-X1),false);
end;


Procedure Helpview1.ViewLines;
begin
  OutTopic;
  SelectView0.ViewLines;
end;


Procedure  Helpview1.ViewPage(Page : Word);
var jump    : word;
    Help_Bu : Button;
    z       : byte;
begin
  If HelpFehler then exit;
  Open(65,18,Helpba);
  for z:=1 to 50  do BackJump[z].Page:=0;
  BackCount:=0;
  PageSelect(Page);
  Initbutton(Help_Bu, 2, Y2+3,'   ~Gehe zu   '    ,Alt_G,1);
  Initbutton(Help_Bu,18, Y2+3,'   Gehe ~zurÅck   ',Alt_Z,2);
  Initbutton(Help_Bu,38, Y2+3,'   ~Index   '      ,Alt_I,3);
  Initbutton(Help_Bu,52, Y2+3,'   ~Abbruch   '    ,Alt_A,4); Help_Bu.anz:=4;
  Help_Bu.FaFen:=scrollb;
  Repeat
    SetButton(Help_Bu);
    ViewLines;
    ActiveButton(Help_Bu);
    SelectView0.CtrlLines;
    case EventThisButton(Help_Bu) of
      1 : CtrlCode:=CR;
      2 : begin
            PageBack;
            Help_Bu.Pos:=1;
          end;
      3 : begin
            PageSelect(1);
            Help_Bu.Pos:=1;
          end;
      4 : Ev.CtrlCode:=ESC;
    end{Case};
    If Ctrlcode=CR then
    begin
      PageSelect(GetjumpNumber);
      Help_Bu.Pos:=1;
    end;
    {EndIf}
  Until (Ev.Ctrlcode = ESC);
  Clrliste;
  for z:=1 to High(Backjump) do Backjump[z].Page:=0;
  closewindow;
end;


Destructor  Helpview1.Done;
begin
end;


begin
end.