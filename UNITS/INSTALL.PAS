{$A+,B-,D+,E-,F+,G+,I+,L+,N-,O-,P+,Q-,R+,S+,T-,V+,X+}
program Install;
uses crt,dos,tksaa,tkstring,tkwin,kbm,tpinst,tkvideo,tkdisk,tkview2,tkstream,init;
Type Copystream = Object(Typedstream)
       Procedure Read(var R; P: Longint; Anz: Word);  virtual;
       Procedure Write(var R; P: Longint; Anz: Word); virtual;
     End;

const
    First  : boolean = true;
    Inst_Konfignr=33408;
    First_pos = 58;

    Top_Konfignr =159136;
    Name_pos    =718;
    Strasse_pos =760;
    Ort_pos     =802;
    Liznr_pos   =844;

    Zielverz_pos     = 664;    {tempverz}
    Packerverz_pos   = 612;
    Buf_max = 4042;

    AR : Acceptrec = ('      OK      ','','');

var Ed1,Ed2,Ed3,Ed4: edit;
    Bu         : Button;
    I          : integer;
    fTime      : longint;
    f          : text;
    str40      : string[40];
    str5       : string[5];
    CopyF      : Textstream;
    LizF,
    SourceF,
    TargetF    : Copystream;
    Hilfe      : Helpview1;
    Zeile      : string;
    verz       : Pathstr;
    Laufw      : String[2];
    Buf        : array [1..Buf_Max] of Char;
    OK,weiter  : boolean;
    S          : string;
    z          : byte;
    Dirinfo    : SearchRec;
label  Fehler;


Procedure Copystream.read(var R; P: Longint; Anz: Word);
begin
  If P = -1 then P:=Pos;                       {sequentielles Lesen}
  If OK then
     repeat
       seek(P);
       {$I-} Blockread (F, R, Anz, Result); {$I+}
       Ok := Inoutres=0;
     until testerror(readmsg);
  {EndIf}
end;

Procedure Copystream.Write(var R; P: Longint; Anz: Word);
begin
  If P = -1 then P:=Pos;                        {sequentielles Schreiben}
  If OK then
     repeat
        seek(P);
        {$I-} Blockwrite(F, R, Anz, Result); {$I+}
        Ok := Inoutres=0;
     until Testerror(writemsg);
  {End IF}
end;


FUNCTION Mkver(S:String) : Boolean;
var Verzeichnis : Pathstr;
    Verz        : string;
begin
  getver(0,Verzeichnis);
  S:=addbackslash(S);
  If length(S) > 1 then
    If S[2]=':' then
    begin
      If not chver(S[1]+':'+'\') then
      begin
        Mkver:=false; chver(Verzeichnis); exit;
      end;
      delete(S,1,2);
    end;
  {EndIF}
  If pos('\',S)=1 then delete(S,1,1);
  while (S<>'') and (S<>'\') do
  begin
    Verz  :=copy(S,1,pos('\',S)-1);
    If not chver(Verz) then
    begin
      {$I-} mkdir(Verz); {$I+}
      If (Ioresult>0) or not chver(Verz) then
      begin
        Mkver:=false; chver(Verzeichnis); exit;
      end;
    end;
    delete(S,1,pos('\',S));
  end;
  chver(Verzeichnis);
  Mkver:=true;
end;



  function Abfrage(M :Message):boolean;
  var i      : byte;
      Ab     : Button;
      weiter : boolean;

  begin
    Abfrage:=true;
    openwindow(31,4,white,red,'Abfrage');
    textcolor(yellow);writeXY(1,2,center(M,31));
    Initbutton(Ab, 4,4,'    ~Ja    ',Alt_J,1);
    Initbutton(Ab,19,4,'   ~Nein   ',Alt_N,2);
    Ab.anz:=2; I:=1; weiter:=false; Ab.FaFen:=red;
    repeat
      Setbutton(Ab);
      case I of
        1: Activebutton(Ab);
      end;

      case EventThisbutton(Ab) of
       1 : begin
             Abfrage:=true; weiter:=true;
           end;
       2 : begin
             Abfrage:=false; weiter:=true;
           end;
        end;

      case ev.Ereignis of
        EV_KEY_PRESSED :
        case ev.key of
      ESC : begin
               Abfrage:=false; weiter:=true;
            end;
          end;
      end;
    until weiter;
    closewindow;
  end;

Function CopyFrom(S:string):string;
begin
  while pos(' ',S)=1 do delete(S,1,1);
  If pos(' ',S)>0 then
    CopyFrom:=copy(S,1,pos(' ',S)) else
    CopyFrom:=copy(S,1,length(S));
end;


Function CopyTo(S:string):string;
var l : string;
begin
  while pos(' ',S)=1 do delete(S,1,1);
  If pos(' ',S)>0 then
    CopyTo:=(trim(copy(S,pos(' ',S),length(S)-pos(' ',S)+1))) else
    CopyTo:='';
end;


Procedure Ende(Fehler:boolean);
var Bu     : Button;
    weiter : boolean;

begin
  openwindow(50,5,fenfo,fenba,'Ende');
  Initbutton(Bu, 20,5,'     ~Ok     ',Alt_O,1); Bu.anz:=1;
  textcolor(MessageCol);
  If Fehler then
    writeXY(1,2,center('Die Installation wurde abgebrochen!',50)) else
  begin
    writeXY(2,2,'Die Installation wurde erfolgreich durchgefÅhrt!');
    writeXY(2,3,'Geben Sie TOP ein, um das Programm zu starten!');
  end;
  weiter:=false;
  repeat
    Activebutton(Bu);
    weiter:=EventThisbutton(Bu)=1;

    case ev.Ereignis of
        EV_KEY_PRESSED :
        case ev.key of
      ESC : begin
               weiter:=true;
            end;
          end;
      end;
  until weiter;
  closewindow;
  textbackground(black); textcolor(Lightgray);
  CopyF.Done; Cursor_on;
  halt(0);
end;


begin
  Farbe1; cursor_off;
  Moushowmouse; getver(0,verz); Laufw:=verz[1]+':';
  CopyF.Init(addbackslash(justpathname(paramstr(0)))+'install.fid');
  If first then
  begin

    CopyF.Open;
    If not CopyF.Ok then Ende(True);
    CopyF.ReadLn(Zeile);
    If not CopyF.Ok then Ende(True);
    CopyF.Close;

    {Initeditor (Ed1 ,20, 4,'Lizensnummer   :',true,'',  5);}
    Initeditor (Ed2 ,20, 4,'Name           :',true,'',  40);
    Initeditor (Ed3 ,20, 6,'Stra·e         :',true,'',  40);
    Initeditor (Ed4 ,20, 8,'Ort            :',true,'',  40);

    Initbutton(Bu,13,10,'    ~Weiter     ', Alt_W,1);
    Initbutton(Bu,45,10,'    ~Abbruch    ', Alt_A,2); Bu.anz:=2;

    openwindow(70,10,fenfo,fenba,'Installation von TOP 2.1');
    Fehler :;
    textbackground(fenba); textcolor(MessageCol);
    writeXY(3,2,'Bitte geben Sie hier Ihre persînlichen Daten an!');
    OK:=false; weiter:=false;     I:=2;
    repeat
      SetButton(Bu);

      {Seteditor(Ed1);}
      Seteditor(Ed2);
      Seteditor(Ed3);
      Seteditor(Ed4);


      case I of
       {1: ActiveEditor(Ed1);}
       2: ActiveEditor(Ed2);
       3: ActiveEditor(Ed3);
       4: ActiveEditor(Ed4);
       6: Activebutton(Bu);
      end;

     case EventThisButton(Bu) of
       1 : begin
              If trim(Ed2.T)='' then goto Fehler;   { kein Name eingegeben }
              If Abfrage('Sind Ihre Angaben korrekt ?') then
              begin

                chver(justpathname(Laufw+CopyFrom(Zeile)));
                tpiopenfile('top.exe', Top_Konfignr);

                {str40:=crypt(Ed1.T);
                tpiput(Liznr_pos,6,str40);}
                str40:=crypt(Ed2.T);
                tpiput(Name_pos,41,str40);
                str40:=crypt(Ed3.T);
                tpiput(Strasse_pos,41,str40);
                str40:=crypt(Ed4.T);
                tpiput(Ort_pos,41,str40);
                tpisavechanges;
                tpiclosefile;

                If f_spe then
                begin
                  IO_Error('Kann Top.exe nicht initialisieren','IOERROR.MSG',101, AR);
                  goto Fehler;
                end;

                chver(justpathname(paramstr(0)));
                tpiopenfile('install.exe', Inst_Konfignr);
                First:=false;
                tpiput(First_pos,1,First);
                tpisavechanges;
                tpiclosefile;
                If f_spe then
                begin
                  IO_Error('Kann Install.exe nicht initialisieren','IOERROR.MSG',101, AR);
                  goto Fehler;
                end;
                OK:=true; weiter:=true;
              end;
           end;
       2 : begin
              weiter:=true;
           end;
     end;


     {If EventEditor(Ed1)  then I:=1;}
     If EventEditor(Ed2)  then I:=2;
     If EventEditor(Ed3)  then I:=3;
     If EventEditor(Ed4)  then I:=4;


   case ev.Ereignis of
     EV_KEY_PRESSED :
       case ev.key of
   BACKTAB,
   CUP    : begin
             dec(I);
             If I<{1}2 then I:=6;
            end;
   TAB,
   CDOWN  : begin
             inc(I);
             If I>6 then I:={1}2;
            end;
    ESC   : weiter:=true;
     end;
   end;

    until weiter;
    closewindow;

  If not Ok then Ende(True);
 end;
  { 2. Fenster }
  Initeditor (Ed1 ,22, 7,'Zielverzeichnis  :',true,'',  45);
  Initeditor (Ed2 ,22, 9,'Packerverzeichnis:',true,'',  45);
  Ed1.T:='C:\TOP';
  Ed2.T:='C:\TOP\PACKER';
  Initbutton(Bu,15,12,'    ~Installieren     ', Alt_S,1);
  Initbutton(Bu,45,12,'   ~Abbruch   ',   Alt_A,2); Bu.anz:=2;

  openwindow(70,12,fenfo,fenba,'Installation von TOP 2.1');
  textcolor(white);
  writeXY(11,2,'TOP - Toms OberflÑche fÅr Packprogramme - Version 2.1');
  textcolor(MessageCol);
  writeXY(17,3,'Copyright (C) 1992-95, Thomas Knîfel');
  textcolor(fenfo);
  for z:=1 to 71 do
    writexy(z,4,'ƒ');
  OK:=false; weiter:=false;     I:=1;
  repeat
    SetButton(Bu);

    Seteditor(Ed1);
    Seteditor(Ed2);

    case I of
     1: ActiveEditor(Ed1);
     2: ActiveEditor(Ed2);
     3: ActiveButton(Bu);
    end;

   case EventThisButton(Bu) of
     1 : begin
           If not chver(Ed1.T[1]+':'+'\') then
           begin
             closewindow; closewindow;
             Ende(True);
           end;

           CopyF.Open;
           CopyF.ReadLn(Zeile);
           CopyF.Close;


           CopyF.Open;
           Openwindow(36,2,yellow,lightgreen,'Kopieren');

           If not mkver(Ed1.T) or not mkver(Ed2.T)then
           begin
             closewindow; closewindow;
             Ende(True);
           end;

           While not CopyF.EOF do
           begin
             CopyF.ReadLn(Zeile);
             chver(justpathname(Laufw+CopyFrom(Zeile)));
             S :=Ed1.T;
             SourceF.Init(Laufw+CopyFrom(Zeile),1);
             If CopyTo(Zeile) = '2' then
               TargetF.Init(addbackslash(Ed2.T)+justfilename(CopyFrom(Zeile)),1) else
               TargetF.Init(addbackslash(Ed1.T)+justfilename(CopyFrom(Zeile)),1);
             SourceF.Open;
             If not SourceF.OK then
             begin
               closewindow; closewindow;
               Ende(True);
             end;
             TargetF.Create;
             If not TargetF.OK then
             begin
               closewindow; closewindow;
               Ende(True);
             end;
             findFirst(Laufw+CopyFrom(Zeile), $37, DirInfo);
             If Doserror > 0 then
             begin
               closewindow; closewindow;
               Ende(True);
             end;
             writeXY(3,2,concat('Kopiere   ÕÕÕÕ   ',pad(justfilename(CopyFrom(Zeile)),12)));
             While not SourceF.EOF  do
             begin
               SourceF.Read(Buf,-1,Buf_max);
               TargetF.Write(Buf,-1,SourceF.Result);
               If not SourceF.OK or not TargetF.OK then
               begin
                 closewindow; closewindow;
                 Ende(True);
               end;
             end;
             {$I-}GetFTime(SourceF.F,fTime);{$I+}
             Doserror:=IOresult; Doserror:=0;
             SetFTime(TargetF.F,fTime);
             SourceF.Done;
             TargetF.Done;

             chver(Ed1.T);
             tpiopenfile('top.exe', Top_Konfignr);
             tpiput(Zielverz_pos,  51,Ed1.T);
             tpiput(Packerverz_pos,51,Ed2.T);
             tpisavechanges;
             tpiclosefile;

           End{While};
           closewindow;
           CopyF.Close;
           OK:=true; weiter :=true;
         end;
     2 : weiter :=true;
   end;

   If EventEditor(Ed1)  then I:=1;
   If EventEditor(Ed2)  then I:=2;

   case ev.Ereignis of
   EV_KEY_PRESSED :
     case ev.key of
 BACKTAB,
 CUP    : begin
           dec(I);
           If I<1 then I:=3;
          end;
 TAB,
 CDOWN  : begin
           inc(I);
           If I>3 then I:=1;
          end;
  ESC   : weiter:=true;
   end;
 end;

  until weiter;
  closewindow;
  If not OK then Ende(True);
  chver(Ed1.T);
  Ende(False);
end.