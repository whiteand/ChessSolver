Program ChessSolver;
uses crt;
type move = record
              iStart, iEnd, jStart, jEnd, figureStart, figureEnd: integer;
            end;
     mas = array [1..10000] of move;
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


var field: array [1..n, 1..n] of integer;
    moves: array [1..10000] of move;
    countOfPossibleMoves: integer;
    isCheckToWhite, isCheckToBlack: boolean;

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
      if (field[i,j] = korol) and (field[i,j]*color>0) then
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
    f     : text;
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
  assign(f, fName);
  reset(f);
  while not eof(f) do
  begin
    readln(f,figure,i,j);
    field[i,j] := figure;
  end;
  close(f);
  countOfPossibleMoves := 0;

  clrscr;
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
  readkey;
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
  end;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function isCheckTo(color: integer):boolean; //TOWRITE
var res: boolean;
begin
  isCheckTo := res;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure AddAllPossibleMoves(var movarr: mas;color: integer);//TOWRITE
begin

end;
function isMateTo(color: integer): boolean;
var res: boolean;
begin
  res := true;
  if (isCheckTo(color)) then
  begin

  end;
  isMateTo := res;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure Solve(color, countOfMoves: integer);//TOWRITE
var FirstPossibleMoveIndex: integer;
    LastPossibleMoveIndex: integer;
    i,j,k: integer;
    checkWhite, checkBlack: boolean;
    isOk: boolean;
begin
  if (countOfMoves > 0) then
  begin
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
      AddAllPossibleMoves(moves, color);
      LastPossibleMoveIndex := countOfPossibleMoves;
      if (LastPossibleMoveIndex < FirstPossibleMoveIndex) then
      begin
          showField;
          saveField;
      end else
      for i := LastPossibleMoveIndex downto FirstPossibleMoveIndex do
      begin
        DoMove(moves[i]);
        Solve(-color, countOfMoves -1);        
        UndoMove(moves[i]);
      end;
      countOfPossibleMoves := FirstPossibleMoveIndex - 1;

    end;
  end else // countOfMoves <0
  begin
    if (isCheckTo(black)) then
    begin
      //showField;
      //saveField;
    end;
  end;
end;
Begin
  initialize;
  showField;
end.
