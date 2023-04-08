unit TKstream;
Interface
Uses Dos,Crt,Tkstring,Tkwin,Kbm,Tksaa,Tkvideo;

Const
    Message4Col : byte = yellow;
    Om  = 'Fehler beim ôffnen von ';
    Crm = 'Fehler beim Anlegen von ';
    Rm  = 'Fehler beim Lesen aus ';
    Wm  = 'Fehler beim Schreiben in ';
    Cm  = 'Fehler beim Schlie·en von ';
    Em  = 'Fehler beim Lîschen von ';

Type
    Acceptrec = array[1..3] of string[25];


Urstream = Object
            Openmsg  : Message;
            Createmsg: Message;
            Readmsg  : Message;
            WriteMsg : Message;
            Closemsg : Message;
            Erasemsg : Message;
            OK       : Boolean;
          {Streamerror: Integer;}
            Result   : word;
            Constructor Init (Name : Pathstr);
            Destructor Done;   Virtual;
            procedure  Close;  Virtual;
            procedure Reseterror;
            function Isok : boolean;

            {Function Streamresult : Integer;}
         End{Object Urstream};

Textstream = Object(Urstream)
            F       : Text;
            Constructor Init (Name : Pathstr);
            procedure Open;    Virtual;
            procedure Create;  Virtual;
            procedure Close;   Virtual;
            procedure Append;  Virtual;
            procedure Readln (var S:String); Virtual;
            procedure Writeln(S:string);     Virtual;
            function  Eof  : boolean;
            procedure DelFile;  Virtual;
         End{Object Textstream};
TypedStream = Object(Urstream)
            F       : File;
            Recsize : Word;
            Constructor Init (Name : Pathstr;Rsize: Word);
            procedure Open;   Virtual;
            procedure Create; Virtual;
            procedure Close;  Virtual;
            procedure Read(var R; P: Longint; Anz: Word); Virtual;
            procedure Write(var R; P: Longint; Anz: Word); Virtual;
            procedure Remove(P: Longint; Anz: Longint); Virtual;
            procedure Seek(P: Longint); Virtual;
            function  Eof : Boolean; Virtual;
            function  Pos : Longint; Virtual;
            function  Size: Longint; Virtual;
            procedure DelFile;  Virtual;
         End{Object TypedStream};


Function Testerror(var M :Message): Boolean;

function IO_Error(M: Message; Name: filenameStr; IO_R: integer; Ar: Acceptrec) : byte;


Implementation

{----------------------- Fehlerprozeduren------------------------------}


function IO_Error(M: Message; Name: filenameStr; IO_R: integer; Ar: Acceptrec) : byte;
var T          : text;
    zeile      : string;
    Banz,i,la  : byte;
    Bu         : Button;
    weiter     : boolean;
    IO_Str     : string;
    z,l        : byte;
    Verz       : pathstr;
    found      : boolean;

begin                                           { Datei }
  str(IO_R,IO_Str); Doserror:=0; i:=IOresult;
  If pos('.',Name)=0 then Name:=trim(justname(Name))+'.err';
  Verz:=addbackslash(justpathname(paramstr(0)))+Name;
  assign(T,Verz);
  {$I-} reset(T); found:=false;
  while not EOF(T) and (Doserror=0) do
  begin
    readln(T,Zeile);
    If  trim(copy(Zeile,1,pos(':',zeile)-1)) = IO_Str then
    begin
       delete(Zeile,1,pos(':',zeile)); Zeile:=trim(Zeile); found:=true; break;
    end;
  end; close(T);{$I+} i:=Ioresult; Doserror:=0;
  If not found then
    Zeile:=concat('Fehlercode: ',IO_Str);
  If length(Zeile) > Messlange then delete(Zeile,Messlange,length(Zeile)-Messlange+1);
  If not openwindow(Messlange-2,4,fen2fo,fen2ba,'Fehler') then exit;
  textcolor(Message4Col);
  writexy(2,1,M);
  writeXY(1,2,center(Zeile,Messlange));
  Banz:=0;la:=2;
  for i:=1 to 3 do
    If Ar[i]>'' then
    begin
      inc(Banz);
      inc(la,length(Ar[i])+4);
    end;
  la:=(Messlange Div 2) - (la Div 2);
  inc(la,4);
  for i:=1 to 3 do
  begin
    If Ar[i]>'' then
    begin
      InitButton(Bu,la,4,Ar[i],EV_NO_EVENT,i);
      inc(la,length(Ar[i])+4);
    end;
  end;
  Bu.anz:=Banz; Bu.FaFen:=fen2ba;
  I:=1; weiter:=false;
  repeat
    Setbutton(Bu);
    Activebutton(Bu);
    L:=EventThisbutton(Bu);
    for z:=1 to Banz do
      If L=Z then
      begin
        weiter:=true; break;
      end;
    If ev.Ereignis=EV_KEY_PRESSED then
      case ev.key of
       CLEFT  : If I>1    then dec(I) else I:=Banz;
       CRIGHT : If I<Banz then inc(I) else I:=1;
      end;
  until weiter;
  closewindow;
  IO_Error:=Z;
end;


Function Testerror(var M: message) :boolean;
const AR : Acceptrec = ('  Wiederholen  ','    Abbruch    ','');
begin
  Testerror := (Inoutres=0) or
               (IO_Error(M,'IOERROR.MSG',Ioresult, AR)>1);
end;



{------------------------ Dateiprozeduren -----------------------------}

Constructor Urstream.Init(Name: Pathstr);
begin
  Openmsg  := concat(Om  ,ShrinkPath(Name,Messlange-length(Om) -3));
  Createmsg:= concat(Crm ,ShrinkPath(Name,Messlange-length(Crm)-3));
  Readmsg  := concat(Rm  ,ShrinkPath(Name,Messlange-length(Rm) -3));
  WriteMsg := concat(Wm  ,ShrinkPath(Name,Messlange-length(Wm) -3));
  CloseMsg := concat(Cm  ,ShrinkPath(Name,Messlange-length(Cm) -3));
  Erasemsg := concat(Em  ,ShrinkPath(Name,Messlange-length(Em) -3));
  Ok:=true;
end;



Destructor Urstream.Done;
begin
  Close;
end;


Procedure Urstream.Close;
begin
end;

procedure Urstream.Reseterror;
begin Ok := True; End;


function Urstream.Isok : boolean;
begin Isok := Ok; End;



{-----------Textstream Behandlung von Textdateien------------}

Constructor Textstream.Init(Name : Pathstr);
begin
  Urstream.Init(Name);
  Assign(F,Name);
end;

procedure Textstream.open;
begin
  repeat
    {$I-} Reset(F); {$I+}
    Ok := Inoutres=0;
  until Testerror(openmsg);
end;


procedure Textstream.Create;
begin
   repeat
      {$I-} Rewrite(F); {$I+}
       OK := Inoutres=0;
   until Testerror(createmsg);
end;


procedure Textstream.close;
begin
  repeat
    {$I-} If Textrec(F).Mode <> FmClosed then
             System.close(F); {$I+}
    Ok:= Inoutres=0;
  until Testerror(closemsg);
end;

procedure Textstream.append;
begin
  repeat
    {$I-} System.Append(F) {$I+};
    Ok:=Inoutres=0;
  until Testerror(openmsg);
end;

procedure Textstream.Readln(var S: String);
begin
  repeat
    {$I-} System.readln(F, S); {$I+}
     OK := Inoutres=0;
  until testerror(readmsg);
end;

procedure Textstream.writeln(S:String);
begin
  repeat
     {$I-} System.Writeln(F,S); {$I+}
      OK := Inoutres=0;
  until Testerror(writeMsg);
end;

function Textstream.Eof : boolean;
begin
  repeat
    {$I-} Eof := System.Eof(F); {$I+}
    OK := Inoutres=0;
  until Testerror(readmsg);
  If not Ok then Eof:=true;
end;

procedure Textstream.DelFile;
begin
  repeat
    {$I-} Erase(F); {$I+}
    OK := Inoutres=0;
  until Testerror(Erasemsg);
end;


{--------------allgem. Object fÅr typisierte Dateien---------------}
Constructor Typedstream.Init(Name : Pathstr; Rsize: Word);
begin
   urstream.Init(name);
   assign(F, Name);
   Recsize := RSize;
end;

procedure Typedstream.Open;
begin
  repeat
    {$I-} Reset(F, Recsize); {$I+}
    OK := Inoutres=0;
  until Testerror(Openmsg);
end;

procedure Typedstream.Create;
begin
  repeat
    {$I-} Rewrite(F,Recsize); {$I+}
    OK := Inoutres=0;
  until Testerror(createmsg);
end;

procedure Typedstream.Close;
begin
  repeat
    {$I-} If (Filerec(F).Mode = fmInput) or (Filerec(F).Mode = fmInOut) then
              System.close(f); {$I+}
    OK := Inoutres=0;
  until testerror(Closemsg);
end;


procedure Typedstream.read(var R; P: Longint; Anz: Word);
begin
  If P = -1 then P:=Pos;                       {sequentielles Lesen}
  If OK then
     repeat
       seek(P);
       {$I-} Blockread (F, R, Anz, Result); {$I+}
       If (Inoutres=0) and (Result < Anz) then Inoutres:=100;
       Ok := Inoutres=0;
     until testerror(readmsg);
  {EndIf}
end;

procedure Typedstream.Write(var R; P: Longint; Anz: Word);
begin
  If P = -1 then P:=Pos;                        {sequentielles Schreiben}
  If OK then
     repeat
        seek(P);
        {$I-} Blockwrite(F, R, Anz, Result); {$I+}
        If (Inoutres=0) and (Result < Anz) then Inoutres:=101;
        Ok := Inoutres=0;
     until Testerror(writemsg);
  {End IF}
end;


procedure Typedstream.Remove(P:Longint; Anz: Longint);
const AR : Acceptrec=('   Ok   ','','');
var
  I : Longint;
  B : Pointer;
  M : Message;
begin
  M:='Datei kann nicht gekÅrzt werden !';
  Getmem(B, FileRec(F).Recsize);
  If B =Nil then begin
     I:=IO_Error(M,'IOERROR.MSG',203,AR);
     OK:=False;
     Exit;
  End{If};
  I:=P+Anz; Seek(I);
  while (not eof) and OK do begin
    read(B^,I,1);
    If OK then Write(B^,I-Anz,1);
    Inc(I); Seek(I);
  end{While};
  If Ok then Begin
    I:=Size-Anz;
    repeat
      seek(I); {$I-} Truncate(f); {$I+}
      OK := Inoutres=0;
    until Testerror(M);
    seek(P);
  End{IF};
  Freemem(B,Filerec(F).Recsize);
end;


procedure TypedStream.Seek(P : Longint);
begin
  repeat
     {$I-} System.Seek(F, P); {$I+}
      OK:=InoutRes =0;
  until Testerror(Readmsg);
end;


function Typedstream.Eof : boolean;
begin
   repeat
     {$I-} Eof :=System.Eof(f); {$I+}
     OK := Inoutres=0;
   until TestError(Readmsg);
   If not OK then Eof:=true;
end;


function Typedstream.Pos : Longint;
begin
  repeat
    {$I-} Pos:=System.Filepos(F); {$I+}
    OK := Inoutres=0;
  until Testerror(Readmsg);
  If not OK then Pos:=0;
end;


function Typedstream.Size : longint;
begin
  repeat
    {$I-} Size:=System.Filesize(F); {$I+}
    OK := Inoutres=0;
  until Testerror(readmsg);
  If not OK then Size:=0;
end;


procedure Typedstream.DelFile;
begin
  repeat
    {$I-} Erase(F); {$I+}
    OK := Inoutres=0;
  until Testerror(Erasemsg);
end;


{---------------------- Dos-Funktionen --------------------------------}


begin
end.





