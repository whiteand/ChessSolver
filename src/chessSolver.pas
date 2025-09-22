{$DEFINE SHOULD_LOG_NOT}
Program ChessSolver;
uses crt;
type
    PlayerColor = (PlayerColorWhite, PlayerColorBlack);
    TCmdArgs =
    record
        ShowHelp: Boolean;
        Fen: string;
        Moves: longint;
        Color: PlayerColor;
        OutputFileName: string;
        BufferSize: longint;
        A1IsAtTheLeftBottomCorner: boolean;
        MovesGroupSize: integer;
        ShowEnemyMoves: boolean;
    end;
    Move = record
      iStart: integer;
      iEnd: integer;
      jStart: integer;
      jEnd: integer;
      figureStart: integer;
      figureEnd: integer;
     end;
     mas = array [1..1000] of Move;
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

type TBoard = array [1..n, 1..n] of shortint;

{$macro on}
{$define VECTOR_ELEM_TYPE := string}
{$define VECTOR_TYPE := TStrings}
{$define VECTOR_PUSH := TStringsPush}
{$define VECTOR_POP := TStringsPop}
{$i ./vector.pas}
{$macro off}

var cmdArgs: TCmdArgs;
    board: TBoard;
    moves: mas;
    countOfPossibleMoves: longint;
    isCheckToWhite, isCheckToBlack: boolean;
    MakedMoves: mas;
    countOfMakedMoves: longint =0;
    cVariants: int64 = 0;
    cSolving: int64 = 0;
    maxcountofpossibleMoves: int64 = 0;
    buffer: TStrings;
    orientation: integer;
    lastMakedMoves: mas;
operator =(a,b:Move)z:boolean;
begin
  Exit(
    (a.iStart = b.iStart) and
     (a.jStart = b.jStart) and
     (a.iEnd = b.iEnd) and
     (a.jEnd = b.jEnd) and
     (a.figureStart = b.figureStart)
  );
end;
operator <>(a,b:Move)z:boolean;
begin
  z := not (a = b);
end;

procedure ShowChessBoard(
  var board: TBoard
);
const COLOR_WHITE     = 15;
      COLOR_BLACK     = 0;
      COLOR_BLUE      = 1;
      COLOR_DARK_GRAY = 8;
var r: integer;
    c: integer;
    cell: longint;
begin
  for r := 1 to n do
  begin
    for c := 1 to n do
    begin
      cell := board[r, c];
      if (cell = 0) then
      begin
        TextColor(COLOR_DARK_GRAY);
        if ((r + c) mod 2 = 0)
          then write('▫ ')
          else write('▪ ');
        TextColor(COLOR_WHITE)
      end else case cell of 
        bpeshka: begin TextColor(Blue); write('♙ '); TextColor(COLOR_WHITE) end;
        peshka: begin write('♟ '); end;
        bladya: begin TextColor(Blue); write('♖ '); TextColor(COLOR_WHITE) end;
        ladya: begin write('♜ '); end;
        bloshad: begin TextColor(Blue); write('♘ '); TextColor(COLOR_WHITE) end;
        loshad: begin write('♞ '); end;
        officer: begin write('♝ '); end;
        bofficer: begin TextColor(Blue); write('♗ '); TextColor(COLOR_WHITE) end;
        ferz: begin write('♛ '); end;
        bferz: begin TextColor(Blue); write('♕ '); TextColor(COLOR_WHITE) end;
        korol: begin write('♚ '); end;
        bkorol: begin TextColor(Blue); write('♔ '); TextColor(COLOR_WHITE) end;
          else write('?'); end;
    end;
    writeln;
  end;
end;

procedure ShowHelp;
begin
    writeln('Usage: ChessSolver --fen <fen-notation> -o <output-file-path> [--color <white|black>] [--moves <moves>] [--buffer-size <buffer size>] [--a1-at-top-right] [--moves-group-size <group-moves-size>] [--show-enemy-moves]');
    writeln('Example:');
    writeln('  ChessSolver --fen r1b4k/b6p/2pp1r2/pp6/4P3/PBNP2R1/1PP3PP/7K --moves 1 --color white');
    writeln('Options:');
    writeln('  --fen              - Fen notation string describing the chess board. Read more: http://www.ee.unb.ca/cgi-bin/tervo/fen.pl');
    writeln('  -o                 - File into which the output will be written');
    writeln('  --color            - Color of the player that should win. Possible values: white | black. Default is white');
    writeln('  --moves            - Number of expected moves for checkmate to be found');
    writeln('  --buffer-size      - No one knows what is this parameter, TBD. Default to 10000');
    writeln('  --a1-at-top-right  - Should show A1 at the top right corner. Defaults to false');
    writeln('  --moves-group-size - How many moves should be grouped together. Defaults to 0 (means no grouping).');
    writeln('  --show-enemy-moves - Shows enemy moves in the output. Defaults to false.');
end;
function ParseArguments(var args: TCmdArgs): boolean;
var i: integer;
    argument: string;
    expectsFenString: boolean = false;
    expectsMoves: boolean = false;
    expectsBufferSize: boolean = false;
    expectsMovesGroupSize: boolean = false;
    expectsColor: boolean = false;
    expectsOutputFileName: boolean = false;
    fenArgumentProvided: boolean = false;
    outputFileNameProvided: boolean = false;
    bufferSizeProvided: boolean = false;
    code: Shortint;
begin
    args.A1IsAtTheLeftBottomCorner := true;
    args.Color := PlayerColorWhite;

    for i := 1 to ParamCount() do
    begin
        argument := ParamStr(i);
        if (argument = '--help') then
        begin
          args.ShowHelp := true;
          Exit(true);
        end
        else if (argument = '--fen') then expectsFenString := true
        else if (expectsFenString) then
        begin
            if Length(argument) < 15 then
            begin
                ShowHelp;
                writeln('ERROR: Expected --fen <fen-notation-string>, but ', argument, ' occurred');
                Exit(false);
            end;
            {TODO: Add validation of fen string}
            fenArgumentProvided := true;
            args.Fen := argument;
            expectsFenString := false;
        end else if (argument = '--moves') then expectsMoves := true
        else if (expectsMoves) then
        begin
            Val(argument, args.Moves, code);
            if code <> 0 then
            begin
                ShowHelp;
                writeln('ERROR: Expected --moves <moves-number>, but ', argument, ' is passed');
                Exit(false);
            end;
            expectsMoves := false;
        end
        else if (argument = '-o') then expectsOutputFileName := true
        else if (expectsOutputFileName) then
        begin
            if Length(argument) <= 0 then
            begin
              ShowHelp;
              writeln('ERROR: Output file name should not be empty');
              Exit(false);
            end;
            cmdArgs.OutputFileName := argument;
            expectsOutputFileName := false;
            outputFileNameProvided := true;
        end
        else if argument = '--buffer-size' then expectsBufferSize := true
        else if expectsBufferSize then
        begin
            Val(argument, args.BufferSize, code);
            if code <> 0 then
            begin
                ShowHelp;
                writeln('ERROR: Expected --buffer-size <buffer-size>, but ', argument, ' is passed');
                Exit(false);
            end;
            expectsBufferSize := false;
        end
        else if argument = '--color' then expectsColor := true
        else if expectsColor then
        begin
            if argument = 'white' then args.Color := PlayerColorWhite
            else if argument = 'black' then args.Color := PlayerColorBlack
            else begin
                ShowHelp;
                writeln('ERROR: Expected --color <black|white>, but ', argument, ' is passed');
                Exit(false);
            end;
            expectsColor := false
        end
        else if argument = '--a1-at-top-right' then args.A1IsAtTheLeftBottomCorner := false
        else if argument = '--show-enemy-moves' then args.ShowEnemyMoves := true
        else if argument = '--moves-group-size' then expectsMovesGroupSize := true
        else if expectsMovesGroupSize then
        begin
            Val(argument, args.MovesGroupSize, code);
            if code <> 0 then
            begin
                ShowHelp;
                writeln('ERROR: Expected --moves-group-size <group size>, but ', argument, ' is passed');
                Exit(false);
            end;
            expectsMovesGroupSize := false;
        end;
    end;
    if expectsFenString or not fenArgumentProvided then
    begin
        ShowHelp;
        writeln('ERROR: Expected --fen <fen-notation-string>, but nothing is passed');
        Exit(false);
    end;
    if expectsOutputFileName or not outputFileNameProvided then
    begin
        ShowHelp;
        writeln('ERROR: Expected -o <output file path>, but nothing is passed');
        Exit(false);
    end;
    if expectsMoves then
    begin
        ShowHelp;
        writeln('ERROR: Expected --steps <steps-count>, but nothing is passed');
        Exit(false);
    end;
    if expectsColor then
    begin
        ShowHelp;
        writeln('ERROR: Expected --color <white|black>, but nothing is passed');
        Exit(false);
    end;
    if expectsBufferSize then
    begin
        ShowHelp;
        writeln('ERROR: Expected --buffer-size <buffer-size>, but nothing is passed');
        Exit(false);
    end;
    if expectsMovesGroupSize then
    begin
        ShowHelp;
        writeln('ERROR: Expected --moves-group-size <group size>, but nothing is passed');
        Exit(false);
    end;
    if not bufferSizeProvided then args.BufferSize := 10000;
    Exit(true);
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure findKorol(color: longint; var i0,j0: longint);
var i,j: longint;
begin
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin
      if board[i,j] = korol*color then
      begin
        i0:=i;
        j0:=j;
        Exit();
      end;
    end;
  end;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure MakeBoardWithFen(var board: TBoard; s:string);
var k,z,i,j: integer;
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
          board[i,j]:=0;
          next;
        end;
      end else
      if (s[k] = 'K') then
      begin
        board[i,j]:=6;
        next;
      end else
      if (s[k] = 'Q') then
      begin
        board[i,j]:=5;
        next;
      end else
      if (s[k] = 'R') then
      begin
        board[i,j]:=4;
        next;
      end else
      if (s[k] = 'B') then
      begin
        board[i,j]:=3;
        next;
      end else
      if (s[k] = 'N') then
      begin
        board[i,j]:=2;
        next;
      end else
      if (s[k] = 'P') then
      begin
        board[i,j]:=1;
        next;
      end else
      if (s[k] = 'k') then
      begin
        board[i,j]:=-6;
        next;
      end else
      if (s[k] = 'q') then
      begin
        board[i,j]:=-5;
        next;
      end else
      if (s[k] = 'r') then
      begin
        board[i,j]:=-4;
        next;
      end else
      if (s[k] = 'b') then
      begin
        board[i,j]:=-3;
        next;
      end else
      if (s[k] = 'n') then
      begin
        board[i,j]:=-2;
        next;
      end else
      if (s[k] = 'p') then
      begin
        board[i,j]:=-1;
        next;
      end;
    end;
  end;

end;
procedure ReverseColors(var board: TBoard);
var i, j: shortint;
begin
  for i:=1 to 8 do
  begin
    for j:=1 to 8 do
    begin
      board[i,j] := -board[i,j];
    end;
  end;
end;
procedure ClearBoard(var board: TBoard);
var i,j:integer;
begin
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin
      board[i,j] := 0;
    end;
  end;
end;
procedure Initialize(var cmdArgs: TCmdArgs; var board: TBoard);
var outputFile: text;
begin
  clrscr;
  ClearBoard(board);
  cmdArgs.Moves := 1;
  if not ParseArguments(cmdArgs) then Halt(1);
  if cmdArgs.ShowHelp then
  begin
    ShowHelp;
    Halt(0);
  end;
  writeln('Moves: ', cmdArgs.Moves);
  writeln('Color: ', cmdArgs.Color);
  makeBoardWithFen(board, cmdArgs.fen);
  if cmdArgs.Color = PlayerColorBlack then ReverseColors(board);
  countOfPossibleMoves := 0;
  if cmdArgs.A1IsAtTheLeftBottomCorner then orientation := -1
                                       else orientation := 1;
  assign(outputFile, cmdArgs.OutputFileName);
  rewrite(outputFile);
  close(outputFile);
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function colorOf(f: integer): integer;
begin
  if f > 0 then Exit(1)
  else if f < 0 then Exit(-1)
  else Exit(0)
end;
function getFigureOn(i,j: longint): longint;
begin
  if (i>=1) and (i<=n) and (j>=1) and (j<=n) then
  begin
    getFigureOn := board[i,j];
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

  while (i<=n) and (i>=1) and (j<=n) and (j>=1) do
  begin
	  current := getFigureOn(i,j);
    if current <> 0 then Exit(current);
    i := i + dn;
    j := j + dm;
  end;
  Exit(0);
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
begin
   if isUnderAttackByFigure(peshka * colorOfattacker, i0, j0) then Exit(true);
   if isUnderAttackByFigure(loshad * colorOfattacker, i0, j0) then Exit(true);
   if isUnderAttackByFigure(officer * colorOfattacker, i0, j0) then Exit(true);
   if isUnderAttackByFigure(ladya * colorOfattacker, i0, j0) then Exit(true);
   if isUnderAttackByFigure(ferz * colorOfattacker, i0, j0) then Exit(true);
   if isUnderAttackByFigure(korol * colorOfattacker, i0, j0) then Exit(true);
   
   Exit(false)
end;
procedure saveBoard;
var f: text;
    i,j: longint;
begin
  assign(f,'out.txt');
  append(f);
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin
      write(f, board[i,j]:3);
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
  Exit(chr(ord('a') + j - 1) + res)
end;
function MoveToStr(m:Move): string;
begin
  Exit(
    figureToStr(m.figureStart) + ' '
    + getCoordStr(m.iStart, m.jStart) + ' '
    + getCoordStr(m.iEnd, m.jEnd)
  )
end;
procedure SaveBuf(var buffer: TStrings; outputFileName: string);
var f: text;
    i: longint;
begin
    assign(f, outputFileName);
    append(f);
    for i:=0 to buffer.length-1 do
    begin
      writeln(f,buffer.items[i]);
    end;
    close(f);
    buffer.length := 0
end;
procedure saveMoves(
  outputFileName: string;
  var buffer: TStrings;
  buffermax: longint;
  showEnemyMoves: boolean;
  movesGroupSize: longint
);
var i: longint;
    s: string;
begin
  i:=1;
  s:='';
  for i:=1 to countOfMakedMoves do
  begin
    if (i<=movesGroupSize) then
    begin
      if (lastMakedMoves[i] <> MakedMoves[i]) then TStringsPush('', buffer);
    end;
  end;
  for i:=1 to countOfMakedMoves do
  begin
    if (i mod 2 = 1) or showEnemyMoves then
    begin
      s := s + MoveToSTr(makedmoves[i])+chr(9)
    end;
  end;
  TStringsPush(s, buffer);
  if (buffer.length >= buffermax) then
  begin
    SaveBuf(buffer, outputFileName);
  end;
  lastMakedMoves := makedmoves;
end;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function CreateMove(
  iStart: longint;
  jStart: longint;
  iEnd: longint;
  jEnd: longint;
  figureStart: longint
): Move;
var res: Move;
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
procedure DoMove(var m: Move);
begin
  with m do
  begin
    figureEnd := board[iEnd, jEnd];
    if (iEnd = 1) and (figureStart*orientation = peshka) then
    begin
      board[iEnd,jEnd] := ferz*colorOf(figureStart);
    end else if (iEnd = 8) and (figureStart*orientation = bpeshka) then
    begin
      board[iEnd,jEnd] := ferz*colorOf(figureStart);
    end else board[iEnd, jEnd] := figureStart;

    board[iStart, jStart] := 0;
    inc(countOfMakedMoves);
    MakedMoves[countOfMakedMoves]:=m;
  end;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure UndoMove(var m: Move);
begin
  with m do
  begin
    board[iStart, jStart] := figureStart;
    board[iEnd, jEnd] := figureEnd;
    dec(countOfMakedMoves);
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
procedure AddMove(m: Move);
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
    curmov: Move;
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
    curmov: Move;
begin
  for i:=1 to n do
  begin
    for j:=1 to n do
    begin
      if (board[i,j]*color > 0) then
      begin
        curfig := board[i,j];
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
procedure Solve(
  color, countOfMoves: longint;
  var buffer: TStrings;
  buffermax: longint;
  movesGroupSize: longint;
  showEnemyMoves: boolean;
  outputFileName: string
);
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
          SaveMoves(outputFileName, buffer, buffermax, showEnemyMoves, movesGroupSize);

      end else
      for i := LastPossibleMoveIndex downto FirstPossibleMoveIndex do
      begin
        DoMove(moves[i]);
        {$IFDEF SHOULD_LOG}
        writeln;
        ShowChessBoard(board);
        {$ENDIF}
        Solve(-color, countOfMoves -1, buffer, buffermax, movesGroupSize, showEnemyMoves, outputFileName);
        UndoMove(moves[i]);
        moves[i] := CreateMove(0,0,0,0,0);
      end;
      countOfPossibleMoves := FirstPossibleMoveIndex - 1;

    end;
  end;
end;

Begin
  Initialize(cmdArgs, board);
  ShowChessBoard(board);
  readkey;
  textcolor(7);
  textbackground(0);
  clrscr;
  Solve(
    white,
    cmdArgs.Moves*2,
    buffer,
    cmdArgs.BufferSize,
    cmdArgs.MovesGroupSize,
    cmdArgs.ShowEnemyMoves,
    cmdArgs.OutputFileName
  );
  SaveBuf(
    buffer,
    cmdArgs.OutputFileName
  );
  writeln('Solved: ',cSolving);
  writeln('Watched: ', cVariants);
  readkey;
end.
