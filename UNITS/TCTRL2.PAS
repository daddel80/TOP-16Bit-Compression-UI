Unit TCTRL2;

Interface
uses TControl,Init,Tksaa,Tkstream,Tkstring,Tkdisk,Tkwin,Tkvideo,Kbm,Crt,Dos,Swap;

Type
RechtsFenster = Object(Control)
                Constructor Init;
                function  Packen_Entpacken : boolean; virtual;
                function  Entpacken        : boolean;
                procedure Dekomprimieren;
                procedure Fakt;
      End{Object Rechtsfenakt};

LinksFenster = Object(Control)
               Constructor Init;
               function  Packen_Entpacken : boolean;  virtual;
               function  Packen           : boolean;
               function  APacken          : boolean;
               procedure Komprimieren;
      End{LinksFenster};

var LFenster              : ^Linksfenster;
    RFenster              : ^Rechtsfenster;


Implementation






{--------------------------- Linksfenster ------------------------}

Constructor Linksfenster.Init;
begin
  Control.Init(Links,Leftdatname,Leftdatindex,2); Funktionen(true);
  Fenakt(False,True,False);
end;


function Linksfenster.Packen_Entpacken : boolean;
begin
  If ArcOpen then
    Packen_Entpacken:=APacken else
    Packen_Entpacken:=Packen;
end;


function Linksfenster.Packen : boolean;
const    M = 'Fehler beim Komprimieren :';
var tas,fun   : char;
    Vp        : Dparam;
    i         : byte;
    weiter    : boolean;
    zahl      : string[15];
    Bu        : Button;
    Sb1,Sb2,Sb3,
    Sb4,Sb5   : Selbutton;
    Ed1,Ed2,Ed3 : Edit;
    Pack        : boolean;
    LwCh        : boolean;



  procedure Packers;
  var z,k       : byte;
      Pack,
      PackStart,
      PackMerk  : PackPointer;
      pmax      : byte;

  begin
    Packer_File.Seek(0);
    PackStart:=NIL; Pack:=NIL;
    while not Packer_File.EOF do      {Liste aufbauen}
    begin
      Packer_File.Read(Vp,-1,1);
      PackMerk:=Pack;
      new(Pack);
      If PackStart=NIL then Packstart:=Pack;
      Pack^.Name:=upstring(justname(Vp.verp));
      Pack^.Next:=NIL;
      If PackMerk<>NIL then PackMerk^.Next:=Pack;
    end;
    Packerlst(PackStart,Kom.pack);
    while PackStart<>NIL do           {Liste l”schen}
    begin
      Pack:=PackStart; PackStart:=Pack^.Next; dispose(Pack);
    end;
    Packer_File.Read(Vp,Kom.pack,1);
    Sb1.Sb[1].S:=false; Sb2.Sb[1].S:=false; Sb3.Sb[1].S:=true; Sb4.Sb[1].S:=true; Sb5.Sb[1].S:=false;
    Sb1.akt:=true; Sb2.akt:=true; Sb3.akt:=true; Sb4.akt:=true; Sb5.akt:=true;
    Ed3.akt:=true;
  end;



begin
  Packen:=false; Packer_File.Open;
  If Packer_File.Size=0 then
  begin
    IO_Error(M,'IOERROR.MSG',223,AR1); exit;
  end;
  If not dat.ver_dat and (dat.filanz>1) then Packdateiwrite(dat.vpos);
  Listendatei(Kom.sel,Kom.ausw);
  If Packer_File.Size<=m_pack then m_pack:=0;
  Kom.pack:=m_pack; Kom.komp:=m_komp; Kom.arc:=''; Kom.pas:='';Kom.ver:=false;
  Kom.self:=false; Kom.path:=false; Kom.Uv:=false; Kom.mV:=false;
  Packer_File.Read(Vp,Kom.pack,1);
  Lw.Dr:=RFenster^.dat.ver[1].name[1];
  DriveKind(Lw);
  LwCh:=Lw.Ch[1]='0';
  If dat.vpos>1 then Kom.arc:=dat.ver[dat.vpos].name;
  Kom.datei:='*.*';
  If not openwindow(59,12,fenfo,fenba,'Komprimieren') then exit;

  writeXY(3,2,'Packen von :');

  InitEditor(Ed1,16,2,'',true,Kom.datei,12);
  InitEditor(Ed2,16,4,'in Archiv  :',true,Kom.arc  ,8);
  InitEditor(Ed3,45,4,'Passwort :',true,Kom.pas,12);

  InitSelbutton(Sb1,3 ,8 ,'Dateien verschieben',Kom.ver,1);      Sb1.Anz:=1;
  InitSelbutton(Sb2,34,8,'Selbstentpacker',Kom.self,1);          Sb2.Anz:=1;
  InitSelbutton(Sb3,3 ,9 ,'Mit Verzeichnisstruktur',true{Kom.path},1); Sb3.Anz:=1;
  InitSelbutton(Sb4,34,9 ,'Multiple Volume',true,1);           Sb4.Anz:=1;
  InitSelbutton(Sb5,3 ,10,'Mit Unterverzeichnissen',Kom.Uv,1);   Sb5.Anz:=1;


  InitButton(Bu, 3,12,'  ~Komprimieren  ',Alt_K,1);
  InitButton(Bu,21,12,'   ~Packer   ',    Alt_P,2);
  InitButton(Bu,35,12,'   ~Modus   ',     Alt_M,3);
  InitButton(Bu,48,12,'  ~Abbruch  ',   Alt_A,4); Bu.Anz:=4;

  I:=2; weiter:=false; Pack:=false;
  repeat

    SetEditor(Ed2);

    textcolor(fenfo);textbackground(fenba);
    If trim(Vp.passw)>'' then
      SetEditor(Ed3) else
      writeXY(34,4,'                        ');

    textcolor(fenfo);textbackground(fenba);
    If (trim(Vp.VohneV)>'')  then
      SetSelbutton(Sb1) else
    begin
      writeXY(3,8,'                        '); Sb1.Sb[1].S:=false;
    end;

    

    If not ((trim(Vp.multipleV)>'') and LwCh) then
      If (trim(Vp.self)>'') then
        SetSelbutton(Sb2) else
      begin
        writeXY(34,8,'                   ');     Sb2.Sb[1].S:=false;
      end;
    {EndIf}

    If ((trim(Vp.VohneV)='') and (trim(Vp.PmitV)>'')) or
       ((trim(Vp.VohneV)>'') and (trim(Vp.PmitV)>'') and (trim(Vp.VmitV)>'')) then
      SetSelbutton(Sb3) else
    begin
      writeXY(3,9,'                           '); Sb3.Sb[1].S:=false;
    end;

    If (trim(Vp.multipleV)>'') and LwCh then
      SetSelbutton(Sb4) else
    begin
      writeXY(34,9,'                   ');     Sb4.Sb[1].S:=false;
    end;

    If Kom.sel=0 then
    begin
      If trim(Vp.PmitUv)>'' then
        SetSelbutton(Sb5) else
      begin
        writeXY(3,10,'                           '); Sb5.Sb[1].S:=false;
      end;
    end;



    Setbutton(Bu);

    textcolor(fenfo);textbackground(fenba);
    writeXY( 3,6,concat(chr(254),' ',pad(justname(upstring(Vp.verp)),9),'Packer'));
    writeXY(34,6,concat(chr(254),' ',pad(Ko[Kom.komp],5),'Komprimierung'));

    If (Kom.sel>0) and Kom.ausw then
    begin
      str(Kom.sel,zahl);
      If Kom.sel>1 then
        writeXY(16,2,concat(zahl,' Dateien')) else
        writeXY(16,2,concat(zahl,' Datei'));
    end else
    begin
      If (not dat.ver_dat) and (dat.fpos>1) then
        writeXY(16,2,upstring(dat.fil[dat.fpos].name)) else
        SetEditor(Ed1);
    end;

    case I of
     1: ActiveEditor(Ed1);
     2: ActiveEditor(Ed2);
     3: ActiveEditor(Ed3);
     4: ActiveSelButton(Sb1);
     5: ActiveSelButton(Sb2);
     6: ActiveSelButton(Sb3);
     7: ActiveSelButton(Sb4);
     8: ActiveSelButton(Sb5);
     9: ActiveButton(Bu);
    end;

    case EventThisbutton(Bu) of
      1 : begin
            If (Kom.sel=0) then
              Kom.datei:=Ed1.T;
            Kom.arc  :=Ed2.T;
            If trim(Kom.arc)<>'' then
            begin
              Pack  :=true;
              weiter:=true;
            end;
            If (trim(Vp.passw)>'') then
              Kom.pas  :=Ed3.T;
            If (trim(Vp.VohneV)>'') then
              Kom.ver :=Sb1.Sb[1].S;
            If not((trim(Vp.multipleV)>'') and LwCh) then
              If (trim(Vp.self)>'') then
                Kom.self :=Sb2.Sb[1].S;
            If ((trim(Vp.VohneV)='') and (trim(Vp.PmitV)>'')) or
               ((trim(Vp.VohneV)>'') and (trim(Vp.PmitV)>'') and (trim(Vp.VmitV)>'')) then
              Kom.path:=Sb3.Sb[1].S;
            If (trim(Vp.multipleV)>'') and LwCh then
              Kom.mV:=Sb4.Sb[1].S;
            If (trim(Vp.PmitUv)>'') and (Kom.sel=0) then
              Kom.Uv:=Sb5.Sb[1].S;
          end;
      2 : begin
            Packers;
            Sb1.Akt:=True;
            Sb2.Akt:=True;
            Sb3.Akt:=True;;
            Ed1.Akt:=True;
            Ed2.Akt:=True;
            Ed3.Akt:=True;
            I:=2;
          end;
      3 : Moduslst(Ko,Kom.komp);
      4 : begin
            weiter:=true;
            Pack:=false;
          end;
       end;

    If (Kom.sel=0) then
      If EventEditor(Ed1) then I:=1;
    If EventEditor(Ed2) then I:=2;

    If (trim(Vp.passw)>'') then
      If EventEditor(Ed3) then I:=3;

    If (trim(Vp.VohneV)>'') then
      If EventSelButton(Sb1) then I:=4;

    If not((trim(Vp.multipleV)>'') and LwCh) then
      If (trim(Vp.self)>'') then
        If EventSelButton(Sb2) then I:=5;

    If ((trim(Vp.VohneV)='') and (trim(Vp.PmitV)>'')) or
       ((trim(Vp.VohneV)>'') and (trim(Vp.PmitV)>'') and (trim(Vp.VmitV)>'')) then
      If EventSelButton(Sb3) then I:=6;

    If (trim(Vp.multipleV)>'') and LwCh then
      If EventSelButton(Sb4) then I:=7;

    If (trim(Vp.PmitUv)>'') and (Kom.sel=0) then
      If EventSelButton(Sb5) then I:=8;

    case ev.Ereignis of
    EV_KEY_PRESSED :
      case ev.key of
  CUP,
  BACKTAB: begin
             If I>1 then dec(I) else I:=9;
             If ((trim(Vp.PmitUv)='') and (I=8)) or
                ((Kom.sel>0)          and (I=8))then dec(I);
             If ((trim(Vp.multipleV)='') or not LwCh) and (I=7) then dec(I);
             If not (((trim(Vp.VohneV)='') and (trim(Vp.PmitV)>'')) or
                    ((trim(Vp.VohneV)>'') and (trim(Vp.PmitV)>'') and (trim(Vp.VmitV)>'')))
                                     and (I=6)  then dec(I);
             If ((trim(Vp.self) ='') or ((trim(Vp.multipleV)>'') and LwCh))
                                     and (I=5) then dec(I);
             If (trim(Vp.VohneV)='') and (I=4) then dec(I);
             If (trim(Vp.passw)='')  and (I=3) then dec(I);
             If (Kom.sel>0)          and (I=1) then dec(I);
            end;
     CDOWN,
       TAB:begin
             If I<9 then inc(I) else I:=1;
             If (Kom.sel>0)          and (I=1) then inc(I);
             If (trim(Vp.passw)='')  and (I=3) then inc(I);
             If (trim(Vp.VohneV)='') and (I=4) then inc(I);
             If ((trim(Vp.self) ='') or ((trim(Vp.multipleV)>'') and LwCh))
                                     and (I=5) then inc(I);
             If not (((trim(Vp.VohneV)='') and (trim(Vp.PmitV)>'')) or
                    ((trim(Vp.VohneV)>'') and (trim(Vp.PmitV)>'') and (trim(Vp.VmitV)>'')))
                                     and (I=6) then inc(I);
             If ((trim(Vp.multipleV)='') or not LwCh) and (I=7) then inc(I);
             If ((trim(Vp.PmitUv)='') and (I=8)) or
                ((Kom.sel>0)          and (I=8))then inc(I);
           end;
       Esc : weiter:=true;
       F1  : Hilfe.ViewPage(23);
        end;
   end;
  until weiter;
  closewindow; m_pack:=Kom.pack; m_komp:=Kom.komp; Packer_File.Close;
  If Pack then Komprimieren;
  Packen:=Pack;
end;

function Linksfenster.APacken:boolean;
const  M = 'Fehler beim Komprimieren :';
var tas,fun   : char;
    Vp        : Dparam;
    i         : byte;
    weiter    : boolean;
    zahl      : string[15];
    Bu        : Button;
    Sb1,Sb3,Sb5: Selbutton;
    Ed1,Ed3   : Edit;
    Pack      : boolean;

begin
  APacken:=false; Packer_File.Open;
  If Packer_File.Size=0 then
  begin
    IO_Error(M,'IOERROR.MSG',223,AR1); exit;
  end;
  If not LFenster^.dat.ver_dat and (LFenster^.dat.filanz>1) then LFenster^.Packdateiwrite(LFenster^.dat.vpos);
  LFenster^.Listendatei(Kom.sel,Kom.ausw);
  Vp.Arcend:='';

  while not Packer_File.EoF and not CompArcend(Vp.Arcend,RFenster^.dat.fil[RFenster^.dat.fpos].name) do
    Packer_File.Read(Vp,-1,1);


  Kom.pack:=Packer_File.Pos-1; Kom.komp:=m_komp; Kom.arc:=''; Kom.pas:='';Kom.ver:=false;
  Kom.self:=false; Kom.path:=false; Kom.Uv:=false; Kom.ver:=false;

  Kom.arc:=RFenster^.dat.fil[RFenster^.dat.fpos].name;
  If (trim(Vp.PmitUv) > '') and (Kom.sel=0) then Kom.path:=true;
  Kom.datei:='*.*';
  If not openwindow(59,12,fenfo,fenba,'Komprimieren') then exit;

  writeXY(3,2,'Packen von :');

  InitEditor(Ed1,16,2,'',true,Kom.datei,12);
  writeXY(3,4,'in Archiv  : '+upstring(Kom.arc));
  InitEditor(Ed3,45,4,'Passwort :',true,Kom.pas,12);

  InitSelbutton(Sb1,3,8,'Dateien verschieben',Kom.ver,1); Sb1.Anz:=1;
  InitSelbutton(Sb3,3 ,9 ,'Mit Verzeichnisstruktur',true{Kom.path},1); Sb3.Anz:=1;
  InitSelbutton(Sb5,3 ,10,'Mit Unterverzeichnissen',Kom.Uv,1);   Sb5.Anz:=1;

  InitButton(Bu, 3,12,'  ~Komprimieren  ',Alt_K,1);
  InitButton(Bu,35,12,'   ~Modus   ',     Alt_M,2);
  InitButton(Bu,48,12,'  ~Abbruch  ',   Alt_A,3); Bu.Anz:=3;

  I:=6; weiter:=false; Pack:=false;
  repeat

    If trim(Vp.passw)>'' then
      SetEditor(Ed3);

    textcolor(fenfo);textbackground(fenba);

    If (trim(Vp.VohneV)>'')  then
      SetSelbutton(Sb1) else
    begin
      writeXY(3,8,'                        '); Sb1.Sb[1].S:=false;
    end;

    If ((trim(Vp.VohneV)='') and (trim(Vp.PmitV)>'')) or
       ((trim(Vp.VohneV)>'') and (trim(Vp.PmitV)>'') and (trim(Vp.VmitV)>'')) then
      SetSelbutton(Sb3) else
    begin
      writeXY(3,9,'                           '); Sb3.Sb[1].S:=false;
    end;

    If Kom.sel=0 then
    begin
      If trim(Vp.PmitUv)>'' then
        SetSelbutton(Sb5) else
      begin
        writeXY(3,10,'                           '); Sb5.Sb[1].S:=false;
      end;
    end;


    If (Kom.sel>0) and Kom.ausw then
    begin
      str(Kom.sel,zahl);
      If Kom.sel>1 then
        writeXY(16,2,concat(zahl,' Dateien')) else
        writeXY(16,2,concat(zahl,' Datei'));
    end else
    begin
      If (not LFenster^.dat.ver_dat) and (LFenster^.dat.fpos>1) then
      begin
        writeXY(16,2,upstring(LFenster^.dat.fil[LFenster^.dat.fpos].name))
      end else
        SetEditor(Ed1);
    end;

    Setbutton(Bu);
    textcolor(fenfo);textbackground(fenba);
    writeXY( 3,6,concat(chr(254),' ',pad(justname(upstring(Vp.verp)),9),'Packer'));
    writeXY(34,6,concat(chr(254),' ',pad(Ko[Kom.komp],5),'Komprimierung'));

    case I of
     1: ActiveEditor(Ed1);
     2: ActiveEditor(Ed3);
     3: ActiveSelButton(Sb1);
     4: ActiveSelButton(Sb3);
     5: ActiveSelButton(Sb5);
     6: ActiveButton(Bu);
    end;


    case EventThisbutton(Bu) of
      1 : begin
            Pack:=true;
            weiter:=true;
            If (Kom.sel=0) then
              Kom.datei:=Ed1.T;
            If (trim(Vp.passw)>'') then
              Kom.pas  :=Ed3.T;
            If (trim(Vp.VohneV)>'') then
              Kom.ver :=Sb1.Sb[1].S;
            If ((trim(Vp.VohneV)='') and (trim(Vp.PmitV)>'')) or
               ((trim(Vp.VohneV)>'') and (trim(Vp.PmitV)>'') and (trim(Vp.VmitV)>'')) then
              Kom.path:=Sb3.Sb[1].S;
            If (trim(Vp.PmitUv)>'') and (Kom.sel=0) then
              Kom.Uv:=Sb5.Sb[1].S;
          end;
      2 : Moduslst(Ko,Kom.komp);
      3 : begin
            weiter:=true;
          end;
       end;


    If not ((Kom.sel>0) and Kom.ausw) and not ((not LFenster^.dat.ver_dat) and (LFenster^.dat.fpos>1)) then
      If EventEditor(Ed1) then I:=1;

    If (trim(Vp.passw)>'') then
      If EventEditor(Ed3) then I:=2;
    If (trim(Vp.VohneV)>'') then
      If EventSelButton(Sb1) then I:=3;
    If ((trim(Vp.VohneV)='') and (trim(Vp.PmitV)>'')) or
       ((trim(Vp.VohneV)>'') and (trim(Vp.PmitV)>'') and (trim(Vp.VmitV)>'')) then
      If EventSelButton(Sb3) then I:=4;
    If (trim(Vp.PmitUv)>'') and (Kom.sel=0) then
      If EventSelButton(Sb5) then I:=5;
    case ev.Ereignis of
    EV_KEY_PRESSED :
      case ev.key of
  CUP,
  BACKTAB: begin
             If I>1 then dec(I) else I:=6;
             If ((trim(Vp.PmitUv)='') and (I=5)) or
                ((Kom.sel>0)          and (I=5))then dec(I);
             If not (((trim(Vp.VohneV)='') and (trim(Vp.PmitV)>'')) or
                    ((trim(Vp.VohneV)>'') and (trim(Vp.PmitV)>'') and (trim(Vp.VmitV)>'')))
                                     and (I=4)  then dec(I);
             If (trim(Vp.VohneV)='') and (I=3) then dec(I);
             If (trim(Vp.passw)='')  and (I=2) then dec(I);
             If (Kom.sel>0)          and (I=1) then dec(I);
            end;
     CDOWN,
       TAB:begin
             If I<6 then inc(I) else I:=1;
             If (Kom.sel>0)          and (I=1) then inc(I);
             If (trim(Vp.passw)='')  and (I=2) then inc(I);
             If (trim(Vp.VohneV)='') and (I=3) then inc(I);
             If not (((trim(Vp.VohneV)='') and (trim(Vp.PmitV)>'')) or
                    ((trim(Vp.VohneV)>'') and (trim(Vp.PmitV)>'') and (trim(Vp.VmitV)>'')))
                                     and (I=4) then inc(I);
             If ((trim(Vp.PmitUv)='') and (I=5)) or
                ((Kom.sel>0)         and (I=5))then inc(I);
       End{Case};
       Esc : weiter:=true;
       F1  : Hilfe.ViewPage(23);
        end;
   end;
  until weiter;
  closewindow; m_komp:=Kom.komp; Packer_File.Close;
  If Pack then Komprimieren;
  APacken:=Pack;
end;



  procedure LinksFenster.Komprimieren;
  const M = 'Fehler beim Komprimieren :';
  var Cmdline,progdir : pathstr;
                 tstr : pathstr;
                   Vp : Dparam;
             ex,fhohe : byte;

  begin
    Dosexitcode;
    Packer_File.Open;
    Packer_File.read(Vp,kom.pack,1);
    Packer_File.Close;
    Progdir:=concat(addbackslash(m_packverz),Vp.verp,' ');
    FindFirst(Progdir, $27, DirInfo);
    If ((Dirinfo.name='') or (Doserror>0)) then
    begin
       execend(Vp.verp,concat(M,' ',Vp.verp),Ar1); MouShowMouse;
       Doserror:=0;exit;
    end;
    chver(LFenster^.dat.aktverz); Cmdline:='';
    If Kom.ver then
    begin
      If Kom.path then
        Cmdline:=Vp.VmitV else Cmdline:=Vp.VohneV;
    end else
    begin
      If Kom.path then
        Cmdline:=Vp.PmitV else Cmdline:=Vp.PohneV;
    end;
    If Kom.Uv then
        Cmdline:=Cmdline+' '+Vp.PmitUv;
    case Kom.Komp of
     0: Cmdline:=Cmdline+' '+Vp.null;
     1: Cmdline:=Cmdline+' '+Vp.min;
     2: Cmdline:=Cmdline+' '+Vp.norm;
     3: Cmdline:=Cmdline+' '+Vp.max;
    end;
    If Kom.self then
      Cmdline:=concat(Cmdline,' ',Vp.self);
    If Kom.mV then
      CmdLine:=concat(Cmdline,' ',Vp.multipleV);
    If Kom.pas>'' then
      Cmdline:=concat(Cmdline,' ',Vp.passw,Kom.pas);
    Cmdline:=concat(Cmdline,' ',addbackslash(RFenster^.dat.aktverz),Kom.arc);
    If m_interM then
    begin
      If not savewin(2,2,crtxmax-ShadowX,crtymax-ShadowY) then exit;
      MouDefBereich(2,Map);
      MouHideMouse; Ausblenden;
    end else
    begin
      If trim(Vp.packdat)>'' then fhohe:=2 else fhohe:=4;
      If not openwindow(31,fhohe,fenfo,fenba,'Komprimieren') then exit;
      textcolor(MessageCol);
      If Kom.sel=1 then
        writeXY(10,2,'Packe Datei...') else writeXY(10,2,'Packe Dateien...');
      MouHideMouse; redout;
    end;
    If Kom.sel=0 then
    begin
      Cmdline:=concat(Cmdline,' ',Kom.datei);
      repeat
        textcolor(lightgray); textbackground(black);
        Doserror:=ExecPrg(concat(Progdir,Cmdline));
      until execend(Vp.verp,M,Ar2)=2;
    end else
    begin
      If trim(Vp.packdat)>'' then
      begin
        Cmdline:=concat(Cmdline,' ',Vp.packdat,addbackslash(m_tempverz),'PDAT.LST');
        repeat
          textcolor(lightgray); textbackground(black);
          Doserror:=ExecPrg(concat(Progdir,Cmdline));
        until execend(Vp.verp,M,Ar2)=2;
      end else
      begin
        Pdat.Open; ex:=0;
        while not Pdat.EOF and (ex<>3) do
        begin
          Pdat.Readln(tstr);
          If not m_InterM then
          begin
            textcolor(fenfo); textbackground(fenba);
            writeXY(1,4,center(justfilename(tstr),31));
          end;
          repeat
            textcolor(lightgray); textbackground(black);
            Doserror:=ExecPrg(concat(Progdir,Cmdline,' ',tstr));
            ex:=execend(Vp.verp,M,Ar3);
          until ex in [2,3];
        end;
        Pdat.Close;
      end;
    end;
    If not m_interM then
    begin
      redback;
      closewindow;
    end else
    {If not m_flashend then}
    begin
      Blackscreen; restwindow; Einblenden;
    end;
    MouShowMouse;
  end;


{--------------------------- Rechtsfenster ------------------------}

Constructor Rechtsfenster.Init;
begin
  Control.Init(Rechts,Rightdatname,Rightdatindex,(Crtxmax Div 2)+2); Funktionen(true);
  Fenakt(False,True,True);
end;


procedure RechtsFenster.Fakt;
var vpos : word;
begin
 {UnselectAll;}
 ClrUnterf;
 {Fenakt(True,True,True);}
 Fenakt(True,False,True);
 ArcOpen:=false;
end;


function RechtsFenster.Packen_EntPacken;
begin
  Packen_EntPacken:=Entpacken;
end;




function RechtsFenster.Entpacken :boolean;
const M  : Message = 'Fehler beim Dekomprimieren :';
      AR1 : Acceptrec = ('    OK    ','','');
var tas,fun     : char;
    entpack     : byte;
    i           : byte;
    Vp          : Dparam;
    Bu          : Button;
    Sb,Sb4      : SelButton;
    Ed1,Ed2     : Edit;
    zahl        : string[10];
    weiter      : boolean;
    entp        : boolean;
    LwCh        : boolean;


begin
   Entpacken:=false; Packer_File.Open;
   If not dat.ver_dat and (dat.filanz>1) then Packdateiwrite(dat.vpos);
   Listendatei(Kom.sel,Kom.ausw);
   entpack:=0; Entp:=false; Packer_File.Seek(entpack);
   If Kom.sel=0 then
   begin
     IO_Error(concat(M),'IOERROR.MSG',222,AR1);
     Entpacken:= Entp; exit;
   end;
   If not Kom.ausw then
   begin
     Vp.Arcend:='';
     while not Packer_File.EoF and not CompArcend(Vp.Arcend,dat.fil[dat.fpos].name) do
       Packer_File.Read(Vp,-1,1);
   end else Vp.passw:='';
   Packer_File.Close;
   Lw.Dr:=dat.ver[1].name[1];
   DriveKind(Lw);
   LwCh:=Lw.Ch[1]='0';
   Kom.datei:='*.*'; Kom.pas:=''; Kom.path:=false; Kom.mV:=false;
   If not openwindow(60,9,fenfo,fenba,'Dekomprimieren') then exit;

   writeXY(3,2,'Entpacken von :');
   InitEditor(Ed1,19,2,'',true,Kom.datei,12);
   If (Kom.sel>0) and Kom.ausw then
   begin
     str(Kom.sel,zahl);
     If Kom.sel>1 then
       writeXY(3,4,concat('aus ',zahl,' Archiven'));
       writeXY(3,4,concat('aus ',zahl,' Archiv'));
   end else
     writeXY(3,4,concat('aus Archiv    : ',upstring(dat.fil[dat.fpos].name)));

   If (trim(Vp.passw)>'') and not Kom.ausw then
     Initeditor(Ed2,45,4,'Passwort :',true,Kom.pas,12);

   InitSelButton(Sb,3,7   ,'Mit Verzeichnissen',true{Kom.path},1); Sb.Anz:=1;
   InitSelbutton(Sb4,34,7 ,'Multiple Volume',true,1);            Sb4.Anz:=1;


   InitButton(Bu,10 ,9,'  ~Dekomprimieren  ',ALT_D,1);
   InitButton(Bu,38,9, '    ~Abbruch    ',   ALT_A,2); Bu.Anz:=2;

   I:=1;weiter:=false;
   repeat

     SetEditor(Ed1);

     If (trim(Vp.EmitV)>'') and not Kom.ausw then
       SetSelButton(Sb);
     If (trim(Vp.multipleV)>'') and LwCh and not Kom.ausw then
       SetSelbutton(Sb4);

     If (trim(Vp.passw)>'') and not Kom.ausw then
       SetEditor(Ed2);

     SetButton(Bu);
     case I of
     1: ActiveEditor(Ed1);
     2: ActiveEditor(Ed2);
     3: ActiveSelButton(Sb);
     4: ActiveSelButton(Sb4);
     5: ActiveButton(Bu);
     end;

     case EventThisButton(Bu) of
      1: begin
           Kom.datei:=Ed1.T;
           If (trim(Vp.passw)>'') and not Kom.ausw then
             Kom.pas  :=Ed2.T;
           If (trim(Vp.EmitV)>'') and not Kom.ausw then
             Kom.path :=Sb.Sb[1].S;
           If (trim(Vp.multipleV)>'') and LwCh and not Kom.ausw then
             Kom.mV:=Sb4.Sb[1].S;
           Entp:=true;
           weiter:=true;
         end;
      2: begin
           weiter:=true;
         end
     end;

     If EventEditor(Ed1)   then I:=1;
     If ((trim(Vp.passw)>'') and not Kom.ausw ) then
       If EventEditor(Ed2)   then I:=2;
     If (trim(Vp.EmitV)>'') and not Kom.ausw then
       If EventSelButton(Sb) then I:=3;
     If (trim(Vp.multipleV)>'') and LwCh and not Kom.ausw then
       If EventSelButton(Sb4) then I:=4;


     case ev.key of
   CUP,
   BACKTAB: begin
             If I>1 then dec(I) else I:=5;
             If ((trim(Vp.multipleV)='') or not LwCh or Kom.ausw) and (I=4) then dec(I);
             If ((trim(Vp.EmitV)='') or Kom.ausw ) and (I=3) then dec(I);
             If ((trim(Vp.passw)='') or Kom.ausw ) and (I=2) then dec(I);
            end;
   CDOWN,
   TAB   : begin
             If I<5 then inc(I) else I:=1;
             If ((trim(Vp.passw)='') or Kom.ausw ) and (I=2) then inc(I);
             If ((trim(Vp.EmitV)='') or Kom.ausw ) and (I=3) then inc(I);
             If ((trim(Vp.multipleV)='') or not LwCh or Kom.ausw) and (I=4) then inc(I);
           end;
      ESC : weiter:=true;
      F1  : Hilfe.ViewPage(24);
        end;
   until weiter;
   closewindow;
   If entp then Dekomprimieren;
   Entpacken:=entp;
end;

  procedure RechtsFenster.Dekomprimieren;
  const M = 'Fehler beim Dekomprimieren :';
  var Cmdline,progdir : pathstr;
            tstr      : pathstr;
            Vp        : Dparam;
            ex,Z      : byte;
            en        : Endg;
  begin
    Dosexitcode;
    chver(LFenster^.dat.aktverz);
    If m_interM then
    begin
      If not savewin(2,2,crtxmax-ShadowX,crtymax-ShadowY) then exit;
      MouHideMouse; Ausblenden;
    end else
    begin
      If not openwindow(31,4,fenfo,fenba,'Dekomprimieren') then exit;
      textcolor(MessageCol);
      If Kom.sel>1 then
        writeXY(9,2,'Entpacke Archive...') else writeXY(9,2,'Entpacke Archiv...');
      MouHideMouse;redout;
    end;
    Pdat.Open; ex:=0;
    while not Pdat.EOF and (ex<>3) do
    begin
      Pdat.Readln(tstr);
      If not m_InterM then
      begin
        textcolor(fenfo); textcolor(fenba);
        writeXY(1,4,center(justfilename(tstr),31));
      end;

      Packer_File.Open;
      Vp.arcend:='';
      while not Packer_File.EoF and not CompArcend(Vp.Arcend,dat.fil[dat.fpos].name) do
        Packer_File.Read(Vp,-1,1);
      Packer_File.Close;

      If trim(Vp.entp)='' then Vp.entp:=Vp.verp;
      Progdir:=addbackslash(m_packverz)+Vp.entp+' ';
      FindFirst(Progdir, $27, DirInfo);
      If ((Dirinfo.name>'') and (Doserror=0)) then
      begin
        Cmdline:='';
        If Kom.path then
           Cmdline:=Vp.EmitV else Cmdline:=Vp.EohneV;
        If Kom.pas>'' then
          Cmdline:=Cmdline+' '+Vp.passw+Kom.pas;
        If Kom.mV then
          Cmdline:=Cmdline+' '+Vp.multipleV;

        Cmdline:=Cmdline+' '+tstr;
        Cmdline:=Cmdline+' '+Kom.datei;
        repeat
          Doserror:=ExecPrg(concat(Progdir,Cmdline));
          ex:=execend(Vp.Entp,M,Ar3);
        until ex in[2,3];
      end else
         execend(Vp.Entp,concat(M,' ',Vp.Entp),Ar1);
    end;
    Pdat.Close;
    If not m_interM then
    begin
      redback; closewindow
    end else
    {If not m_flashend then}
    begin
      Blackscreen; restwindow; Einblenden;
    end;
    MouShowMouse;
  end;


begin
end.