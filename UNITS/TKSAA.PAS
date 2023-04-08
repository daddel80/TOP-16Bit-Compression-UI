Unit TKSAA;

Interface
uses Crt,Kbm,Tkwin,Tkstring,Tkvideo;


Const Buttonfo : byte = lightgray;
      Buttonba : byte = blue;
      ButtonSe : byte = white;
      ButtonKe : byte = yellow;

      Editfo   : byte = black;
      Editba   : byte = lightgray;


type


    Buttontyp = Record
               X : byte;
               Y : byte;
               M : Message;
               P : byte;
               T : Taste;
               S : boolean;
             end;

    Button   = Record
                Bu  : array [1..26] of Buttontyp;
                Anz : byte;
                Akt : boolean;
                Pos : byte;
                FaS : byte;
                FaN : byte;
                FaH : byte;
              Fafen : byte;
           Schatten : boolean;
                Sel : boolean;
             end;

    RaButtontyp = Record
                X : byte;
                Y : byte;
                M : Message;
              end;

    RaButton = Record
               Rb  : array [1..19] of Rabuttontyp;
               Anz : byte;
               Sel : byte;
               Pos : byte;
               Akt : boolean;
            end;

  SelButtontyp = Record
               X  : byte;
               Y  : byte;
               M  : Message;
               S  : boolean;
            end;

   SelButton = Record
               Sb  : array [1..10] of SelButtontyp;
               Anz : byte;
               Pos : byte;
               Akt : boolean;
            end;

   Edit     = Record
               X       : byte;
               Y       : byte;
               M       : String;
               P       : boolean;
               T       : String;
               la      : byte;
               Sp      : byte;
               Pos     : byte;
               Akt     : boolean;
            end;

function  MouseEventinBox (Button,x1,y1,x2,y2:byte) : boolean;
procedure Getevent;

{----------------------- Button ---------------------------}
PROCEDURE Initbutton      (var But : Button; X,Y:Integer; M:string;T:Taste; Nr:byte);
PROCEDURE Setbutton       (var But : Button);
PROCEDURE Activebutton    (var But : Button);
FUNCTION  EventThisbutton (var But  : Button) : byte;
{----------------------- RadioButton ----------------------}
PROCEDURE InitRadioButton   (var RBut : RaButton; X,Y:Integer; M:string; Nr:byte);
PROCEDURE SetRadioButton    (var RBut : RaButton);
PROCEDURE ActiveRadioButton (var Rbut : RaButton);
FUNCTION  EventRadioButton  (var Rbut : RaButton) : boolean;
{----------------------- SelButton ------------------------}
PROCEDURE InitSelButton   (var Sbut : SelButton ; X,Y:Integer;  M:string; S:boolean; Nr:byte);
PROCEDURE SetSelButton    (var SBut : SelButton);
PROCEDURE ActiveSelButton (var SBut : SelButton);
FUNCTION  EventSelButton  (var SBut : SelButton) : boolean;
{----------------------- Zeileneditor ---------------------}
PROCEDURE InitEditor   (var Edi : Edit; X,Y : integer; M : Message; P : boolean;
                              T : string; la: byte);
PROCEDURE SetEditor    (var Edi : Edit);
PROCEDURE ActiveEditor (var Edi : Edit);
FUNCTION  EventEditor  (var Edi :Edit) : boolean;

Implementation





function  MouseEventinBox (Button,x1,y1,x2,y2:byte) : boolean;
begin
  If (Button=ev.Ereignis) and
     (ev.spalterel+1>=x1) and (ev.spalterel+1<=x2) and
     (ev.zeilerel+1 >=y1) and (ev.zeilerel+1 <=y2) and
     ((fenanz>0)          and (aktber=fenanz)) then
  begin
    MouseEventinBox:=true;
  end else
    MouseEventinBox:=false;
end;


procedure Getevent;
begin
  KbClrevent;
  repeat
    KbmEventWait( EV_ALL, ev );
  until (ev.Ereignis<>EV_MOU_MOVE) and (ev.Ereignis<>EV_KEY_UNKNOWN) and (ev.Ereignis<>EV_KEY_Status)
        or (ev.Buttons in [1,2]);
end;



{---------------------------------- Buttons ---------------------------------}

procedure Paintbutton(But : Button);
var Nr   : byte;
     x   : byte;
begin
   for Nr:=1 to But.anz do
   begin
     textbackground(But.FaH);
     If But.Bu[Nr].S then
     begin
       If But.Schatten then
       begin
         textcolor(black); textbackground(But.FaFen);
         writeXY(But.Bu[Nr].X,But.Bu[Nr].Y,' ');
         for x:=1 to length(But.Bu[Nr].M) do
           writeXY(But.Bu[Nr].X+x,But.Bu[Nr].Y+1,' ');
         textbackground(But.FaH);
       end else
         textbackground(But.FaN);
     end;
     If But.Bu[Nr].S and But.Schatten then
       x:=1 else x:=0;
     If But.Bu[Nr].P>0 then
     begin
       If But.Pos=Nr then textcolor(But.Fas) else textcolor(But.FaN);
       If But.Akt and But.Schatten and (But.Pos=Nr) then
         writeXY(But.Bu[Nr].X+x,But.Bu[Nr].Y,concat('',copy(But.Bu[Nr].M,2,But.Bu[Nr].P-1))) else
         writeXY(But.Bu[Nr].X+x,But.Bu[Nr].Y,copy(But.Bu[Nr].M,1,But.Bu[Nr].P-1));
       textcolor(ButtonKe);
       writeXY(But.Bu[Nr].X+But.Bu[Nr].P-1+x,But.Bu[Nr].Y,But.Bu[Nr].M[But.Bu[Nr].P]);
       If But.Pos=Nr then textcolor(But.Fas) else textcolor(But.FaN);
       If But.Akt and But.Schatten and (But.Pos=Nr) then
         writeXY(But.Bu[Nr].X+But.Bu[Nr].P+x,But.Bu[Nr].Y,
         concat(copy(But.Bu[Nr].M,But.Bu[Nr].P+1,length(But.Bu[Nr].M)-But.Bu[Nr].P-1),'')) else
         writeXY(But.Bu[Nr].X+But.Bu[Nr].P+x,But.Bu[Nr].Y,copy(But.Bu[Nr].M,But.Bu[Nr].P+1,length(But.Bu[Nr].M)));
     end else
     begin
       If But.Pos=Nr then textcolor(But.Fas) else textcolor(But.FaN);
       writeXY(But.Bu[Nr].X+x,But.Bu[Nr].Y,But.Bu[Nr].M);
     end;
     If But.Schatten and not But.Bu[Nr].S then
     begin
       textcolor(black); textbackground(But.FaFen);
       writeXY(But.Bu[Nr].X+1,But.Bu[Nr].Y+1,leftpadch('','ß',length(But.Bu[Nr].M)));
       writeXY(But.Bu[Nr].X+length(But.Bu[Nr].M),But.Bu[Nr].Y,'Ü');
     end;
   end;
end;




procedure Setbutton(var But : Button);
begin
  But.Akt:=false; Paintbutton(But);
end;


procedure Activebutton(var But : Button);
begin
  But.Akt:=true; Paintbutton(But);
  Getevent;
end;


procedure Initbutton(var But : Button; X,Y:Integer; M:string; T:Taste; Nr:byte);
begin
  But.Bu[Nr].X:=X;  But.Bu[Nr].Y:=Y;
  But.Bu[Nr].P:=Pos('~',M);
  while Pos('~',M)>0 do
    delete(M,Pos('~',M),1);
  But.Bu[Nr].M:=M;But.Bu[Nr].T:=T; But.Bu[Nr].S:=false;
  But.Pos:=1; But.Akt:=false; But.Schatten:=true; But.Fafen:=fenba;
  But.FaH:=Buttonba; But.FaS:=ButtonSe; But.FaN:=Buttonfo;
end;



function EventThisbutton (var But  : Button ) : byte;
var ze : char;
    i  : byte;
    Nr : byte;
begin
  {If (fenanz>0) and (aktber<>fenanz) then exit;}
  EventThisbutton:=0;
  case ev.Ereignis of
       EV_KEY_PRESSED :
       case ev.key of
          CLEFT : If (But.Pos > 1)       and But.Akt then dec(But.Pos);
          CRIGHT: If (But.Pos < But.Anz) and But.Akt then inc(But.Pos);
       end;
  end;

  for Nr:=1 to But.Anz do
  begin
    ze:=upcase(But.Bu[Nr].M[But.Bu[Nr].P]);
    case ev.Ereignis of
         EV_KEY_PRESSED :
         begin
           case ev.key of
             CR    : If (Nr=But.Pos) then EventThisbutton := Nr;
           end;
           If (upword(ev.key) = But.Bu[Nr].T) then EventThisbutton := Nr;
         end;
         EV_LEFT_REL:
         begin
            If (ev.spalterel+2>But.Bu[Nr].X) and (ev.spalterel+1<But.Bu[Nr].X+length(But.Bu[Nr].M)) and
                (ev.zeilerel+1=But.Bu[Nr].Y) then
              EventThisbutton:=Nr; But.Bu[Nr].S:=false;
         end;
         EV_LEFT_PRESS :
         begin
           for i:=1 to But.anz do
             If (ev.spalterel+2>But.Bu[i].X) and (ev.spalterel+1<But.Bu[i].X+length(But.Bu[i].M)) and
                (ev.zeilerel+1=But.Bu[i].Y) and ((fenanz>0) and (aktber=fenanz)) then
             begin
                But.Bu[i].S:=true;
             end;
         end;
         EV_MOU_MOVE :
         begin
           If ev.Buttons=1 then
             If (ev.spalterel+2>But.Bu[Nr].X) and (ev.spalterel+1<But.Bu[Nr].X+length(But.Bu[Nr].M)) and
                (ev.zeilerel+1=But.Bu[Nr].Y) and ((fenanz>0) and (aktber=fenanz))then
              begin
                But.Bu[Nr].S:=true;
              end else
                But.Bu[Nr].S:=false;
         end;
      end;
  end;
end;


{----------------------------- RadioButton ----------------------------------}

procedure PaintRadioButton(RBut : RaButton);
var Nr : byte;
begin
  textcolor(fenfo);textbackground(fenba); cursor_off;
  For Nr:=1 to Rbut.Anz do
  begin
    WriteXY(RBut.RB[Nr].X,RBut.RB[Nr].Y,'(');
    If RBut.Sel=Nr then
      WriteXY(RBut.RB[Nr].X+1,RBut.RB[Nr].Y,#254) else
      WriteXY(RBut.RB[Nr].X+1,RBut.RB[Nr].Y,' ');
    WriteXY(RBut.RB[Nr].X+2,RBut.RB[Nr].Y,')');
    WriteXY(RBut.RB[Nr].X+3,RBut.RB[Nr].Y,concat(' ',RBut.RB[Nr].M));
  end;
end;



procedure InitRadioButton (var RBut : RaButton; X,Y:Integer; M:string; Nr:byte);
begin
  RBut.Rb[Nr].X:=X;   RBut.Rb[Nr].Y:=Y;  RBut.Rb[Nr].M:=M;  RBut.Pos:=1; RBut.Akt:=true;
end;



procedure SetRadioButton (var RBut : RaButton);
begin
   If RBut.Akt then PaintRadioButton(RBut); RBut.Akt:=false;
end;



procedure ActiveRadioButton (var RBut : RaButton);
begin
  PaintRadiobutton(Rbut); Rbut.Akt:=true;
  gotoxy(RBut.RB[RBut.Pos].X+1,RBut.RB[RBut.Pos].Y); cursor_on;
  Getevent; cursor_off;
end;


function EventRadioButton (var Rbut : RaButton) : boolean;
var i:byte;
begin
  EventRadioButton:=false;
  case ev.Ereignis of
       EV_KEY_PRESSED :
          If Rbut.Akt then
            case ev.key of
              SPACE  : begin
                         Rbut.Sel := Rbut.Pos;
                         EventRadioButton:=true;
                       end;
              CDOWN  : begin
                         If Rbut.Pos<Rbut.anz  then inc(Rbut.Pos) else Rbut.Pos:=1;
                         EventRadioButton:=true;
                       end;
                CUP  : begin
                         If Rbut.Pos>1  then dec(Rbut.Pos) else Rbut.Pos:=Rbut.Anz;
                         EventRadioButton:=true;
                       end;
            end;
       end;
  If ((fenanz>0) and (aktber=fenanz)) then
     case ev.Ereignis of
         EV_LEFT_REL :
         begin
           for i:=1 to Rbut.anz do
           begin
             If (ev.spalterel+2<Rbut.Rb[i].X+length(Rbut.Rb[i].M)+5) and (ev.spalterel+2>Rbut.Rb[i].X) and
                (ev.zeilerel+1=RBut.Rb[i].Y) then
             begin
               EventRadioButton:=true; Rbut.Sel:=i;
             end;
           end;
         end;
         EV_LEFT_PRESS :
         begin
           for i:=1 to Rbut.anz do
             If (ev.spalterel+2<Rbut.Rb[i].X+length(Rbut.Rb[i].M)+5) and (ev.spalterel+2>Rbut.Rb[i].X) and
                (ev.zeilerel+1=RBut.Rb[i].Y) then
             begin
               EventRadioButton:=true; Rbut.Pos:=i;
             end;
         end;
     end;
end;


{----------------------------------- SelButton ------------------------------}

procedure PaintSelButton (SBut : SelButton);
var Nr : byte;
begin
  textcolor(fenfo);textbackground(fenba); cursor_off;
  For Nr:=1 to Sbut.Anz do
  begin
    WriteXY(Sbut.SB[Nr].X,Sbut.SB[Nr].Y,'[');
    If Sbut.Sb[Nr].S then
      WriteXY(Sbut.SB[Nr].X+1,Sbut.SB[Nr].Y,'x') else
      WriteXY(Sbut.SB[Nr].X+1,Sbut.SB[Nr].Y,' ');
    WriteXY(Sbut.SB[Nr].X+2,Sbut.SB[Nr].Y,']');
    WriteXY(Sbut.SB[Nr].X+3,Sbut.SB[Nr].Y,concat(' ',Sbut.SB[Nr].M));
  end;
end;


procedure InitSelButton (var Sbut : SelButton; X,Y:Integer; M:string; S: boolean; Nr:byte);
begin
   SBut.Sb[Nr].X:=X;   SBut.Sb[Nr].Y:=Y;  SBut.Sb[Nr].M:=M;  Sbut.Sb[Nr].S:=S; SBut.Pos:=1;
   SBut.Akt:=true;
end;


procedure SetSelButton (var SBut : SelButton);
begin
  If Sbut.Akt then PaintSelButton(SBut); Sbut.Akt:=false;
end;

procedure ActiveSelButton (var SBut : SelButton);
begin
  PaintSelButton(Sbut); Sbut.Akt:=true;
  gotoxy(SBut.SB[SBut.Pos].X+1,SBut.SB[SBut.Pos].Y); cursor_on;
  Getevent; cursor_off;
end;



function EventSelButton (var SBut : SelButton) : boolean;
var i : byte;
begin
  EventSelButton:=false;
    case ev.Ereignis of
       EV_KEY_PRESSED :
          If Sbut.Akt then
            case ev.key of
              SPACE  : begin
                         If Sbut.Sb[Sbut.Pos].S  then Sbut.Sb[Sbut.Pos].S:=false else Sbut.Sb[Sbut.Pos].S:=true;
                         EventSelButton:=true;
                       end;
              CDOWN  : begin
                         If Sbut.Pos<Sbut.anz  then inc(Sbut.Pos) else Sbut.Pos:=1;
                         EventSelButton:=true;
                       end;
                CUP  : begin
                         If Sbut.Pos>1  then dec(Sbut.Pos) else Sbut.Pos:=Sbut.Anz;
                         EventSelButton:=true;

                       end;
            end;
        end;
   If ((fenanz>0) and (aktber=fenanz)) then
      case ev.Ereignis of
         EV_LEFT_REL :
         begin
           for i:=1 to Sbut.anz do
           begin
             If (ev.spalterel+2<Sbut.Sb[i].X+length(Sbut.Sb[i].M)+5) and (ev.spalterel+2>Sbut.Sb[i].X) and
                (ev.zeilerel+1=SBut.Sb[i].Y) then
             begin
               EventSelButton:=true; If Sbut.Sb[i].S then Sbut.Sb[i].S:=false else Sbut.Sb[i].S:=true;
             end;
           end;
         end;
         EV_LEFT_PRESS :
         begin
           for i:=1 to Sbut.anz do
             If (ev.spalterel+2<Sbut.Sb[i].X+length(Sbut.Sb[i].M)+5) and (ev.spalterel+2>Sbut.Sb[i].X) and
                (ev.zeilerel+1=SBut.Sb[i].Y) then
             begin
               EventSelButton:=true; Sbut.Pos:=i;
             end;
         end;
     end;
end;

{---------------------------------- Editor ----------------------------------}


procedure PaintEditor(Edi : Edit);
begin
  textcolor(fenfo); textbackground(fenba);
  If Edi.P then writeXY ((Edi.X-length(Edi.M)-1),Edi.Y,Edi.M) else
                writeXY (Edi.X, Edi.Y-1, Edi.M);
  textcolor(Editfo); textbackground(Editba);
  writeXY(Edi.X, Edi.Y, pad(Edi.T,Edi.la+1));
end;


procedure InitEditor (var Edi : Edit; X,Y : integer; M : Message; P : boolean;
                          T : string; la: byte);
begin
  Edi.X:=X; Edi.Y:=Y;
  If length(T)>la then delete(T,la+1,length(T)-la);
  Edi.M:=M; Edi.P:=P;
  Edi.T:=T; Edi.Pos:=length(T)+1; Edi.La:=la;
  Edi.Akt:=true;
end;


procedure SetEditor (var Edi : Edit);
begin
  If Edi.Akt then PaintEditor (Edi);  Edi.Akt:=false;
end;


procedure ActiveEditor (var Edi : Edit);
var mla,i : byte;
    ch    : array [1..80] of char;

begin
   textcolor(Editfo); textbackground(Editba);

   for i:=1 to Edi.la do
      ch[i]:=Edi.T[i];

   mla:= length(Edi.T);
   Edi.Sp:=Edi.X+Edi.Pos-1;
   gotoxy(Edi.Sp,Edi.Y);
   if einf = true then  Cursor_Set(18) else Cursor_On;
    repeat
      Getevent;

     If ev.Ereignis=EV_KEY_PRESSED then
     begin

       if ev.key=INSERTKEY then                             { Einf }
       begin
         if einf=false then
         begin
           einf:=true;
           Cursor_Set(18);
         end else
         begin
           einf:=false;
           Cursor_On;
         end;
       end;

       if (Edi.Pos<=Edi.la) and ( (ev.key>31) and (ev.key<127)
          or  (ev.key=129) or (ev.key=132) or (ev.key=142) or (ev.key=148) or (ev.key=153) or (ev.key=154) )
          or (ev.key=225) then
       begin
         if (not einf)  then
         begin
             for i:=mla downto Edi.Pos do
             begin
               ch[i+1]:=ch[i];
               if i<Edi.la then
                 writeXY(Edi.Sp+i-Edi.Pos+1,Edi.Y,ch[i]);
             end;
             if (mla<Edi.la)  then
               inc(mla);
         end else
         begin
           if mla<Edi.Pos then
             inc(mla) ;
         end;
         ch[Edi.Pos]:=char(ev.key);writeXY(Edi.Sp,Edi.Y,ch[Edi.Pos]);
         inc(Edi.Pos);inc(Edi.Sp); gotoxy(Edi.Sp,Edi.Y);
       end;

       if ev.key=BS then                         { Backspace }
       begin
         if Edi.Pos > 1 then
         begin
           ch[mla+1]:=' ';
           for i:=Edi.Pos-1  to mla do
           begin
             ch[i]:=ch[i+1];
             writeXY(Edi.Sp+i-Edi.Pos,Edi.Y,ch[i]);
           end;
           dec(mla);dec(Edi.Pos);dec(Edi.Sp);
           gotoxy(Edi.Sp,Edi.Y);
         end;
       end;

       if ev.key=CLEFT then                         { Links }
       begin
         if (Edi.Pos > 1)  then
         begin
           dec(Edi.Pos);dec(Edi.Sp);gotoxy(Edi.Sp,Edi.Y);
         end;
       end;

       if ev.key=CRIGHT  then                         { Rechts }
       begin
         if Edi.Pos <= mla then
         begin
           inc(Edi.Pos);inc(Edi.Sp);gotoxy(Edi.Sp,Edi.Y);
         end;
       end;

       if ev.key=DELETEKEY then                          { Entf }
       begin
         ch[mla+1]:=' ';
         for i:=Edi.Pos  to mla do
         begin
           ch[i]:=ch[i+1];
           writeXY(Edi.Sp+i-Edi.Pos,Edi.Y,ch[i]);
         end;
         If Edi.Pos <= mla then     dec(mla);
         gotoxy(Edi.Sp,Edi.Y);
     end;

     if ev.key=CHOME then                          { Home }
     begin
       Edi.Sp:=Edi.Sp-Edi.Pos+1;
       gotoxy(Edi.Sp,Edi.Y);
       Edi.Pos:=1;
     end;

     if ev.key=CEND then                           { End }
     begin
       Edi.Sp:=Edi.Sp+mla-Edi.Pos+1;
       gotoxy(Edi.Sp,Edi.Y);
       Edi.Pos:=mla+1;
     end;
   end;

   until (ev.key=CR) or (ev.key=CUP) or (ev.key=CDOWN) or (ev.key=TAB) or (ev.key=ESC) or
         (ev.key=CPGUP) or (ev.key=CPGDN) or (ev.key=BACKTAB) or ((ev.key>=315) and (ev.key<=324) or
         (ev.Buttons in [1,2]) or (ev.Ereignis=EV_LEFT_REL) or (ev.key>=ALT_Q) and (ev.key<=ALT_M));
   Edi.T:='';
    for i:=1 to mla do
    begin
      Edi.T:=(concat(Edi.T,ch[i]));
    end;
    Cursor_Off;  Edi.Akt:=true;
end;


function EventEditor (var Edi: Edit) : boolean;
begin
    EventEditor:=false;
    case ev.Ereignis of
       EV_KEY_PRESSED :
       begin
         If Edi.Akt then EventEditor:=true;
       end;
     end;
  If ((fenanz>0) and (aktber=fenanz)) then
    case ev.Ereignis of
     EV_LEFT_REL:
     begin
       If (ev.spalterel+2>Edi.X) and (ev.spalterel<Edi.X+Edi.la) and
          (ev.zeilerel+1=Edi.Y) then
        begin
          If (ev.spalterel+2>Edi.X) and (ev.spalterel<Edi.X+length(Edi.T)) then
          begin
             Edi.Sp:=ev.Spalterel+1; Edi.Pos:=Edi.Sp-Edi.X+1;
          end else
          begin
             Edi.Sp:=Edi.X+length(Edi.T); Edi.Pos:=Edi.Sp-Edi.X+1;
          end;
          EventEditor:=true;
        end;
     end;
     EV_LEFT_PRESS :
     begin
       If (ev.spalterel+2>Edi.X) and (ev.spalterel<Edi.X+Edi.la) and
          (ev.zeilerel+1=Edi.Y) then
       begin
          If (ev.spalterel+2>Edi.X) and (ev.spalterel<Edi.X+length(Edi.T)) then
            begin
               Edi.Sp:=ev.Spalterel+1; Edi.Pos:=Edi.Sp-Edi.X+1;
            end else
            begin
               Edi.Sp:=Edi.X+length(Edi.T); Edi.Pos:=Edi.Sp-Edi.X+1;
            end;
            EventEditor:=true;
        end;
     end;
     EV_MOU_MOVE :
     begin
       If ev.Buttons=1 then
       begin
         If (ev.spalterel+2>Edi.X) and (ev.spalterel+1<Edi.X+Edi.la) then
         begin
            Edi.Pos:=ev.spalterel-Edi.X+2;
         end;
         If (ev.spalterel+1>=Edi.X+length(Edi.T)) then
         begin
            Edi.Pos:=length(Edi.T)+1;
         end;
         If (ev.spalterel+2<=Edi.X) then
         begin
            Edi.Pos:=1;
         end;
       end;
     end;
  end;

end;



begin
end.


