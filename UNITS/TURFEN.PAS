UNIT TUrfen;

Interface
uses TKstream,Init,TKSaa,Dos,Crt,TKvideo,TKwin,TKstring,KBM;


 Type

  UrFenster = Object
          einmal   : boolean;
          dat      : FensterDat;
          xanf,
          yanf,
          ydiff,
          xdiff    :  byte;
          change   :  boolean;
          ebene    :  byte;
          Fmod     :  FensterModeR;

          einschub :  byte;
          Filsel,
          Filind   :  Typedstream;
          LaBu     :  Button;
          Fendg    :  endg;

 {Urfen.Pas}   Constructor Init;
               function    fullpath (vpos:word)      : pathstr;
               procedure   Pfeilwrite(pfeil:boolean;vpos:word);

               procedure   Summev (var SelGro:longint;var SelAnz:word);
               procedure   Summed (var SelGro:longint;var GesGro:longint);
               procedure   Unterfenster;
               procedure   ClrUnterf;
               procedure   Clrwin;
               Destructor  Done;
  End{Urfenster};


 Implementation

  Constructor Urfenster.Init;
  begin
  end;


    function Urfenster.fullpath(vpos:word): pathstr;
     var pfad,
         hpfad: pathstr;
         a    : word;
         p    : byte;
     begin
       a:=0;
       If (dat.ver[vpos].Vart=Verzeichnis) then
         pfad :=dat.ver[vpos].name else pfad:='';
       p    :=dat.ver[vpos].pos;
       for a:=vpos downto 1 do
       begin
         If (dat.ver[a].pos < p) and (dat.ver[a].Vart=Verzeichnis) then
         begin
           pfad:=addbackslash(dat.ver[a].name)+pfad;
           p:=dat.ver[a].pos;
         end;
       end;
       fullpath:=pfad;
     end;




    procedure Urfenster.Pfeilwrite(pfeil:boolean;vpos:word);
    var S : string;
        P : string;
    begin
      window(1,yanf-2,crtxmax,crtymax);
      textcolor(Pfeilfo);textbackground(Pfeilba);
      S:='';
      If dat.ver[1].Vart=Packer then
        S:=S+dat.ver[1].name+':';
      P:=ShrinkPath(fullpath(vpos),xdiff-12-length(S));
      S:=S+pad(ShrinkPath(fullpath(vpos),xdiff-12-length(S)),xdiff-11-length(S));
      writeXY(xanf+3,1,S);
      If pfeil then
        If Fmod=Links then
           writeXY(xdiff-2,1,'様様')
           else
           writeXY(xdiff-2,1,'様様');
       window(xanf,yanf,xanf+xdiff-3,yanf+ydiff+1);
       dat.aktverz:=fullpath(dat.vpos);
    end;



  procedure Urfenster.Summev (var SelGro:longint;var SelAnz:word);
  var j : word;
  begin
     Selgro:=0; SelAnz:=0;
     for j:=1 to dat.veranz do
     begin
       If dat.ver[j].files>0 then
       begin
         inc(SelGro,dat.ver[j].selgr);
         inc(SelAnz,dat.ver[j].files);
       end;
     end;
  end;


  procedure Urfenster.Summed (var SelGro:longint;var GesGro:longint);
  var j : word;
  begin
     SelGro:=0; GesGro:=0;
     for j:=2 to dat.filanz do
     begin
       If dat.fil[j].select then
       begin
         inc(SelGro,dat.fil[j].size);
       end;
       inc(GesGro,dat.fil[j].size);
     end;
  end;

  procedure Urfenster.Unterfenster;
  var GesGro:longint;
      Selanz:word;
      Ratio :real;
      Ratiostr: string[7];
  begin
    textbackground(Winba); textcolor(Winfo);
    If dat.ver_dat then
    begin
      summev(dat.selgr,Selanz);
      writeXY(13 , ydiff,leftpadch(SpNumber(Selanz),' ',6));
      writeXY(23, ydiff,leftpadch(SpNumber(dat.selgr)+' B',' ',15));
    end else
    begin
      summed(dat.ver[dat.vpos].selgr,GesGro);
      writeXY(13 ,ydiff,leftpadch(SpNumber(dat.ver[dat.vpos].files),' ',6));
      writeXY(23 ,ydiff,leftpadch(SpNumber(dat.ver[dat.vpos].selgr)+' B',' ',15));
    end;
    case Fmod of
Rechts,Links :begin
                writeXY(18,ydiff+1,leftpadch(SpNumber(dat.dsize)+' B',' ',15));
                writeXY(18,ydiff+2,leftpadch(SpNumber(dat.dfree)+' B',' ',15));
              end;
   Archiv :begin
             If dat.arcorig > 0 then
               Ratio:=dat.arckomp/dat.arcorig *100 else Ratio:=100;
             str (Ratio:3:2,Ratiostr); Ratiostr:=Ratiostr+'%';
             writeXY(10,ydiff+1,leftpadch(SpNumber(dat.arcorig)+' B',' ',15));
             writeXY(10,ydiff+2,leftpadch(SpNumber(dat.arckomp)+' B',' ',15));
             writeXY(31,ydiff+1,leftpadch(Ratiostr,' ',7));
             writeXY(31,ydiff+2,leftpad(dat.arckind,7));
           end;
    end{Case};
  end;


  procedure   Urfenster.ClrUnterf;
  var Wmax,Wmin : word;
  begin
    Wmax:=WindMax; Wmin:=WindMin; textbackground(Winba);
    {window(Lo(Wmin)+1,Hi(Wmin)+1+ydiff-1,Lo(Wmax)+1,Hi(Wmax)+1);}
    window(xanf,ydiff+3,xanf+xdiff-3,yanf+ydiff+1);
    winclrscr;
    window(Lo(Wmin)+1,Hi(Wmin)+1,Lo(Wmax)+1,Hi(Wmax)+1);
  end;


  procedure Urfenster.clrwin;
  begin
    window(LO(windmin)+1,Hi(windmin)+1,LO(windmax)+1,HI(windmax)-3);
    textbackground(Winba);winclrscr;
    window(LO(windmin)+1,Hi(windmin)+1,LO(windmax)+1,HI(windmax)+5);
  end;




  Destructor Urfenster.Done;
  begin
  end;




begin
end.