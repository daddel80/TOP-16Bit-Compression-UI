Procedure Copystream.read(var R; P: Longint; Anz: Word);
begin
  If P = -1 then P:=Pos;                       {sequentielles Lesen}
  If OK then
     repeat
       seek(P);
       {$I-} Blockread (F, R, Anz, Result); {$I+}
       Ok := Inoutres=0;
     until testerror(readmsg);
  {EndIf}
end;







Function ArchivFenster.ArcViewer(Ver_dat : boolean; vpos:word) : boolean;
const
      MaxTampon = 200;

      DateMini  : LongInt = 0;
      DateMaxi  : LongInt = $7FFFFFFF;
      TailleMini: LongInt = 0;
      TailleMaxi: LongInt = $7FFFFFFF;

      ZooId     = $FDC4A7DC;
Type  ZooHdrTyp = Record
                      Zoo_Text  : Array[1..20] of Char; { Nom du compacteur }
                      Zoo_Tag   : LongInt;              { Identifie une archive Zoo }
                      Zoo_Start : LongInt;              { D‚but des donn‚es }
                      Zoo_Minus : LongInt;              { V‚rification de concordance }
                      Zoo_Major : Char;                 { Version nø }
                      b1 : byte;                        { ? }
                      Zoo_Minor : Char;                 { Sous-version nø }
                      b2 : array[1..7] of Char;         { ? }
                  End;

      DwcHdrType =Record
                      Dwc_Sign : Char;                  { Esc }
                      Dwc_Unkn : Array[1..15] of Char;
                      Dwc_Date : Longint;               { Zeit der letzte Žnderung }
                      Dwc_File : Longint;               { Anzahl der Dateien }
                      Dwc_Text : Array[1..3] of Char;   { DWC }
                  End;

        LimHdrType=Record
                      Lim_Sign : Array[1..3] of Char;
                      Lim_Start: Byte;
                      b1       : Char;
                      Lim_Major: Char;
                      Lim_Minor: Char;
                      b2       : Char;
                   End;


      Arctype = (ZIP,LHA,ARJ,HYPER,ZOO,ARC{PAK},DWC,SQZ,LIMIT,BSA,SIT,TPZ,UNKNOWN);

var   Tampon    : Array[1..MaxTampon] of Byte;
      Lu        : word;
      Arcfile   : CopyStream;
      Count     : longint;
      Cmt       : boolean;

      j1,j2     : Word;
      Flusher   : LongInt;
      d1,d2     : LongInt;



      i         : Byte;
      w         : Word;
      Li        : LongInt;
      St        : String;
      St2       : String;

      NomFic    : String;
      Algo      : String[7];
      PSize     : LongInt;    { Packed Size          }
      USize     : LongInt;    { Unpacked (real) size }
      Attr      : Byte;
      CRC       : Longint;

      ZooHdr    : ZooHdrTyp;
      DwcHdr    : DwcHdrType;
      LimHdr    : LimHdrType;

      aktverz   : pathstr;
      NomficPath: Dirstr;
      NomficName: FileNameStr;
      Arcformat : Arctype;

label Fin;




  procedure VEinordnen(Path:Pathstr; Name:FileNameStr; Psize,Usize:longint; anfang:word; ebene :byte);
  var   stop  : boolean;
        Nom   : FileNameStr;

    procedure Einsetzen;
    var k     : word;
    begin
      For k:=dat.veranz downto anfang  do
        dat.ver[k+1]:=dat.ver[k];
      dat.ver[anfang].name       :=Nom;
      dat.ver[anfang].select     :=false;
      dat.ver[anfang].files      :=0;
      dat.ver[anfang].selgr      :=0;
      dat.ver[anfang].pos        :=ebene;
      dat.ver[anfang].Vopen      :=true;
      dat.ver[anfang].Vart       :=Verzeichnis;
      inc(dat.veranz);
    end;

  begin
   If Path[1]<>'\' then
     Nom:=copy(Path,1,pos('\',Path)-1) else
     Nom:=Path;
   delete(Path,1,pos('\',Path));

   If (Nom='\') then
   begin
     If Name<>'' then
     begin
       inc(dat.arcorig,Usize);
       inc(dat.arckomp,Psize);
       dat.ver[anfang].select:=true;
     end;
     stop:=true;
   end else
   begin
     inc(anfang); stop:=false;
     While ((not stop) or (Path>'')) and (not stop) do
     begin
       If (dat.veranz<anfang) then
       begin
         Einsetzen;
         If Path>'' then
         begin
            VEinordnen(Path,Name,PSize,USize,anfang,ebene+1);
            dat.ver[anfang].select:=false;
         end else
            If Name<>'' then
            begin
              inc(dat.arcorig,Usize);
              inc(dat.arckomp,Psize);
              dat.ver[anfang].select:=true;
            end;
         stop:=true;
       end else
       begin
         If (dat.ver[anfang].name=Nom) then
           If (Path='') then
           begin
             If Name<>'' then
             begin
              inc(dat.arcorig,Usize);
              inc(dat.arckomp,Psize);
              dat.ver[anfang].select:=true;
             end;
             stop:=true;
           end else
           begin
             VEinordnen(Path,Name,PSize,USize,anfang,ebene+1);
             stop:=true;
           end;
         {EndIf}
         If (dat.ver[anfang].pos<ebene) then
           If (dat.veranz>anfang) then
           begin
             Einsetzen;
             If Path>'' then
             begin
               VEinordnen(Path,Name,PSize,USize,anfang,ebene+1);
               dat.ver[anfang].select:=false;
             end else
               If Name<>'' then
               begin
                 inc(dat.arcorig,Usize);
                 inc(dat.arckomp,Psize);
                 dat.ver[anfang].select:=true;
               end;
             stop:=true;
           end;{IF}
          {EndIF}
       end;{EndIf}
       inc(anfang);
     end{While};
   end{IF};
  end;


  procedure DEinordnen(Name :filenamestr);
  begin
    inc(dat.filanz);
    dat.fil[dat.filanz].name  :=Lostring(Name);
    dat.fil[dat.filanz].attr  :=attr;
    dat.fil[dat.filanz].time  :=Li;
    dat.fil[dat.filanz].size  :=Usize;
    dat.fil[dat.filanz].uns   :=dat.filanz;
    dat.fil[dat.filanz].select:=false;

    dat.fil[dat.filanz].Crc   :=CRC;
    dat.fil[dat.filanz].Psize :=Psize;
    dat.fil[dat.filanz].Algo  :=Algo;

  end;



  function Arctest : Arctype;
  var Ext       : string[3];
  begin
    Arctest:=Unknown;
    Arcfile.Read(Tampon[1],Count,MaxTampon);
    If not Arcfile.OK then exit;
    Ext:=upstring(justextension(Arcname));
    Move(Tampon[1],w,2);           {ZIP}
    If w=$4b50 then
    begin
      dat.arckind:='PKZIP';
      Move(Tampon[3],w,2);
      If w=$0807 then
        Count:=4;
      Arctest:= ZIP; exit;
    end;

    Move(Tampon[1],w,2);            {ARJ}
    If (w=$EA60) and (Tampon[11]=2) then
    begin
      dat.arckind:='ARJ';
      Move(Tampon[3],w,2);
      Count:=4+w+4+2;
      Arctest:= ARJ; exit;
    end;

    st[0]:=Chr(3);
    Move(Tampon[1],st[1],3);        {Hyper}
    If (st = Chr($1A)+'HP') or (st = Chr($1A)+'ST') then
    begin
      dat.arckind:='HYPER';
      Arctest:= HYPER; exit;
    end;

    st[0]:=Chr(3);
    Move(Tampon[3],st[1],3);        {LHA}
    If st = '-lh' then
    begin
      dat.arckind:='LHA';
      Arctest:=LHA;  exit;
    end;

    If Arcfile.result>SizeOf(ZooHdr) then {ZOO}
    begin
      Move(Tampon[1],ZooHdr,SizeOf(ZooHdr));
      st[0]:=Chr(3);
      Move(ZooHdr.Zoo_text[1],st[1],3);
      IF st='ZOO' then
      begin
        dat.arckind:='ZOO';
        Count:=ZooHdr.Zoo_Start;
        Arctest:=ZOO; exit;
      end;
    end;

    Move(Tampon[1],i,1);           {ARC}
    If i = $1A then
    begin
      dat.arckind:='ARC/PAK';
      Arctest:=ARC; exit;
      {Arctest:=PAK}
    end;

    st[0]:=Chr(5);
    Move(Tampon[1],st[1],5);        {SQZ}
    If st='HLSQZ' then
    begin
      dat.arckind:='SQZ';
      Count:=8;
      Arctest:=SQZ; exit;
    end;

    If Arcfile.result>SizeOf(LimHdr) then {LIMIT}
    begin
      Move(Tampon[1],LimHdr,SizeOf(LimHdr));
      If LimHdr.Lim_Sign = 'LM'+CHR($1A) then
      begin
        dat.arckind:='LIMIT';
        Count:=LimHdr.Lim_Start;
        Arctest:=LIMIT; exit;
      end;
    end;

    Move(Tampon[1],Li,4);             {BSA}
    If Li = $475342FF then
    begin
     dat.arckind:='BSA';
     Count:=6;
     Arctest:=BSA; exit;
    end;

    If Arcfile.result>SizeOf(DwcHdr) then {DWC}
    begin
      Li:=Arcfile.Size-SizeOf(DwcHdr);
      Arcfile.Read(DwcHdr,Li,SizeOf(DwcHdr));
      If DwcHdr.Dwc_Text = 'DWC' then
      begin
        dat.arckind:='DWC';
        Count:=Li-34*DwcHdr.Dwc_File;
        Arctest:=DWC; exit;
      end
    end;

    if Ext='SIT' then                 {SIT-StuffIt}
    Begin
       dat.arckind:='STUFFIT';
       Count:=150;
       Arctest:=SIT; exit;
    End;

    If Ext='TPZ' then                 {TPZ}
    begin
      dat.arckind:='TPZ';
      Arctest:=TPZ; exit;
    end;



  end;



begin
 If ver_dat then
 begin
   for w:=0 to 10 do
   begin
     dat.ver[w].name:='';
     dat.ver[w].files:=0;
   end;
   dat.arcorig:=0;              {Summe von   orig. Gr”áe}
   dat.arckomp:=0;              {Summe von packed. Gr”áe}
   dat.ver[1].name:=justfilename(Arcname);
   dat.ver[1].pos:=0;
   dat.ver[1].select:=false;
   dat.ver[1].files :=0;
   dat.ver[1].Vopen:=true;
   dat.ver[1].Vart :=Packer;
   dat.veranz :=1;
 end else
 begin
   aktverz:=fullpath(vpos);
   If aktverz<>'\' then
     delete(aktverz,1,1);
   aktverz:=addbackslash(aktverz);
   dat.fil[1].name:='.';
   dat.fil[1].select:=false;
   dat.filanz:=1; dat.fanf:=1;
   dat.fpos:=1;
 end;

 FindFirst(Arcname, $27, Dirinfo);
 If ((Dirinfo.name='') or (Doserror>0)) then
 begin
   Arcviewer:=false;
   Doserror:=0; exit;
 end;

 If ver_dat then
 begin
   dat.ver[2].name:='\';
   dat.ver[2].pos:=0;
   dat.ver[2].select:=false;
   dat.ver[2].files :=0;
   dat.ver[2].Vopen :=true;
   dat.ver[2].Vart  :=Verzeichnis;
   dat.veranz  :=2;
 end;

 Arcfile.Init(Arcname,1);

 FileMode:=0;       {Nur zum Lesen ”ffnen}
 Arcfile.Open;
 FileMode:=2;

 Lu:=0; Count:=0;

 Arcviewer:=true;
 If not Arcfile.Ok then
 begin
   Arcviewer:=false; Goto Fin;
 end;

 Arcformat := Arctest;
 If Arcformat=Unknown then
 begin
   IO_Error(concat('Archiv: ', Shrinkpath(Arcname,20)),'IOERROR.MSG',225,AR1);
   Arcviewer:=false; Goto Fin;
 end;


 If Demo and not (Arcformat in [Unknown,ARJ]) then
 begin
   St:=concat('Archivbetrachter ''',dat.arckind,''':');
   IO_Error(St,'IOERROR.MSG',229,AR1);
   Arcviewer:=false; Goto Fin;
 end;


 repeat
   Cmt:=False;
   Arcfile.Read(Tampon[1],Count,MaxTampon);
   If (Arcfile.result<26) then  Goto Fin;

   If not Arcfile.Ok then
   begin
     Arcviewer:=false; Goto Fin;
   end;


   if  Arcformat = ZIP then
   Begin
     Move(Tampon[1],Li,4); if Li=$02014B50 then Goto Fin;
     Move(Tampon[9],w,2);
     Case w of
      0: Algo:='Stored ';
      1: Algo:='Shrunk ';
   2..5: Algo:='Reduce'+Chr(w-1);
      6: Algo:='Implode';
      7: Algo:='Token  ';
      8: Algo:='DeflatX';
     else Algo:='Unknown';
     End;
     Move(Tampon[13],w,2); Li:=LongInt(w) shl 16;
     Move(Tampon[11],w,2); Li:=Li+w;
     Move(Tampon[15],Crc,4);
     Attr:=0;
     Move(Tampon[19],PSize,4);
     Move(Tampon[23],USize,4);
     Move(Tampon[27],w,2); if w>255 then w:=255;
     NomFic[0]:=Chr(w); Move(Tampon[31],NomFic[1],w);
     Flusher:=30+w+PSize;
     Move(Tampon[29],w,2);
     Attr:=0;
     Flusher:=Flusher+w;
   End else
   if Arcformat = ARJ then
   Begin
     Move(Tampon[17],PSize,4);
     Move(Tampon[21],USize,4);
     Move(Tampon[25],Crc,4);
     Move(Tampon[31],Attr,1);
     i:=35; NomFic:='';
     While (Tampon[i]<>0) and (i<MaxTampon) do Begin
       NomFic:=NomFic+Chr(Tampon[i]); Inc(i);
     End;
     Case Tampon[10] of
        0: Algo:='Stored';
     1..4: Algo:='Arj-'+Chr($30+Tampon[10]);
      else Algo:='Unknown';
     End;
     Cmt:=Tampon[11]=2;
     Move(Tampon[3],w,2);
     Move(Tampon[13],Li,4);
     if Cmt then Begin
       Flusher:=4+w+4+2;
     End else Flusher:=14+w+PSize-4;
   End else
   If Arcformat = LHA then
   begin
     Move(Tampon[3],St[1],3); St[0]:=#3;
     if St<>'-lh' then Goto Fin;
     Move(Tampon[22],NomFic,Tampon[22]+1);
     Algo[0]:=#5; Move(Tampon[3],Algo[1],5);
     Move(Tampon[8],PSize,4);
     Move(Tampon[12],USize,4);
     Move(Tampon[18],w,2); Li:=LongInt(w) shl 16;
     Move(Tampon[16],w,2); Li:=Li+w;
     Move(Tampon[20],Attr,1);
     Move(Tampon[Tampon[22]+1],w,2); Crc:=w;

     i:=Tampon[Tampon[1]+1]; st:='';              {Verzeichnis lesen}
     If i > 0 then
     begin
       i:=Tampon[1]+5;
       While (Tampon[i]<>5 ) and (i<MaxTampon) do begin
         st:='';
         While not (Tampon[i] in[255,5]) and  (i<MaxTampon) do Begin
           St:=concat(st,Chr(Tampon[i])); inc(i);
         End;
         St:=concat(St,'\'); inc(i);
       end;
       Nomfic:=concat(st,Nomfic);
     end;

     Flusher:=PSize+2+Tampon[1];
     NomFic:=justfilename(NomFic);      {kein Verzeichnis l”schen !!!!}
   end;
   If Arcformat = HYPER then
   begin
     case Tampon[2] of
       $53: Algo:='Stored';    {ST- 53 54}
       $48: Algo:='Packed';    {HP- 48 50}
      else Algo:='Unknown';
     end;
     Move(Tampon[5], Psize,4);
     Move(Tampon[9], Usize,4);
     Move(Tampon[13],Li,4);
     Move(Tampon[17],Crc,4);
     Move(Tampon[21],Attr,1);
     Move(Tampon[22],i,1);
     NomFic[0]:=Chr(i);
     Move(Tampon[23],Nomfic[1],i);
     Flusher:=22+i+PSize;
   end else
   if Arcformat = ZOO then
   Begin
     Move(Tampon[1],Li,4);
     if Li<>ZooId then Goto Fin;
     Flusher:=0; Move(Tampon[7],Count,4);
     If Count=0 then Goto Fin;
     Case Tampon[6] of
       0: Algo:='Stored';
       1: Algo:='Lzw';
      else Begin Str(Tampon[6]:3,Algo); Algo:='? '+Algo; End;
     End;
     Move(Tampon[20],w,2); Crc:=w;
     Move(Tampon[25],PSize,4);
     Move(Tampon[21],USize,4);
     i:=39; NomFic:='';
     While (Tampon[i]<>0) and (i<MaxTampon) do Begin
       NomFic:=NomFic+UpCase(Chr(Tampon[i])); Inc(i); End;

     i:=59; st:='';
     While (Tampon[i]<>0) do Begin                       {Verzeichnis}
       st:=st+UpCase(Chr(Tampon[i])); Inc(i); End;
     Nomfic:=concat(addbackslash(st),Nomfic);
     Move(Tampon[15],w,2); Li:=LongInt(w) shl 16;
     Move(Tampon[17],w,2); Li:=Li+w;
     Attr:=0;
   End else
   If Arcformat = ARC then
   begin
     Case Tampon[2] of
       0: Goto Fin;
       1: Algo:='Stor1';
       2: Algo:='Stor2';
       3: Algo:='Packd';
       4: Algo:='Squzd';
       5: Algo:='Crun1';
       6: Algo:='Crun2';
       7: Algo:='Crun3';
       8: Algo:='Crun4';
       9: Algo:='Sqash';
      10: Algo:='Crushed';
      11: Algo:='Distill';
      else Algo:='Unknown';
     End;
     i:=3; NomFic:='';
     While Tampon[i]<>0 do Begin NomFic:=NomFic+Chr(Tampon[i]); Inc(i); End;
     Move(Tampon[16],PSize,4);
     if Tampon[2]=1 then USize:=PSize
       else Move(Tampon[26],USize,4);
     if Tampon[2]=1 then Flusher:=25+PSize
       else Flusher:=29+Psize;
     Move(Tampon[20],Li,2); Li:=LongInt(Li) shl 16;
     Move(Tampon[22],w,2);  Li:=Li+w;
     Move(Tampon[24],w,2);  Crc:=w;
     Attr:=0;
   End else
   If Arcformat = DWC then
   Begin
     If DwcHdr.Dwc_File=0 then Goto Fin;
     dec(DwcHdr.Dwc_File);
     i:=1; Nomfic:='';
     While Tampon[i]<>0 do Begin NomFic:=NomFic+Chr(Tampon[i]); Inc(i); End;
      Move(Tampon[16],PSize,4);
     Move(Tampon[14],Usize,4);
     {Move(Tampon[18],Li,4);} Li:=0;
     Move(Tampon[22],Psize,4);
     case Tampon[27] of
       1: Algo:='Crunche';
       2: Algo:='Stored';
       else Algo:='Unknown';
     end;
     Move(Tampon[29],w,2); Crc:=w;
     Attr:=0;
     Flusher:=34;
   End else
   If Arcformat = SQZ then
   begin
     Nomfic:='';
     If Tampon[1]>18 then
     begin
       case Tampon[3] of
        0 : Algo:='Stored';
      1..7: Algo:='Comp-'+Chr($30+Tampon[3]);
        else Algo:='Unknown';
       end;
       Move(Tampon[4],PSize,4);
       Move(Tampon[8],USize,4);
       Move(Tampon[12],Li,4);
       Move(Tampon[16],Attr,1);
       Move(Tampon[17],Crc,4);
       Nomfic[0]:=Chr(Tampon[1]-18);
       Move(Tampon[21],Nomfic[1],Tampon[1]-18);
       Flusher:=Tampon[1]+PSize+2;
     end else
      case Tampon[1] of
       0 : Goto Fin;
      else Flusher:=Tampon[2]+3;
     End;
     NomFic:=justfilename(NomFic);      {kein Verzeichnisl”schen !!!!}
   End else
   If Arcformat = LIMIT then
   begin
     Move(Tampon[1],w,2);
     If w=$F813 then Goto Fin;
     If w=$D180 then              {Verzeichnis}
     begin
       i:=5; st:='';
       While Tampon[i]<>0 do Begin st:=st+Chr(Tampon[i]); Inc(i); End;
       Flusher:=Tampon[3];
       Nomfic:='';
     end;
     If w=$F123 then              {Datei}
     begin
       Move(Tampon[7],Li,4);
       Move(Tampon[11],Attr,1);
       Move(Tampon[14],Usize,4);
       Move(Tampon[18],Psize,4);
       Move(Tampon[22],Crc,4);
       i:=26; NomFic:='';
       While (Tampon[i]<>0) and ($10<>(Attr and $10)) do
         Begin NomFic:=NomFic+Chr(Tampon[i]); Inc(i); End;
       Nomfic:=concat(addbackslash(st),Nomfic);
       Algo:='       ';    {??}
       Flusher:=Tampon[3]+PSize;
     end;
   end else
   If Arcformat = BSA then
   begin
     Move(Tampon[11],Li,4); Reverse(Li);
     i:=15; NomFic:='';
     While (Tampon[i]<>0) do Begin NomFic:=NomFic+Chr(Tampon[i]); Inc(i); End;
     Move(Tampon[Tampon[6]-5],Usize,4); Reverse(Usize);
     Move(Tampon[Tampon[6]-1],PSize,4); Reverse(Psize);
     Move(Tampon[Tampon[6]+3],Crc,4);
     Attr:=0;
     Algo:='       ';   {??}
     Flusher:=Tampon[6]+Psize+10
   end else
   If Arcformat = SIT then
   Begin
     Move(Tampon[3],NomFic,64);
     Move(Tampon[85],USize,4); Reverse(USize);
     Move(Tampon[93],PSize,4); Reverse(PSize);
     Move(Tampon[89],d1,4); Reverse(d1);
     Move(Tampon[97],d2,4); Reverse(d2);
     PSize:=PSize+d2; USize:=USize+d1;
     if Tampon[1]=0 then i:=Tampon[2] else i:=Tampon[1];
     Case i of
        0: Algo:='Stored';
        2: Algo:='Lzw';
      else Algo:='Unknown';
     End;
     Crc :=0;
     Attr:=0;
     Li:=0;
     Flusher:=100+PSize+12;
   End else
   if Arcformat = TPZ then
   Begin
     Case Tampon[25] of
        0: Algo:='inclu';
        1: Algo:='implo';
     End;
     Move(Tampon[26],USize,4);
     Move(Tampon[30],PSize,4);
     NomFic:='';
     i:=56;
     While (Tampon[i]<>32) And (i<56+67) do
     Begin
       NomFic:=NomFic+UpCase(Chr(Tampon[i])); Inc(i);
     End;
     i:=43;
     While (Tampon[i]<>32) And (i<43+12) do
     Begin
       NomFic:=NomFic+UpCase(Chr(Tampon[i])); Inc(i);
     End;
     Crc :=0;
     Attr:=0;
     Flusher:=PSize+122;
     Move(Tampon[36],Li,4);
   End;



   While Pos('/',NomFic)<>0 do NomFic[Pos('/',NomFic)]:='\';


   i:=0;

   If Nomfic<>'' then
   begin
     If pos('\',Nomfic)=1 then delete(Nomfic,1,1);
     If pos('\',Nomfic)=0 then Nomfic:=concat('\',Nomfic);
   end;

   Nomfic:=upstring(nomfic);
   NomficName:= justfilename(NomFic);
   If (pos('.',NomficName)=0) and (length(NomficName)>0) then
     NomficName:=concat(NomficName,'.');
   NomficPath  := justpathname(Nomfic);

   If (Li>=DateMini) and (Li and $FFFF0000<=DateMaxi) and
      (USize>=TailleMini) and (USize<=TailleMaxi) then
   If (NomFic<>'') and not Cmt then
   Begin
     If ver_dat then
       VEinordnen(NomficPath, NomficName,PSize,USize,2,1) else
     If (aktverz=NomficPath) and CompFilename('*.*',NomFicName) and
        (Attr<>Directory) and (((Attr and m_attrib)>0)
        and (not ((Attr and $18) in[$10,$8])) or (Attr=0)) then
       DEinordnen(NomficName);
   end;

   Inc(Count,Flusher);

 until false;


 Fin :

 Arcfile.Close;

End;






Function Archivfenster.VerzNeu : boolean;
begin
 VerzNeu:=ArcViewer(true,0);
 If fullpath(dat.vpos)<>dat.aktverz then dat.ver_dat:=true;
end;

function Archivfenster.Dateilesen (vpos:word): boolean;
begin
 Dateilesen:=Arcviewer(false,vpos);
end;

procedure Archivfenster.Fakt;
begin
 {RFenster^.Drivewrite(False);}
 Arcname:=concat(addbackslash(RFenster^.dat.aktverz),RFenster^.dat.fil[RFenster^.dat.fpos].name);
 If VerzNeu then
 begin
   dat.vpos:=1; dat.sanf:=1; dat.wanf:=1; einmal:=false; dat.ver_dat:=true;
   LaBu:=RFenster^.LaBu;
   ClrUnterf;
   UnselectAll;
   Fenakt(True,False,False);
   Arcopen:=true;
 end;
end;


function Archivfenster.Packen_EntPacken : boolean;
begin
  Packen_EntPacken:=EntPacken;
end;


function Archivfenster.Entpacken:boolean;
const M  : Message = 'Fehler beim Dekomprimieren :';
var tas,fun     : char;
    entpack     : byte;
    i           : byte;
    Vp          : Dparam;
    ausw        : boolean;
    Bu          : Button;
    Sb          : SelButton;
    Ed2         : Edit;
    zahl        : string[10];
    weiter      : boolean;
    entp        : boolean;


begin
   Entpacken:=false; Packer_File.Open;
   If not dat.ver_dat and (dat.filanz>1) then Packdateiwrite(dat.vpos);
   Listendatei(Kom.sel,ausw);
   entpack:=0; Packer_File.Seek(entpack);
   If Kom.sel=0 then
   begin
     IO_Error(concat(M),'IOERROR.MSG',222,AR1); exit;
   end;
   Kom.datei:=upstring(Rfenster^.dat.fil[Rfenster^.dat.fpos].name);
   Vp.Arcend:='';
   while not Packer_File.EoF and not CompArcend(Vp.Arcend,Kom.datei) do
     Packer_File.Read(Vp,-1,1);
   Kom.pack:=Packer_File.Pos-1;
   Packer_File.Close;
   Kom.pas:='';
   If (trim(Vp.EmitV)>'') then
     Kom.path:=true else Kom.path:=false;

   If not openwindow(60,9,fenfo,fenba,'Dekomprimieren') then exit;

   writeXY(3,2,'Entpacken von :');

   If (Kom.sel>0) and ausw then
   begin
     str(Kom.sel,zahl);
     If Kom.sel>1 then
       writeXY(19,2,concat(zahl,' Dateien')) else
       writeXY(19,2,concat(zahl,' Datei'));
   end else
     writeXY(19,2,concat(upstring(dat.fil[dat.fpos].name)));

   writeXY(3,4,concat('aus Archiv    : ',Kom.datei));

   If (trim(Vp.passw)>'') then
     Initeditor(Ed2,45,4,'Passwort :',true,Kom.pas,12);

   InitSelButton(Sb,3,7,'Mit Verzeichnissen',Kom.path,1); Sb.Anz:=1;

   InitButton(Bu,10 ,9,'  ~Dekomprimieren  ',ALT_D,1);
   InitButton(Bu,38,9, '    ~Abbruch    ',     ALT_A,2); Bu.Anz:=2;

   I:=4;weiter:=false; entp:=false;
   repeat


     If (trim(Vp.EmitV)>'') then
       SetSelButton(Sb);
     If (trim(Vp.passw)>'') then
       SetEditor(Ed2);

      SetButton(Bu);
     case I of
     2: ActiveEditor(Ed2);
     3: ActiveSelButton(Sb);
     4: ActiveButton(Bu);
     end;

     case EventThisButton(Bu) of
      1: begin
           If (trim(Vp.passw)>'') then
             Kom.pas  :=Ed2.T;
           If (trim(Vp.EmitV)>'') then
             Kom.path :=Sb.Sb[1].S;
           entp:=true;
           weiter:=true;
         end;
      2: begin
           weiter:=true;
         end;
     end;

     If (trim(Vp.passw)>'') then
       If EventEditor(Ed2)   then I:=2;
     If (trim(Vp.EmitV)>'') then
       If EventSelButton(Sb) then I:=3;

     case ev.key of
   CUP,
   BACKTAB: begin
             If I>1 then dec(I) else I:=4;
             If (trim(Vp.EmitV)='')            and (I=3) then dec(I);
             If ((trim(Vp.passw)='') or ausw ) and (I=2) then dec(I);
            end;
   CDOWN,
   TAB   : begin
             If I<4 then inc(I) else I:=1;
             If ((trim(Vp.passw)='') or ausw ) and (I=2) then inc(I);
             If (trim(Vp.EmitV)='')            and (I=3) then inc(I);
           end;
      ESC : weiter:=true;
      F1  : Hilfe.ViewPage(24);
        end;
   until weiter;
   closewindow;
   If entp then Dekomprimieren;
   Entpacken:=entp;
end;


  procedure ArchivFenster.Dekomprimieren;
  const M = 'Fehler beim Dekomprimieren :';
  var Cmdline,progdir : pathstr;
            tstr      : pathstr;
            Vp        : Dparam;
            ex        : byte;

  begin
    Dosexitcode;
    Packer_File.Open;
    Packer_File.read(Vp,kom.pack,1);
    Packer_File.Close;
    If trim(Vp.entp)='' then Vp.entp:=Vp.verp;
    Progdir:=concat(addbackslash(m_packverz),Vp.entp,' ');
    FindFirst(Progdir, $27, DirInfo);
    If ((Dirinfo.name='') or (Doserror>0)) then
    begin
       execend(Vp.verp,concat(M,' ',Vp.entp),Ar1); MouShowMouse;
       Doserror:=0;exit;
    end;

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
        writeXY(9,2,'Entpacke Dateien...') else writeXY(9,2,'Entpacke Dateien...');
      MouHideMouse;redout;
    end;

    Cmdline:='';
    If Kom.path then
      Cmdline:=Vp.EmitV else Cmdline:=Vp.EohneV;
    If Kom.pas>'' then
      Cmdline:=concat(Cmdline,' ',Vp.passw,Kom.pas);

    Cmdline:=concat(CmdLine,' ',addbackslash(Rfenster^.dat.aktverz),Kom.datei);

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

    If not m_interM then
    begin
      redback; closewindow
    end else
    If not m_flashend then
    begin
      Blackscreen; restwindow; Einblenden;
    end;
    MouShowMouse;

  end;


procedure Archivfenster.Floschen;
const  M   : Message = 'Fehler beim L”schen ';

var Vp     : Dparam;
    Progdir,
    CmdLine: pathstr;
    fhohe  : byte;
    ex     : byte;
    tstr   : pathstr;

begin
   Dosexitcode;
   Kom.arc:=RFenster^.dat.fil[RFenster^.dat.fpos].name;
   Vp.arcend:='';
   Packer_File.Open;
   while not Packer_File.EOF and not CompArcend(Vp.Arcend,Kom.arc)  do
     Packer_File.Read(Vp,-1,1);
   Packer_File.Close;

   Progdir:=concat(addbackslash(m_packverz),Vp.verp,' ');
   FindFirst(Progdir, $27, DirInfo);
   If ((Dirinfo.name='') or (Doserror>0)) then
   begin
     execend(Vp.verp,concat(M,' ',Vp.verp),Ar1); MouShowMouse;
     Doserror:=0;exit;
   end;

   Cmdline:=concat(Vp.datdel,' ',addbackslash(RFenster^.dat.aktverz),Kom.arc);

   If m_interM then
   begin
      If not savewin(2,2,crtxmax-ShadowX,crtymax-ShadowY) then exit;
      MouDefBereich(2,Map);
      MouHideMouse; Ausblenden;
    end else
    begin
      If trim(Vp.packdat)>'' then fhohe:=2 else fhohe:=4;
      If not openwindow(31,fhohe,fenfo,fenba,'L”schen') then exit;
      textcolor(MessageCol);
      If Kom.sel=1 then
        writeXY(10,2,'L”sche Datei...') else writeXY(10,2,'L”sche Dateien...');
      MouHideMouse; redout;
    end;



    If Kom.sel=0 then
    begin
      Cmdline:=Cmdline+' '+Kom.datei;
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
    If not m_flashend then
    begin
      Blackscreen; restwindow; Einblenden;
    end;
    MouShowMouse;
end;
