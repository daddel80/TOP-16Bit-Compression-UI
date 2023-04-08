UNIT TControl;

Interface
uses Init,TFunktion,Tkstream,KBM,Tkstring,Tkwin,Crt,Tkview,Tkvideo,Dos,Tkdisk;
Type
 Control = Object(Funktion)
               Constructor Init( SMode : FensterModeR; Datname,Datindex : FilenameStr; xa:byte);
               procedure   Drahmen  (paint :boolean);
               procedure   Fenakt   (Rahmen,VerzL,DatL:boolean);
               procedure   Fenster;
               Destructor  Done;
      End{Control};




Implementation

Constructor Control.Init( Smode : FensterModeR; Datname,Datindex : FilenameStr; xa:byte);
begin
  einschub:=3;  xanf:=xa ;  einmal:=true; Fmod:=SMode;
  yanf:=4;  ydiff:=(crtymax-3)-yanf;   xdiff:=(crtxmax DIV 2); ebene:=(xdiff-24) Div 3;
  Readendg;
  Filsel.Init (concat(addbackslash(m_tempverz),Datname),SizeOf(Ftemp));
  Filind.Init (concat(addbackslash(m_tempverz),Datindex),SizeOf(Findex));
  Filsel.Create;  Filsel.Close;
  Filind.Create;  Filind.Close;
  Funktion.Init;
end;



procedure Control.Fenakt(Rahmen,VerzL,DatL : boolean);
begin

    Drahmen(Rahmen);

    If not (Fmod=Archiv) and (dat.veranz>0) and
       (VerzL or DatL ) then
    begin
      dat.dfree:=diskfrei(DrvLet_Num(dat.ver[1].name[1]));
      DriveAkt;
    end;

    If VerzL then
    begin
      VerzNeu;
    end;

    If DatL and not dat.ver_dat then
    begin
      Dateiread(dat.vpos);
    end;

    If (not dat.ver_dat) and (dat.veranz>0) then
    begin
      {Anpassen(dat.wanf,dat.sanf,dat.vpos);}
      fullsort(m_sort); DateienWrite(false,dat.fpos); Pfeilwrite(false,dat.vpos);
    end else
    begin
      Anpassen(dat.wanf,dat.sanf,dat.vpos); BaumWrite(false,dat.vpos); Pfeilwrite(false,dat.vpos);
    end;
    {UnterFenster;}
end;

procedure Control.Fenster;
type Sel = Record
           Manf :word;
           Msel :boolean;
       end;
var k              : word;
    Er             : boolean;
    auha           : boolean;
    ev2            : Event;
    M              : Sel;
   Right_Pr,Left_Pr,
   Midd_Pr         : boolean;
begin
    Drahmen(True);

    If dat.ver_dat then
      verselect(true,dat.vpos) else
      datselect(true,dat.fpos);
     weiter:=false;  Aktber:=1;
    Left_Pr:=false; Right_Pr:=false; Midd_Pr:=false;
    ev1.ctrlcode:=0;
    If ev1.Ereignis>0 then begin er:=true; ev:=ev1; end else er:=false;
    ev1.Ereignis:=0;
    repeat
       auha:=true;
       If not er then
       begin
         KbClrevent;  KbmEventWait( EV_ALL, ev );
       end else er:=false;


       case ev.Ereignis of
  EV_LEFT_PRESS :begin
                     If (ev.Buttons=1) then
                     begin
                       Left_Pr:=true; Midd_Pr:=false;
                       Akber:=AktBer;
                       case AktBer of
                        1 : begin
                              If ev.zeilerel<ydiff-2 then        { CR }
                              begin
                                If dat.ver_dat then
                                begin
                                  If dat.veranz>0 then
                                  begin
                                    vselect(Vposition(ev.zeilerel));
                                    If Doppelklick then
                                    begin
                                      If (dat.vpos=1) and (Fmod=Archiv) then
                                      begin               {Archiv heraus}
                                        weiter:=true; Ftaste:=CR;
                                      end else
                                      If not VerzZoom then
                                        If DateiRead(dat.vpos) then
                                        begin
                                          dat.ver_dat:=false;
                                          DateienWrite(true,dat.fpos);
                                        end;
                                    end;
                                  end;
                                end else
                                begin
                                  Dselect(dat.fanf+ev.zeilerel);
                                  If Doppelklick then
                                  begin
                                    ev.ctrlcode:=CR;
                                  end;
                                end;
                              end;
                            end;
                        2 : begin
                              ev.ctrlcode:=TAB; ev1:=ev;
                            end;
                          end;
                        auha:=false;
                        If (ev.ZeileAbs+1<yanf) or (ev.ZeileAbs+1>ydiff+1) then
                          auha:=true;
                          If (ev.ZeileAbs+1<yanf) and (ev.ZeileAbs+1>1) and (aktber<>2) then
                          begin
                            ev.ctrlcode:=CPGUP;
                          end;
                          If (ev.ZeileAbs+1>ydiff+yanf-2) and (ev.ZeileAbs+1<Crtymax) and (aktber<>2) then
                          begin
                            ev.ctrlcode:=CPGDN;
                          end;
                     end else
                     begin
                       Midd_Pr:=true;
                       If Right_Pr then
                         If dat.ver_dat then
                           begin Treemark(m.manf); end else Filmark(m.manf);
                       Right_Pr:=false;
                     end;
                   end;
     EV_LEFT_REL : begin
                     If (ev.Buttons=0) and not Midd_Pr then
                     begin
                       If not Right_Pr and (ev.zeileAbs<yanf-2) and (ev.zeileRel>ydiff-2) then auha:=true;
                       Left_Pr:=false;
                     end;
                     If ev.Buttons=0 then Midd_Pr:=false;
                   end;
  EV_RIGHT_PRESS : begin
                     If (ev.Buttons=2) then
                     begin
                       Right_Pr:=true; Midd_Pr:=false;
                       Akber:=AktBer; m.manf:=0;
                       case AktBer of
                        1 : begin
                              If ev.zeilerel<ydiff-2 then        { Select }
                              begin
                                If dat.ver_dat then
                                begin
                                  If dat.veranz>0 then
                                  begin
                                    vselect(Vposition(ev.ZeileRel));
                                    m.manf:=dat.vpos;
                                  end;
                                end else
                                begin
                                  Dselect(dat.fanf+ev.zeilerel);
                                  m.manf:=dat.fpos;
                                end;
                              end;
                            end;
                        2 : begin
                              ev.ctrlcode:=TAB; ev1:=ev;
                            end;
                          end;
                          auha:=false;
                          If (ev.ZeileAbs+1<yanf) or (ev.ZeileAbs+1>ydiff+1) then
                            auha:=true;
                     end else
                     begin
                       Midd_Pr:=true; Left_Pr:=false;
                     end;
                   end;
     EV_RIGHT_REL: begin
                     If (ev.Buttons=0) and not Midd_Pr then
                     begin
                       If Left_Pr and (ev.zeileAbs<yanf-2) and (ev.zeileRel>ydiff-2) then auha:=true;
                       If Right_Pr then
                       If dat.ver_dat then
                         begin Treemark(m.manf); end else Filmark(m.manf);
                       Right_Pr:=false;
                     end;
                     If ev.Buttons=0 then Midd_Pr:=false;
                   end;
     EV_MOU_MOVE : begin
                      case aktber of
                      1 : begin
                            If (ev.zeileAbs>yanf-2) and (ev.zeileAbs<yanf+ydiff-3) then
                            begin
                              If Left_Pr then
                                If dat.ver_dat then            { Positionieren }
                                  vselect(Vposition(ev.zeilerel)) else
                                  Dselect(dat.fanf+ev.zeilerel);
                              If Right_Pr then
                                If dat.ver_dat then              {Select}
                                begin
                                  Baummark(m.manf,Vposition(ev.zeileRel));
                                end else
                                begin
                                  Datmark(m.manf,dat.fanf+ev.zeileRel);
                                end;
                            end;
                          end;
                        end;
                   end;

       end;

        case ev.ctrlcode of
         CR: begin
               If dat.veranz>0 then
               begin
                 If dat.ver_dat then
                 begin
                   If (dat.vpos=1) and (Fmod = Archiv) then
                   begin                     {Archiv heraus}
                     weiter:=true; Ftaste:=CR;
                   end else
                   If DateiRead(dat.vpos) then
                   begin
                     dat.ver_dat:=false;
                     DateienWrite(true,dat.fpos);
                   end;
                 end else
                 If dat.fil[dat.fpos].name='.' then
                 begin
                   If change then PackdateiWrite(dat.vpos);
                   dat.ver_dat:=true;
                   BaumWrite(true,dat.vpos);
                 end else
                 If (Fmod=Rechts) then    {Archiv hinein}
                 begin
                   weiter:=true; Ftaste:=CR;
                 end;
               end;
             end;
      SPACE: begin
               If dat.ver_dat then
               begin
                 treemark(dat.vpos); vselect(Vjump(dat.vpos,1,true));
               end else
               begin
                 filmark(dat.fpos); dselect(dat.fpos+1);
               end;
             end;
        CUP: begin            { Hoch }
               If dat.ver_dat then
               begin
                 vselect(Vjump(dat.vpos,1,false));
               end else
               begin
                 dselect(dat.fpos-1);
               end;
             end;
      CDOWN: begin            { Down }
               If dat.ver_dat then
               begin
                 vselect(Vjump(dat.vpos,1,true));
               end else
               begin
                 dselect(dat.fpos+1);
               end;
             end;
      CPGUP: begin             { PgUp }
               If dat.ver_dat then
               begin
                 If Vdiff1(1,dat.vpos)>=(ydiff-2) then vselect(Vjump(dat.vpos,ydiff-2,false)) else vselect(1);
               end else
               begin
                 If dat.fpos>ydiff-2 then dselect(dat.fpos-(ydiff-2)) else dselect(1);
               end;
             end;
     CPGDN: begin             { PgDn }
               If dat.ver_dat then
               begin
                 If Vdiff1(dat.vpos,dat.veranz)>=(ydiff-2) then
                 vselect(Vjump(dat.vpos,(ydiff-2),true)) else
                 vselect(Vjump(dat.vpos,Vdiff1(dat.vpos,dat.veranz),true));
               end else
               begin
                 dselect(dat.fpos+(ydiff-2));
               end;
            end;
     CLEFT: begin            { Links }
              If dat.ver_dat then
              For k:=dat.vpos-1 downto 1 do
              begin
                If (dat.ver[dat.vpos].pos>dat.ver[k].pos) then break;
                If (dat.ver[dat.vpos].pos=dat.ver[k].pos) then
                begin
                  vselect(k);
                  break;
                end;
              end;
            end;
    CRIGHT: begin            { Rechts }
              IF dat.ver_dat then
              For k:=dat.vpos+1 to dat.veranz do
              begin
                If (dat.ver[dat.vpos].pos>dat.ver[k].pos) then break;
                If (dat.ver[dat.vpos].pos=dat.ver[k].pos) then
                begin
                  vselect(k);
                  break;
                end;
              end;
            end;
     CHOME: begin             { Home }
              If dat.ver_dat then
              begin
                vselect(1);
              end else
              begin
                dselect(1);
              end;
            end;
      CEND: begin             { End }
              If dat.ver_dat then
              begin
                vselect(Vjump(dat.vpos,Vdiff1(dat.vpos,dat.veranz),true));
              end else
              begin
                dselect(dat.filanz);
              end;
            end;
 INSERTKEY: begin              { Ins }
              If dat.ver_dat then
              begin
                treemark(dat.vpos);
                vselect(Vjump(dat.vpos,1,true));
              end else
              begin
                filmark(dat.fpos); dselect(dat.fpos+1);
              end;
            end;
      TAB:  begin
              Ftaste:=TAB;weiter:=true;
            end;
 ord('+'):  begin
              If dat.ver_dat then
                VerzZoom else
                Selendg (true)
            end;
 ord('-'):  begin
              If dat.ver_dat then
                VerzZoom else
                Selendg (false);
            end;
 ord('*'):  begin
              Selrev;
            end;
 CTRL_R  :  begin
              weiter:=true; Ftaste:=CTRL_R;
            end;
       End{Case};




       ev2.Ereignis:=0;
       while ((ev.ZeileAbs+1<yanf) or (ev.ZeileAbs+1>yanf+ydiff-3)) and
             (Right_Pr xor Left_Pr) and (ev2.Ereignis=0) and (ev.Ereignis=1) and auha do
       begin
         KbmPeekEvent( ev2 );
         If ev2.Ereignis<>0 then break;
         If (ev.ZeileAbs+1<yanf) then          {Up}
         begin
            If Left_Pr then
            begin
              If dat.ver_dat then
                vselect(Vjump(dat.vpos,1,false)) else
                dselect(dat.fpos-1);
            end;
            If Right_Pr then
            begin
              If dat.ver_dat then
              begin
                Baummark(m.manf,Vjump(dat.vpos,1,false));
              end else
              begin
                datmark(m.manf,dat.fpos-1);
              end;
            end;
         End;
        If (ev.ZeileAbs+1>yanf+ydiff-3) then     {Down}
        begin
          If Left_Pr then
          begin
            If dat.ver_dat then
              vselect(Vjump(dat.vpos,1,true)) else
              dselect(dat.fpos+1);
          end;
          If (Right_Pr) then
          begin
             If dat.ver_dat then
             begin
                Baummark(m.manf,Vjump(dat.vpos,1,true));
             end else
             begin
               datmark(m.manf,dat.fpos+1);
             end;
          end;
        End;
      end;{While}


      If auha then
      begin
        Laufwerk  (false);
        Funktionen(false);
      end;



    until weiter;

    If dat.ver_dat then
    begin
      If (dat.veranz>0) then
      begin
        verselect(false,dat.vpos); textbackground(Winba);
        textcolor(LaufCuCol); writeXY(1,Vdiff1(dat.sanf-1,dat.vpos),'');
      end;
    end else datselect(false,dat.fpos);
    If (Ftaste=TAB) or (AkBer=2) then Drahmen(false);

    {If not ((Ftaste=CR) and ((Fmod=Rechts) or (Fmod=Archiv))) then
      window(Lo(wmi)+1,Hi(wmi)+1,Lo(wma)+1,Hi(wma)+1);}
end;



procedure FensterRahmen(x1,y1,x2,y2:byte;Kopf:string;Rahmen:boolean);
var wlinwo,wlinwu,wlinsl, wlinsr, wole, wore, wule, wure: string[1];
    i       : byte;
    KopfPos : byte;
begin
  
  If Rahmen then
  begin
   {wlinwo:=blinwo;
   wlinwu:=blinwu;
   wlinsl:=blinsl;
   wlinsr:=blinsr;
   wole:=blinwo;
   wore:=blinwo;
   wule:=blinwu;
   wure:=blinwu;}
   wlinwo:=dlinw;
   wlinwu:=dlinw;
   wlinsr:=dlins;
   wlinsl:=dlins;
   wole:=dole;
   wore:=dore;
   wule:=dule;
   wure:=dure;
  end else
  begin
   wlinwo:=linw;
   wlinwu:=linw;
   wlinsr:=lins;
   wlinsl:=lins;
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
    writexy(x1,y1+i,wlinsl);
    writexy(x2,y1+i,wlinsr);
  end;

  KopfPos:=(x2-x1-Length(Kopf)) div 2;

  writexy(x1+1,y1,padch('',wlinwo[1],KopfPos-2));
  writexy(KopfPos+Length(Kopf),y1,padch('',wlinwo[1],(x2-x1)-(KopfPos+Length(Kopf))+1));

  writexy(x1+1,y2,padch('',wlinwu[1],(x2-x1)-1));

  textbackground(Laufwerkba);
  writeXY(KopfPos,y1,Kopf);


end;


    procedure Control.Drahmen(paint:boolean);
        var vlinw,vlins,vole,vore,
        vule,vure,vbrl,vbrr,vbru:char;
    begin
      window(xanf,yanf,xanf+xdiff-3,yanf+ydiff+1);
      window(LO(windmin),Hi(windmin),LO(windmax)+2,HI(windmax)+3);
      If paint then
      begin
        Map^[1].x1:=LO(windmin)+1; Map^[1].y1:=Hi(windmin)+1;
        Map^[1].x2:=LO(windmax)-1; Map^[1].y2:=HI(windmax)-2;
        Funktionen(true);
        MouDefBereich(5,Map);
      end else
      begin
        MoudefBereich(1,Map);
        Map^[2].x1:=LO(windmin)+1; Map^[2].y1:=Hi(windmin)+1;
        Map^[2].x2:=LO(windmax)-1; Map^[2].y2:=HI(windmax)-2;
      end;

      textcolor(Winfo);textbackground(Winba);
      {Winframe(1,1,xdiff,ydiff+4,Paint);}
      case Fmod of
        Rechts : FensterRahmen(1,1,xdiff,ydiff+4,' Komprimiert ',Paint);
        Links  : FensterRahmen(1,1,xdiff,ydiff+4,' Unkomprimiert ',Paint);
        Archiv : FensterRahmen(1,1,xdiff,ydiff+4,' Archiv ',Paint);
      End;

      window(LO(windmin)+2,Hi(windmin)+2,LO(windmax),HI(windmax)-1);
      textbackground(Winba);
      If einmal then begin winclrscr; Laufwerk(true); einmal:=false; end;
      textcolor(Winfo); textbackground(Winba);
      writeXY(2,ydiff,'Ausgew.:');
      case Fmod of
Rechts,Links: begin
                writeXY(2,ydiff+1,'Gesamtkapazit„t:');
                writeXY(2,ydiff+2,'freier Speicher:');
              end;
      Archiv: begin
                writeXY(2,ydiff+1,'orig. G:');
                writeXY(26,ydiff+1,'Rat.:');
                writeXY(2,ydiff+2,'komp. G:');
                writeXY(26,ydiff+2,'Form:');
              end;
           end{Case};
  end;




Destructor Control.Done;
begin
   Filind.DelFile;
   Filind.Done;
   Filsel.Delfile;
   Filsel.Done;
end;

begin
end.