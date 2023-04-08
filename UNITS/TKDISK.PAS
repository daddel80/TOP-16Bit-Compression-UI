UNIT TKDisk;

INTERFACE
uses Tkstring,Dos,TKstream;

TYPE
   DrRec = Record
           Dr :string[26];
           Ch :string[26];
         end;


CONST
  stdin   : WORD = 0;
  stdout  : WORD = 1;
  stderr  : WORD = 2;
  RedOutPath : Dirstr   = 'c:\';
  RedOutName : FileNameStr = 'STDOUT.RED';


VAR
  oldout : WORD;
  newout : WORD;
  olderr : WORD;
  Err    : WORD;
  Redfile: Pathstr;

    {-Lenkt die Bildschirmausgabe in eine Datei}
FUNCTION RedOut  : WORD;
    {-Restauriert die Bildschirmausgabe}
FUNCTION RedBack : WORD;
    {-Sucht nach einer angegebenen Datei Åber Path}
FUNCTION  ReadProgDir (P : PathStr) : Dirstr;
    {-Sucht nach allen vorhandenen Laufwerken}
PROCEDURE DriveKind (var D: DrRec);
    {-Wechselt in ein Verzeichnis}
FUNCTION  Chver  (P:PathStr) : Boolean;
    {-Gibt das Verzeichnis auf dem angegebenen Laufwerk zurÅck}
FUNCTION Getver(Dr:byte;VAR Path:PathStr) : Boolean;
    {-Erzeugt den angegebenen Pfad}
FUNCTION Mkver(S:PathStr) : Boolean;
    {-Lîscht den angegebenen Pfad}
FUNCTION Rmver(S:PathStr) : Boolean;
    {-Ermittelt den freien Platz auf dem Lw}
FUNCTION DiskFrei(Drive:Byte) : Longint;
    {-Ermittelt die Grî·e des Lw}
FUNCTION DiskGrosse(Drive:Byte) : Longint;
    {Wandelt einen Lwbuchstaben in eine Zahl um}
FUNCTION DrvLet_Num(Drive:Char) : Byte;

IMPLEMENTATION

var Drive : DrRec;

  FUNCTION RedOut : WORD;
  BEGIN
    Redfile:=addbackslash(justpathname(paramstr(0)))+RedOutName+#0;
    ASM

      MOV  BX, stdout
      MOV  AH, 45h
      INT  21h                 (* duplicate stdout        *)
      JC   @Error              (* failed                  *)

      MOV  oldout, AX          (* save stdout             *)

      MOV  CX, 0               (* normal attribute        *)
      MOV  DX, OFFSET redfile + 1
      MOV  AH, 3Ch
      INT  21h
      JC   @Error              (* failed                  *)

      MOV  newout, AX

      MOV  BX, AX              (* redirect stdout hdle to *)
      MOV  CX, stdout          (* track the new file hdle *)
      MOV  AH, 46h
      INT  21h
      JC   @Error              (* failed                  *)

      MOV  Err, 0
      JMP  @ok
    @Error:
      MOV  Err, AX             (* Error code              *)
    @Ok:

  { Zugriff auf IO Ports sperrren VGA}
    MOV  AH, 12h
    MOV  BL, 32h
    MOV  AL, 1
    INT  10h

    END;
  END;

  FUNCTION RedBack : WORD;
  BEGIN
    ASM
      MOV  BX, oldout          (* restore original handle *)
      MOV  CX, stdout
      MOV  AH, 46h
      INT  21h
      JC   @Error2             (* failed                  *)

      MOV  BX, oldout          (* close orig. handle      *)
      MOV  AH, 3Eh
      INT  21h
      JC   @Error2             (* failed                  *)

      MOV  BX, newout          (* close dup'd handle      *)
      MOV  AH, 3Eh
      INT  21h
      JC   @Error2             (* failed                  *)

      MOV  Err, 0
      JMP  @ok2
    @Error2:
      MOV  Err, AX
    @Ok2:

  { Zugriff auf IO Ports freigeben VGA}
    MOV  AH, 12h
    MOV  BL, 32h
    MOV  AL, 0
    INT  10h
    END;
  END;



{-------------------------------------------------------------------------}
FUNCTION ReadProgDir (P:PathStr) : Dirstr;
var
  Progdir : Dirstr;
  Dir     : String;
  Dirinfo : Searchrec;
  I       : byte;

Begin
  Progdir:=justpathname(P);
  If progdir = '' then
  begin
    dir:=addbackslash(justpathname(paramstr(0)));
    findfirst(dir+P,anyfile,dirinfo);
    if doserror <> 0 then
    begin
      dir := getenv('PATH');
      while (dir<>'')and (dir<>';') do
      begin
        I:=pos(';',Dir);
        If I=0 then I:=length(dir);
        findfirst(Addbackslash(copy(dir,1,pred(I)))+P,Anyfile,Dirinfo);
        If doserror =0 then
        begin
          progdir := copy(dir,1,pred(I));
          break;
        end
        else delete(dir,1,I);
        {endif}
      end{while};
    end{If} else
    progdir:=dir;
  end{If};
  If (progdir[length(progdir)]='\') and (progdir[length(progdir)-1]<>':')
  then dec(byte(progdir[0]));
  readprogdir := progdir;
end;


PROCEDURE DriveInit;
var     lw          : byte;
        wechsel,fest: boolean;

begin
 Drive.Dr:=''; Drive.Ch:='';
 for lw:=1 to 26 do
 begin
    Regs.ah := $44;
    Regs.al := $8;
    Regs.bl := lw;
    intr($21, Regs);
    wechsel:=false;fest:=false;
    If Regs.ax = 0 then wechsel:=true;
    If Regs.ax = 1 then fest:=true;
    Regs.ah := $44;
    Regs.al := $e;
    Regs.bl := lw;
    intr($21, Regs);
    If (wechsel and ((Regs.al=0) or (Regs.al=lw))) or fest then
    begin
      Drive.Dr:=Drive.Dr+chr(lw+64);
      If wechsel then
      begin
        Drive.Ch:=Drive.Ch+'0'
      end else
      begin
        Regs.ax := $1500;        { CD-Romlaufwerk }
        Regs.bx := $0000;
        Intr ($2F,Regs); {Drives BX} {Drive  CX}
        If (LW>Regs.cx) and (LW<=Regs.cx+Regs.bx) and (Regs.bx>0) then
          Drive.Ch:=Drive.Ch+'0' else
          Drive.Ch:=Drive.Ch+'1';
      end;
    end;
 end;
end;

{-------------------------------------------------------------------------}
PROCEDURE DriveKind(var D: DrRec);
var   z,z1        : byte;
begin
  If length(D.Dr)>0 then
  begin
    D.Ch[0]:=D.Dr[0];
    for z:=1 to length(D.Dr) do
      for z1:=1 to length(Drive.Dr) do
        If upcase(D.Dr[z])=Drive.Dr[z1] then
        begin
          D.Ch[z]:=Drive.Ch[z1]; break;
        end;
        {EndIf}
      {EndFor}
    {EndFor}
  end else
  begin
    D:=Drive;
  end;
end;


{-------------------------------------------------------------------------}
FUNCTION Chver (P:PathStr) : boolean;
begin
   If (P[length(P)]='\') and not ((length(P)=3) and (P[3]='\'))  then
     Dec(Byte(P[0]));
   {$I-}chdir(P);{$I+}
   chver:= IOresult=0; Doserror:=0;
end;

{-------------------------------------------------------------------------}
FUNCTION Getver(Dr:byte;VAR Path:PathStr) : boolean;
begin
  {$I-} getdir(dr,path); {$I+}
  getver:= Ioresult=0; Doserror:=0;
end;

{-------------------------------------------------------------------------}
(*FUNCTION Mkver(S:String) : Boolean;
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
end;*)


FUNCTION Mkver(S:Pathstr) : Boolean;
const AR : Acceptrec=('   OK   ','','');
var   M : Message;
begin
   M:='Fehler beim Erstellen des Verzeichnisses:';
   repeat
     {$I-} MkDir(S); {$I+}
      Mkver:= Inoutres=0;
      If (Inoutres=0) and not chver(S) then
      begin
        IO_Error(M,'IOERROR.MSG',3,AR); Mkver:=false;
      end;
   until Testerror(M);
end;


FUNCTION Rmver(S:PathStr) : Boolean;
var   M : Message;
begin
   M:='Fehler beim Lîschen des Verzeichnisses:';
   repeat
     {$I-} RmDir(S); {$I+}
     RmVer:= Inoutres=0;
   until Testerror(M);
end;



FUNCTION DiskFrei(Drive:Byte) : Longint;
var frei : Longint;
begin
  frei:=diskfree(Drive);
  If frei=-1 then frei:=0;
  DiskFrei:=frei;
end;


FUNCTION DiskGrosse(Drive:Byte) : Longint;
var grosse : Longint;
begin
  grosse:=diskfree(Drive);
  If grosse=-1 then grosse:=0;
  DiskGrosse:=grosse;
end;


FUNCTION DrvLet_Num(Drive:Char) : Byte;
begin
  If ord(Drive)>$40 then
    DrvLet_Num:=ord(Drive)-$40 else
    DrvLet_Num:=0;
end;


BEGIN
 DriveInit;
END.