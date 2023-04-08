Unit TBaum;

Interface
uses TUrfen,Dos,Crt,Tkvideo,Tkwin,Tkstring,Init,KBM,Tkdisk,Tkstream;

Type
 Baum = Object(Urfenster)
               Constructor Init;
               procedure   Unselect;
               procedure   UnselectAll;

               function    VerzNeu             : boolean;         virtual;
               procedure   VerzAkt;
               function    VerzRead (Var vpos:word; vtiefe:byte; vname: Pathstr) : boolean;
               procedure   VerzEinf (S:PathStr);
               procedure   VerzLosch(Var vpos :word);
               function    Verzlesen                 : pathstr;

               function    Vjump    (vpos,jump : word; up:boolean) : word;
               function    Vposition(pos  : word) : word;
               function    Vdiff1(vpos1,vpos2 : word) : word;
               function    Vdiff2(vpos1,vpos2 : word) : word;
               function    VerzZoom                   : boolean;

               function    Anpassen (var wanf: byte;var sanf,vpos : word): boolean;
               procedure   verwrite (m:boolean;Ypos,Vpos:word);
               procedure   Baumwrite(m:boolean;anf:word);
               procedure   vselect  (Evpos:word);
               procedure   verselect(m:boolean;anf:word);
               procedure   Baummark (anf,ende: word);

               procedure   VLoschen(Uv:boolean);                  virtual;

               function    DriveRead(Var written: boolean) : boolean;
               procedure   DriveWrite(NewWritten:boolean);
               procedure   DriveDelete;
               procedure   DriveAkt;

               Destructor  Done;
 End{Baum};

Implementation

  Constructor Baum.Init;
  begin
    Urfenster.Init;
  end;




  function Baum.Vjump  (vpos,jump :word; up:boolean) : word;
  var diff,z : word;
  begin
    diff:=0;z:=0;
    If Up then
    begin
      while (jump>diff) and (vpos+z<dat.veranz) do
      begin
        inc(z);
        If dat.ver[vpos+z].Vopen then inc(diff);
      end;
      If (vpos+z=dat.veranz) and not dat.ver[dat.veranz].Vopen then z:=0;
      Vjump:=vpos+z;
    end else
    begin
      while (jump>diff) and (vpos-z>1) do
      begin
        inc(z);
        If dat.ver[vpos-z].Vopen then inc(diff);
      end;
      Vjump:=vpos-z;
    end;
  end;

  function Baum.Vdiff1(vpos1,vpos2 : word) : word; {Angabe der realen Position mit Erg abs.Breite}
  var z,z1 : word;
  begin
    z:=vpos1; z1:=0;
    while (z<dat.veranz) and (z<vpos2) do
    begin
      inc(z);
      If dat.ver[z].Vopen then inc(z1);
    end;
    Vdiff1:=z1;
  end;

  function Baum.Vdiff2(vpos1,vpos2 : word) : word; {Angabe der absoluten Differenz mit Erg. reale Pos.}
  var z,z1 : word;
  begin
    z:=vpos1; z1:=0;
    while (z<dat.veranz) and (z1+vpos1<vpos2) do
    begin
      inc(z);
      If dat.ver[z].Vopen then inc(z1);
    end;
    Vdiff2:=z1;
  end;


  function  Baum.Vposition (pos :word) : word;
  var z,z1,posm : word;
  begin
    z:=dat.sanf; z1:=dat.sanf;  posm:=dat.sanf+pos;
    while (z<dat.veranz) and (z1<posm) do
    begin
      inc(z);
      If dat.ver[z].Vopen then inc(z1);
    end;
    If (z=dat.veranz) and not dat.ver[dat.veranz].Vopen then z:=dat.vpos;
    Vposition:=z;
  end;



  function Baum.Anpassen(var wanf:byte;var sanf,vpos : word) :boolean;
  var z,z1 :word;
  begin
    Anpassen:=false;
    If wanf=0 then wanf:=1;
    If (vpos>dat.veranz) then vpos:=dat.veranz;

    If vpos<1          then vpos:=1;
    If (dat.ver[vpos].pos<wanf{+(ebene-2)}) and (wanf>1) and (dat.ver[vpos].pos>=0) then
    begin
      If {(dat.ver[vpos].pos>(ebene-2)) and} (dat.ver[vpos].pos>0) then
         wanf:=dat.ver[vpos].pos{-(ebene-2)} else wanf:=1;
                                         Anpassen:=true;
    end;
    If (dat.ver[vpos].pos>wanf+(ebene-1)) then
    begin
      wanf:=dat.ver[vpos].pos-(ebene-1);Anpassen:=true;
    end;

    If sanf<vpos then
    begin
      z:=sanf; z1:=sanf;
      while (z<dat.veranz) and (z<vpos) do
      begin
        inc(z);
        If dat.ver[z].Vopen then inc(z1);
      end;

      If (sanf+ydiff-3<z1) then
      begin

        z:=vpos; z1:=vpos;
        while (z1>vpos-(ydiff-3)) and (z>1) do
        begin
          dec(z);
          If dat.ver[z].Vopen then dec(z1);
        end;
        sanf:=z;

        Anpassen:=true;
      end;
    end;

    If (vpos<sanf) and dat.ver[vpos].Vopen then
    begin
      z:=vpos+1; z1:=vpos+1;
      repeat
        dec(z);
      until (z=1) or dat.ver[z].Vopen;
      sanf:=z;
      Anpassen:=true;
    end;
  end;


  procedure Baum.verwrite(m:boolean;Ypos,Vpos:word);
  begin
    If ((dat.ver[Vpos].pos<dat.wanf) or
       (dat.ver[Vpos].pos>dat.wanf+ebene-1)) and (dat.ver[Vpos].pos<>0) then exit;
    If m then
      textbackground(Balkenba) else textbackground(Winba);
    If (dat.ver[Vpos+1].Vopen=false) and (Vpos<dat.veranz) then
         textcolor(VcloseCol) else textcolor(Winfo);
    If (dat.ver[Vpos].Vart=Packer) then textcolor(PackerCol);
    writeXY(((dat.ver[Vpos].pos-dat.wanf)*3)+10+1+einschub,Ypos{-dat.sanf+1)},
              concat(pad(dat.ver[Vpos].name,12)));
  end;

  procedure Baum.BaumWrite(m :boolean;anf:word);
  var vernext         : array[1..vertiefe] of boolean;
      za,zah,i,zamax  : word;
      n               : string[5];
      zstr            : string[9];
      AktMouY         : byte;
      Zeile           : string;
      x,y             : byte;
      files,k         : word;

    function lastdir(numb:word) :boolean;
    var last, stop      : boolean;
    begin
      repeat
        i:=numb+1;
        repeat
          If (dat.ver[numb].pos>dat.ver[i].pos) or (i=dat.veranz+1) then
          begin
            lastdir:=true;break;
          end;
          If (dat.ver[numb].pos=dat.ver[i].pos) then
          begin
            lastdir:=false;break;
          end;
          inc(i);
        until false;
        inc(numb);
      until dat.ver[i].Vopen or (i>=dat.veranz);
    end;

    procedure senkline;
    var k,t : word;
        merk: byte;
        st  : string;

    begin
       merk:=dat.ver[za].pos;st:='';
       If merk>(dat.wanf+ebene) then merk:=dat.wanf+ebene+1;
       If merk<dat.wanf then merk:=dat.wanf+ebene+1;
       If dat.ver[za].pos>1 then
       for k:=za-1 downto 2 do
       begin
         If dat.ver[k].pos<dat.wanf then break;
         If dat.ver[k].pos < merk then
         begin
           if lastdir(k) then
             vernext[dat.ver[k].pos]:=false
           else
             vernext[dat.ver[k].pos]:=true;
           merk:=dat.ver[k].pos;
         end;
         If dat.ver[k].pos=dat.wanf then break;
       End;
       if dat.ver[za].pos-1>dat.wanf+ebene then
         t:=dat.wanf+ebene else t:=dat.ver[za].pos-1;
       for k:=dat.wanf to t do
        If (vernext[k]) then
          st:=concat(st,lins,'  ') else st:=concat(st,'   ');
       Zeile:=st;
       writeXY(x,y,Zeile); inc(x,length(Zeile));
       { End }
    end;

  begin
    textcolor(Winfo); textbackground(Winba);
    Unterfenster;
    If dat.veranz=0 then
    begin
      clrwin;
      writeXY(5,ydiff div 2,  'Keine Diskette im Laufwerk oder');
      writeXY(9,ydiff div 2+1,'Diskette nicht lesbar !');
      exit;
    end;
    vernext[1]:=false; AktMouY:=akty;

    zamax:=dat.sanf+Vdiff2(dat.sanf,dat.sanf+ydiff-3);

    za:=dat.sanf-1;
    for zah:=dat.sanf to zamax do
    begin

      repeat
        inc(za);
      until dat.ver[za].Vopen;
      {EndIf}


      Zeile:='';
      textcolor(Winfo);textbackground(Winba);
      x:=1; y:=zah-dat.sanf+1;

      If za=dat.vpos then
      begin
        textcolor(LaufcuCol);
        Zeile:=pad('',einschub-2);
        writeXY(x,y,Zeile); inc(x,length(Zeile));
        textcolor(Winfo);
      end else
      begin
        Zeile:=pad('',einschub-2);
        writeXY(x,y,Zeile); inc(x,length(Zeile));
      end;

      files:=0; k:=za;
      repeat
        inc(files,dat.ver[k].files);
        inc(k);
      until dat.ver[k].Vopen or (k>dat.veranz);

      If (files>0) then
      begin
        str(files,n);
        Zeile:=padch(n,' ',5);

        If (dat.ver[za+1].Vopen=false) and (za<dat.veranz) then
          textcolor(VcloseCol) else
          If not dat.ver[za].select then textcolor(SelNumCol);

        writeXY(x,y,Zeile); inc(x,length(Zeile));
        textcolor(Winfo);
      end else
      begin
        Zeile:='     ';
        writeXY(x,y,Zeile); inc(x,length(Zeile));
      end;

      If dat.ver[za].pos > 0 {za>1} then
      begin
        Zeile:=' ';
        writeXY(x,y,Zeile); inc(x,length(Zeile));
      end;
      If dat.ver[za].pos > 0{za > 1} then senkline;
      If (dat.ver[za].pos<dat.wanf+ebene+1) and (dat.ver[za].pos+1>dat.wanf) then
      begin
        if (dat.ver[za].pos=dat.ver[za+1].pos) and (dat.veranz>za) then
        begin
          Zeile:=concat(brl,linw);
          writeXY(x,y,Zeile); inc(x,length(Zeile));
        end;
        if (dat.ver[za].pos<>dat.ver[za+1].pos) or (dat.veranz=za) then
          if lastdir(za) then
          begin
            Zeile:=concat(ule,linw);
            writeXY(x,y,Zeile); inc(x,length(Zeile));
          end else
          begin
            Zeile:=concat(brl,linw);
            writeXY(x,y,Zeile); inc(x,length(Zeile));
          end;
        { End }
        If dat.ver[za].pos<dat.wanf+ebene then
        begin

          If (dat.ver[za].pos<dat.ver[za+1].pos) and (not dat.ver[za+1].Vopen) and (za<dat.veranz) then
          begin
            Zeile:='[+] ';
          end else
          begin
            If (dat.ver[za].pos<dat.ver[za+1].pos) and (za<dat.veranz) then
              Zeile:='[-] ' else
              Zeile:='[ ] '
          end;

          dat.ver[za].VXpos:=x-1;
          writeXY(x,y,Zeile); inc(x,length(Zeile));
          If m and (((anf<=za) and (dat.vpos>=za)) or
                   ((anf>=za) and (dat.vpos<=za))) then
            textbackground(Balkenba);

          Zeile:=pad(dat.ver[za].name,12);

          If (dat.ver[za+1].Vopen=false) and (za<dat.veranz) then
            textcolor(VcloseCol) else textcolor(Winfo);

          writeXY(x,y,Zeile); inc(x,length(Zeile));
          textbackground(Winba);
          Zeile :=pad('',((ebene-1)-(dat.ver[za].pos-dat.wanf))*3);
          writeXY(x,y,Zeile); inc(x,length(Zeile));
        end;
        If dat.ver[za].pos=dat.wanf+ebene then
        begin
          Zeile:=concat(linw,'           ');
          writeXY(x,y,Zeile); inc(x,length(Zeile));
        end;


      end else
      begin
        If (dat.ver[za].pos=0) {and (dat.wanf=1)} then
        begin

          If (dat.ver[za].Vart=Verzeichnis) then
          begin
            If (dat.ver[za].pos<dat.ver[za+1].pos) and (not dat.ver[za+1].Vopen) and (za<dat.veranz) then
            begin
              Zeile:='[+] ';
            end else
            begin
              If (dat.ver[za].pos<dat.ver[za+1].pos) and (za<dat.veranz) then
                Zeile:='[-] ' else
                Zeile:='[ ] '
            end;
          end else
            Zeile:='    ';
          dat.ver[za].VXpos:=x-1;
          writeXY(x,y,Zeile); inc(x,length(Zeile));

          If (dat.ver[za+1].Vopen=false) and (za<dat.veranz) then
            textcolor(VcloseCol) else textcolor(Winfo);
          If (dat.ver[za].Vart=Packer) then textcolor(PackerCol);

          If m and (((anf<=za) and (dat.vpos>=za)) or
                   ((anf>=za) and (dat.vpos<=za))) then
            textbackground(Balkenba);

           Zeile:=pad(dat.ver[za].name,12);

          writeXY(x,y,Zeile); inc(x,length(Zeile)); textbackground(Winba);
          Zeile :=pad('',((ebene-1)-(dat.ver[za].pos-0{dat.wanf}))*3);
          writeXY(x,y,Zeile); inc(x,length(Zeile));
        end else


        If (dat.ver[za].pos+1=dat.ver[za+1].pos) and (dat.ver[za].pos+1=dat.wanf) then
        begin
          Zeile:=pad('',(ebene*3+15));
          writeXY(x,y,Zeile); inc(x,length(Zeile));
        end else
           If (dat.ver[za].pos<dat.wanf+ebene+1) and (dat.wanf>1) then
           begin
             Zeile:=pad('',(ebene*3+15));
             writeXY(x,y,Zeile); inc(x,length(Zeile));
           end else
           begin
             Zeile:='            ';
             writeXY(x,y,Zeile); inc(x,length(Zeile));
           end;
      end;

    Zeile:=pad('',Xdiff-X-1);                                {letzteSpalte fÅllen}
    writeXY(x,y,Zeile);  inc(x,length(Zeile));
    end;


    inc(zamax);
    while (zamax<dat.sanf+ydiff-2) do                         {letzte Zeilen lîschen}
    begin
      inc(zamax);
      writeXY(1,zamax-dat.sanf,pad('',xdiff-2));
    end;
    Unterfenster;
  end;



  procedure Baum.verselect(m:boolean;anf:word);
  var z,z1,Ypos:word;
  begin
    If not Anpassen(dat.wanf,dat.sanf,dat.vpos) then
    begin
      If anf<dat.sanf           then anf:=dat.sanf;

      If Vdiff1(dat.sanf,anf)>(ydiff-3) then
        anf:=dat.sanf+(ydiff-3);

      If (dat.veranz>0) then
      begin
        If anf<dat.vpos then
        begin
          for z:=anf to dat.vpos do
          begin
            Ypos:=0;
            If dat.ver[z].Vopen then
            begin
              for z1:=z downto dat.sanf do
                If dat.ver[z1].Vopen then
                  inc(Ypos);
              verwrite(m,Ypos,z);
              textcolor(LaufcuCol); textbackground(Winba);
              If (z=dat.vpos) and m then
                writeXY(1,Ypos,'')
              else
                writeXY(1,Ypos,' ');
            end;
          end;
        end else
        begin
          for z:=anf downto dat.vpos do
          begin
            Ypos:=0;
            If dat.ver[z].Vopen then
            begin
              for z1:=z downto dat.sanf do
                If dat.ver[z1].Vopen then
                  inc(Ypos);
              verwrite(m,Ypos,z);
               textcolor(LaufcuCol); textbackground(Winba);
              If (z=dat.vpos) and m then
                writeXY(1,Ypos,'')
              else
                writeXY(1,Ypos,' ');
            end;
          end;
        end;
      end;
    end else
       BaumWrite(m,anf);
    dat.aktverz:=fullpath(dat.vpos); Pfeilwrite(m,dat.vpos);
    {chver(dat.aktverz);}
  end;


  procedure Baum.vselect(Evpos:word);
  var sanf,vpos: word;
      wanf     : byte;
  begin
    sanf:=dat.sanf;
    wanf:=dat.wanf;
    vpos:=dat.vpos;

    If not Anpassen(wanf,sanf,Evpos) and (dat.vpos<>Evpos) then
      verselect(false,dat.vpos);

    dat.vpos:=Evpos;
    verselect(true,dat.vpos);
  end;


  procedure Baum.Baummark (anf,ende: word);
  var  bpos  : word;
       seite : boolean;
       wanf  : byte;
       sanf,vpos : word;
  begin
    seite:=false;
    If (ende < 1) or (anf < 1)   then exit;
    If ende-1 > dat.veranz       then ende :=dat.veranz;
    If ende < dat.sanf           then seite:=true;
    If ende > Vjump(dat.sanf,Vdiff2(dat.sanf,dat.sanf+ydiff-3),true) {(dat.sanf+ydiff-3)} then seite:=true;
    If anf  > Vjump(dat.sanf,Vdiff2(dat.sanf,dat.sanf+ydiff-3),true) {(dat.sanf+ydiff-3)} then
        {anf  :=dat.sanf+ydiff-2;} anf:=Vjump(dat.sanf,ydiff-2,true);
    If anf  < dat.sanf           then
        {anf  :=dat.sanf-1;}       anf:=Vjump(dat.sanf,1,false);

    If dat.vpos > dat.veranz     then dat.vpos:=dat.veranz;

    If (dat.vpos<>ende) then
    begin
      wanf:=dat.wanf;
      sanf:=dat.sanf;
      bpos:=dat.vpos;
      dat.vpos:=ende;


      If (((dat.vpos>bpos) and (anf>bpos)) or
          ((dat.vpos<bpos) and (anf<bpos))) and not Anpassen(wanf,sanf,ende) then
      begin
        If (bpos>dat.vpos) and (anf<bpos) then
        begin
          dat.vpos:=Vjump(dat.vpos,1,true); verselect(false,bpos);  dat.vpos:=Vjump(dat.vpos,1,false);
        end;
        If (bpos<dat.vpos) and (anf>bpos) then
        begin
          dat.vpos:=Vjump(dat.vpos,1,false);  verselect(false,bpos); dat.vpos:=Vjump(dat.vpos,1,true);
        end;
        verselect(true,dat.vpos);
      end;{else}

      wanf:=dat.wanf;
      sanf:=dat.sanf;
      If (((bpos>dat.vpos) and (anf>=dat.vpos)) or
         ((bpos<dat.vpos) and (anf<=dat.vpos))) or Anpassen(wanf,sanf,ende) then
      begin
         verselect(true,anf);
      end;
    end else
    begin
    end;
  end;



function Baum.VerzZoom : boolean;
 var z    : word;
     Open : boolean;
 begin

   If ((ev.Ereignis=EV_LEFT_PRESS) and
      ((dat.ver[dat.vpos].VXpos <=ev.spalterel) and
      (dat.ver[dat.vpos].VXpos+2>=ev.spalterel))) or
      ((ev.Ereignis=EV_KEY_PRESSED) and
      ((ev.key=ord('+')) or (ev.key=ord('-')))) then
   begin
     VerzZoom:=true;
     If (ev.Ereignis=EV_LEFT_PRESS) then Open:=not dat.ver[dat.vpos+1].Vopen;
     If (ev.Ereignis=EV_KEY_PRESSED) then
       If (ev.key=ord('+')) then Open:=true else Open:=false;
     for z:=dat.vpos+1 to dat.veranz do
     begin
       If (dat.ver[z].pos-1=dat.ver[dat.vpos].pos) and Open then
         dat.ver[z].Vopen:= Open;
       If (dat.ver[z].pos>dat.ver[dat.vpos].pos) and not Open then
         dat.ver[z].Vopen:= Open;

       If dat.ver[z].pos<=dat.ver[dat.vpos].pos then
         break;
     end;
     BaumWrite(true,dat.vpos);
   end else
     VerzZoom:=false;
 end;


  function Baum.Verzlesen : pathstr;
  var ver   : pathstr;
      gef   : boolean;
      VerStr: Ftemp;

  begin
    ver:=''; gef:=false;
    while not Filsel.Eof and not gef do
    begin
      Filsel.Read(VerStr,-1,1);
      If Verstr.ver_dat then
      begin
        ver:=concat(ver,addbackslash(Verstr.name));
      end else
      begin
        If length(ver)>0 then
        begin
          gef:=true; Filsel.Seek(Filsel.Pos-1);
        end else
          Filsel.Seek(Filsel.Pos+Verstr.jump);
      end;
    end;
    Verzlesen:=ver;
  end;

 procedure Baum.unselect;
 var Vsel  : Ftemp;
     Vind  : Findex;
     beg,en: word;
     Fpos  : longint;
     Dseek : longint;
     Laufw : char;
     S     : string;
 begin
   S:=fullpath(2);
   Laufw:=S[1];
   If dat.ver_dat then
   begin
     for z:=1 to dat.veranz do
     begin
      dat.ver[z].select:=false;
      dat.ver[z].files :=0;
      dat.ver[z].selgr :=0;
     end;
   end else
   begin
     for z:=2 to dat.filanz do
     begin
       dat.ver[z].select:=false;
     end;
   end;

   Dseek:=0;
   Filsel.Open; Filind.Open;
   while not Filind.Eof do
   begin
     Filind.Read(Vind,-1,1);
     If Dseek>0 then                   {Indexdatei anpassen}
     begin
       Vind.Fseek:=Vind.Fseek-Dseek;
       Filind.Write(Vind,Filind.Pos-1,1);
     end;
     If (Vind.Lw=Laufw) then
     begin
        Fpos:=Vind.Fseek;

        repeat
          dec(Fpos);                   {Verzeichnis}
          Filsel.Read(Vsel,Fpos,1);
        until not Vsel.ver_dat or (Fpos=0);

        beg:=Fpos+1;

        Fpos:=Vind.Fseek;
        Filsel.Seek(Fpos);

        repeat
          Filsel.Read(Vsel,-1,1);      {Dateien}
        until Filsel.Eof or Vsel.ver_dat;

        If Vsel.ver_dat then
          en:=Filsel.Pos-1 else en:=Filsel.Pos;

        Filsel.Remove(beg,en-beg);
        inc(Dseek,en-beg);
     end;

   end;

   Filsel.Close;

   Filind.Seek(0);
   Fpos:=Filind.Pos;
   while not Filind.Eof do
   begin
     Filind.Read(Vind,-1,1);
     If dat.ver[1].name[1]=Vind.Lw then
       Filind.Remove(Filind.Pos-1,1);
   end;
   Filind.Close;

   For z:=1 to dat.veranz do
   begin
     dat.ver[z].selgr:=0;
     dat.ver[z].files:=0;
     dat.ver[z].select:=true;
     dat.selgr:=0;
   end;
   DriveWrite(False);

   If not dat.ver_dat then
   begin
     for z:=2 to dat.filanz do
       dat.fil[z].select:=false;
   end;

 end;


procedure Baum.UnselectAll;
var z      : word;
    written: boolean;
begin
  for z:=1 to dat.veranz do
  begin
    dat.ver[z].select:=false;
    dat.ver[z].files :=0;
    dat.ver[z].selgr :=0;
  end;

  If not dat.ver_dat then
    for z:=2 to dat.filanz do
    begin
      dat.fil[z].select:=false;
    end;


  Filind.Open;
  Filind.Remove(0,Filind.Size);
  Filind.Close;

  Filsel.Open;
  Filsel.Remove(0,Filsel.Size);
  Filsel.Close;

  Drive.Open;
  while not Drive.Eof do
  begin
    Drive.Read(Lver,-1,1);
    for z:=1 to Lver.veranz do
    begin
      If Fmod=Links then
      begin
        Lver.ver[z].leftselect:=false;
        Lver.ver[z].leftfiles :=0;
        Lver.ver[z].leftselgr :=0;
      end;
      If Fmod =Rechts then
      begin
        Lver.ver[z].rightselect:=false;
        Lver.ver[z].rightfiles :=0;
        Lver.ver[z].rightselgr :=0;
      end;

    end{For};

    Drive.Write(Lver,Drive.Pos-1,1);
  end{While};
  Drive.Close;

end;


procedure Baum.DriveAkt;
var lw    : DrRec;
    Laufw : char;
begin
  Laufw:=dat.ver[1].name[1];
  lw.Dr:=dat.ver[1].name[1];
  DriveKind(lw);
  If lw.Ch[1] in ['0','1'] then
  begin
    Drive.Open;
    while not Drive.Eof do
    begin
      Drive.Read(Lver,-1,1);
      If (Laufw=Lver.drive) and (length(dat.aktverz)>0) then
      begin
        If (Fmod = Links) then
        begin
          Lver.leftsanf     := dat.sanf;
          Lver.leftwanf     := dat.wanf;
          Lver.leftvpos     := dat.vpos;
          Lver.dfree        := dat.dfree;
          Lver.dsize        := dat.dsize;
        end;
        If (Fmod =Rechts) then
        begin
          Lver.rightsanf     := dat.sanf;
          Lver.rightwanf     := dat.wanf;
          Lver.rightvpos     := dat.vpos;
          Lver.dfree        := dat.dfree;
          Lver.dsize        := dat.dsize;
        end;

        Drive.Write(Lver,Drive.Pos-1,1);
        break;
      end;
    end;
    Drive.Close;
  end;
end;



function Baum.DriveRead(Var written :boolean) : boolean;
var z  : word;
    lw : DrRec;
    Laufw : char;
begin
  Driveread := false;
  Laufw:=dat.ver[1].name[1];
  lw.Dr:=dat.ver[1].name[1];
  DriveKind(lw);
  written:=false;
  If lw.Ch[1] in ['0','1'] then
  begin
    Drive.Open;
    while not Drive.Eof do
    begin
      Drive.Read(Lver,-1,1);
      If Laufw=Lver.Drive then
      begin
        for z:=1 to Lver.veranz do
        begin
          dat.ver[z].name  :=Lver.ver[z].name;
          dat.ver[z].pos   :=Lver.ver[z].pos;
          dat.ver[z].Vart  :=Verzeichnis;
          If Fmod=Links  then
          begin
            If not Lver.leftwritten then
            begin
              dat.ver[z].Vopen :=Lver.ver[z].rightVopen;
            end else
            begin
              dat.ver[z].select:=Lver.ver[z].leftselect;
              dat.ver[z].files :=Lver.ver[z].leftfiles;
              dat.ver[z].selgr :=Lver.ver[z].leftselgr;
              dat.ver[z].Vopen :=Lver.ver[z].leftVopen;
            end;

          end;
          If Fmod =Rechts then
          begin
            If not Lver.rightwritten then
            begin
              dat.ver[z].Vopen :=Lver.ver[z].leftVopen;
            end else
            begin
              dat.ver[z].select:=Lver.ver[z].rightselect;
              dat.ver[z].files :=Lver.ver[z].rightfiles;
              dat.ver[z].selgr :=Lver.ver[z].rightselgr;
              dat.ver[z].Vopen :=Lver.ver[z].rightVopen;
            end;
          end;
        end{For};
        dat.veranz   :=Lver.veranz;
        dat.dfree    :=Lver.dfree;
        dat.dsize    :=Lver.dsize;
        If (Fmod = Links) then
        begin
          If Lver.leftwritten then
          begin
            dat.vpos := Lver.leftvpos;
            dat.sanf := Lver.leftsanf;
            dat.wanf := Lver.leftwanf;
          end else
          begin
            dat.vpos := Lver.rightvpos;
            dat.sanf := Lver.rightsanf;
            dat.wanf := Lver.rightwanf;
          end;
          written:=Lver.leftwritten;
        end;
        If (Fmod =Rechts) then
        begin
          If Lver.rightwritten then
          begin
            dat.vpos := Lver.rightvpos;
            dat.sanf := Lver.rightsanf;
            dat.wanf := Lver.rightwanf;
          end else
          begin
            dat.vpos := Lver.leftvpos;
            dat.sanf := Lver.leftsanf;
            dat.wanf := Lver.leftwanf;
          end;

          written:=Lver.rightwritten;
        end;
        If (Fmod=Links) and not written then
        begin
          UnselectAll; dat.ver_dat:=true;
        end;
        If (Fmod=Rechts) and not written then
        begin
          UnselectAll; dat.ver_dat:=true;
        end;
        DriveRead:=true;

        break;
      end{IF};
    end{While};
    Drive.Close;
  end else
   for z:=1 to dat.veranz do
    dat.ver[z].Vopen := true;
  {EndIf};

  Drive.Open;
  while not Drive.Eof do
  begin
    Drive.Read(Lver,-1,1);
    If (Laufw=Lver.drive) then
    begin
      If (Fmod = Links) and not Lver.leftwritten then
      begin
        Lver.leftsanf     := dat.sanf;
        Lver.leftwanf     := dat.wanf;
        Lver.leftvpos     := dat.vpos;
        Lver.leftwritten  := true;
      end;
      If (Fmod =Rechts) and not Lver.Rightwritten then
      begin
        Lver.rightsanf     := dat.sanf;
        Lver.rightwanf     := dat.wanf;
        Lver.rightvpos     := dat.vpos;
        Lver.rightwritten  := true;
      end;
      Drive.Write(Lver,Drive.Pos-1,1);
      break;
    end;
  end;
  Drive.Close;

end;



procedure Baum.DriveWrite(NewWritten:boolean);
var z  : word;
    lw : DrRec;
    wr : boolean;
    Laufw :char;
begin
  wr:=false;
  Laufw:=dat.ver[1].name[1];
  lw.Dr:=dat.ver[1].name[1];
  DriveKind(lw);
  If lw.Ch[1] in ['0','1'] then
  begin
    Drive.Open;
    while not Drive.Eof do
    begin
      Drive.Read(Lver,-1,1);
      If (Laufw=Lver.drive) then
      begin
        for z:=1 to dat.veranz do
        begin
          Lver.ver[z].name  :=dat.ver[z].name;
          Lver.ver[z].pos   :=dat.ver[z].pos;
          If Fmod=Links then
          begin
            Lver.ver[z].leftselect:=dat.ver[z].select;
            Lver.ver[z].leftfiles :=dat.ver[z].files;
            Lver.ver[z].leftselgr :=dat.ver[z].selgr;
            Lver.ver[z].leftVopen :=dat.ver[z].Vopen;
          end;
          If Fmod =Rechts then
          begin
            Lver.ver[z].rightselect:=dat.ver[z].select;
            Lver.ver[z].rightfiles :=dat.ver[z].files;
            Lver.ver[z].rightselgr :=dat.ver[z].selgr;
            Lver.ver[z].rightVopen  :=dat.ver[z].Vopen;
          end;
        end;
        Lver.veranz   := dat.veranz;
        Lver.dfree    := dat.dfree;
        Lver.dsize    := dat.dsize;
        If Fmod = Links then
        begin
          Lver.leftsanf     := dat.sanf;
          Lver.leftwanf     := dat.wanf;
          Lver.leftvpos     := dat.vpos;
          Lver.leftwritten  := True;
          If NewWritten then
              Lver.rightwritten:=False;
        end;

        If Fmod =Rechts then
        begin
          Lver.rightsanf    := dat.sanf;
          Lver.rightwanf    := dat.wanf;
          Lver.rightvpos    := dat.vpos;
          Lver.rightwritten := True;
          If NewWritten then
              Lver.leftwritten:=False;
        end;

        wr:=true;
        Drive.Write(Lver,Drive.Pos-1,1);
      end{If};
    end;{While}
    If not wr then
    begin
      for z:=1 to dat.veranz do
      begin
        Lver.ver[z].name  :=dat.ver[z].name;
        Lver.ver[z].pos   :=dat.ver[z].pos;
        If Fmod=Links then
        begin
          Lver.ver[z].leftselect:=dat.ver[z].select;
          Lver.ver[z].leftfiles :=dat.ver[z].files;
          Lver.ver[z].leftselgr :=dat.ver[z].selgr;
          Lver.ver[z].leftVopen :=dat.ver[z].Vopen;
          Lver.leftwritten  := True;
          If NewWritten then
              Lver.ver[z].rightVopen:=true;
        end;
        If Fmod =Rechts then
        begin
          Lver.ver[z].rightselect:=dat.ver[z].select;
          Lver.ver[z].rightfiles :=dat.ver[z].files;
          Lver.ver[z].rightselgr :=dat.ver[z].selgr;
          Lver.ver[z].rightVopen :=dat.ver[z].Vopen;
          Lver.rightwritten := True;
          If NewWritten then
              Lver.ver[z].leftVopen:=true;
        end;
      end;
      Lver.drive    := dat.ver[1].name[1];
      Lver.veranz   := dat.veranz;
      Lver.dfree    := dat.dfree;
      Lver.dsize    := dat.dsize;
      If Fmod = Links then
      begin
        Lver.leftsanf     := dat.sanf;
        Lver.leftwanf     := dat.wanf;
        Lver.leftvpos     := dat.vpos;
        Lver.rightwritten := not NewWritten;
      end;
      If Fmod =Rechts then
      begin
        Lver.rightsanf     := dat.sanf;
        Lver.rightwanf     := dat.wanf;
        Lver.rightvpos     := dat.vpos;
        Lver.leftwritten   := not NewWritten;
      end;

      Drive.Write(Lver,-1,1);
    end;
    Drive.Close;
  end{If};
end;


procedure Baum.DriveDelete;
begin
  Unselect;
  Drive.Open;
  while not Drive.Eof do
  begin
    Drive.Read(Lver,-1,1);
    If dat.ver[1].name[1]=Lver.Drive then
    begin
      Drive.Remove(Drive.Pos-1,1);
      break;
    end;
  end;
  Drive.Close;
  
end;



function Baum.VerzNeu : boolean;
var      vp,vanz      : word;
         written      : boolean;

  procedure DatReset;
  begin
    dat.veranz:=0;
    dat.gesamtdat:=0;
    dat.gesamtgr:=0;
    dat.dfree:=0;
    dat.dsize:=0;
    dat.selgr:=0;
    dat.ver[0].pos:=0;
    dat.ver[0].Vopen:=true;
    dat.ver[1].pos   :=0;
    dat.ver[1].selgr :=0;
    dat.ver[1].files :=0;
    dat.ver[1].select:=false;
    dat.ver[1].Vopen :=True;
    dat.ver[1].Vart  :=Verzeichnis;
  end;


begin
    vanz:=1; DatReset;

    VerzNeu:=true;
    If not DriveRead(written) then
    begin
      If not VerzRead(vanz,1,dat.ver[1].name) then
      begin                                  {Keine Diskette im Laufwerk}
        VerzNeu:=false;
        dat.vpos:=1;
        dat.ver_dat:=true;
        exit;
      end;
      dat.ver[vanz+1].pos:=0; dat.veranz:=vanz;

      If length(dat.aktverz)=0 then          {Verzeichnis suchen}
      begin
        getver(DrvLet_Num(dat.ver[1].name[1]),dat.aktverz);
        for vp:=1 to dat.veranz do
        begin
          If dat.aktverz=fullpath(vp) then
          begin
            dat.sanf:=vp;
            dat.vpos:=vp;
            If dat.ver[vp].pos>ebene then dat.wanf:=dat.ver[vp].pos else dat.wanf:=1;
            break;
          end;
        end;
      end;

      DriveWrite(True);
    end{If} else
    begin
      chver(dat.ver[1].name[1]+':');
    end;


    If not written then
    begin
      Anpassen(dat.wanf,dat.sanf,dat.vpos);
      DriveAkt;
    end;

    {If not (Doserror in [0,18]) then DatReset;
    Doserror:=0;}
end;


procedure Baum.VerzAkt;
var z,w : word;
begin
  UnselectAll;
  z:=dat.vpos;
  while (dat.ver[z+1].pos > dat.ver[z].pos) and (dat.veranz>z) do
  begin
    dec(dat.veranz);
    For w:=z+1 to dat.veranz do
    begin
      dat.ver[w]:=dat.ver[w+1];
    end;
  end;

  If VerzRead(z,dat.ver[dat.vpos].pos+1, dat.aktverz) then
    DriveWrite(True);
end;



function Baum.VerzRead(var vpos :word; vtiefe: byte; vname: Pathstr) : boolean;
var   vername : array [0..vertiefe] of FileNameStr;
      drv     : string[2];
      enter,
      ende    : boolean;
      verstr  : pathstr;
      tiefe   : byte;
      w       : word;
      Verzmerk: pathstr;
begin
  Verzread:=false;
  If not openwindow(31,5,fenfo,fenba,'Lesen') then exit;
  textcolor(MessageCol);
  enter:=true;ende:=false;drv:=dat.ver[1].name;
  tiefe:=vtiefe;
  writeXY(3,2,'Lese die Verzeichnisstruktur');
  writeXY(9,3,concat('auf Laufwerk ',drv,' !'));
  getver(DrvLet_Num(vname[1]),Verzmerk);
  If chver(vname) then
  begin
    Verzread:=true;
    repeat
      If enter then
      begin
        dat.ver[vpos].select:=false;
        {findFirst('*.*', $37, DirInfo);}
        findFirst('*.*', $10, DirInfo);            { Anfang }
        while (((Dirinfo.name= '.') or (Dirinfo.name='..'))
             and ($10=(dirinfo.attr and $10))) and (doserror=0) do
        begin                                                   { Info }
        (*If (Dirinfo.name<> '.') and (Dirinfo.name<>'..') and (doserror=0)  and
           (((dirinfo.attr and m_attrib)>0) and (not ((dirinfo.attr and $18) in[$10,$8])) or (Dirinfo.attr=0)) then
         begin}
            {inc(dat.gesamtdat);
            inc(dat.gesamtgr,Dirinfo.size);}
            {for l:=1 to Lendg.fanz do
              If compend(Lendg.en[l],dirinfo.name) then
               dat.ver[vpos].leftselect:=(dirinfo.name<>'..') and (dirinfo.name<>'');}
            {for l:=1 to Rendg.fanz do
              If compextension(Rendg.en[l],dirinfo.name) then
              begin
                dat.ver[vpos].rightselect:=true; break;
              end;}
          end;*)
          findnext(DirInfo);
       end{While};
       vername[tiefe]:=Dirinfo.name;
      end else
      begin
        {findFirst('*.*', $37, DirInfo);}
        findFirst('*.*', $10, DirInfo);            { Weiter }
        while (Dirinfo.name<>vername[tiefe]) and (Doserror=0) do
          findnext(DirInfo);
        If Doserror=0 then
        repeat
           findnext(dirinfo);       { Info }
           (*If (doserror=0) and (((dirinfo.attr and m_attrib)>0) and
               (not ((dirinfo.attr and $18) in[$10,$8])) or (Dirinfo.attr=0))}then
            begin
              {inc(dat.gesamtdat);
              inc(dat.gesamtgr,Dirinfo.size);}
              {for l:=1 to Lendg.fanz do
                If compextension(Lendg.en[l],dirinfo.name) then}
                {If (dirinfo.name<>'..') and (dirinfo.name<>'') then
                 for zah:=vpos downto 1 do
                   If dat.ver[zah].pos=tiefe-1 then
                   begin
                     dat.ver[zah].leftselect:=true; break;
                   end;}
              {for l:=1 to Rendg.fanz do
                If compextension(Rendg.en[l],dirinfo.name) then
                 for zah:=vpos downto 1 do
                   If dat.ver[zah].pos=tiefe-1 then
                   begin
                     dat.ver[zah].rightselect:=true; break;
                   end;}
            end;*)
          until ($10=(dirinfo.attr and $10)) or (doserror>0);
        {End IF}
        vername[tiefe]:=Dirinfo.name;
      end;

      If (doserror>0)  then
      begin
        ende:=true;
        If tiefe > vtiefe then                                 { Exit }
        begin
          chver('..');
          dec(tiefe);
          Enter:=false;ende:=false;
        end;


      end else
      begin
        {$I-}chdir(vername[tiefe]);{I+}                    { Enter }
        If ioresult=0 then
        begin
          If dat.veranz>=vpos then                         { EinfÅgen }
          begin
            For w:=dat.veranz downto vpos do
            begin
              dat.ver[w+1]:=dat.ver[w];
            end;
            inc(dat.veranz);
          end;
          verstr:=Fexpand('');
          inc(vpos);textcolor(fenfo);writeXY(11,5,center(vername[tiefe],12));
          dat.ver[vpos].name:=vername[tiefe];
          dat.ver[vpos].pos :=tiefe;
          dat.ver[vpos].select:=false;
          dat.ver[vpos].files:=0;
          dat.ver[vpos].selgr:=0;
          dat.ver[vpos].Vopen:=True;
          dat.ver[vpos].Vart :=Verzeichnis;
          inc(tiefe);
          Enter:=true;
          ende:=false;
          If vpos+1>veranz then break;
        end else
          Enter:=false;
      end;
   until (tiefe=vtiefe) and ende or not (Doserror in [0,18]);
   dat.dfree:=diskfree(0); dat.dsize:=disksize(0);
   chver(Verzmerk);
  end;
    
  {EndIF}
  closewindow;
end;


procedure Baum.VerzEinf(S:PathStr);
var Z,Z2   : word;
    vpos : byte;
    Vname: FilenameStr;
    new_vpos:word;
begin
  new_vpos:=dat.vpos;
  If Mkver(S) and (Veranz>dat.veranz) then
  begin
    Vname:=justfilename(S);
    S:=justpathname(S);
    If length(S)>3 then delete(S,length(S),1);
    For z:=1 to dat.veranz do
      If fullpath(z)= S Then
      begin
        vpos:=dat.ver[z].pos;

        while (z<dat.veranz) and (vpos<dat.ver[z+1].pos) do
        begin
          inc(z);
          If vpos=dat.ver[z].pos-1 then dat.ver[z].Vopen:=true;
        end;

        For z2:=dat.veranz downto z+1 do
          dat.ver[z2+1]:=dat.ver[z2];

        inc(dat.veranz);
        dat.ver[z+1].name :=Vname;
        dat.ver[z+1].pos  :=vpos+1;
        dat.ver[z+1].Vopen:=true;
        dat.ver[z+1].Vart :=Verzeichnis;
        dat.ver[z+1].files:=0;
        dat.ver[z+1].selgr:=0;
        new_vpos:=z+1;
        dat.ver_dat:=true;

        break;
      end;
    {EndIF}
  end;
  verselect(false,dat.vpos);
  dat.vpos:=new_vpos;
  verselect(false,dat.vpos);
  UnselectAll;
  DriveWrite(True);
end;


procedure Baum.VerzLosch(Var vpos : word);
var z : word;
begin
  for z:=vpos to dat.veranz do
  begin
    dat.ver[z]:=dat.ver[z+1];
  end;
  dec(dat.veranz);
end;



procedure Baum.VLoschen(Uv:boolean);
var P : PathStr;
    z : word;
    rm_dir : boolean;
    rm_vpos: word;

    procedure DatLoschen(P:PathStr);
    var DelFile : Typedstream;
    begin
       findfirst (addbackslash(P)+'*.*',$3F,Dirinfo);
       while (Doserror=0) and ((Dirinfo.name='.') or (Dirinfo.name='..')) do
       begin
         findnext(Dirinfo);
       end;
       while (Doserror=0) do
       begin
         If (dirInfo.attr<>Directory) and
           ((not ((dirinfo.attr and $18) in[$10,$8])) or (Dirinfo.attr=0)) then
         begin
           DelFile.Init((concat(addbackslash(P),Dirinfo.Name)),1);
           DelFile.DelFile;
           DelFile.Done;
         end;
         findnext(Dirinfo);

       end;
       Doserror:=0;
    end;

begin
  If not openwindow(31,4,fenfo,fenba,'Lîschen') then exit;
  writeXY(6,2,'Lîsche Verzeichnis...');
  chver(dat.ver[1].name);
  If Uv then
  begin
    z:=dat.vpos;
    while (dat.ver[dat.vpos].pos<dat.ver[z+1].pos) and (z<dat.veranz) do
      inc(z);
    while z>dat.vpos do
    begin
      P:=fullpath(z);
      writeXY(1,4,center(justfilename(P),31));
      DatLoschen(P);
      If RmVer(P) then
      begin
        VerzLosch(z);
      end;
      dec(z);
    end;
    P:=fullpath(dat.vpos);
    writeXY(1,4,center(justfilename(P),31));
    DatLoschen(P);
  end;

  P:=fullpath(dat.vpos);
  rm_dir:=RmVer(P);
  closewindow;
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
end;




Destructor  Baum.Done;
begin
end;

begin
end.