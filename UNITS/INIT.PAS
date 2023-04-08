unit Init;
Interface
uses dos,crt,kbm,Tkstring,Tkstream,Tpinst,Tksaa,Tkdisk,Tkview2,Tkwin,Tkview,
     Tkvideo;

const
   vertiefe=40;
   packanz =99;
   veranz  =700;
   dateianz=1000;
   datanz  =65535;
   ko_anz  =3;
   Endganz =3;

   Drivename   = 'DRIVE.$$$';
   Leftdatname = 'LEFTDAT.$$$';
   Leftdatindex= 'LEFTIND.$$$';
   Rightdatname= 'RIGHTDAT.$$$';
   Rightdatindex='RIGHTIND.$$$';
   Arcdatname  = 'ARCDAT.$$$';
   Arcdatindex = 'ARCIND.$$$';
   Packername  = 'PACKER.CFG';
   Topname     = 'TOP.CFG';
   Pdatname    = 'PDAT.LST';
   Scriptdatei = '*.SCR';

   sort      : byte    = 1;
   attrib    : byte    = $27 {20};
   color     : byte    = 1;
   prgend    : boolean = false;
   auto      : boolean = true;
   flashend  : boolean = false;
   ver       : boolean = true;
   interM    : boolean = true;
   packverz  : string[50] = 'C:\TOP\PACKER';
   tempverz  : string[50] = 'C:\TOP';
   restlauf  : char       = 'C';
   pack      : byte=0;
   komp      : byte=2;
   Name      : string[40] ='EGNK';
   Strasse   : string[40] ='';
   Ort       : string[40] ='';
   Liznr     : string[5]  ='';

   Pfeilfo    : Byte = white;
   Pfeilba    : Byte = black;
   Winfo      : Byte = white;
   Winba      : Byte = blue;
   Balkenba   : byte = cyan;
   VcloseCol  : byte = lightcyan;
   PackerCol  : byte = yellow;
   LaufcuCol  : byte = yellow;
   SelNumCol  : byte = lightgray;
   MessageCol : byte = black;
   Message2Col:byte = yellow;
   Message3Col: byte=white;
   Laufwerkfo : byte = white;
   Laufwerkba : byte = cyan;
   Funktionfo : byte = black;
   Funktionba : byte = lightgray;


   ko: array [0..Ko_anz] of FilenameStr =('NULL','MIN ','NORM','MAX ');

   Ar : Acceptrec = (' Wiederholen ',' Abbruch ','');
   { --- Demo --- }
   demo      : boolean = false;

   AR1 : Acceptrec = ('    OK    ','','');
   AR2 : Acceptrec = ('  Wiederholen  ','    Abbruch    ','');
   AR3 : Acceptrec = ('  Wiederholen  ','  Weiter  ','  Abbruch  ');



type

  PackPointer = ^PackPointRec;
  PackPointRec = Record
                   name : FilenameStr;
                   next : PackPointer;
                 End;

  Packstr  = text;

  DateiRec    = Record
                 name  : FilenameStr;
                 attr  : byte;
                 time  : longint;
                 size  : longint;
                 uns   : word;
                 select: boolean;

                 Crc   : longint;
                 Psize : longint;
                 Algo  : string[7];
                End;

  Script_Rec = Record
               Inkl : boolean;
               Verz : Dirstr;
               Datei: Filenamestr;
              End;

  VartRec = (Verzeichnis,Packer);

  VerzeichnisRec = Record
                  name        : FilenameStr;
                  select      : boolean;
                  files       : word;
                  selgr       : longint;
                  pos         : byte;
                  Vopen       : boolean;      { fr Baumstruktur }
                  VXpos       : byte;
                  Vart        : VartRec;
                 End;

  FVerzeichnis = Record
                  name        : FilenameStr;
                  leftselect  : boolean;
                  leftfiles   : word;
                  leftselgr   : longint;
                  leftVopen   : boolean;
                  rightselect : boolean;
                  rightfiles  : word;
                  rightselgr  : longint;
                  rightVopen  : boolean;
                  pos         : byte;
                End;


  ADatei        = array[1..dateianz] of DateiRec;
  AVerzeichnis  = array[0..veranz]   of VerzeichnisRec;
  DrVerzeichnis = array[0..veranz]   of FVerzeichnis;

  FensterDat  = Record
                fil       : ADatei;
                filanz    : word;
                aktverz   : pathstr;
                ver       : AVerzeichnis;
                veranz    : word;
                vpos      : word;
                fpos      : word;
                ver_dat   : boolean;
                wanf      : byte;
                sanf      : word;
                fanf      : word;
                gesamtgr  : longint;
                gesamtdat : word;
                selgr     : longint;
                dfree     : longint;
                dsize     : longint;
                arcorig   : longint;
                arckomp   : longint;
                arckind   : string[7];
              End;

  Dtemp   = Record
              drive       : char;
              ver         : DrVerzeichnis;
              veranz      : word;
              dfree       : longint;
              dsize       : longint;
              leftwritten : boolean;
              leftselgr   : longint;
              leftwanf    : byte;
              leftsanf    : word;
              leftvpos    : word;
              rightwritten: boolean;
              rightwanf   : byte;
              rightsanf   : word;
              rightvpos   : word;
            End;



  Findex  = Record
               Lw      : char;
               VPos    : word;
               Fseek   : longint;
            End;

  Ftemp   = Record
               name  : FilenameStr;
              select : boolean;
             ver_dat : boolean;
               jump  : word;
            End;

  Dparam  = Record
             Verp      : string[12];
             Entp      : string[12];
             Arcend    : string[11];
             PohneV    : string[29];
             PmitV     : string[29];
             VohneV    : string[29];
             VmitV     : string[29];
             EohneV    : string[29];
             EmitV     : string[29];
             PmitUv    : string[13];
             max       : string[13];
             norm      : string[13];
             min       : string[13];
             null      : string[13];
             self      : string[13];
             packdat   : string[13];
             datdel    : string[13];
             passw     : string[13];
             multipleV : string[13];
         end;

  Kompr  = Record
             datei  : FilenameStr;
             sel    : longint;
             arc    : string[12];
             pas    : FilenameStr;
             ver    : boolean;
             path   : boolean;
             Uv     : boolean;
             mV     : boolean;
             self   : boolean;
             pack   : byte;
             komp   : byte;
             ausw   : boolean;
          end;

   endg  = Record
             en    : array [1..Packanz*Endganz] of string[5];
             packer: array [1..Packanz*Endganz] of byte;
             fanz  : byte;
           end;

   FensterModeR = (Rechts,Links,Archiv);

   ToggleRec =(normal,spez1,spez2);

var
   dummy                 : integer;
   xanfR,xanfL,yanf,
   xdiff,ydiff           : byte;
   Kom                   : Kompr;
   z                     : word;
   DirInfo               : SearchRec;
   wmi,wma               : word;
   FensterM              : FensterModeR;
   F                     : file of Ftemp;
   D                     : file of Dparam;
   ev1                   : Event;
   Fu,He                 : Button;
   weiter                : boolean;
   Ftaste                : integer;
   Verzdel               : boolean;


   test                  : boolean;
   merkdir               : pathstr;
   m_packverz,m_tempverz : pathstr;
   m_ver,m_prgend,m_auto,
   m_flashend,m_interM   : boolean;
   m_pack,m_komp,m_sort,
   m_color,m_attrib      : byte;
   top_verz              : dirstr;
   Drive,Packer_File,Script_File : TypedStream;
   Pdat                  : TextStream;
   Hilfe                 : Helpview1;
   Akber                 : byte;
   ArcOpen               : boolean;
   lw                    : DrRec;
   Verz                  : pathstr;
   Lver                  : Dtemp;
   ch_dat                : boolean;


   function tpibegin : boolean;
   function tpiend(save:boolean) :boolean;
   function CompArcend (Arcend,Packfile:pathstr) : boolean;
   procedure Farbe1;
   procedure Farbe2;
   procedure Monochrome;
   procedure Rahmen;

Implementation


 function tpibegin : boolean;
 begin
   chver(readprogdir(paramstr(0)));
   tpibegin := tpiopenfile('top.exe',159136);
 end;

{-------------------------------------------------------------------------}
 function tpiend(save:boolean) : boolean;
 var fTime : longint;
     f     : text;
 begin
   if save then tpisavechanges;
   tpiclosefile;
   tpiend:=f_spe;
 end;

{-------------------------------------------------------------------------}
 function CompArcend (Arcend,Packfile:pathstr) : boolean;
 var Endung: string[3];
     wa :boolean;
 begin
  CompArcend:=false;
  repeat
    If pos(',',Arcend)>0 then
    begin
      Endung:=copy(Arcend,1,pos(',',Arcend));
      delete(Arcend,1,pos(',',Arcend));
    end else
    begin
      Endung:=Arcend; Arcend:='';
    end;
    If CompExtension( '*.'+Endung, PackFile )then
      CompArcend:=true;
  until Arcend='';
 end;

 procedure Monochrome;
 begin
   Pfeilfo    := white;
   Pfeilba    := black;
   Winfo      := white;
   Winba      := black;
   Balkenba   := lightgray;
   VcloseCol  := white;
   PackerCol  := white;
   LaufcuCol  := lightgray;
   SelNumCol  := lightgray;
   MessageCol := darkgray;
   Message2Col:= lightgray;
   Message3Col:= white;
   Message4Col:= lightgray;
   Laufwerkfo := darkgray;
   Laufwerkba := Lightgray;
   Funktionfo := black;
   Funktionba := lightgray;
   Buttonfo   := black;
   Buttonba   := lightgray;
   ButtonSe   := white;
   ButtonKe   := white;
   Editfo     := black;
   Editba     := lightgray;
   Fenfo      := lightgray;
   Fenba      := darkgray;
   Fen2fo     := white;
   Fen2ba     := black;
   Helpba     := darkgray;
   Pullfo     := black;
   Pullba     := lightgray;
   Scrollfo   := lightgray;
   ActSelfo   := black;
   ActSelba   := white;
   Selfo      := white;
   Balkenback := darkgray;
   yCol       := lightgray;
   wCol       := white;
 end;


 procedure Farbe1;
 begin
   Pfeilfo    := white;
   Pfeilba    := black;
   Winfo      := white;
   Winba      := blue;
   Balkenba   := cyan;
   VcloseCol  := lightcyan;
   PackerCol  := yellow;
   LaufcuCol  := yellow;
   SelNumCol  := lightgray;
   MessageCol := black;
   Message2Col:= yellow;
   Message3Col:= white;
   Message4Col:= yellow;
   Laufwerkfo := white;
   Laufwerkba := cyan;
   Funktionfo := black;
   Funktionba := lightgray;
   Buttonfo   := lightgray;
   Buttonba   := blue;
   ButtonSe   := white;
   ButtonKe   := yellow;
   Editfo     := black;
   Editba     := lightgray;
   Fenfo      := blue;
   Fenba      := cyan;
   Fen2fo     := white;
   Fen2ba     := red;
   Helpba     := green;
   Pullfo     := black;
   Pullba     := Lightgray;
   Scrollfo   := yellow;
   Scrollba   := green;
   Balkenback := black;
   ActSelfo   := white;
   ActSelba   := black;
   Selfo      := black;
   yCol       := yellow;
   wCol       := white;
   ProgColors(1);
 end;

 procedure Farbe2;
 begin
   Pfeilfo    := white;
   Pfeilba    := black;
   Winfo      := white;
   Winba      := green;
   Balkenba   := red;
   VcloseCol  := lightcyan;
   PackerCol  := black;
   LaufcuCol  := lightred;
   SelNumCol  := lightgray;
   MessageCol := white;
   Message2Col:= white;
   Message3Col:= white;
   Message4Col:= white;
   Laufwerkfo := darkgray;
   Laufwerkba := Lightgray;
   Funktionfo := black;
   Funktionba := lightgray;
   Buttonfo   := black;
   Buttonba   := lightgray;
   ButtonSe   := white;
   ButtonKe   := red;
   Editfo     := black;
   Editba     := lightgray;
   Fenfo      := lightgreen;
   Fenba      := blue;
   Fen2fo     := white;
   Fen2ba     := red;
   Helpba     := brown;
   Pullfo     := black;
   Pullba     := lightgray;
   Scrollfo   := yellow;
   ActSelfo   := white;
   ActSelba   := red;
   Selfo      := white;
   Balkenback := black;
   yCol       := black;
   wCol       := black;
   ProgColors(2);
 end;


  procedure Rahmen;
  begin
     cursor_off;
     textcolor(white);textbackground(black);
     clrscr;
     textcolor(Funktionfo);textbackground(Funktionba);
     gotoxy(1,1); insline;
     WriteXY(CrtxmaX Div 2 -2,1,'TOP ');
     textcolor(darkgray);
     writeXY(CrtXmax-7,1,'Ver 2.1á');
     MouShowMouse;
  end;


begin
end.