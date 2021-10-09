   uses crt;
   const ed:longint=1;
         dtcnt=6500;
   var
       header:array [0..$3D] of byte;
       DataArr:array[1..dtcnt] of byte;
       OutArr:array[1..dtcnt] of byte;
       fprn,fbmp:file;
       fnb,fnp:string;

  procedure WriteHeader(maxl,maxy:word);
   var i:word;
       fsz:longint;
    begin
    fsz:=(((maxl-1) div 32+1)*ed*32*maxy);
    for i:=2 to $3D do header[i]:=0;
    header[0]:=$42;
    header[1]:=$4D;
    fsz:=fsz+62;
    header[4]:=trunc(fsz/65536);
    fsz:=fsz-longint(header[4]*65536);
    header[3]:=fsz div 256;
    fsz:=fsz-word(header[3]*256);
    header[2]:=fsz;
    header[$13]:=maxl div 256;
    header[$12]:=maxl mod 256;
    maxy:=maxy*8;
    header[$17]:=maxy div 256;
    header[$16]:=maxy mod 256;
    header[$0A]:=$3E;
    header[$0E]:=$28;
    header[$1A]:=$1;
    header[$1C]:=$1;
    header[$3A]:=$FF;
    header[$3B]:=$FF;
    header[$3C]:=$FF;
    assign(fbmp,fnb);
    rewrite(fbmp,1);
    blockwrite(fbmp,header,62);
    end;

  function ReadCommand(var Cmd,DataLen:word):boolean;
  {Cmd 2 пер. строки
       1 печ. граф}
   var x:byte;
       res:word;
    begin
    Cmd:=0;
    DataLen:=0;
    blockread(fprn,x,1,res);
    if x=27 then begin
                 blockread(fprn,x,1);
                 case x of
                 $40:Cmd:=$00;
                 $2A:begin
                     Cmd:=$01;
                     blockread(fprn,x,1);
                     blockread(fprn,DataLen,2);
                     DataLen:=DataLen*3;
                     end;
                 $4A:Cmd:=$02;
         $4C,$59,$5A:begin
                     Cmd:=$01;
                     blockread(fprn,DataLen,2);
                     DataLen:=DataLen;
                     end;
                   else Cmd:=0;
                   end;
                 end
            else   case x of
                 $0A:Cmd:=$02;
                 else Cmd:=0;
                    end;
    ReadCommand:=res<>0;
    end;

  function GetPrintData(L:word):boolean;
   var r:word;
    begin
    blockread(fprn,DataArr,l,r);
    GetPrintData:=l=r;
    end;

  var maxl,maxy,l,res,i,j,ind2,ind3,nbt:word;
      Cmd,DL,num,cx,cy:word;
      t,t2,k:byte;
  begin
  fnp:=paramstr(1)+'.prn';
  fnb:=paramstr(1)+'.bmp';
  assign(fprn,fnp);
  {$I-}
  reset(fprn,1);
  if IOresult<>0 then begin
                      writeln(' File not found: ',fnp);
                      halt(1);
                      end;
  writeln;
  write('  Converting ',fnp,' to ',fnb,' ');
  assign(fbmp,fnb);
  rewrite(fbmp,1);
  maxl:=0;
  maxy:=0;
  repeat
  ReadCommand(Cmd,Dl);
  if Cmd=1 then begin
                inc(maxy);
                if maxl<dl then maxl:=dl;
                GetPrintData(dl);
                end;
  until eof(fprn);
  WriteHeader(maxl,maxy);
  nbt:=((maxl-1) div 32+1)*4-1;
  num:=0;
  cx:=whereX;
  cy:=whereY;
  if maxl>0 then begin
                 reset(fprn,1);
                 repeat
                 ReadCommand(Cmd,Dl);
                  case Cmd of
                1:begin
                  GetPrintData(dl);
                  for res:=1 to dl do dataArr[res]:=not DataArr[res];
                  for res:=dl+1 to dtcnt do dataArr[res]:=$FF;
                     for i:=7 downto 0 do
                                  begin
                                  ind2:=i;

                                    for j:=0 to nbt do
                                          begin
                                          k:=$FF;
                                          ind3:=word(j*8);
                                          for l:=7 downto 0 do
                                             begin
                                             t:=1 shl ind2;
                                             t:=dataArr[1+l+ind3] and t;
                                             t2:=1 shl l;
                                             if t=0 then begin
                                                      t2:=not t2;
                                                      k:=k and t2;
                                                      end
                                                 else k:=k or t2;
                                             end;
                                          OutArr[1+nbt-j]:=k;
                                          end;
                                  blockwrite(fbmp,OutArr,nbt+1,res);
                                  end;
                                inc(num);
                                gotoxy(cx,cy);
                                write(trunc(longint(100)*num/maxy):3,'% complete...');
                  end;
                 2:begin
                   end;
                  end;{of case}
                 until eof(fprn);
                 end;
  close(fbmp);
  close(fprn);
  writeln;
  end.