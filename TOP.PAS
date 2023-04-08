{$A+,B-,D+,E-,F+,G+,I+,L+,N-,O-,P+,Q-,R+,S+,T-,V+,X+}
program Top;
{$M 45000,0,300000}


uses Crt,Dos,KBM,Tkwin,{Fenster}Archive,Init,Tkstring,
      Tpinst,Tkdisk,Tkstream,Tksaa,Tkvideo,Swap,Tctrl2;




 procedure Ende;
 var T  :text;
 begin
   textcolor(Lightgray);textbackground(black);
   window(1,1,crtxmax,crtymax); winclrscr;
   tpibegin;

   tpiput(604,1,m_sort);
   tpiput(605,1,m_attrib);
   tpiput(606,1,m_color);
   tpiput(607,1,m_prgend);
   tpiput(608,1,m_auto);
   tpiput(609,1,m_flashend);
   tpiput(610,1,m_ver);
   tpiput(611,1,m_interM);
   tpiput(612,51,m_packverz);
   tpiput(664,51,m_tempverz);
   If (RFenster^.dat.ver[1].name<>addbackslash(restlauf+':')) and auto then
       tpiput(715,1,RFenster^.dat.ver[1].name[1]);
   tpiput(716,1,m_pack);
   tpiput(717,1,m_komp);
   tpiput(718,41,Name);
   tpiput(760,41,Strasse);
   tpiput(802,41,Ort);
   tpiput(844,6 ,Liznr);

   If not Test then
     tpiend(((RFenster^.dat.ver[1].name<>addbackslash(restlauf+':')) and auto) or
             (m_pack<>pack) or
             (m_komp<>komp) or
             (m_packverz<>packverz) or
             (m_tempverz<>tempverz) or
             (m_prgend<>prgend) or
             (m_sort<>sort) or
             (m_color<>color) or
             (m_attrib<>attrib) or
             (m_auto<>auto) or
             (m_flashend<>flashend) or
             (m_ver<>ver) or
             (m_interM<>interM));

   RFenster^.Done;
   LFenster^.Done;
   AFenster^.Done;
   Drive.DelFile;Drive.Done;
   Pdat.Delfile; Pdat.Done;
   Packer_File.Done; Hilfe.Done;
   setverify(ver);chver(merkdir);cursor_on;
   textcolor(Lightgray);textbackground(black);
   writeXY(1,1,
   {crypt('TOP - Toms OberflÑche fÅr Packprogramme - V2.1, Copyright 1992-95, Thomas Knîfel'));}
crypt('UMS$(&Sgdy+Cok}v}ñp|p6qôk:K}~uoRNEQEHKB'#8#4#10'}'#30#3#31#3#16'r]CMG_PPM'#26#10#5#4#12#18'ytnc'#16'-)*):j'#0'"Ÿ(*<'));
   If not Demo then
   begin
     writeXY(1,3,crypt('Mkyakunm{~+jå|5'));      {Lizensiert fÅr:}
     WinFrame(19,4,61,8,true);
     writeXY(20,5,center(crypt(Name),40));
     writeXY(20,6,center(crypt(Strasse),40));
     writeXY(20,7,center(crypt(Ort),40));
     gotoXY(1,9);
   end;
   halt(0);
 end;




  procedure Back_o_Rest;
  var paverz  : string;
      veranz  : word;
  begin

    new(RFenster); new(LFenster); new(AFenster);

    If (RFenster=NIL) or (LFenster=NIL) or (AFenster=NIL) then
    begin
      HErrorMsg; halt(1);
    end;

    Rahmen;

    If Demo then Hilfe.ViewPage(2);

    Drive.Init (concat(addbackslash(m_tempverz),Drivename),SizeOf(Dtemp));

    Pdat.Init  (concat(addbackslash(m_tempverz),Pdatname));

    paverz:=concat(addbackslash(readprogdir(paramstr(0))),Packername);

    Packer_File.Init (paverz,SizeOf(Dparam));


    Findfirst(paverz,$27,Dirinfo);
    If (Dirinfo.Name='') then
    begin
      Packer_File.Create; Packer_File.Close; Doserror:=0;
    end;

    Drive.Create; Drive.Close;
    Pdat.Create;  Pdat.Close;

    lw.Dr:=restlauf;
    DriveKind(lw);


    If auto and  (lw.ch<>'') then
    begin
       LFenster^.dat.ver[1].name :=merkdir[1]+':\';
       RFenster^.dat.ver[1].name :=restlauf+':\';
       FindFirst(concat(addbackslash(merkdir),'*.*'), $35, DirInfo);
       repeat
         Findnext(DirInfo);
       until ((DirInfo.Name<>'.') and (DirInfo.Name<>'..')) or (Doserror>0);
       If Doserror=0 then
       begin
         RFenster^.dat.ver_dat:=true;
         FensterM:=Links;
       end else
       begin
         RFenster^.dat.ver_dat:=false;
         FensterM:=Rechts; Doserror:=0;
       end;
    end else
    begin
       FensterM:=Links;
       LFenster^.dat.ver[1].name:=merkdir[1]+':\';
       RFenster^.dat.ver[1].name:=merkdir[1]+':\';
       RFenster^.dat.ver_dat:=true;
    end;


    LFenster^.dat.vpos:=1;LFenster^.dat.sanf:=1; LFenster^.dat.ver_dat:=true;
    LFenster^.dat.aktverz:='';
    RFenster^.dat.vpos:=1;RFenster^.dat.sanf:=1; RFenster^.dat.aktverz:='';

    ev1.Ereignis:=0; ArcOpen:=false;

    If FensterM=Links then
    begin
      LFenster^.Init;
      RFenster^.Init;
      AFenster^.Init;
    end else
    begin
      RFenster^.Init;
      LFenster^.Init;
      AFenster^.Init;
    end;


    repeat
      case FensterM of
        Links : begin
                  LFenster^.Fenster;
                  case Ftaste of
                   TAB : begin
                           FensterM:=Rechts;
                         end;
                 CTRL_R: begin
                           Drive.Open; Lver.Drive:=' ';
                           While (Lver.Drive <> LFenster^.dat.ver[1].name[1]) and
                                 not Drive.Eof do
                           begin
                             Drive.Read(Lver,-1,1);
                             If Lver.Drive = LFenster^.dat.ver[1].name[1] then
                               Drive.Remove(Drive.Pos-1,1);
                           end;
                           Drive.Close;
                           LFenster^.VerzNeu;
                           If not ArcOpen and
                             (LFenster^.dat.ver[1].name[1] = RFenster^.dat.ver[1].name[1]) then
                           begin
                             RFenster^.UnselectAll;
                             RFenster^.Fenakt(False,True,True);
                           end;
                           LFenster^.UnselectAll;
                           LFenster^.Fenakt(True,False,True);
                         end;
                    F3 : begin
                            LFenster^.Fenakt(True,False,False);
                         end;
                    F5 : begin
                           If m_flashend then ende;
                           If ArcOpen then
                           begin
                             AFenster^.UnselectAll;
                             AFenster^.Fenakt(False,True,True);
                           end else
                           begin
                             RFenster^.UnselectAll;
                             RFenster^.Fenakt(False,False,True);
                           end;
                           If Kom.ver then
                           begin
                             If Kom.ausw then
                             begin
                               Lfenster^.Drivedelete;
                               Lfenster^.VerzNeu;
                             end else
                               Lfenster^.VerzAkt;
                           end else
                             Lfenster^.UnselectAll;
                           LFenster^.Fenakt(True,False,True);
                         end;
                     F7: begin
                           If not Arcopen then
                           begin
                             RFenster^.Fenakt(False,True,False);
                           end;
                           LFenster^.Fenakt(True ,False,False);
                         end;
                     F8: begin
                           If ArcOpen then
                           begin
                             AFenster^.UnselectAll;
                             AFenster^.Fenakt(False,True,True);
                           end;

                           If Verzdel then
                           begin
                             If not ArcOpen then
                             begin
                               Rfenster^.Fenakt(False,True,False);
                             end;
                             Lfenster^.Fenakt(True,True,False);
                           end else
                           begin
                             If not ArcOpen then
                             begin
                               Rfenster^.UnselectAll;
                               Rfenster^.Fenakt(False,False,True);
                             end;
                             LFenster^.UnselectAll;
                             Lfenster^.Fenakt(True,False,True);
                           end;

                         end;
                     F2: begin
                           AFenster^.Laufwerk(true);
                           RFenster^.Laufwerk(true);
                           If ArcOpen then
                           begin
                               AFenster^.ClrUnterF;
                               If ch_dat then
                                 AFenster^.UnselectAll;
                               AFenster^.Fenakt(False,True,ch_dat);
                           end else
                           begin
                               RFenster^.ClrUnterF;
                               If ch_dat then
                                 RFenster^.UnselectAll;
                               RFenster^.Fenakt(False,False,ch_dat);
                           end;
                             LFenster^.Laufwerk(true);
                             LFenster^.ClrUnterF;
                             If ch_dat then
                               LFenster^.UnselectAll;
                             LFenster^.Fenakt(True,False,ch_dat);
                         end;
                     F9: begin
                           RFenster^.Readendg;
                           If ArcOpen then
                           begin
                               AFenster^.UnselectAll;
                               AFenster^.Fenakt(False,True,True);
                           end else
                           begin
                               RFenster^.UnselectAll;
                               RFenster^.Fenakt(False,False,True);
                           end;
                           LFenster^.UnselectAll;
                           LFenster^.Fenakt(True,False,True);
                         end;
                    end;
                end;
        Rechts: begin
                  If ArcOpen then
                    AFenster^.Fenster
                  else
                    RFenster^.Fenster;
                  case Ftaste of
                   TAB : FensterM:=Links;
                    CR : begin
                           If ArcOpen then
                             RFenster^.Fakt
                           else
                             AFenster^.Fakt;
                         end;
                 CTRL_R: begin
                           Drive.Open; Lver.Drive:=' ';
                           While (Lver.Drive <> RFenster^.dat.ver[1].name[1]) and not ArcOpen and
                                 not Drive.Eof do
                           begin
                             Drive.Read(Lver,-1,1);
                             If Lver.Drive = RFenster^.dat.ver[1].name[1] then
                               Drive.Remove(Drive.Pos-1,1);
                           end;
                           Drive.Close;
                           If ArcOpen then
                           begin
                             AFenster^.UnselectAll;
                             AFenster^.Fenakt(True,True,True);
                           end else
                           begin
                             RFenster^.VerzNeu;
                             If LFenster^.dat.ver[1].name[1] = RFenster^.dat.ver[1].name[1] then
                             begin
                               LFenster^.UnselectAll;
                               LFenster^.Fenakt(False,True,True);
                             end;
                             RFenster^.UnselectAll;
                             RFenster^.Fenakt(True,False,True);
                           end;
                         end;
                    F3 : begin
                           RFenster^.Fenakt(True,False,False);
                         end;
                    F5 : begin
                           If m_flashend then ende;
                           If Kom.path then
                             Lfenster^.VerzAkt else
                             Lfenster^.UnselectAll;
                           Lfenster^.Fenakt(False,False,True);
                           If ArcOpen then
                           begin
                             AFenster^.UnselectAll;
                             AFenster^.Fenakt(True,True,True);
                           end else
                           begin
                             RFenster^.UnselectAll;
                             RFenster^.Fenakt(True,False,True);
                           end;
                         end;
                     F7: begin
                           LFenster^.Fenakt(False,True,False);
                           If not ArcOpen then
                             RFenster^.Fenakt(True ,False,False);
                         end;
                     F8: begin

                           If Verzdel and not ArcOpen then
                           begin
                             Lfenster^.Fenakt(False,True,False);
                             If not ArcOpen then
                             begin
                               Rfenster^.Fenakt(True,True,False);
                             end;
                           end else
                           begin
                             LFenster^.UnselectAll;
                             Lfenster^.Fenakt(False,False,True);
                             If not ArcOpen then
                             begin
                               Rfenster^.UnselectAll;
                               Rfenster^.Fenakt(True,False,True);
                             end;
                           end;
                           If ArcOpen then
                           begin
                             AFenster^.UnselectAll;
                             AFenster^.Fenakt(True,True,True);
                           end;

                         end;
                     F2: begin
                           LFenster^.Laufwerk(true);
                           LFenster^.ClrUnterF;
                           If ch_dat then
                             LFenster^.UnselectAll;
                           LFenster^.Fenakt(False,False,ch_dat);
                           AFenster^.Laufwerk(true);
                           RFenster^.Laufwerk(true);
                           If ArcOpen then
                           begin
                               AFenster^.ClrUnterF;
                               If ch_dat then
                                 AFenster^.UnselectAll;
                               AFenster^.Fenakt(True,True,ch_dat);
                           end else
                           begin
                               RFenster^.ClrUnterF;
                               If ch_dat then
                                 RFenster^.UnselectAll;
                               RFenster^.Fenakt(True,False,ch_dat);
                           end;
                         end;
                     F9: begin
                           RFenster^.Readendg;
                           LFenster^.UnselectAll;
                           LFenster^.Fenakt(False,False,True);
                           If ArcOpen then
                           begin
                             AFenster^.UnselectAll;
                             AFenster^.Fenakt(True,True,True);
                           end else
                           begin
                             RFenster^.UnselectAll;
                             RFenster^.Fenakt(True,False,True);
                           end;
                         end;
                    end;
                end;
      end;
    until Ftaste=ALT_X;
  end;



begin
   getverify(m_ver);

   m_pack    := pack;
   m_komp    := komp;

   m_packverz:= packverz;
   m_tempverz:= tempverz;
   m_prgend  := prgend;
   m_sort    := sort;
   m_color   := color;
   m_attrib  := attrib;
   m_auto    := auto;
   m_flashend:= flashend;
   m_ver     := ver;
   m_interM  := interM;

   If not getver(0,merkdir) then halt(1);
   setverify(ver);

   getver(DrvLet_Num(tempverz[1]),Verz);
   If chver(tempverz) then
   begin
     m_tempverz:=tempverz;
   end else
   begin
     writeln('Fehlerhaftes TemporÑres-Verzeichnis !');delay(400);
     m_tempverz:=justpathname(paramstr(0));
   end;

   SwapPath  := m_tempverz;
   RedoutPath:= m_tempverz;
   chver(Verz);

   top_verz:=addbackslash(justpathname(paramstr(0)));

   getver(DrvLet_Num(packverz[1]),Verz);
   If chver(packverz) then
   begin
     m_packverz:=packverz;
   end else
   begin
     write('Fehlerhaftes Packer-Verzeichnis !');delay(400);
     m_packverz:=justpathname(paramstr(0));
   end;
   
   chver(Verz);


   If upstring(paramstr(1))=crypt('UGPP517:>:') then      { TEST }
     test:=true else test:=false;

   If upstring(paramstr(1))=crypt('MKYAKU') then    { LIZENS }
   begin
     writeln(crypt(Name));
     writeln(crypt(Strasse));
     writeln(crypt(Ort));
     writeln(crypt(Liznr)); halt;
   end;

   If (Name='EGNK') and not test then                { DEMO }
   begin
     Demo:=true;
   end;

   cursor_off;

   case m_color of
     1 : Farbe1;
     2 : Farbe2;
     3 : Monochrome;
   end;

   Hilfe.init(addbackslash(readprogdir(paramstr(0)))+'top.hlp',$32504f54);

   Back_o_Rest;
   Ende;
end.