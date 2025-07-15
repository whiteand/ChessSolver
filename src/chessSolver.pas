{$DEFINE SHOULD_LOG}
Program ChessSolver;
uses crt;
type move = record
              iStart, iEnd, jStart, jEnd, figureStart, figureEnd: integer;
            end;
     mas = array [1..1000] of move;
const n        = 8;
      peshka   = 1;
      loshad   = 2;
      officer  = 3;
      ladya    = 4;
      ferz     = 5;
      korol    = 6;
      bpeshka   = -peshka;
      bloshad   = -loshad;
      bofficer  = -officer;
      bladya    = -ladya;
      bferz     = -ferz;
      bkorol    = -korol;
      white    =  1;
      black    = -1;
      isLog = false;

var field: array [1..n, 1..n] of longint;
    moves: mas;
    countOfPossibleMoves: longint;
    isCheckToWhite, isCheckToBlack: boolean;
    z: longint;
    MakedMoves: mas;

    CountOfMakedMoves: longint =0;
    cVariants: int64 = 0;
    cSolving: int64 = 0;
    maxcountofpossibleMoves: int64 = 0;
    buffer: array [1..20000] of string;
    buffercursor: longint = 0;
    buffermax: longint;
    outfilename: string;
    orientation: integer;
    c: char;
    MoveMarking: integer;
    lastMakedMoves: mas;
    showblack: boolean = true;
    fName: string;
operator =(a,b:move)z:boolean;
begin
  if (a.iStart = b.iStart) and
     (a.jStart = b.jStart) and
     (a.iEnd = b.iEnd) and
     (a.jEnd = b.jEnd) and
     (a.figureStart = b.figureStart) then
     begin
       z:=true;
     end else
     begin
       z:=false;
     end;

end;
operator <>(a,b:move)z:boolean;
begin
  z := not (a = b);
end;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure showHelp;
begin
  textcolor(14);
  writeln('You should to create a file with data');
  textcolor(13);
  writeln('If you use FEN notation then file must be like that: ');
  textcolor(15);
  writeln('First string: Number of moves to make mate(ex: 2)');
  writeln('Second string: FEN string(ex: 3rk3/8/8/8/8/5pPq/R4P1P5QK1)');
  writeln('Third string: first move color(w - white, b - black)');
  writeln(chr(9),'File example');
  writeln('2');
  writeln('3rk3/8/8/8/8/5pPq/R4P1P/5QK1');
  writeln('b');
  textcolor(13);
  writeln('If you are NOT using FEN notation then file must be like that: ');
  textcolor(15);
  writeln('First string: Number of moves to make mate(ex: 2)');
  writeln('Other strings: records with format "Figure horizontal vertical"');
  writeln('For Example: 6 1 3 - means that there is white king at c1 (c - vertical(transformes into 3), 1 - horizontal)');
  writeln(chr(9),'File example');
  writeln('2');
  writeln('-6 1 7');
  writeln('-5 1 6');
  writeln('-1 2 8');
  writeln('6 4 4');
  writeln('2 7 2');

  textcolor(14);
  writeln('Figures codes: ');
  textcolor(15);

  writeln('WHITE');
  textcolor(7);
  writeln('peshka:    ', peshka);
  writeln('loshad:    ', loshad);
  writeln('officer:   ', officer);
  writeln('ladya:     ', ladya);
  writeln('ferz:      ', ferz);
  writeln('korol:     ', korol);
  textcolor(15);
  writeln('BLACK');
  textcolor(7);
  writeln('peshka:   ', -peshka);
  writeln('loshad:   ', -loshad);
  writeln('officer:  ', -officer);
  writeln('ladya:    ', -ladya);
  writeln('ferz:     ', -ferz);
  writeln('korol:    ', -korol);
end;//End showHelp
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure findKorol(color: longint; var i0,j0: longint);
var founded: boolean;
    i,j: longint;
begin
  founded := false;
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin
      if (field[i,j] = korol*color) then
      begin
        founded :=true;
        i0:=i;
        j0:=j;
        break;
      end;
    end;
    if (founded) then break;
  end;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure makeFieldWithFen(s:string);
var k,z, i, j: integer;
procedure next;
  begin
    j:=j+1;
    if(j>8) then
    begin
      j:=1;
      i:=i-1;
    end;
  end;
begin
  i:=8;
  j:=1;
  for k:=1 to length(s) do
  begin
    if (s[k]<>'') and (s[k]<>'/') then
    begin
      if (s[k] in ['1'..'8']) then
      begin
        for z:=1 to ord(s[k]) - ord('0') do
        begin
          field[i,j]:=0;
          next;
        end;
      end else
      if (s[k] = 'K') then
      begin
        field[i,j]:=6;
        next;
      end else
      if (s[k] = 'Q') then
      begin
        field[i,j]:=5;
        next;
      end else
      if (s[k] = 'R') then
      begin
        field[i,j]:=4;
        next;
      end else
      if (s[k] = 'B') then
      begin
        field[i,j]:=3;
        next;
      end else
      if (s[k] = 'N') then
      begin
        field[i,j]:=2;
        next;
      end else
      if (s[k] = 'P') then
      begin
        field[i,j]:=1;
        next;
      end else
      if (s[k] = 'k') then
      begin
        field[i,j]:=-6;
        next;
      end else
      if (s[k] = 'q') then
      begin
        field[i,j]:=-5;
        next;
      end else
      if (s[k] = 'r') then
      begin
        field[i,j]:=-4;
        next;
      end else
      if (s[k] = 'b') then
      begin
        field[i,j]:=-3;
        next;
      end else
      if (s[k] = 'n') then
      begin
        field[i,j]:=-2;
        next;
      end else
      if (s[k] = 'p') then
      begin
        field[i,j]:=-1;
        next;
      end;
    end;
  end;

end;
procedure askField;
var i,j: integer;
    variant: string;
    fen: string;
    fin:text;
    figure: integer;
begin
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin
      field[i,j] := 0;
    end;
  end;

  textcolor(14);
  write('Do you want to use fen notation? ');
  textcolor(7);
  readln(variant);
  textcolor(14);
  write('Enter the file name: ');
  textcolor(7);
  readln(fName);
  assign(fin, fName);
  reset(fin);
  readln(fin,z);

  if (variant = 'y') or (variant = 'Y') or (variant = 'Yes') or (variant = 'YES') or (variant = 'yes') then
  begin
    readln(fin, fen);
    makeFieldWithFen(fen);
    readln(fin, fen);
    if (fen = 'b') or (fen = 'B') then
    begin
      for i:=1 to 8 do
      begin
        for j:=1 to 8 do
        begin
          field[i,j] := -field[i,j];
        end;
      end;
    end;
  end else
  begin
    while not eof(fin) do
    begin
      readln(fin,figure,i,j);
      field[i,j] := figure;
    end;
  end;//end else
  close(fin);
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function GetOutputFileName(_inputFileName: string): string;
begin
  {
  | TODO:
  |  Implement this function to generate different output file name
  |  based on input file name
  }
  Exit('moves_output.txt');
end;
procedure initialize;
var fin   : textfile;
begin
  clrscr;
  showHelp;
  askfield;
  countOfPossibleMoves := 0;
  textcolor(14);
  writeln('Enter buffer size: ');
  textcolor(7);
  readln(buffermax);
  textcolor(14);
  writeln('Enter Y if a1 is at left bottom corner: ');
  textcolor(7);
  readln(c);
  if (c = 'y') or (c = 'Y') then orientation := -1
                            else orientation := 1;

  textcolor(14);
  writeln('Enter how many moves must be marked by empty strings: ');
  textcolor(7);
  readln(MoveMarking);
  textcolor(14);
  writeln('Do you want to see black moves?(y/n): ');
  textcolor(7);
  readln(c);
  showblack := (c = 'y') or (c = 'Y');
  assign(fin, GetOutputFileName(fName));
  rewrite(fin);
  close(fin);
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function colorOf(f: integer): integer;
begin
  if (f>0) then colorOf := 1
           else if (f<0) then colorOf := -1
                         else colorOf := 0;
end;
function getFigureOn(i,j: longint): longint;
begin
  if (i>=1) and (i<=n) and (j>=1) and (j<=n) then
  begin
    getFigureOn := field[i,j];
  end else
  begin
    getFigureOn := 0;
  end;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function searchTo(i0,j0,dn,dm: longint): longint;
var i,j: longint;
    current: longint;
begin
	i := i0 + dn;
	j := j0 + dm;

	current := getFigureOn(i,j);
	if (dn <> 0) or (dm <> 0) then
	begin
		while (current = 0) and (i<=n) and (i>=1) and (j<=n) and (j>=1) do
		begin
			i := i + dn;
			j := j + dm;
			current := getFigureOn(i,j);
		end;
	end;
	searchTo := current;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function isUnderAttackByFigure(figure, i0, j0: longint): boolean;
var res: boolean;
begin
  res := false;
  if (abs(figure) = peshka) then
  begin
    if (figure*orientation > 0) then
    begin
    	if (getFigureOn(i0+1,j0+1) = figure) or (getFigureOn(i0+1,j0-1) = figure) then
    	begin
    		res := true;
    	end;
    end else
    begin
    	if (getFigureOn(i0-1,j0+1) = figure) or (getFigureOn(i0-1,j0-1) = figure) then
    	begin
    		res := true;
    	end;
    end;
  end else
  if (abs(figure) = loshad) then
  begin
  	if ((getFigureOn(i0-2,j0-1) = figure) or
                (getFigureOn(i0-2,j0+1) = figure) or
  		(getFigureOn(i0+2,j0-1) = figure) or
  		(getFigureOn(i0+2,j0+1) = figure) or
  		(getFigureOn(i0-1,j0-2) = figure) or
  		(getFigureOn(i0-1,j0+2) = figure) or
  		(getFigureOn(i0+1,j0-2) = figure) or
  		(getFigureOn(i0+1,j0+2) = figure)) then
  	begin
  		res := true;
  	end
  end else
  if (abs(figure) = officer) then
  begin
  	if (searchTo(i0,j0,-1,-1) = figure) then
  	begin
  		//To The left top
  		res := true;
  	end
  	else if (searchTo(i0,j0,-1,1) = figure) then
  	begin
  		//To The right Top
  		res := true;
  	end
	else if (searchTo(i0,j0,1,-1) = figure) then
  	begin
  		//To the left bottom
  		res := true;
  	end
  	else if (searchTo(i0,j0,1,1) = figure) then
  	begin
	  	//to the right bottom
  		res := true;
  	end;

  end else
  if (abs(figure) = ladya) then
  begin
  	//Search
  	if (searchTo(i0,j0,-1,0) = figure) then
  	begin
  		res := true;
  	end else if (searchTo(i0,j0,1,0) = figure) then
  	begin
  		res := true;
  	end else if (searchTo(i0,j0,0,-1) = figure) then
  	begin
  		res := true;
  	end else if (searchTo(i0,j0,0,1) = figure) then
  	begin
  		res := true;
  	end;

  end else
  if (abs(figure) = ferz) then
  begin
  	//Search
  	if (searchTo(i0,j0,-1,-1) = figure) then
  	begin
  		res := true;
  	end else if (searchTo(i0,j0,-1,0) = figure) then
  	begin
  		res := true;
  	end else if (searchTo(i0,j0,-1,1) = figure) then
  	begin
  		res := true;
  	end else if (searchTo(i0,j0,0,1) = figure) then
  	begin
  		res := true;
  	end else if (searchTo(i0,j0,1,1) = figure) then
  	begin
  		res := true;
  	end else if (searchTo(i0,j0,1,0) = figure) then
  	begin
  		res := true;
  	end else if (searchTo(i0,j0,1,-1) = figure) then
  	begin
  		res := true;
  	end else if (searchTo(i0,j0,0,-1) = figure) then
  	begin
  		res := true;
  	end;
  end else
  if (abs(figure) = korol) then
  begin
  	if ((getFigureOn(i0-1,j0-1) = figure) or
  	    (getFigureOn(i0-1,j0) = figure) or
  	    (getFigureOn(i0-1,j0+1) = figure) or
  	    (getFigureOn(i0,j0-1) = figure) or
  	    (getFigureOn(i0,j0+1) = figure) or
  	    (getFigureOn(i0+1,j0-1) = figure) or
  	    (getFigureOn(i0+1,j0) = figure) or
  	    (getFigureOn(i0+1,j0+1) = figure)) then
  	begin
  		res := true;
  	end
  end;
  isUnderAttackByFigure := res;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function isUnderAttackBy(colorOfattacker, i0, j0: longint): boolean;
var res: boolean;
begin
   res := isUnderAttackByFigure(peshka * colorOfattacker, i0, j0);
   if (not res) then
   begin
     res := isUnderAttackByFigure(loshad * colorOfattacker, i0, j0);
     if (not res) then
     begin
       res := isUnderAttackByFigure(officer * colorOfattacker, i0, j0);
       if (not res) then
       begin
         res := isUnderAttackByFigure(ladya * colorOfattacker, i0, j0);
         if (not res) then
         begin
           res := isUnderAttackByFigure(ferz * colorOfattacker, i0, j0);
           if (not res) then
           begin
             res := isUnderAttackByFigure(korol * colorOfattacker, i0, j0);
           end;
         end;
       end;
     end;
   end;
   isUnderAttackBy := res;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
Procedure showField;
var i,j, i0,j0: longint;
begin
   textbackground(7);
  clrscr;
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin
      if (orientation = -1) then
      begin
        i0:=8-i+1;
        j0:=j;
      end else
      begin
        i0:=i;
        j0:=8-j+1;
      end;

      if ((i+j) mod 2 = 0) then textbackground(6)
                               else textbackground(5);

      //if (isUnderAttackBy(white,i0,j0)) then textbackground(4);

      if (field[i0,j0]>0) then textcolor(15)
                          else textcolor(0);
      gotoxy(1+9*j,1+6*i);
      write(' ');
      gotoxy(1+9*j,2+6*i);
      write(' ');
      gotoxy(1+9*j,3+6*i);
      write(' ');
      gotoxy(2+9*j,1+6*i);
      write(' ');
      gotoxy(2+9*j,3+6*i);
      write(' ');
      gotoxy(3+9*j,1+6*i);
      write(' ');
      gotoxy(3+9*j,2+6*i);
      write(' ');
      gotoxy(3+9*j,3+6*i);
      write(' ');
      gotoxy(2+9*j,2+6*i);
      if (field[i0,j0]<>0) then write(abs(field[i0,j0]))
                           else write(' ');
    end;
  end;
end; // end showField
procedure saveField;
var f: text;
    i,j: longint;
begin
  assign(f,'out.txt');
  append(f);
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin
      write(f, field[i,j]:3);
    end;
    writeln(f);
  end;
  writeln(f);
  close(f);
end;
function figureTOSTR(f: longint): string;
var res: string;
begin
  res:= ' ';
  if (abs(f) = peshka) then res:= ' peshka';
  if (abs(f) = loshad) then res:= ' loshad';
  if (abs(f) = officer) then res:= ' officer';
  if (abs(f) = ladya) then res:= ' ladya';
  if (abs(f) = ferz) then res:= ' ferz';
  if (abs(f) = korol) then res:= ' korol';
  if (f<0) then res[1] := 'b'
           else res[1] := 'w';
  figuretoSTR:=res;
end;
function getCoordStr(i,j: longint): string;
var res: string;
begin
  str(i, res);
  res := chr(ord('a') + j - 1) + res;
  getCoordStr := res;
end;
function MoveToStr(m:move): string;
var res: string;
begin
  res := figureToStr(m.figureStart);
  res := res + ' ' + getCoordStr(m.iStart, m.jStart);
  res := res + ' ' + getCoordStr(m.iEnd, m.jEnd);
  MoveToStr := res;
end;
procedure savebuf;
var f: text;
    i: longint;
begin
    assign(f, outfilename);
    append(f);
    for i:=1 to buffercursor do
    begin
      writeln(f,buffer[i]);
    end;
    close(f);
    buffercursor := 0;
end;
procedure AddStrToBuffer(s: string);
begin
  inc(buffercursor);
  buffer[buffercursor] := s;
end;
procedure saveMoves;
var i: longint;
    s: string;
begin
  i:=1;
  s:='';
  for i:=1 to CountOfMakedMoves do
  begin
    if (i<=MoveMarking) then
    begin
      if (lastMakedMoves[i] <> MakedMoves[i]) then AddStrToBuffer('');
    end;
  end;
  for i:=1 to CountOfMakedMoves do
  begin
    if (i mod 2 = 1) or showblack then
    begin
      s := s + MoveToSTr(makedmoves[i])+chr(9)
    end;
  end;
  AddStrToBuffer(s);
  if (buffercursor >=buffermax) then
  begin
    savebuf;
  end;
  lastMakedMoves := makedmoves;
end;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function CreateMove(iStart, jStart, iEnd, jEnd, figureStart: longint): move;
var res: move;
begin
  res.iStart := iStart;
  res.jStart := jStart;
  res.iEnd := iEnd;
  res.jEnd := jEnd;
  res.figureStart := figureStart;
  res.figureEnd := 0;
  CreateMove := res;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure DoMove(var m: move);
begin
  with m do
  begin
    figureEnd := field[iEnd, jEnd];
    if (iEnd = 1) and (figureStart*orientation = peshka) then
    begin
      field[iEnd,jEnd] := ferz*colorOf(figureStart);
    end else if (iEnd = 8) and (figureStart*orientation = bpeshka) then
    begin
      field[iEnd,jEnd] := ferz*colorOf(figureStart);
    end else field[iEnd, jEnd] := figureStart;

    field[iStart, jStart] := 0;
    inc(countOfMakedMoves);
    MakedMoves[countOfMakedMoves]:=m;
  end;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure UndoMove(var m: move);
begin
  with m do
  begin
    field[iStart, jStart] := figureStart;
    field[iEnd, jEnd] := figureEnd;
    dec(CountofMakedMoves);
  end;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function isCheckTo(color: longint):boolean; //TOWRITE
var res: boolean;
    i,j: longint;
begin
  findKorol(color,i,j);
  res := isUnderAttackBy(-color, i,j);
  isCheckTo := res;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure AddMove(m: move);
begin
  if (m.iEnd>=1) and (m.iEnd<=8) and (m.jEnd>=1) and (m.jEnd<=8) then
  begin
    doMove(m);
    if (not isCheckTo(colorOf(m.figureStart))) and (colorOf(m.figurestart)<>colorOf(m.figureEnd)) then
    begin
      inc(countOfPossibleMoves);
      moves[countOfPossibleMoves] := m;
    end;
    UndoMove(m);
  end;
end;
procedure AddMovesDist(i0,j0,dn,dm: longint);
var i,j: longint;
    currentfigure: longint;
    current: longint;
    curmov: move;
begin
  i := i0 + dn;
  j := j0 + dm;
  currentFigure := getFigureOn(i0,j0);
  current := getFigureOn(i,j);
  if (dn <> 0) or (dm <> 0) then
  begin
    while (current*currentFigure <= 0) and (i<=n) and (i>=1) and (j<=n) and (j>=1) do
    begin
      curmov := CreateMove(i0,j0,i,j, currentFigure);
      addMove(curmov);
      if (current*currentFigure < 0) then break;
      i := i + dn;
      j := j + dm;
      current := getFigureOn(i,j);

    end;
  end;
end;
procedure AddAllPossibleMoves(color: longint);//TOWRITE
var i,j: longint;
    curfig: longint; // Curent Figure
    curmov: move;
begin
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin
      if (field[i,j]*color > 0) then
      begin
        curfig := field[i,j];
        if (abs(curfig) = peshka) then
        begin
          if (color*orientation = white) then
          begin
            if (getFigureOn(i-1,j-1)*color<0) then
            begin
              curmov := CreateMove(i,j,i-1,j-1, curfig);
              AddMove(curMov);
            end;
            if (getFigureOn(i-1,j+1)*color<0) then
            begin
              curmov := CreateMove(i,j,i-1,j+1, curfig);
              AddMove(curMov);
            end;
            if (getFigureOn(i-1,j) = 0) then
            begin
              curmov := CreateMove(i,j,i-1,j, curfig);
              AddMove(curMov);
            end;
            if (i = 7) then
            begin
              if (getFigureOn(i-2,j) = 0) then
              begin
                curmov := CreateMove(i,j,i-2,j, curfig);
                AddMove(curMov);
              end;
            end;
          end else
          begin
            if (getFigureOn(i+1,j-1)*color<0) then
            begin
              curmov := CreateMove(i,j,i+1,j-1, curfig);
              AddMove(curMov);
            end;
            if (getFigureOn(i+1,j+1)*color<0) then
            begin
              curmov := CreateMove(i,j,i+1,j+1, curfig);
              AddMove(curMov);
            end;
            if (getFigureOn(i+1,j) = 0) then
            begin
              curmov := CreateMove(i,j,i+1,j, curfig);
              AddMove(curMov);
            end;
            if (i = 2) then
            begin
              if (getFigureOn(i+2,j) = 0) then
              begin
                curmov := CreateMove(i,j,i+2,j, curfig);
                AddMove(curMov);
              end;
            end;
          end;
        end else
        if (abs(curfig) = loshad) then //-----------------------------------------------------Loshad
        begin
          if (getFigureOn(i-2,j-1)*color <= 0) then
          begin
            curmov := CreateMove(i,j,i-2,j-1, curfig);
            AddMove(curMov);
          end;
          if (getFigureOn(i-2,j+1)*color <= 0) then
          begin
            curmov := CreateMove(i,j,i-2,j+1, curfig);
            AddMove(curMov);
          end;
          if (getFigureOn(i+2,j-1)*color <= 0) then
          begin
            curmov := CreateMove(i,j,i+2,j-1, curfig);
            AddMove(curMov);
          end;
          if (getFigureOn(i+2,j+1)*color <= 0) then
          begin
            curmov := CreateMove(i,j,i+2,j+1, curfig);
            AddMove(curMov);
          end;

          if (getFigureOn(i-1,j-2)*color <= 0) then
          begin
            curmov := CreateMove(i,j,i-1,j-2, curfig);
            AddMove(curMov);
          end;
          if (getFigureOn(i-1,j+2)*color <= 0) then
          begin
            curmov := CreateMove(i,j,i-1,j+2, curfig);
            AddMove(curMov);
          end;
          if (getFigureOn(i+1,j-2)*color <= 0) then
          begin
            curmov := CreateMove(i,j,i+1,j-2, curfig);
            AddMove(curMov);
          end;
          if (getFigureOn(i+1,j+2)*color <= 0) then
          begin
            curmov := CreateMove(i,j,i+1,j+2, curfig);
            AddMove(curMov);
          end;
        end else
        if (abs(curfig) = officer) then
        begin
          addmovesDist(i,j,-1,-1);
          addmovesDist(i,j,-1, 1);
          addmovesDist(i,j, 1,-1);
          addmovesDist(i,j, 1, 1);
        end else
        if (abs(curfig) = ladya) then
        begin
          addmovesDist(i,j,-1, 0);
          addmovesDist(i,j, 0, 1);
          addmovesDist(i,j, 1, 0);
          addmovesDist(i,j, 0,-1);
        end else
        if (abs(curfig) = ferz) then
        begin
          addmovesDist(i,j,-1,-1);
          addmovesDist(i,j,-1, 1);
          addmovesDist(i,j, 1,-1);
          addmovesDist(i,j, 1, 1);
          addmovesDist(i,j,-1, 0);
          addmovesDist(i,j, 0, 1);
          addmovesDist(i,j, 1, 0);
          addmovesDist(i,j, 0,-1);
        end else
        if (abs(curfig) = korol) then
        begin
          curmov := CreateMove(i,j,i-1,j-1, curfig);
          AddMove(curmov);
          curmov := CreateMove(i,j,i-1,j,   curfig);
          AddMove(curmov);
          curmov := CreateMove(i,j,i-1,j+1, curfig);
          AddMove(curmov);
          curmov := CreateMove(i,j,i,  j-1, curfig);
          AddMove(curmov);
          curmov := CreateMove(i,j,i,  j+1, curfig);
          AddMove(curmov);
          curmov := CreateMove(i,j,i+1,j-1, curfig);
          AddMove(curmov);
          curmov := CreateMove(i,j,i+1,j,   curfig);
          AddMove(curmov);
          curmov := CreateMove(i,j,i+1,j+1, curfig);
          AddMove(curmov);
        end;
      end;
    end;
  end;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure Solve(color, countOfMoves: longint);
var FirstPossibleMoveIndex: longint;
    LastPossibleMoveIndex: longint;
    i: longint;
    checkWhite, checkBlack: boolean;
    isOk: boolean;
begin
  if (countOfMoves > 0) then
  begin
    inc(cVariants);
    FirstPossibleMoveIndex := countOfPossibleMoves + 1;

    isOk:= true;

    checkWhite := isCheckTo(white);
    checkBlack := isCheckTo(black);

    if (checkWhite) and (isCheckToWhite) then isOk := false;
    if (checkBlack) and (isCheckToBlack) then isOK := false;

    if (isOk) then
    begin
      isCheckToWhite := checkWhite;
      isCheckToBlack := checkBlack;
      AddAllPossibleMoves(color);
      LastPossibleMoveIndex := countOfPossibleMoves;
      if (LastPossibleMoveIndex < FirstPossibleMoveIndex) and (isCheckTo(black)) then
      begin
          inc(cSolving);
          if (maxcountOfPossiblemoves < countofPossibleMoves) then maxcountofPossibleMoves := countOfPossibleMoves;
          Writeln('solved: ', cSolving, ' Solve: ', cVariants, '   max: ', maxcountofpossibleMoves);
          Savemoves;

      end else
      for i := LastPossibleMoveIndex downto FirstPossibleMoveIndex do
      begin
        DoMove(moves[i]);
        {$IFDEF SHOULD_LOG}
        showField;
        {$ENDIF}
        Solve(-color, countOfMoves -1);
        UndoMove(moves[i]);
        moves[i] := CreateMove(0,0,0,0,0);
      end;
      countOfPossibleMoves := FirstPossibleMoveIndex - 1;

    end;
  end;
end;
Begin
  initialize;
  showField;
  readkey;
  textcolor(7);
  textbackground(0);
  clrscr;
  Solve(white,z*2);
  savebuf;
  writeln('Solved: ',cSolving);
  writeln('Watched: ', cVariants);
  readkey;
end.
