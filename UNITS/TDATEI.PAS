UNIT TDatei;

Interface
uses TBaum,Init,Tkstring,Dos,Crt,Tkvideo,Tkwin,Tkstream,Tkdisk;

Type

 Datei = Object(Baum)

               ToggleJ : ToggleRec;

               Constructor Init;

               procedure   PackdateiWrite(vpos:word);
               procedure   PackdateiRead (vpos:word);
               function    Dateiread  (vpos:word): boolean;
               function    Dateilesen (vpos:word): boolean;       virtual;

               procedure   fullsort(so:byte);
               procedure   selcount;

               procedure   Readendg;                              virtual;

               procedure   dwrite       (m:boolean;x:byte;df:word);virtual;
               procedure   Dateienwrite (m:boolean;anf:word);
               procedure   dselect      (Edpos:word);
               procedure   datselect    (m:boolean;anf:word);
               procedure   datmark      (anf,ende:word);
               procedure   filmark      (anf:word);

               procedure   Floschen;                               virtual;
               {procedure   Vloschen(Uv:boolean);                   virtual;}
               procedure   treemark (anf:word);

               Destructor  Done;
 End{Datei};

Implementation

  Constructor Datei.Init;
  begin
    ToggleJ:=normal; Baum.Init;
  end;




  procedure Datei.treemark(anf:word);
  var z,k,vpos  : word;
      se        : boolean;
  begin
    If anf < 1 then exit;
    BaumWrite(false,dat.vpos);
    se:=false;
    k:=anf;
    repeat
      If dat.ver[k].files>0 then se:=true;
      inc(k);
    until dat.ver[k].Vopen or (k>dat.veranz);
    se:= not se;
    If anf<=dat.vpos then
    begin
      vpos:=dat.vpos;
      while (vpos<dat.veranz) and not (dat.ver[vpos+1].Vopen) do inc(vpos);
      for k:=anf to vpos do
      begin
        Pfeilwrite(false,k);
        If Dateilesen(k) then
        begin
          dat.ver[k].files :=0; dat.ver[k].selgr:=0;
          for z:=2 to dat.filanz do
          begin
            dat.fil[z].select:=se;
            If dat.fil[z].select then
            begin
              inc(dat.ver[k].files);
              inc(dat.ver[k].selgr,dat.fil[z].size);
            end;
          end;
          Packdateiwrite(k);
        end;
      end;
    end else
    begin
      while (anf<dat.veranz) and not (dat.ver[anf+1].Vopen) do inc(anf);
      for k:=anf downto dat.vpos do
      begin
        Pfeilwrite(false,k);
        If Dateilesen(k) then
        begin
          dat.ver[k].files :=0; dat.ver[k].selgr:=0;
          for z:=2 to dat.filanz do
          begin
            dat.fil[z].select:=se;
            If dat.fil[z].select then
            begin
              inc(dat.ver[k].files);
              inc(dat.ver[k].selgr,dat.fil[z].size);
            end;
          end;
          Packdateiwrite(k);
        end;
      end;
    end;
    Pfeilwrite(false,dat.vpos);
    BaumWrite(true,dat.vpos);
  end;


type sortstr = string[20];

procedure Datei.fullsort(so:byte);
var    z,l  :byte;

 function sorti(da:DateiRec):sortstr;
 var za : string[9];
 begin
   case so of
     1: begin  { Name }
           sorti:=concat(pad(justname(da.name),8),pad(justextension(da.name),3));
        end;
     2: begin  { Erweiterung }
           sorti:=concat(pad(justextension(da.name),3),pad(justname(da.name),8));
        end;
     3: begin  { Zeit }
           str(da.time,za);
           sorti:=concat(leftpad(za,9),pad(justname(da.name),8),pad(justextension(da.name),3));
        end;
     4: begin  { Gr”áe }
           str(da.size,za);
           sorti:=concat(leftpad(za,9),pad(justname(da.name),8),pad(justextension(da.name),3));
        end;
     5: begin   { Attribut }
           str(da.attr,za);
           sorti:=concat(leftpad(za,9),pad(justname(da.name),8),pad(justextension(da.name),3));
        end;
   else begin
           str(da.uns,za);
           sorti:=leftpad(za,9);
        end;
    end;
 end;

 Procedure SortQuick(Left,Right:Integer);
  Var I, J : Integer;
      Hold : DateiRec;
      X    : sortstr;
  Begin
    I:=Left;
    J:=Right;
    If J>I Then
    Begin
     X:=sorti(dat.fil[(Left+Right) DIV 2]);
     Repeat
       While sorti(dat.fil[I])<X Do Inc(I);
       While sorti(dat.fil[J])>X Do Dec(J);
       If I<=J Then
       Begin
         Hold:=dat.fil[I];
         dat.fil[I]:=dat.fil[J];
         dat.fil[J]:=Hold;
         Inc(I);
         Dec(J);
      End
     Until I>J;
    End;
    If J>Left  Then SortQuick(Left,J);
    If I<Right Then SortQuick(I,Right);
  End;

begin
   Sortquick(2,dat.filanz);
end;


procedure Datei.PackdateiWrite(vpos:word);
var weiter     : boolean;
    RenameFile : TypedStream;
    Laufw      : char;
    Vind       : Findex;
    Vsel       : Ftemp;
    found      : boolean;
    aktver,
    fullver    : pathstr;
    zahl       : word;
    Fpos       : longint;

begin
  If dat.filanz<=1 then exit;
  If not dat.ver_dat then fullsort(6);
  aktver:=fullpath(vpos);
  Laufw:=aktver[1];
  found:=false;
  Filind.Open; weiter:=true;
  while not FilInd.Eof and weiter do
  begin
    FilInd.Read(Vind,-1,1);
    If (Laufw=Vind.Lw) then
    begin
      If (vpos=Vind.vpos) then
      begin
        found:=true; weiter:=false;
      end;
    end else
    begin

    end;
  end;

  Filsel.Open; zahl:=1; z:=2;
  If found then
  begin
    Fpos:=Vind.Fseek;
    Filsel.Seek(Fpos); weiter:=true;
    while not Filsel.Eof and weiter do
    begin
      Filsel.Read(Vsel,-1,1); inc(Fpos);
      If (Vsel.select<>dat.fil[z].select) and (Vsel.name=dat.fil[z].name)  then
      begin
        Vsel.select:=dat.fil[z].select;
        Filsel.write(Vsel,Fpos-1,1);
      end;
      inc(z);
      weiter:=not Vsel.ver_dat;
      If Vsel.select and weiter then inc(zahl);
    end;
  end else
  begin
    Fpos:=Filsel.Size;
    Filsel.Seek(Fpos);
    fullver:=addbackslash(aktver);              { Verzeichnis speichern }
    Vsel.ver_dat:=true;
    while not (length(fullver)=0) do
    begin
      If fullver[1]='\' then
      begin
        Vsel.name:='\'; delete(fullver,1,1);
      end else
      begin
        Vsel.name:=copy(fullver,1,pos('\',fullver)-1);
        delete(fullver,1,pos('\',fullver));
      end;
      Vsel.jump:=0;
      Filsel.write(Vsel,-1,1);inc(Fpos);
    end;


    Vind.Lw   :=Laufw;
    Vind.Fseek:=Fpos;
    Vind.vpos :=vpos;
    Filind.Write(Vind,-1,1);
    Vsel.ver_dat:=false; zahl:=1;
    for z:=2 to dat.filanz do                    { Dateien abspeichern }
    begin
      Vsel.name  :=dat.fil[z].name;
      Vsel.select:=dat.fil[z].select;
      Vsel.jump  :=dat.filanz-z;
      If dat.fil[z].select then inc(zahl);
      Filsel.write(Vsel,-1,1);
    end;

  end;
  If zahl=dat.filanz then
     dat.ver[vpos].select:=true else dat.ver[vpos].select:=false;
  Filsel.Close;
  Filind.Close;
  If not dat.ver_dat then fullsort(m_sort);
end;




procedure Datei.PackdateiRead(vpos:word);
var aktver     : PathStr;
    Laufw      : Char;
    weiter     : boolean;
    Vind       : Findex;
    Vsel       : Ftemp;
    found      : boolean;
    Fpos       : longint;
    zahl       : word;

begin
  aktver:=fullpath(vpos);
  Laufw :=aktver[1];
  Filind.Open; weiter:=true; found:=false;
  while not FilInd.Eof and weiter do
  begin
    FilInd.Read(Vind,-1,1);
    If (Laufw=Vind.Lw) then
    begin
      If (vpos=Vind.vpos) then
      begin
        found:=true; weiter:=false;
      end;
    end else
    begin

    end;
  end;

  Filsel.Open; z:=2;
  If found then
  begin
    Fpos:=Vind.Fseek;
    Filsel.Seek(Fpos); weiter:=true;
    while not Filsel.Eof and weiter do
    begin
      Filsel.Read(Vsel,-1,1); inc(Fpos);
      If trim(Vsel.name)=dat.fil[z].name then
      begin
        dat.fil[z].select:=Vsel.select;
      end;
      inc(z);
      weiter:=not Vsel.ver_dat;
    end;
  end else
  begin
  end;
  fullsort(m_sort);
  Filsel.Close;
  Filind.Close;
end;




  procedure Datei.Readendg;
  var Vp     : Dparam;
      PackPos: byte;
    endgcount: byte;
  begin
    PackPos:=0;
    case FMod of
    Links : begin
              Fendg.en[1]    :='*.*';
              Fendg.packer[1]:=PackPos;
              Fendg.fanz     :=1;
            end;
    Rechts: begin
              Packer_File.Open;
              Fendg.fanz:=0;  Packer_File.Seek(0);
              while not Packer_File.EOF do
              begin
                Packer_File.Read(Vp,-1,1);
                endgcount:=0;
                repeat
                  inc(Fendg.fanz); inc(endgcount);
                  If pos(',',Vp.arcend)>0 then
                  begin
                    Fendg.en[Fendg.fanz]    :=concat('*.',copy(Vp.arcend,1,pos(',',Vp.arcend)-1));
                    Fendg.Packer[Fendg.fanz]:=PackPos;
                    delete(Vp.arcend,1,pos(',',Vp.arcend));
                  end else
                  begin
                    Fendg.en[Fendg.fanz]:=concat('*.',Vp.arcend); Vp.arcend:='';
                    Fendg.Packer[Fendg.fanz]:=PackPos;
                  end;
                until (Vp.arcend='') or (endgcount=EndgAnz);
                inc(PackPos);
              end;
              Packer_File.Close;
             end;
         end{Case};
  end;




    function Datei.Dateilesen (vpos:word): boolean;
    var name     : string[13];
        taste2   : char;
        l        : byte;
        aktverz  : pathstr;

     begin
       aktverz:=fullpath(vpos);
       {If not chver(dat.aktverz) then
       begin
         Dateilesen:=false; exit;
       end;}

       dat.fanf:=1;dat.filanz:=1;dat.fil[1].name:='.';dat.fpos:=1;
       dat.fil[1].select:=false;
       change:=false;
       findfirst (addbackslash(aktverz)+'*.*',$3F,Dirinfo);
       while (Doserror=0) and ((Dirinfo.name='.') or (Dirinfo.name='..')) do
       begin
         findnext(Dirinfo);
       end;
       while (Doserror=0) and (dat.filanz<dateianz) do
       begin
          for l:=1 to Fendg.fanz do
           If (compextension(Fendg.en[l],dirinfo.name)) and
              (dirInfo.attr<>Directory) and (((dirinfo.attr and m_attrib)>0)
              and (not ((dirinfo.attr and $18) in[$10,$8])) or (Dirinfo.attr=0))
              and (dat.filanz<dateianz) then
           begin
             If dat.filanz=datanz then break;
             inc(dat.filanz); Name:=DirInfo.Name;
             DirInfo.Name:=lostring(dirInfo.Name);
             dat.fil[dat.filanz].name:=DirInfo.Name;
             dat.fil[dat.filanz].attr:=Dirinfo.attr;
             dat.fil[dat.filanz].time:=Dirinfo.time;
             dat.fil[dat.filanz].size:=Dirinfo.size;
             dat.fil[dat.filanz].uns:=dat.filanz;
             dat.fil[dat.filanz].Select:=false;
             break;
           end;
           findnext(Dirinfo);
       end;

       if not (Doserror in [18,0]) then
       begin
         dat.filanz:=0;
         Dateilesen:=false;
       end else
       begin
         Dateilesen:=true;
         dat.dfree:=diskfree(ord(dat.ver[1].name[1])-64);
       end;
       Doserror:=0;
    end;



   function Datei.Dateiread (vpos:word): boolean;
   var lesen : boolean;
   begin
     lesen:=Dateilesen(vpos);
     If lesen then Packdateiread(vpos);
     Dateiread:=lesen;
   end;

  procedure Datei.dwrite(m: boolean;x: byte;df:word);
  var dt                     :DateTime;
      Tag,Monat,Stunde,Minute,Jahr,Groesse,name:string[12];
      zeile    :string;
  begin
    If m then textbackground(Balkenba) else textbackground(Winba);
    textcolor(Winfo);
    zeile:='';
    If dat.fil[df].select then Zeile:='û' else Zeile:=' ';
    Zeile:=concat(Zeile,pad(justname(dat.fil[df].name),9));
    Zeile:=concat(Zeile,pad(justextension(dat.fil[df].name),4));
    If df>1 then
    begin
      unpacktime(dat.fil[df].time,dt);
      str(dt.day,Tag);str(dt.month,Monat);
      str(dt.hour,Stunde);str(dt.min,Minute);str(dt.year,Jahr);
      str(dat.fil[df].size,Groesse);
      delete(Jahr,1,2);
      Zeile:=concat(Zeile,leftpadch(Tag,'0',2),'/',leftpadch(Monat,'0',2),'/',Jahr);
      Zeile:=concat(Zeile,' ',leftpadch(Stunde,' ',2),':',leftpadch(Minute,'0',2));
      case ToggleJ of
      normal : begin
                 Zeile:=concat(Zeile,leftpadch(Groesse,' ',10));
               end;
      spez1  : begin
                 Zeile:=concat(Zeile,' ');
                 if $20=(Dat.fil[df].attr and $20) then
                   Zeile:=concat(Zeile,'A') else Zeile:=concat(Zeile,'-');
                 if $4=(Dat.fil[df].attr and $4) then
                   Zeile:=concat(Zeile,'S') else Zeile:=concat(Zeile,'-');
                 if $2=(Dat.fil[df].attr and $2) then
                   Zeile:=concat(Zeile,'H') else Zeile:=concat(Zeile,'-');
                 if $1=(Dat.fil[df].attr and $1) then
                   Zeile:=concat(Zeile,'R') else Zeile:=concat(Zeile,'-');
               end;
          end;
    end;
    Zeile:=pad(Zeile,xdiff-2);
    writeXY(1,x,Zeile);
  end;




  procedure Datei.Dateienwrite(m:boolean;anf:word);
  var dz,dzmax :word;
      zstr     :string[9];

  begin
    If dat.filanz>ydiff-3 then dzmax:=dat.fanf+ydiff-3 else dzmax:=dat.filanz;
    for dz:=dat.fanf to dzmax do
    begin
      If (((dat.fpos>=dz) and (anf<=dz)) or
          ((dat.fpos<=dz) and (anf>=dz))) and m then
      dwrite(true,dz-dat.fanf+1,dz) else dwrite(false,dz-dat.fanf+1,dz);
     end;
    textcolor(Winfo); textbackground(Winba);
    For dz:=(dzmax-dat.fanf)+2 to ydiff-2 do
      writeXY(1,dz,pad('',xdiff-2));
    Unterfenster;
  end;




  procedure Datei.datselect(m:boolean;anf:word);
  var files : boolean;
      z     : byte;
  begin
   files:=false;
   If dat.fpos>dat.filanz then
      dat.fpos:=dat.filanz;
   If dat.fpos<1          then
      dat.fpos:=1;
   If (dat.fpos>dat.fanf+ydiff-3) then
   begin
     dat.fanf:=dat.fpos-(ydiff-3);  files:=true;
   end;
   If dat.fpos<dat.fanf then
   begin
     dat.fanf:=dat.fpos;            files:=true;
   end;

   If anf<dat.fanf           then anf:=dat.fanf;
   If anf>dat.fanf+(ydiff-3) then anf:=dat.fanf+(ydiff-3);

   IF files then
     Dateienwrite(m,anf) else
   begin

     If anf<dat.fpos then
     begin
       for z:=anf to dat.fpos do
         dwrite(m,z-dat.fanf+1,z);
     end else
     begin
       for z:=anf downto dat.fpos do
         dwrite(m,z-dat.fanf+1,z);
     end;
   end;
   Pfeilwrite(m,dat.vpos);
  end;


  procedure Datei.dselect(Edpos:word);
  var files : boolean;
  begin
    files:=false;
    If Edpos>dat.filanz then Edpos:=dat.filanz;
    If Edpos<1          then Edpos:=1;
    If (Edpos>dat.fanf+ydiff-3) then
      files:=true;
    If Edpos<dat.fanf then
      files:=true;

    If (not files) and (dat.fpos<>Edpos)then
      Datselect(false,dat.fpos);
    dat.fpos:=Edpos;

    Datselect(true,dat.fpos);
  end;


  procedure Datei.Selcount;
  begin
    dat.ver[dat.vpos].files:=0;
    for z:=2 to dat.filanz do
      If dat.fil[z].select then inc(dat.ver[dat.vpos].files);
    
  end;


  procedure Datei.datmark (anf,ende: word);
  var  dfpos : word;
       seite : boolean;
  begin
    seite:=false;
    If anf <= 1                  then exit;
    If ende = 1                  then ende :=2;
    If ende-1 > dat.filanz       then ende :=dat.filanz;
    If ende < dat.fanf           then seite:=true;
    If ende > (dat.fanf+ydiff-3) then seite:=true;
    If anf  > (dat.fanf+ydiff-3) then anf  :=dat.fanf+ydiff-2;
    If anf  < dat.fanf           then anf  :=dat.fanf-1;
    If dat.fpos > dat.filanz     then dat.fpos:=dat.filanz;

    If (dat.fpos<>ende) then
    begin
      dfpos:=dat.fpos;
      dat.fpos:=ende;

      If (((dat.fpos>=dfpos) and (anf>=dfpos)) or
          ((dat.fpos<=dfpos) and (anf<=dfpos))) and not seite then
      begin
        If (dfpos>dat.fpos) and (anf<dfpos) then
        begin
          inc(dat.fpos); datselect(false,dfpos); dec(dat.fpos);
        end;
        If (dfpos<dat.fpos) and (anf>dfpos) then
        begin
           dec(dat.fpos); datselect(false,dfpos); inc(dat.fpos);
        end;
      end;

      If ((dfpos>dat.fpos) and (anf>=dat.fpos)) or
         ((dfpos<dat.fpos) and (anf<=dat.fpos)) then
      begin
         datselect(true,anf);
      end;
    end else
    begin
    end;
  end;

 procedure Datei.filmark(anf:word);
 var z : word;
     se: boolean;
 begin
   If anf <=1 then exit;
   se:=not dat.fil[anf].select;
   If anf<=dat.fpos then
   begin
     for z:=anf to dat.fpos do
     begin
       dat.fil[z].select:=se;
       If (z>=dat.fanf) and (z<dat.fanf+ydiff-2) then
         dwrite(dat.fpos=z,z-dat.fanf+1,z);
     end;
  end else
     for z:=dat.fpos to anf do
     begin
        dat.fil[z].select:=se;
       If (z>=dat.fanf) and (z<dat.fanf+ydiff-2) then
         dwrite(dat.fpos=z,z-dat.fanf+1,z);
     end;
  SelCount; Unterfenster;
  change:=true;
 end;

procedure Datei.Floschen;
var tstr   : string;
    DelFile: TypedStream;


begin
  If not openwindow(31,4,fenfo,fenba,'L”schen') then exit;
  If Kom.sel=1 then writeXY(7,2,'L”sche Datei...') else writeXY(6,2,'L”sche Dateien...');
  Pdat.Open;
  while not Pdat.EOF do
  begin
    Pdat.Readln(tstr); textbackground(fenba); textcolor(fenfo);
    writeXY(1,4,center(justfilename(tstr),31));
    DelFile.Init(tstr,1);
    DelFile.DelFile;
    DelFile.Done;
  end;
  Pdat.Close;
  closewindow;
end;


(*procedure Datei.Vloschen(Uv:boolean);
var
    z : word;
    rm_dir : boolean;
    rm_vpos: word;


 procedure DatLoschen(vpos:word);
 var z    : word;
     attr : byte;
 begin
   attr:=m_attrib; m_attrib:=$27; {Alle Dateien}
   Dateilesen(vpos);
   m_attrib:=attr;
   For z:=2 to dat.filanz do
     dat.fil[z].select:=true;
   If (dat.filanz>1) then
   begin
     Packdateiwrite(vpos);Listdatei;
     Floschen;
     UnselectAll;
   end;

   
 end;

begin
  chver(dat.ver[1].name);
  If Uv then
  begin
    z:=dat.vpos;
    while (dat.ver[dat.vpos].pos<dat.ver[z+1].pos) and (z<dat.veranz) do
      inc(z);
    while z>dat.vpos do
    begin
      DatLoschen(z);
      If RmVer(fullpath(z)) then
      begin
        VerzLosch(z);
      end;
      dec(z);
    end;
    DatLoschen(z);
  end;

  rm_dir:=RmVer(fullpath(dat.vpos));
  If rm_dir then
  begin
    rm_vpos:=dat.vpos;
    {vselect(Vjump(dat.vpos,1,false));}
    verselect(false,dat.vpos);
    dat.vpos:=Vjump(dat.vpos,1,false);
    verselect(false,dat.vpos);
    VerzLosch(rm_vpos);
  end;
  Drivewrite(True);
end;*)




 Destructor Datei.Done;
 begin
 end;

begin
end.