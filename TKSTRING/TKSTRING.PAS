
(*{$A+,B-,D-,E-,F-,I-,L-,N-,O-,R-,S-,V-}*)

  {*********************************************************}
  {*                 TKSTRING.PAS V 1.0                    *}
  {*        Copyright (c) TK-Soft, Thomas Knîfel 1994.     *}
  {*      Createt with Turbo-Pascal 7.0 by Borland Inc.    *}
  {*                 All rights reserved.                  *}
  {*                                                       *}
  {*********************************************************}

UNIT TKString;
  {-grundlegende Routinen zur Stringmanipulation}

INTERFACE

USES CRT,DOS;


CONST
  MessLange = 52;
  {used by CompareLetterSets for estimating word similarity}
  LetterValues : ARRAY[1..30] OF Byte =
  (3 {A}, 6 {B}, 5 {C}, 4 {D}, 3 {E}, 5 {F}, 5 {G}, 4 {H}, 3 {I},
   8 {J}, 7 {K}, 4 {L}, 5 {M}, 3 {N}, 3 {O}, 5 {P}, 7 {Q}, 4 {R},
   3 {S}, 3 {T}, 4 {U}, 6 {V}, 5 {W}, 8 {X}, 8 {Y}, 9 {Z},
   5 {é}, 5 {ô}, 5 {ö}, 6 {·});


TYPE
  Message   = string[MessLange];
  BTable      = ARRAY[0..255] OF Byte; {For Boyer-Moore searching}
  FileNameStr = String[12];


  {------------------------- Numerik-Konvertierung -------------------------}

FUNCTION HexB(B : Byte) : String;
  {-Return: Hex-String des Bytes}

FUNCTION HexW(W : Word) : String;
  {-Return: Hex-String des Wortes}

FUNCTION HexL(L : LongInt) : String;
  {-Return: Hex-String des LongInteger-Wertes}

FUNCTION HexPtr(P : Pointer) : String;
  {-Return: Hex-String des Pointers}

FUNCTION Binary(L : LongInt; Bits : Byte) : String;
  {-Die in BITS angegebene Anzahl Bits (Rechts beginnend) werden
    im String dargestellt}

FUNCTION Form(Maske : String; R: Real) : String;
 { Wandelt reelle Zahl r in einen formatierten String um.
   Die Maske darf folgende Zeichen enthalten:
   '#' : Vornullen werden an dieser Stelle nicht ausgegeben
   '@' : Vornullen werden mit dargestellt
   '*' : Vornullen werden als '*' dargestellt
   '=' : Vornullen werden als '=' dargestellt
   '%' : Vornullen werden als '%' dargestellt
   '-',
   '+' : das Vorzeichen wird an dieser Stelle ausgegeben, '+' steht fÅr die
	 expliziete Ausgabe von + als positives Vorzeichen
   '.',
   ',' : Legen die Position des Dezimalpunktes fest.

   Alle anderen Zeichen in der Maske werde unverÑndert Åbernommen}

FUNCTION TimeStr(TimeMS:LongInt; hmsh:Byte) : String;
  {-Gibt TimeMs (Zeit in Millisekunden) formatiert aus
    hmsz=1: nur Stunden
         2: HH:MM
         3: HH:MM:SS
	 4: HH:MM:SS.hh }

FUNCTION DateStr: String;
{ Datum im Format DD.MM.JJ }

  {----------------- einfache Stringmanipulationen -----------------}

FUNCTION Upcase(C : Char) : Char;
  { BerÅcksichtigt Umlaute}

FUNCTION LoCase(C : Char) : Char;
  {-Return Kleinbuchstabe von C, berÅcksichtigt auch Umlaute}

FUNCTION UpString(S : String) : String;
  {-Konvertiert einen String in Gro·schreibung}
  { BerÅcksichtigt Umlaute}

FUNCTION LoString(S : String) : String;
  {-Konvertiert einen String in Kleinbuchstaben}
  { BerÅcksichtigt Umlaute}

PROCEDURE ClrStr(var S : String; Len : Byte);
  {-FÅllt einen String der LÑnge Len mit Leerzeichen}

FUNCTION PadCh(S : String; C : Char; Len : Byte) : String;
    {-Return: String S der rechts mit C aufgefÅllt wird bis er Len Zeichen
	      lang ist}

FUNCTION Pad(S : String; Len : Byte) : String;
  {-wie PadCh, es wird mit Leerzeichen aufgefÅllt}

FUNCTION LeftPadCh(S : String; C : Char; Len : Byte) : String;
    {-Return: String S der links mit C aufgefÅllt wird bis er Len Zeichen
	      lang ist}

FUNCTION LeftPad(S : String; Len : Byte) : String;
  {-wie LeftPadCh, es werden Leerzeichen voran gestellt}

FUNCTION LTrim(S : String) : String;
  {-Leerzeichen am Ende des Strings werden entfernt}

FUNCTION RTrim(S : String) : String;
  {-entfernt fÅhrende Leerzeichen}

FUNCTION Trim(S : String) : String;
  {-Entfernt Leerzeichen am Beginn und am Ende eines Strings}

FUNCTION CenterCh(S : String; Ch : Char; Len : Byte) : String;
  {-Return: String in dem S zentriert ist und von Ch eingeschlossen wird.
    Die GesamtlÑnge ergibt sich aus Len.}

FUNCTION Center(S : String; Len : Byte) : String;
  {-Wie CenterCh, es werden Leerzeichen aufgefÅllt}

FUNCTION Entab(S : String; TabSize : Byte) : String;
  {-Konvertiert Leerzeichen in einem string zu Tabs, TAB=' '*TabSize}

FUNCTION Detab(S : String; TabSize : Byte) : String;
  {-Erweitert Tabs in einem String zu Leerzeichen}

FUNCTION  SpNumber (N : Longint) : String;
  {-Zahlen werden mit TausenderPunkten dargestellt}

FUNCTION  Crypt(S: String)  : String;
  {-Ver- und EntschlÅsselt einen String}

  {------------- Zeichenkettenvergleich und Zeichenkettensuche ------------}
TYPE
  CompareType = (Less, Equal, Greater);

FUNCTION CompString(S1, S2 : String) : CompareType;
  {-Return: less, equal, greater if s1<s2, s1=s2, or s1>s2}

FUNCTION CompUCString(S1, S2 : String) : CompareType;
  {-Compare two strings in a case insensitive manner}
  { BerÅcksichtigt deutsche Umlaute bei der Umwandlung in Gro·buchstaben}

FUNCTION CompStruct(VAR S1, S2; Size : Word) : CompareType;
  {-Compare two fixed size structures}

FUNCTION  CompName      (S1,S2 : PathStr) : boolean;
  {-Compare just then Name of two FileNames}

FUNCTION  CompExtension (S1,S2 : PathStr) : boolean;
  {-Compare the Extension of two Filenames}

FUNCTION  CompFileName  (S1,S2 : PathStr) : boolean;
  {-Compare two whole Filenames}

FUNCTION Search(VAR Buffer; BufLength : Word;
                VAR Match; MatLength : Word) : Word;
  {-Search through Buffer for Match. BufLength is length of range to search.
    MatLength is length of string to match. Returns number of bytes searched
    to find Match, $FFFF if not found.}

FUNCTION SearchUC(VAR Buffer; BufLength : Word;
                  VAR Match; MatLength : Word) : Word;
  {-Search through Buffer for Match, CASE-INSENSITIVE.
    Otherwise same as Search.}
  { BerÅcksichtigt Umlaute}

PROCEDURE BMMakeTable(MatchString : String; VAR BT : BTable);
  {-Build Boyer-Moore link table}

FUNCTION BMSearch(VAR Buffer; BufLength : Word;
                  BT : BTable; MatchString : String) : Word;
  {-Search Buffer for MatchString. BufLength is length of range to search.
    Returns number of bytes searched to find MatchString, $FFFF if not found}

FUNCTION BMSearchUC(VAR Buffer; BufLength : Word;
                    BT : BTable; MatchString : String) : Word;
  {-Search Buffer for MatchString, CASE-INSENSITIVE.
    Assumes MatchString is already in uppercase.
    Otherwise same as BMSearch}

FUNCTION Soundex(S : String) : String;
  {-Return 4 character soundex of input string}

FUNCTION MakeLetterSet(S : String) : LongInt;
  {-Return a bit-mapped long storing the individual letters contained in S}

FUNCTION CompareLetterSets(Set1, Set2 : LongInt) : Word;
  {-Returns the sum of the values of the letters common to Set1 and Set2}


  {----- dynamische Stringablage  auf dem Heap ------}

FUNCTION StringToHeap(S : String) : Pointer;
  {-S wird auf den Heap gelegt, der Pointer wird zurÅckgegeben}

FUNCTION StringFromHeap(P : Pointer) : String;
  {-RÅckgabe des Strings auf der Adresse P}

PROCEDURE DisposeString(P : Pointer);
  {-Freigabe des Platzes ab P}


  {--------------- DOS pathname parsing -----------------}

FUNCTION DefaultExtension(Path : PathStr; Exten : ExtStr) : PathStr;
  {-Return a file name with a default extension attached}

FUNCTION ForceExtension(Path : PathStr; Exten : ExtStr) : PathStr;
  {-Force the specified extension onto the file name}

Function JustName(Path : PathStr) : NameStr;
  {-Return just the name of a filename}

FUNCTION JustFilename(Path : PathStr) : FileNameStr;
  {-Return just the filename and extension of a pathname}

FUNCTION JustExtension(Path : PathStr) : ExtStr;
  {-Return just the extension of a pathname}

FUNCTION JustPathname(Path : PathStr) : DirStr;
  {-Return just the drive:directory portion of a pathname}

FUNCTION AddBackSlash(Dir : DirStr) : DirStr;
  {-Add a default backslash to a directory name}

FUNCTION CleanPathName(Path : String) : PathStr;
  {-Return a pathname cleaned up as DOS will do it}

FUNCTION GenNewPathName(PathOld, PathIn : DirStr) : DirStr;
  {-create a new pathname from old pathname and pathin}

FUNCTION ShrinkPath(Path:PathStr; Plength:byte) : Pathstr;
  {-compress the pathname with dots}

PROCEDURE Beep(k:byte);
  {-gibt ein akustisches Signal}

  {----------------- Integer manipulation ----------------}
FUNCTION  Upword (Wort:word) : word;

PROCEDURE Reverse(Var l:LongInt);






Var
 OldDir       : DirStr;
 FullPathName : FUNCTION (FName : PathStr) : PathStr;
 Regs         : Registers;
  {-Given FName (known to exist), return a full pathname}

  {==========================================================================}

IMPLEMENTATION



TYPE
  Long = RECORD
           LowWord, HighWord : Word;
         END;
CONST
  Digits : ARRAY[0..$F] OF Char = '0123456789ABCDEF';
  DosDelimSet : SET OF Char = ['\', #0];


{------------------------- Numerik-Konvertierung -------------------------}
{$L HBHEX.OBJ}
  FUNCTION HexB(B : Byte) : String; EXTERNAL;  {HBHEX.OBJ}
    {-Return: Hex-String des Bytes}
(*  BEGIN
    HexB[0] := #2;
    HexB[1] := Digits[B SHR 4];
    HexB[2] := Digits[B AND $F];
  END;*)

{------------------------------------------------------------------}
  FUNCTION HexW(W : Word) : String; EXTERNAL;  {HBHEX.OBJ}
    {-Return: Hex-String des Wortes}
(*  BEGIN
    HexW[0] := #4;
    HexW[1] := Digits[hi(W) SHR 4];
    HexW[2] := Digits[hi(W) AND $F];
    HexW[3] := Digits[lo(W) SHR 4];
    HexW[4] := Digits[lo(W) AND $F];
  END;*)

{------------------------------------------------------------------}
  FUNCTION HexL(L : LongInt) : String; EXTERNAL;  {HBHEX.OBJ}
    {-Return: Hex-String des LongInt-Wertes}
(*  BEGIN
    WITH Long(L) DO
      HexL := HexW(HighWord)+HexW(LowWord);
  END;*)

{------------------------------------------------------------------}
  FUNCTION HexPtr(P : Pointer) : String; EXTERNAL;  {HBHEX.OBJ}
    {-Return: Hex-String des Pointers}
(*  BEGIN
    HexPtr := HexW(Seg(P^))+':'+HexW(Ofs(P^));
  END;*)

{------------------------------------------------------------------}
{$L HBBINARY.OBJ}
  FUNCTION Binary(L : LongInt; Bits : Byte)
   : String; EXTERNAL;  {HBBINARY.OBJ}
    {-Die in BITS angegebene Anzahl Bits (Rechts beginnend) werden
      im String dargestellt}
(*  VAR
    I : Byte;
  BEGIN
    Binary[0] := char(Bits);
    FOR I := Bits DOWNTO 1 DO BEGIN
      Binary[I] := char((L AND 1)+$30); {0 or 1}
      L:=L SHR 1;
    END;
  END;*)

{------------------------------------------------------------------}
FUNCTION Form(Maske : String; R: Real) : String;
 { Wandelt reelle Zahl r in einen formatierten String um.
   Die Maske darf folgende Zeichen enthalten:
   '#' : Vornullen werden an dieser Stelle nicht ausgegeben
   '@' : Vornullen werden mit dargestellt
   '*' : Vornullen werden als '*' dargestellt
   '=' : Vornullen werden als '=' dargestellt
   '%' : Vornullen werden als '%' dargestellt
   '-',
   '+' : das Vorzeichen wird an dieser Stelle ausgegeben, '+' steht fÅr die
	 expliziete Ausgabe von + als positives Vorzeichen
   '.',
   ',' : Legen die Position des Dezimalpunktes fest.

   Alle anderen Zeichen in der Maske werde unverÑndert Åbernommen}

LABEL Ende,Exit,Exit1;

CONST
  FZch    = '#@*=%.,';
  Ziffer  = '#';
  VorNull = '@';
  VNZ1    = '*';
  VNZ2    = '=';
  VNZ3    = '%';
  DP1     = '.';
  DP2     = ',';
  PlusZ   = '+';
  MinusZ  = '-';

VAR
  S: String;
  Plus, Minus, NeedMinus, Negativ: Boolean;
  BegFld, EndFld, PosPkt, AnzDig, Stellen, PosVZ: Byte;
  I, J: Word;


BEGIN
  IF LENGTH(Maske) = 0 THEN
    GOTO EXIT1;

  PosPkt    := 0;
  Stellen   := 0;
  AnzDig    := 0;
  BegFld    := 1;
  NeedMinus := False;

  Negativ:=(R<0);
  PosVZ:=POS(MinusZ,Maske);
  IF PosVZ=0 THEN BEGIN
   PosVZ:=POS(PlusZ,Maske);
   NeedMinus:=PosVZ=0
  END;
  IF not NeedMinus then R:=ABS(R);
  WHILE (BegFld<=LENGTH(Maske)) AND (POS(Maske[BegFld],FZch)=0) DO
    Inc(BegFld);
  IF BegFld > LENGTH(Maske) THEN
    GOTO EXIT;
  FOR EndFld:=BegFld TO LENGTH(Maske) DO
   CASE Maske[EndFld] OF
    Ziffer,
    VorNull,
    VNZ1,
    VNZ2,
    VNZ3  : Inc(AnzDig);
    DP1,
    DP2   : PosPkt:=EndFld;
    ELSE
      GOTO ENDE;
  END;
  Inc(EndFld);

ENDE:
  Dec(EndFld);
  IF PosPkt>0 THEN BEGIN
    Stellen:=EndFld-PosPkt; Inc(AnzDig)
  END;

  Str(R:AnzDig:Stellen, S);

  IF (LENGTH(S) > AnzDig) THEN                     { To Big }
    BEGIN
      FOR I:=BegFld TO EndFld DO
        CASE Maske[I] OF
	  Ziffer,
	  VorNull,
	  VNZ1,
	  VNZ2,
	  VNZ3  : Maske[I] := '*';
        END;
      GOTO EXIT;
    END
    ELSE BEGIN
      J:=1;
      FOR I := BegFld TO EndFld DO
        CASE Maske[I] OF
	  Ziffer : BEGIN Maske[I]:=S[J]; Inc(J) END;
	  VorNull: BEGIN
		    IF S[J]=' ' THEN Maske[I]:='0' ELSE Maske[I]:=S[J];
		    Inc(J)
		   END;
	  VNZ1,
	  VNZ2,
	  VNZ3   : BEGIN
		    IF S[J]<>' ' THEN Maske[I]:=S[J];
		    Inc(J)
		   END;
	  DP1,
	  DP2    : IF S[J]='.' THEN Inc(J);
	END;
    END;
EXIT:
    IF not NeedMinus THEN
     IF Maske[PosVZ]=PlusZ THEN
       IF Negativ THEN Maske[PosVZ] := '-' ELSE Maske[PosVZ] := '+'
     ELSE
       IF Negativ THEN Maske[PosVZ] := '-' ELSE Maske[PosVZ] := ' ';
EXIT1:
  Form := Maske;
END;

{------------------------------------------------------------------}
{$L HBTIMEST.OBJ}
FUNCTION TimeStr(TimeMS:LongInt; hmsh:Byte) : String;
 EXTERNAL; {HBTIMEST.OBJ}
  {-Gibt TimeMs (Zeit in Millisekunden) formatiert aus
    hmsz=1: nur Stunden
         2: HH:MM
         3: HH:MM:SS
	 4: HH:MM:SS.hh }
(*
CONST
  Trennzeichen:ARRAY[1..4] OF Char=(' ',':',':','.');
  Divisor:ARRAY[0..4] OF Longint=(24,60,60,100,10);

VAR
  HStr: String[12];
  WStr: String[2];
  P   : Byte;

BEGIN {FUNCTION TimeStr}
  HStr:='';
  FOR P:=4 DOWNTO 1 DO BEGIN
    TimeMS:=TimeMS DIV Divisor[P];
    Str(TimeMS MOD Divisor[P-1]:2,WStr);
    IF (WStr[1]=' ') AND (P<>1) THEN WStr[1]:='0';
    IF P<=hmsh THEN HStr:=Trennzeichen[P]+WStr+HStr;
  END;
  DELETE(HStr,1,1); TimeStr:=HStr
END; {FUNCTION TimeStr}*)
 {------------------------------------------------------------------}
{$L HBDATEST.OBJ}
FUNCTION DateStr: String; EXTERNAL;{HBDATEST.OBJ}
{ Datum im Format DD.MM.JJ }
(*VAR MonDay,Year,loop: Word;
    S2: String[2];
    S: String;
BEGIN
  INLINE($B4/$2A / $CD/$21 /
	 $89/$8E/>Year / $89/$96/>MonDay);       {GETDATE(Year,Mon,Day,Wkd);}
  Str(lo(MonDay):2,S);
  Str(hi(MonDay):2,S2);
  S := S + '.' + S2;
  Str((Year MOD 100):2,S2);
  S := S + '.' + S2;
  FOR loop := 1 TO 8 DO IF S[loop] = ' ' THEN S[loop] := '0';
  DateStr := S;
END;*)
 {------------------------------------------------------------------}

{--------------------- einfache Stringmanipulationen --------------------}
{$L HBCASE.OBJ}

  FUNCTION Upcase(C : Char) : Char; external {HBCASE} ;
(*
  BEGIN
    CASE C OF
      'Ñ': Upcase:='é';
      'î': Upcase:='ô';
      'Å': Upcase:='ö';
      ELSE Upcase:=System.Upcase(C)
    END
  END;*)

{------------------------------------------------------------------------}
 FUNCTION LoCase(C : Char) : Char; external {HBCASE} ;
   {-Return Kleinbuchstabe von Ch, berÅcksichtigt auch Umlaute}
(*
  BEGIN
    CASE C OF
      'é': Locase:='Ñ';
      'ô': Locase:='î';
      'ö': Locase:='Å';
      ELSE
       IF (C>='A') AND (C<='Z')
	THEN LoCase:=Char(ord(C)+32)
	ELSE LoCase:=C;
    END
  END;*)


{------------------------------------------------------------------}
  FUNCTION UpString(S : String) : String;  EXTERNAL {HBCASE} ;
(*  VAR I : Byte;
  BEGIN
   UpString[0]:=S[0];
   FOR I:=1 TO LENGTH(S) DO UpString[I]:=Upcase(S[I]);
  END;*)

{------------------------------------------------------------------}
  FUNCTION LoString(S : String) : String; EXTERNAL {HBCASE} ;
(*  VAR I : Byte;
  BEGIN
   LoString[0]:=S[0];
   FOR I:=1 TO LENGTH(S) DO LoString[I]:=Locase(S[I]);
  END;*)

{------------------------------------------------------------------}
{$L HBCLRSTR.OBJ}
 PROCEDURE ClrStr(var S : String; Len : Byte); External {HBCLRSTR.OBJ} ;
(*
 BEGIN
  FillChar(S[1],Len,' ');
  S[0]:=Char(Len)
 END;*)

{------------------------------------------------------------------}
{$L HBPAD.OBJ}
  FUNCTION PadCh(S : String; C : Char; Len : Byte) : String;
  External {HBPAD.OBJ} ;
    {-Return: String S der rechts mit C aufgefÅllt wird bis er Len Zeichen
	      lang ist}
(*  VAR
    o : String;
  BEGIN
    IF LENGTH(S) >= Len THEN
      PadCh := S
    ELSE BEGIN
      o[0] := Char(Len);
      Move(S[1], o[1], LENGTH(S));
      FILLCHAR(o[Succ(LENGTH(S))], Len-LENGTH(S), C);
      PadCh := o;
    END;
  END;*)

{------------------------------------------------------------------}
  FUNCTION Pad(S : String; Len : Byte) : String;
  EXTERNAL {HBPAD.OBJ} ;
    {-wie PadCh, es wird mit Leerzeichen aufgefÅllt}
(*  BEGIN
    Pad := PadCh(S, ' ', Len);
  END;*)

{------------------------------------------------------------------}
{$L HBLEFTP.OBJ}
  FUNCTION LeftPadCh(S : String; C : Char; Len : Byte) : String;
  EXTERNAL {HBLEFTP.OBJ} ;
    {-Return: String S der links mit C aufgefÅllt wird bis er Len Zeichen
	      lang ist}
(*  VAR
    o : String;
  BEGIN
    IF LENGTH(S) >= Len THEN
      LeftPadCh := S
    ELSE BEGIN
      o[0] := Char(Len);
      Move(S[1], o[Succ(Len)-LENGTH(S)], LENGTH(S));
      FILLCHAR(o[1], Len-LENGTH(S), C);
      LeftPadCh := o;
    END;
  END;*)

{------------------------------------------------------------------}
  FUNCTION LeftPad(S : String; Len : Byte) : String;
  EXTERNAL {HBLEEFTP.OBJ} ;
    {-wie LeftPadCh, es werden Leerzeichen voran gestellt}
(*  BEGIN
    LeftPad := LeftPadCh(S, ' ', Len);
  END;*)

{------------------------------------------------------------------}
{$L HBTRIM.OBJ}
  FUNCTION LTrim(S : String) : String; EXTERNAL {HBTRIM.OBJ} ;
    {-Leerzeichen am Ende des Strings werden entfernt}
(*  BEGIN
    WHILE (LENGTH(S) > 0) AND (S[1] = ' ') DO
      Delete(S, 1, 1);
    LTrim := S;
  END;*)

{------------------------------------------------------------------}
  FUNCTION RTrim(S : String) : String; EXTERNAL {HBTRIM.OBJ} ;
    {-Leerzeichen am Ende des Strings werden entfernt}
(*  BEGIN
    WHILE (LENGTH(S) > 0) AND (S[LENGTH(S)] = ' ') DO
      DEC(S[0]);
    RTrim := S;
  END;*)

{------------------------------------------------------------------}
 FUNCTION Trim(S : String) : String; EXTERNAL {HBTRIM.OBJ} ;
    {-Return a string with leading and trailing white space removed}
(*  BEGIN
    WHILE (LENGTH(S) > 0) AND (S[LENGTH(S)] = ' ') DO
      DEC(S[0]);

    WHILE (LENGTH(S) > 0) AND (S[1] = ' ') DO
      Delete(S, 1, 1);

    Trim := S;
  END;*)

{------------------------------------------------------------------}
  FUNCTION CenterCh(S : String; Ch : Char; Len : Byte) : String;
    {-Return: String in dem S zentriert ist und von Ch eingeschlossen wird.
      Die GesamtlÑnge ergibt sich aus Len.}
  VAR
    o : String;
  BEGIN
    IF LENGTH(S) >= Len THEN
      CenterCh := S
    ELSE BEGIN
      o[0] := Chr(Len);
      FILLCHAR(o[1], Len, Ch);
      Move(S[1], o[Succ((Len-LENGTH(S)) SHR 1)], LENGTH(S));
      CenterCh := o;
    END;
  END;

{------------------------------------------------------------------}
  FUNCTION Center(S : String; Len : Byte) : String;
    {-Wie CenterCh, es werden Leerzeichen aufgefÅllt}
  BEGIN
    Center := CenterCh(S, ' ', Len);
  END;

{------------------------------------------------------------------}
  {$L HBTAB.OBJ}
  FUNCTION Entab(S : String; TabSize : Byte) : String;
    EXTERNAL {HBTAB} ;

{------------------------------------------------------------------}
  FUNCTION Detab(S : String; TabSize : Byte) : String;
    EXTERNAL {HBTAB} ;

{-------------------------------------------------------------------------}
function Potenz(bas,ex:longint):longint;
var temp: real;
begin
  temp:=ex*ln(bas);
  potenz:=trunc(Exp(temp));
end;


FUNCTION SpNumber (N:Longint) : String;
var s:string;
    z:integer;
begin
   str(N,s);
   for z:=1 to 3 do
     If ( N Div potenz(10,(3*z)) )>=1  then
       Insert('.', S,length(S)-(z*3+z-2));
   SpNumber:=s;
end;


{-------------------------------------------------------------------------}
FUNCTION Crypt(S: String) : String;
var I : byte;
    st: string;
    zahl : byte;
begin
  st:='';
  For I := 1 To Length(S) Do
  begin
    zahl:=  (Byte(S[I]) xor lo(I));
    st:= concat( st, chr(zahl) );
  end;
  crypt:=st;
end;


{-------------------- Zeichkettenvergleiche -----------------------------}
{$L HBCOMP1.OBJ}
  FUNCTION CompString(S1, S2 : String) : CompareType;
    EXTERNAL {HBCOMP1.OBJ} ;

{------------------------------------------------------------------}
  FUNCTION CompUCString(S1, S2 : String) : CompareType;
    EXTERNAL {HBCOMP1.OBJ} ;
  { BerÅcksichtigt Umlaute bei der Umwandlung von Klein- in Gro·schreibung }

{------------------------------------------------------------------}
  FUNCTION CompStruct(VAR S1, S2; Size : Word) : CompareType;
    EXTERNAL {HBCOMP1.OBJ} ;


{-------------------------------------------------------------------------}
Function sCheck(Mask,Name:String):Boolean;
Var i,j,k:Byte;
    Pile :Array[1..9] of Record a,b:Byte; End;
    PileP:Byte;
    lm:Byte absolute Mask;
    ln:Byte absolute Name;
    Impasse:Boolean;
Begin
     i:=1; j:=1; sCheck:=False; PileP:=0; Impasse:=False;
     Repeat
           if Mask[i]<>'*' then
             if (j<=ln) and ((Mask[i]='?') or (Mask[i]=Name[j]) or
                ((Mask[i]='#') and (Name[j]>='0') and (Name[j]<='9'))) then
             Begin
               Inc(i); Inc(j);
             End else
               Impasse:=True
           else
           Begin
             if i=lm then Begin sCheck:=True; Exit; End else
             Begin
               k:=j;
               While (k<=ln) and (Name[k]<>Mask[i+1]) and
                     (Mask[i+1]<>'?') and
                     ((Mask[i+1]<>'#') or not (Name[k] in ['0'..'9']))
                     do Inc(k);
               if k<=ln then
               Begin
                 Inc(PileP);
                 With Pile[PileP] do
                 Begin
                   a:=i; b:=Succ(k);
                 End;
                 Inc(i,2); j:=Succ(k);
                 if j>ln then
                   if (i=lm) and (Mask[i]='*')
                     then Inc(i) else Impasse:=True;
               End else Impasse:=True;
             End;
           End;

           if (i>lm) then if (j>ln) then
           Begin
             sCheck:=True; Exit;
           End else
             Impasse:=True;

           if Impasse then
             if PileP>0 then
             Begin
               With Pile[PileP] do
               Begin
                 i:=a; j:=b;
               End;
               Dec(PileP);
               Impasse:=False;
               if j>ln then Exit;
             End else Exit;
           {EndIF}
     Until false;
End;





{-------------------------------------------------------------------------}
FUNCTION CompExtension (S1,S2:PathStr):boolean;
begin
   CompExtension:=Scheck(upstring(justextension(S1)),upstring(justextension(S2)));
end;

{-------------------------------------------------------------------------}
FUNCTION CompName (S1,S2:PathStr):boolean;
begin
   CompName:=Scheck(upstring(justname(S1)),upstring(justname(S2)));
end;

{-------------------------------------------------------------------------}
FUNCTION CompFileName(S1,S2:PathStr):boolean;
begin
   CompFileName:=Scheck(upstring(justFilename(S1)),upstring(justFilename(S2)));
end;


{------------------------------------------------------------------}
{$L HBSEARCH.OBJ}
  FUNCTION Search(VAR Buffer; BufLength : Word;
                  VAR Match; MatLength : Word) : Word;
    EXTERNAL {HBSEARCH} ;

{------------------------------------------------------------------}
  FUNCTION SearchUC(VAR Buffer; BufLength : Word;
                    VAR Match; MatLength : Word) : Word;
    EXTERNAL {HBSEARCH} ;
  { BerÅcksichtigt Umlaute}

{------------------------------------------------------------------}
{$L HBBM.OBJ}
  PROCEDURE BMMakeTable(MatchString : String; VAR BT : BTable);
    EXTERNAL {HBBM} ;

{------------------------------------------------------------------}
  FUNCTION BMSearch(VAR Buffer; BufLength : Word;
                    BT : BTable; MatchString : String) : Word;
    EXTERNAL {HBBM};

{------------------------------------------------------------------}
  FUNCTION BMSearchUC(VAR Buffer; BufLength : Word;
                    BT : BTable; MatchString : String) : Word;
    EXTERNAL {HBBM};

{------------------------------------------------------------------}
{$L HBCOMP2.OBJ}
  FUNCTION Soundex(S : String) : String;
    EXTERNAL {HBCOMP2};

{------------------------------------------------------------------}
  FUNCTION MakeLetterSet(S : String) : LongInt;
    EXTERNAL {HBCOMP2};

{------------------------------------------------------------------}
  FUNCTION CompareLetterSets(Set1, Set2 : LongInt) : Word;
    EXTERNAL {HBCOMP2};


{------------ String dynamically allocated on the heap -------------}
  FUNCTION StringToHeap(S : String) : Pointer;
    {-Allocate space for s and return pointer}
  VAR
    L : Word;
    P : Pointer;
  BEGIN
    L := Succ(LENGTH(S));
    IF MaxAvail < L THEN
      StringToHeap := NIL
    ELSE BEGIN
      GetMem(P, L);
      String(P^) := S;
      StringToHeap := P;
    END;
  END;

{------------------------------------------------------------------}
  FUNCTION StringFromHeap(P : Pointer) : String;
    {-Return string at p}
  BEGIN
    IF P = NIL THEN
      StringFromHeap := ''
    ELSE
      StringFromHeap := String(P^);
    {ENDIF}
  END;

{------------------------------------------------------------------}
  PROCEDURE DisposeString(P : Pointer);
    {-Deallocate space for string at p}
  BEGIN
    IF P <> NIL THEN
      FreeMem(P, Succ(Byte(P^)));
    {ENDIF}
  END;


{---------------------- DOS pathname parsing ------------------------}
  FUNCTION DefaultExtension(Path : PathStr; Exten : ExtStr) : PathStr;
    {-Return a pathname with the specified extension attached}
  VAR
    Dir   : DirStr;
    Name  : NameStr;
    Ext   : ExtStr;
  BEGIN
    FSplit(Path, Dir, Name, Ext);
    IF Ext <> '' THEN
      DefaultExtension := Path
    ELSE
      DefaultExtension := concat(Path,Exten);
  END;

{------------------------------------------------------------------}
  FUNCTION ForceExtension(Path : PathStr; Exten : ExtStr) : PathStr;
    {-Return a pathname with the specified extension attached}
  VAR
    Dir   : DirStr;
    Name  : NameStr;
    Ext   : ExtStr;
  BEGIN
    FSplit(Path, Dir, Name, Ext);
    ForceExtension := concat(Dir,Name,Exten);
  END;

{------------------------------------------------------------------}
  Function JustName(Path : PathStr) : NameStr;
  {-Return just then name of a filename}
  VAR
    Dir   : DirStr;
    Name  : NameStr;
    Ext   : ExtStr;
  BEGIN
    If Path[1]<>'.' then
    begin
      FSplit(Path, Dir, Name, Ext);
      JustName := Name;
    end else
      JustName := Path;
  END;

{------------------------------------------------------------------}
  FUNCTION JustExtension(Path : PathStr) : ExtStr;
    {-Return just the extension of a pathname}
  VAR
    Dir   : DirStr;
    Name  : NameStr;
    Ext   : ExtStr;
  BEGIN
    FSplit(Path, Dir, Name, Ext);
    delete(Ext,1,1);
    JustExtension := Rtrim(Ext);
  END;

{------------------------------------------------------------------}
  FUNCTION JustFileName(Path : PathStr) : FileNameStr;
    {-Return just then filename of a pathname}
  VAR
    Dir   : DirStr;
    Name  : NameStr;
    Ext   : ExtStr;
  BEGIN
    FSplit(Path, Dir, Name, Ext);
    JustFilename := concat(Name,Ext);
  END;

{------------------------------------------------------------------}
  FUNCTION JustPathname(Path : PathStr) : DirStr;
    {-Return just the drive:directory portion of a pathname}
  VAR
    Dir   : DirStr;
    Name  : NameStr;
    Ext   : ExtStr;
  BEGIN
    FSplit(Path, Dir, Name, Ext);
    JustPathname := Dir;
  END;

{------------------------------------------------------------------}
  FUNCTION AddBackSlash(Dir : DirStr) : DirStr;
    {-Add a default backslash to a directory name}
  BEGIN
    IF Dir[LENGTH(Dir)] IN DosDelimSet Then
      AddBackSlash := Dir
    ELSE
      AddBackSlash := concat(Dir,'\');
  END;

{------------------------------------------------------------------}
  FUNCTION CleanPathName(Path : String) : PathStr;
    {-Return a pathname cleaned up as DOS will do it}
  VAR
    I     : Word;
    oname : String;
    Dir   : DirStr;
    Name  : NameStr;
    Ext   : ExtStr;
  Begin
    oname := '';
    I := Succ(LENGTH(Path));

    REPEAT
      {Get the next directory or drive portion of pathname}
      REPEAT
        DEC(I);
      UNTIL (I <=0) OR (Path[I] IN DosDelimSet);

      {Clean it up and prepend it to output string}
      FSplit(Copy(Path, Succ(I), 64), Dir, Name, Ext);
      oname := concat(Dir,Name,Ext,oname);
      IF I > 0 THEN BEGIN
        oname := concat(Path[I],oname);
        Delete(Path, I, 255);
      END{IF};
    UNTIL I <= 0;
    CleanPathName := oname;
  END;

{------------------------------------------------------------------}
  FUNCTION GenNewPathName(PathOld, PathIn : DirStr) : DirStr;
    {-create a new pathname from old pathname and pathin}
  VAR
    MerkDir  : DirStr;
    OldDrive : DirStr;
    NewDrive : DirStr;
    Ret      : DirStr;
    I        : Byte;
  BEGIN
    GetDir(0, MerkDir);                          {aktuelles Verz. merken}
    Ret := ''; OldDrive := ''; NewDrive := '';   {clear strings}
    I := Pos(':', PathOld);                      {Lw PathOld ermitteln}
    IF I > 0 Then Begin
      OldDrive := Copy(PathOld, 1, I);
      PathOld  := Copy(PathOld, Succ(I), 67);
    End{I};
    I := Pos(':', PathIn);                       {Lw PathIn ermitteln}
    IF I > 0 Then Begin
      NewDrive := Copy(PathIn, 1, I);
      PathIn   := Copy(PathIn, Succ(I), 67);
    End{IF};
    {------ Drive test ---------------------}
    IF NewDrive = '' Then Begin
      Ret := OldDrive;
      IF PathIn[1] = '\' Then
        Ret := concat(Ret,PathIn)
      Else
        Ret := concat(Ret,AddBackSlash(PathOld),PathIn)
      {EndIF}
    End
    Else
      IF PathIn[1] = '\' Then
        Ret := concat(NewDrive,PathIn)
      Else Begin
        ChDir(NewDrive);
        GetDir(0, Ret);
        Ret := concat(AddBackSlash(Ret),PathIn);
      End{IF};
    {EndIF}
    ChDir(MerkDir);                              {ursprÅngl. Verz. setzen}
    GenNewPathName := Ret;
  End;

{-------------------------------------------------------------------------}
FUNCTION ShrinkPath(Path:PathStr; Plength:byte) : Pathstr;
var en:PathStr;
 begin
   Path:=trim(Path);
   if length(Path)>Plength then
   begin
      If Path[2]=':' then
      begin
        en:=copy(Path,4,length(Path)-3);
        delete(en,1,length(en)-(Plength-6));
        delete(Path,4,length(Path)-3);
        ShrinkPath:=concat(Path,'...',en);
      end else
      begin
        delete(Path,1,length(Path)-(Plength-3));
        ShrinkPath:=concat('...',Path);
      end;
   end else
    ShrinkPath:=Path;
 end;



{-------------------------------------------------------------------------}
PROCEDURE Beep(k:byte);
var s:word;
begin
  case k of
   1: begin
        for s:=10 to 1000 do
        begin
         sound(trunc(sin(s)+1)*s);
         if s/100=trunc(s/100) then
          delay(1);
        end;
        for s:=1000 downto 10 do
        begin
         sound(trunc(sin(s)+1)*s);
         if s/100=trunc(s/100) then
            delay(1);
        end;
      end;
    end;
    nosound;
end;


{-------------------------------------------------------------------------}
function  upword (Wort:word): word;
begin
   If (Wort<123) and (Wort>96) then
   begin
     upword:=byte(upcase(char(Wort)));
   end else
     upword:=Wort;
end;


{-------------------------------------------------------------------------}
Procedure Reverse(Var l:LongInt);
Var l1:LongInt;
Begin
     l1:=((l and $FF000000) shr 24) or ((l and $00FF0000) shr 8) or
         ((l and $0000FF00) shl 8)  or ((l and $000000FF) shl 24);
     l:=l1;
End;




BEGIN
END.