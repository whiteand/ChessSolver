Program ChessSolver;
uses crt;
type move = record
              iStart, iEnd, jStart, jEnd, figureStart, figureEnd: integer;
            end;
     mas = array [1..100000] of move;
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



var field: array [1..n, 1..n] of integer;
    moves: mas;
    countOfPossibleMoves: integer;
    isCheckToWhite, isCheckToBlack: boolean;
    z: integer;
    MakedMoves: mas;
    CountOfMakedMoves: integer =0;
    cVariants: longint = 0;
    cSolving: longint = 0;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure showHelp;
begin
  textcolor(14);
  writeln('You should create a file with datas(Figure, i, j)');
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
procedure findKorol(color: integer; var i0,j0: integer);
var founded: boolean;
    i,j: integer;
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
procedure initialize;
var fName : string;
    i,j   : integer;
    figure: integer;
    fin   : textfile;
begin
  clrscr;
  showHelp;
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin
      field[i,j] := 0;
    end;
  end;
  textcolor(14);
  writeln('Enter the file name: ');
  textcolor(7);
  readln(fName);
  assign(fin, fName);
  reset(fin);
  readln(fin,z);
  while not eof(fin) do
  begin
    readln(fin,figure,i,j);
    field[i,j] := figure;
  end;
  close(fin);
  countOfPossibleMoves := 0;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function getFigureOn(i,j: integer): integer;
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
function searchTo(i0,j0,dn,dm: integer): integer;
var i,j: integer;
    current: integer;
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
function isUnderAttackByFigure(figure, i0, j0: integer): boolean;
var res: boolean;
    i,j: integer;
begin
  res := false;
  if (abs(figure) = peshka) then
  begin
    if (figure > 0) then
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
function isUnderAttackBy(colorOfattacker, i0, j0: integer): boolean;
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
var i,j: integer;
begin
   textbackground(7);
  clrscr;
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin

      if ((i+j) mod 2 = 0) then textbackground(6)
                            else textbackground(5);

      if (isUnderAttackBy(white,i,j)) then textbackground(4);

      if (field[i,j]>0) then textcolor(15)
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
      if (field[i,j]<>0) then write(abs(field[i,j]))
                         else write(' ');
    end;
  end;
end; // end showField
procedure saveField;
var f: text;
    i,j: integer;
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
function figureTOSTR(f: integer): string;
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
<<<<<<< HEAD
end;
function getCoordStr(i,j: integer): string;
var res: string;
begin
  str(8-i+1, res);
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
=======

>>>>>>> a663e6c754a453ac058b4de82bdb9689ed68fa75
end;

procedure saveMoves;
var i: integer;
    f: text;
begin
  i:=1;
  assign(f, 'moves.txt');
  append(f);
  for i:=1 to CountOfMakedMoves do
  begin
<<<<<<< HEAD
    write(f,MoveToSTr(makedmoves[i]),chr(9));
=======
    with makedmoves[i] do
    begin
      writeln(f,figuretostr(figureStart),' ', iStart,' ', jStart,' ', iEnd,' ', jEnd);
    end;
>>>>>>> a663e6c754a453ac058b4de82bdb9689ed68fa75
  end;
  writeln(f);
  close(f);

end;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function CreateMove(iStart, jStart, iEnd, jEnd, figureStart: integer): move;
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
    field[iEnd, jEnd] := figureStart;
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
function isCheckTo(color: integer):boolean; //TOWRITE
var res: boolean;
    i,j: integer;
begin
  findKorol(color,i,j);
  res := isUnderAttackBy(-color, i,j);
  isCheckTo := res;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function colorOf(f: integer): integer;
begin
  if (f>0) then colorOf := 1
           else if (f<0) then colorOf := -1
                         else colorOf := 0;
end;
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
procedure AddMovesDist(i0,j0,dn,dm: integer);
var i,j: integer;
    currentfigure: integer;
    current: integer;
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
procedure AddAllPossibleMoves(color: integer);//TOWRITE
var i,j: integer;
    k: integer;
    isGoodMove: boolean;
    curfig: integer; // Curent Figure
    curmov: move;
    movi, movj: integer;
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
          if (color = white) then
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
procedure Solve(color, countOfMoves: integer);
var FirstPossibleMoveIndex: integer;
    LastPossibleMoveIndex: integer;
    i,j,k: integer;
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
          showField;
          writeln;
          writeln;
          textbackground(3);
          inc(cSolving);
          Writeln('solved: ', cSolving, ' Solve: ', cVariants);
//          readkey;
//          saveField;
          Savemoves;
      end else
      for i := LastPossibleMoveIndex downto FirstPossibleMoveIndex do
      begin
        DoMove(moves[i]);
        if (isLog) then showField;
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
  Solve(white,z*2);
  writeln('Solved: ',cSolving);
  writeln('Watched: ', cVariants);
  readkey;
end.
