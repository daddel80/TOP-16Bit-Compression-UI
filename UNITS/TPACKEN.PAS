UNIT TPacken;

Interface
uses TDatei,Tkwin,Tkstring,Tkstream,Dos,Init,Tkdisk,Tksaa,Tkvideo,KBM,Tkview,Crt;

Type
 Packen = Object(Datei)
               Constructor Init;

               procedure   Listendatei(var z:longint;var ausw:boolean);
               function    Packen_Entpacken          : boolean;   virtual;

               procedure   Packerlst(PPointer :Pointer;var feldpos:byte);
               procedure   Moduslst (feld: array of FilenameStr;var feldpos:byte);
               function    Execend(name:string;M:Message;Ar:Acceptrec) : byte;  virtual;

               Destructor  Done;
 End{Packen};



Implementation

Constructor Packen.Init;
begin
  Datei.Init;
end;

function Packen.Packen_Entpacken : boolean;
begin
end;



procedure Packen.Listendatei(var z:longint;var ausw:boolean);
 var fullver: pathstr;
     Verstr : Ftemp;

begin
  z:=0; ausw:=false; Verstr.ver_dat:=false;
  chver(m_tempverz);
  
  Pdat.Create; Filsel.Open;
  while not Filsel.EOF do
  begin
    fullver:=Verzlesen;
    If fullver[1]='\' then delete(fullver,1,1);
    Verstr.Ver_dat:=false;
    while not Filsel.EOF and not Verstr.ver_dat do
    begin
      Filsel.Read(Verstr,-1,1);
      If Verstr.select and not Verstr.Ver_dat then
      begin
        Pdat.Writeln(concat(fullver,Verstr.name));
        inc(z);ausw:=true;
      end;
      If Verstr.ver_dat then
      begin
          Filsel.Seek(Filsel.Pos-1);
      end;
    end;
  end;
  If (z=0) and (not dat.ver_dat and (dat.fpos>1)) then
  begin
    fullver:=addbackslash(fullpath(dat.vpos))+dat.fil[dat.fpos].name;
    If fullver[1]='\' then delete(fullver,1,1);
    Pdat.Writeln(fullver);inc(z);
  end;
  Pdat.close; Filsel.Close;
end;


procedure Packen.Packerlst(PPointer :Pointer;var feldpos:byte);
var S           : Selectview1;
    weiter,
    Ok          : boolean;
    Bu          : Button;
    PackP       : PackPointer;
    I,z         : byte;

begin
  If not openwindow(21,16,fenfo,fenba,'Packer') then exit;
  textcolor(Balkenback);
  WinFrame(3,1,19,14,false);
  S.Init(4,2,19,13,fenba);
  S.SetMarkMode(false);
  PackP:=PPointer;
  while PackP<>NIL do
  begin
    S.AppendStr(PackP^.name);
    PackP:=PackP^.next;
  end;
  S.LineTop;
  For z:=1 to feldpos do S.LineDown;
  Initbutton (Bu,2, 16,'   ~OK   '  ,Alt_O,1);
  Initbutton (Bu,12,16,' ~Abbruch ',Alt_A,2); Bu.anz:=2;
  weiter:=false; OK:=false; I:=1;
  repeat
    Setbutton(Bu);
    S.ViewLines;
    case I of
      1 : ActiveButton(Bu);
    end;
    case EventThisbutton(Bu) of
     1 : begin
           weiter:=true; OK:=true;
         end;
     2 : begin
           weiter:=true; OK:=false;
         end;
    end;
    case ev.Ereignis of
      EV_KEY_PRESSED :
       case ev.key of
        ESC: begin
                weiter:=true; Ok:=false;
             end;
       end{Case};
    end{Case};
    If S.CtrlCode=CR then
    begin
      weiter:=true; OK:=true;
    end;
    S.CtrlLines;
  until weiter;
  If OK then feldpos:=S.GetLineNumber-1;
  closewindow;
end;


 procedure Packen.Moduslst (feld: array of FilenameStr;var feldpos:byte);
 var i       : byte;
    weiter   : boolean;
    Rb       : Rabutton;
    Bu       : Button;
 begin
   If not openwindow(21,High(feld)+4,fenfo,fenba,'Modus') then exit;
   for i:=0 to High(feld) do
      InitRadioButton(Rb,6,i+2,trim(feld[i]),i+1);
   Rb.Anz:=High(feld)+1;
   Rb.Sel:=feldpos+1;
   Rb.Pos:=Rb.Sel;
   InitButton(Bu, 2,High(feld)+4,'   ~OK   ',     ALT_O,1);
   InitButton(Bu,12,High(feld)+4,' ~Abbruch ',ALT_A,2); Bu.Anz:=2;
   I:=1; weiter:=false;
   repeat
     SetRadioButton(Rb);
     SetButton     (Bu);
     case I of
      1: ActiveRadioButton(Rb);
      2: ActiveButton     (Bu);
     end;

     case EventThisButton(Bu) of
      1: begin weiter:=true; feldpos:=Rb.Sel-1; end;
      2: weiter:=true;
     end;

     If EventRadioButton(Rb) then I:=1;

     case ev.key of
       TAB    : If I<2 then Inc(I) else I:=1;
       BACKTAB: If I>2 then dec(I) else I:=2;
       Esc    : weiter:=true;
     end;
   until weiter;
   closewindow;
 end;





{------------------ Entpacken ----------------------------}





 function Packen.Execend(name:string;M:Message;Ar:Acceptrec) : byte;
 var   Errorlevel   : word;
       z            : byte;

 begin
    Execend:=2;
    If Doserror>0 then
    begin
      If Doserror=1 then inc(Doserror,220);
      MouShowMouse;
      Execend:=IO_Error(M,'IOERROR.MSG',Doserror,AR);
      MouHideMouse;
      Doserror:=0;
    end;
    Errorlevel:=Dosexitcode;
    If (LO(Errorlevel))>0 then
    begin
      MouShowMouse;
      Execend:=IO_Error(M,justname(name),Errorlevel,AR);
      MouHideMouse;
    end;
 end;







Destructor Packen.Done;
begin
end;

begin
end.