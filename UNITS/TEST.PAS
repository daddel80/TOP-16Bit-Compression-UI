program Test;
uses CRT,DOS,KBM;



procedure Verzlesen;
const vertiefe = 20;
      vtiefe = 20;
var Dirinfo :Searchrec;
    vername : array [0..vertiefe] of String[12];
    drv     : string;
    enter,
    ende    : boolean;
    verstr  : pathstr;
    tiefe   : byte;
    w       : word;
    Verzmerk: pathstr;

begin
  clrscr;
  enter:=true;ende:=false;drv:='C:\';
  tiefe:=vtiefe;
  getdir(ord(drv[1])-64,Verzmerk);
  chdir(drv);
    repeat
      If enter then
      begin
        findFirst('*.*', $37, DirInfo);            { Anfang }
        while (((Dirinfo.name= '.') or (Dirinfo.name='..'))
             or (16<>(dirinfo.attr and 16))) and (doserror=0) do
        begin                                                   { Info }
          findnext(DirInfo);
        end;
        vername[tiefe]:=Dirinfo.name;
      end else
      begin
        findFirst('*.*', $37, DirInfo);            { Weiter }
        while  (Dirinfo.name<>vername[tiefe]) and (Doserror=0) do
          findnext(DirInfo);
        If Doserror=0 then
        repeat
           findnext(dirinfo);       { Info }
          until (16=(dirinfo.attr and 16)) or (doserror>0);
        {End IF}
        vername[tiefe]:=Dirinfo.name;
      end;

      If (doserror>0)  then
      begin
        ende:=true;
        If tiefe > vtiefe then                                 { Exit }
        begin
          chdir('..');
          dec(tiefe);
          Enter:=false;ende:=false;
        end;
      end else
      begin
        {$I-}chdir(vername[tiefe]);{I+}                    { Enter }
        If ioresult=0 then
        begin
          gotoxy(1,1);
          write(Vername[tiefe]);
          verstr:=Fexpand('');
          inc(tiefe);
          Enter:=true;
          ende:=false;
        end else
          Enter:=false;
      end;
   until (tiefe=vtiefe) and ende or not (Doserror in [0,18]);
   chdir(Verzmerk);
  {EndIF}
end;


begin
  MouShowMouse;
  Verzlesen;
end.