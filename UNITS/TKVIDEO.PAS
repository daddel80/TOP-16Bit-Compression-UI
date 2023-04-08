Unit Tkvideo;

Interface

  USES Crt, Dos, kbm ;

  const
   einf     : boolean=false;
   Farbe    : Byte = 1;          {Arrayposition}

  var OrigMode   : BYTE;
      MonoChr    : Boolean;

  TYPE    RecArray = ARRAY [1..192] of Byte;
          RegArray = ARRAY [1..2] OF RecArray;

          Time = Record
               Hour:Word;
               Min :Word;
               Sec :Word;
               HSec:Word;
            End;



FUNCTION   Schirmanfang: Longint;
PROCEDURE  TKclrscr;

{-------- Ein/Ausblendfunktionen ---------}
PROCEDURE  Einblenden;
PROCEDURE  Ausblenden;
PROCEDURE  BlackScreen;
PROCEDURE  ProgColors(Color:Byte);

{--------- Cursorfunktionen --------------}
PROCEDURE  Cursor_ON;
PROCEDURE  Cursor_OFF;
PROCEDURE  Cursor_Set(C : Word);



Implementation




CONST BlendDauer  : WORD     =  3; {in HSec}
      M           : WORD     =  0;
     FarbArray  : RegArray = ((0  ,  0 ,  0 ,       {SCHWARZ    , 0,   0,  0}
                              0  ,  0 , 30 ,        {BLAU       , 0,   0, 42}
                              0  , 42 ,  0 ,        {GRšN       , 0,  42,  0}
                              0  , 42 , 42 ,        {ZYAN       , 0,  42, 42}
                             42  ,  0 ,  0 ,        {ROT        , 42,  0,  0}
                             42  ,  0 ,  42,        {MAGENTA    , 42,  0, 42}
                             42  , 42 ,  0 ,        {BRAUN      , 42, 42,  0}
                             42  , 42 , 42 ,        {HELLGRAU   , 42, 42, 42}
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                             42  ,  21 , 0 ,    { Maus, Background , 42, 21, 0}
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                             21  , 21  , 21 ,      {DUNKELGRAU , 21,  21, 21}
                             21  , 21  , 63 ,      {HELLBLAU   , 21,  21, 63}
                             21  , 63  , 21 ,      {HELLGRšN   , 21,  63, 21}
                             21  , 63  , 63 ,      {HELLZYAN   , 21,  63, 63}
                             63  , 21  , 21 ,      {HELLROT    , 63,  21, 21}
                             63  , 21  , 63 ,      {HELLMAGENTA, 63,  21, 63}
                             63  , 63  , 21 ,      {GELB       , 63,  63, 21}
                             63  , 63  , 63 ),     {Weiá       , 63,  63, 63}

                             (0  ,  0 ,  0 ,        {SCHWARZ    , 0,   0,  0}
                              0  ,  0 , 42 ,        {BLAU       , 0,   0, 42}
                              0  , 24 ,  0 ,        {GRšN       , 0,  42,  0}
                              0  , 42 , 42 ,        {ZYAN       , 0,  42, 42}
                             42  ,  0 ,  0 ,        {ROT        , 42,  0,  0}
                             42  ,  0 ,  42,        {MAGENTA    , 42,  0, 42}
                             42  , 42 ,  0 ,        {BRAUN      , 42, 42,  0}
                             42  , 42 , 42 ,        {HELLGRAU   , 42, 42, 42}
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                             42  ,  21 , 0 ,    { Maus, Background , 42, 21, 0}
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                              0  ,  0  , 0 ,
                             21  , 21  , 21 ,      {DUNKELGRAU , 21,  21, 21}
                             21  , 21  , 63 ,      {HELLBLAU   , 21,  21, 63}
                             21  , 63  , 21 ,      {HELLGRšN   , 21,  63, 21}
                             21  , 63  , 63 ,      {HELLZYAN   , 21,  63, 63}
                             63  , 21  , 21 ,      {HELLROT    , 63,  21, 21}
                             63  , 21  , 63 ,      {HELLMAGENTA, 63,  21, 63}
                             63  , 63  , 21 ,      {GELB       , 63,  63, 21}
                             63  , 63  , 63 ));    {Weiá       , 63,  63, 63}



VAR UrspArray,
    AusbArray  : RecArray;
    Counter,C2 : BYTE;
    Regs       : Registers;
    ExitOld    : pointer;               { Zeiger auf die alte Exit-Prozedur }
    schirm     : Pointer;
    cur_set    : word;
    Start,Stop : Time;
    zahler     : word;

FUNCTION Schirmanfang: Longint;
begin
  if lastmode = 7 then
     Schirmanfang := $b000
   else
     Schirmanfang := $b800;
end;



PROCEDURE TKclrscr;
var ofs,qofs,zofs:integer;
    vioseg :longint;
    z,r  : byte;
begin
  vioseg:=Schirmanfang;
  for r:=0 to crtymax-1 do
    begin
      for z:=crtymax downto r do
      begin
        for ofs:=0 to crtxmax-1 do
        begin
          qofs:=( ((z-1)*crtxmax+ofs)*2 );
          zofs:=( ((z)*crtxmax+ofs)*2);
          If z>0 then
          begin
            mem[vioseg:zofs+1]:=mem[vioseg:qofs+1];
            mem[vioseg:zofs]:=mem[vioseg:qofs];
          end else begin
            mem[vioseg:zofs+1]:=7;
            mem[vioseg:zofs]:=0;
          end;
       end;
     end;
     delay(1);
   end;
   window(1,1,crtxmax,crtymax);
   gotoxy(1,1);textbackground(black); textcolor(lightgray);
end;


{--------------------- Ein/Ausblendfunktionen ---------------}



PROCEDURE Dauer(Sta,Sto : Time);
var T,D  : word;
BEGIN
    inc(Zahler);
    T:=((Sto.Min*600+Sto.Sec*100+Sto.HSec)-
       (Sta.Min*600+Sta.Sec*100+Sta.HSec))*10;
    If T<BlendDauer*Zahler then
    begin
      If M>(BlendDauer*Zahler-T) then
      begin
        dec(M,BlendDauer*Zahler-T);
      end else
      begin
        delay((BlendDauer*Zahler-T)-M);
      end;
     end else
     begin
       D:=T-BlendDauer*Zahler;
       inc(M,D);
       If M>BlendDauer then dec(M,BlendDauer) else
                           delay(BlendDauer-M);
    end;
END;

PROCEDURE PushRegs;
BEGIN
  Regs.AX:=$1017;
  Regs.BX:=0;
  Regs.CX:=64;
  Regs.ES:=Seg(UrspArray);
  Regs.DX:=Ofs(UrspArray);
  Intr($10, Regs);
END;

PROCEDURE PopRegs(PopArray : RecArray);
BEGIN
  Regs.AX:=$1012;
  Regs.BX:=0;
  Regs.CX:=64;
  Regs.ES:=Seg(PopArray);
  Regs.DX:=Ofs(PopArray);
  Intr($10, Regs);
END;

PROCEDURE BlackScreen;
BEGIN
  FOR Counter:=1 TO 192 DO AusbArray[Counter]:=0;
  Regs.AX:=$1012;
  Regs.BX:=0;
  Regs.CX:=64;
  Regs.ES:=Seg(AusbArray);
  Regs.DX:=Ofs(AusbArray);
  Intr($10, Regs);
END;

PROCEDURE ProgColors(Color:Byte);
BEGIN
  Farbe:=Color;
  Regs.AX:=$1012;
  Regs.BX:=0;
  Regs.CX:=64;
  Regs.ES:=Seg(FarbArray[Farbe]);
  Regs.DX:=Ofs(FarbArray[Farbe]);
  Intr($10, Regs);
END;


PROCEDURE Ausblenden;
VAR Weiter : BOOLEAN;
    Regs   : Registers;
BEGIN
  IF OrigMode in [1..6,9] THEN BEGIN
    AusbArray:=FarbArray[Farbe];
    M:=0; zahler:=0;
    with Start do
      GetTime (Hour,Min,Sec,Hsec);
    REPEAT
      Weiter:=FALSE;
      FOR Counter:=1 TO 192 DO
        IF AusbArray[Counter]>0 THEN BEGIN
          Weiter:=TRUE;
          Dec(AusbArray[Counter]);
        END;
      Regs.AX:=$1012;
      Regs.BX:=0;
      Regs.CX:=192;
      Regs.ES:=Seg(AusbArray);
      Regs.DX:=Ofs(AusbArray);
      Intr($10, Regs);
      with Stop do
        GetTime (Hour,Min,Sec,Hsec);
      Dauer(Start,Stop);
    UNTIL NOT Weiter;
  END;
  TextBackground(Black);
  TextColor(Lightgray);
  window(1,1,crtxmax,crtymax);
  ClrScr;
  PopRegs(UrspArray);
END;


PROCEDURE Einblenden;
CONST HighVar : BYTE = 0;

VAR Weiter  : BOOLEAN;

BEGIN
  IF OrigMode<>7 THEN BEGIN
    FOR Counter:=1 TO 192 DO IF HighVar<Farbarray[Farbe][Counter] THEN HighVar:=Farbarray[Farbe][Counter];
    M:=0; Zahler:=0;
    with Start do
        GetTime (Hour,Min,Sec,Hsec);
    REPEAT
      Weiter:=TRUE;
      FOR Counter:=1 TO 192 DO BEGIN
        IF AusbArray[Counter]=HighVar-1 THEN Weiter:=FALSE;
        IF AusbArray[Counter]<Farbarray[Farbe][Counter] THEN Inc(AusbArray[Counter]);
      END;
      Regs.AX:=$1012;
      Regs.BX:=0;
      Regs.CX:=192;
      Regs.ES:=Seg(AusbArray);
      Regs.DX:=Ofs(AusbArray);
      Intr($10, Regs);
      with Stop do
        GetTime (Hour,Min,Sec,Hsec);
      Dauer(Start,Stop);
    UNTIL NOT Weiter;
  END;
END;



PROCEDURE VideoEnd;
BEGIN
  PopRegs(UrspArray);
  ExitProc := ExitOld;          { wieder alte Exit-Prozedur installieren }
END;

{---------------------- Cursorfunktionen -----------------------}


procedure Cursor_Get;
begin
  Regs.ah:=$3;
  intr($10, Regs);
  cur_set:=Regs.cx;
end;

procedure Cursor_ON;
Begin
  Cursor_Set(cur_set);
  {Inline($B4/$01/$B9/$0E/$0D/$CD/$10);}
End;

procedure Cursor_OFF;
Begin
  Inline($B4/$01/$B9/$00/$20/$CD/$10);
End;

procedure Cursor_Set(C : Word);
Begin
  Inline($B4/$01/$8B/$4E/<C/$CD/$10);
End;



BEGIN
  OrigMode := LastMode;
  ExitOld  := ExitProc;                { Adresse der Exit-Prozedur merken }
  ExitProc := @VideoEnd;               { KbmEnd als Exit-Prozedur definieren}
  PushRegs;
  Monochr:=(OrigMode=7);
  Cursor_Get;
END.
