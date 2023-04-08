program vv;
uses TKview,Tkview2,crt,Kbm,Tkstring,Tkvideo;

var tH  : Helpview1;
    tH2 : SelectView1;
    tl  : Listview1;
    i : byte;
    s : string;

begin
 textbackground(black); textcolor(white);
 clrscr;    MouShowMouse; Cursor_OFF;
 {tH2.init(50,15); tH2.SetMarkMode(false);
 for i:=1 to 60 do
 begin
   str(i,s);
   If i in [3,10,15,30,32,33,36,60] then
     tH2.appendHelp('^chall^co                                  '+s,5) else
     tH2.appendHelp('hallo                                  '+s,3);
 end;
 tH2.viewlines;
 tH2.done;}

 {tL.init(5,5,50,20);
 for i:=1 to 60 do
 begin
   str(i,s);
   If i in [3,10,15,30,32,33,36,60] then
     tL.appendLine('^hhall^ho                                  '+s,3,5,i) else
     tL.appendLine('hallo                                  '+s,0,0,0);
 end;
 tL.viewlines;
 tL.done;}

 tH.init(paramstr(1),$32504f54);
 tH.viewpage(1);
 tH.done;
end.