{****************************************************************}
{                                                                }
{                        Helpcompiler                            }
{                Copyright 1994 by Thomas Knîfel                 }
{                                                                }
{****************************************************************}

program HelpCompiler;
uses tkstring,tkstream,init;

const MagicHeader  : longint = $32504f54; {TOP2}
      first        : boolean = true;


type

 Helprec  = record
        Number     : word;
        Topic      : record end;
        TextCount  : word;
        Text       : record end;
        jump       : word;
   end;


var
  fin     : textstream;
  fout    : typedstream;
  zeile   : string;
  z       : byte;
  tword   : string[5];
  s       : Helprec;
  Code    : Integer;
  ZeileCop: string;
  MPosTC  : longint;
  MHelp   : Helprec;
  jump_pos: byte;

begin
  If (paramstr(1)='') or (paramstr(2)='') then
  begin
    write('Syntax: help_com  quelldatei zieldatei'); halt(1);
  end;

  Fin.Init(paramstr(1));
  Fin.Open;
  Fout.Init(paramstr(2), Sizeof(Byte) );
  Fout.Create;

  Fout.Write(Magicheader,0,SizeOf(Magicheader));
  while not Fin.EOF do
  begin
    Fin.Readln(zeile); Zeile:=Rtrim(Zeile);
    case zeile[1] of
    '.' : begin
            delete(zeile,pos(Zeile,'.')+1,1);
            Zeile:=trim(Zeile);
            tword:='';
            for z:=1 to pos(' ',Zeile)-1 do                   { Number }
              tword:=tword+Zeile[z];
            Val(tword, S.Number, Code);
            If Code > 0 then
            begin
              Fout.close; Fin.close;
              write('Keine Nummer in Topic angegeben; Zeile:',Zeile); halt(3);
            end;
            Fout.Write(S.Number,Fout.Pos,Sizeof(S.Number));
            delete(zeile,1,Pos(' ',Zeile));
            Zeile:=trim(Zeile);                               { Topic }
            delete(Zeile,Sizeof(S.Topic),length(Zeile)-Sizeof(S.Topic)-1);
            Fout.write(Zeile,Fout.Pos,length(Zeile)+1);
            If not first then
              Fout.write(S.TextCount,MPosTC, SizeOf(S.TextCount));
            S.Textcount:=0; MPosTC:=Fout.Size;
            Fout.write(S.TextCount,MPosTC, SizeOf(S.TextCount));
            first:=false;
          end;
    ';' : begin end;
    else  begin
            inc(S.TextCount); rtrim(Zeile); MHelp.jump:=0;
            If (Pos('{',Zeile)>0) and (Pos('}',Zeile)>0) and (Pos(':',Zeile)>0) and
               (Pos('{',Zeile)<Pos('}',Zeile)) then
            begin
              ZeileCop:=Zeile;              {falls ':' schon vor { }
              While Pos('{',ZeileCop) > Pos(':',ZeileCop) do
                ZeileCop[Pos(':',ZeileCop)]:=' ';
              {EndWhile}
              Jump_Pos:=Pos(':',ZeileCop)+1;
              ZeileCop:=copy(ZeileCop,Jump_Pos,Pos('}',ZeileCop)-Jump_Pos);
              ZeileCop:=trim(ZeileCop);
              Val(ZeileCop,MHelp.Jump,Code);  { Jump }
              If Code > 0 then
              begin
                Fout.close; Fin.close;
                write('Keine Zahl in Crossreferenz; Nr:',S.Number,' Linie:',S.TextCount); halt(4);
              end;
              z:=Pos('{',Zeile);                              { ^h einfÅgen }
              delete(Zeile,z,1); Insert('^c',Zeile,z);
              delete(Zeile,jump_pos,Pos('}',Zeile)-jump_pos);
              z:=Pos('}',Zeile);
              delete(Zeile,z,1); Insert('^c',Zeile,z);
            end;
            Fout.write(Zeile,-1,length(Zeile)+1);
            Fout.write(MHelp.Jump,-1,SizeOf(MHelp.Jump));
          end;
    end;
  end;
  Fout.write(S.TextCount,MPosTC, SizeOf(S.TextCount));
  Fin.Close; Fout.Close;
end.