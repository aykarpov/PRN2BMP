  uses crt;
   const ed:longint=1;
   type
        mstr = record
               ln:word;
               dat:array [1..6500] of byte;
               end;
        sstr=array [0..9] of byte;
  var fprn,fbmp:file;
      num,l,maxl,res,i,nbt,j,ind1,ind2,ind3,cnt:word;
      X:mstr;
      ef:boolean;
      header:array [0..$3D] of byte;
      fsz:longint;
      cx,cy,k,t,t2:byte;
      fnp,fnb:string;

  procedure SearchBytes(N:byte;X:sstr;var enab:boolean);
   var
   fs,tx:byte;
   res:word;
    begin
    fs:=0;
    repeat
    blockread(fprn,tx,1,res);
    if (tx=X[fs]) and (res=1) then inc(fs) else fs:=0;
    until (fs=N) or (res=0);
    enab:=fs=n;
    end;

  procedure GetLine(var X:mstr;var ef:boolean);
   var sb:sstr;
       fnd:boolean;
       res:word;
       a:byte;
    begin
    sb[0]:=$1B;
    sb[1]:=$2A;
    sb[2]:=$27;
    ef:=true;
    SearchBytes(3,sb,fnd);
    if fnd then
      begin
    blockread(fprn,X.ln,2,res);
    X.ln:=X.ln*3;
    if res=2 then begin
                  blockread(fprn,X.dat,X.ln,res);
                  ef:=res<>X.ln;
                  blockread(fprn,a,1,res);
                  ef:=ef or (a<>13) or (res<>1);
                  end;
       end;
    end;

  begin
  fnp:=paramstr(1)+'.prn';
  fnb:=paramstr(1)+'.bmp';
  assign(fprn,fnp);
  {$I-}
  reset(fprn,1);
  if IOresult<>0 then begin
                      writeln(' File not found: ',fnp);
                      exit;
                      end;
  writeln;
  write('  Converting ',fnp,' to ',fnb,' ');
  cx:=whereX;
  cy:=whereY;
  maxl:=0;
  res:=0;
  repeat
  inc(res);
  GetLine(X,ef);
  l:=X.ln div 3;
  if not ef then if maxl<l then maxl:=l;
  until ef;
  cnt:=res;
  dec(res);
  if maxl>0 then begin
                 nbt:=((maxl-1) div 32+1)*4-1;
                 fsz:=(((maxl-1) div 32+1)*ed*96*res);
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
                 res:=res*24;
                 header[$17]:=res div 256;
                 header[$16]:=res mod 256;
                 header[$0A]:=$3E;
                 header[$0E]:=$28;
                 header[$1A]:=$1;
                 header[$1C]:=$1;
                 header[$3A]:=$FF;
                 header[$3B]:=$FF;
                 header[$3C]:=$FF;
                 assign(fbmp,fnb);
                 rewrite(fbmp,1);
                 blockwrite(fbmp,header,62,res);
                 if res=62 then begin
                                reset(fprn,1);
                                num:=0;
                                repeat
                                GetLine(X,ef);
                                for res:=1 to X.ln do X.dat[res]:=not X.dat[res];
                                for res:=X.ln+1 to 6500 do X.dat[res]:=$FF;
                                if not ef then
                                for i:=23 downto 0 do
                                  begin
                                  ind1:=(23-i)div 8;
                                  ind2:=i mod 8;
                                    for j:=0 to nbt do
                                          begin
                                          ind3:=word(j*24);
                                          for l:=7 downto 0 do
                                             begin
                                             t:=1 shl ind2;
                                             t:=X.dat[22-l*3+ind1+ind3] and t;
                                             t2:=1 shl l;
                                             if t=0 then begin
                                                      t2:=not t2;
                                                      k:=k and t2;
                                                      end
                                                 else k:=k or t2;
                                             end;
                                          blockwrite(fbmp,k,1,res);
                                          end;
                                  end;
                                inc(num);
                                gotoxy(cx,cy);
                                write(trunc(longint(100)*num/cnt):3,'% complete...');
                                until ef;
                                end;
                 close(fbmp);
                 end;
  close(fprn);
  writeln;
  end.