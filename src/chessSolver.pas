{$DEFINE SHOULD_LOG_NOT}
Program ChessSolver;
uses crt;
type
    PlayerColor = (PlayerColorWhite, PlayerColorBlack);
    ChessFigure = (
      Pawn,
      Knight,
      Bishop,
      Rook,
      Queen,
      King
    );
    TCmdArgs =
    record
        ShowHelp: Boolean;
        Fen: string;
        Moves: longint;
        Color: PlayerColor;
        OutputFileName: string;
        BufferSize: longint;
        MovesGroupSize: integer;
        ShowEnemyMoves: boolean;
    end;
    Move =
    record
      iStart: integer;
      iEnd: integer;
      jStart: integer;
      jEnd: integer;
      figureStart: integer;
      figureEnd: integer;
     end;
const BOARD_SIZE   = 8;
      WHITE_PAWN   = 1;
      WHITE_KNIGHT = 2; 
      WHITE_BISHOP = 3;
      WHITE_ROOK   = 4;
      WHITE_QUEEN  = 5;
      WHITE_KING   = 6;
      BLACK_PAWN   = -WHITE_PAWN;
      BLACK_KNIGHT = -WHITE_KNIGHT;
      BLACK_BISHOP = -WHITE_BISHOP;
      BLACK_ROOK   = -WHITE_ROOK;
      BLACK_QUEEN  = -WHITE_QUEEN;
      BLACK_KING   = -WHITE_KING;
      WHITE_PAWN_MOVE_DIRECTION = -1;
      EMPTY_CELL   = 0;
      white    =  1;
      black    = -1;
      isLog = false;

type TBoard = array [1..BOARD_SIZE, 1..BOARD_SIZE] of shortint;

{$macro on}
{$define VECTOR_ELEM_TYPE := string}
{$define VECTOR_TYPE := TStrings}
{$define VECTOR_PUSH := TStringsPush}
{$define VECTOR_POP := TStringsPop}
{$i ./vector.pas}
{$macro off}

{$macro on}
{$define VECTOR_ELEM_TYPE := Move}
{$define VECTOR_TYPE := TMoves}
{$define VECTOR_PUSH := TMovesPush}
{$define VECTOR_POP := TMovesPop}
{$i ./vector.pas}
{$macro off}

var cmdArgs: TCmdArgs;
    board: TBoard;
    moves: TMoves;
    previousMoveWasCheckToWhites, previousMoveWasCheckToBlacks: boolean;
    makedMoves: TMoves;
    cVariants: int64 = 0;
    cSolving: int64 = 0;
    maxcountofpossibleMoves: int64 = 0;
    buffer: TStrings;
    lastSavedMoves: TMoves;
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

function OppositeColor(color: PlayerColor): PlayerColor;
begin
  if color = PlayerColorWhite
    then Exit(PlayerColorBlack)
    else Exit(PlayerColorWhite)
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
  for r := 1 to BOARD_SIZE do
  begin
    for c := 1 to BOARD_SIZE do
    begin
      cell := board[r, c];
      if (cell = 0) then
      begin
        TextColor(COLOR_DARK_GRAY);
        if ((r + c) mod 2 = 0)
          then Write('▫ ')
          else Write('▪ ');
        TextColor(COLOR_WHITE)
      end else case cell of 
        BLACK_PAWN: begin TextColor(Blue); Write('♙ '); TextColor(COLOR_WHITE) end;
        WHITE_PAWN: begin Write('♟ '); end;
        BLACK_ROOK: begin TextColor(Blue); Write('♖ '); TextColor(COLOR_WHITE) end;
        WHITE_ROOK: begin Write('♜ '); end;
        BLACK_KNIGHT: begin TextColor(Blue); Write('♘ '); TextColor(COLOR_WHITE) end;
        WHITE_KNIGHT: begin Write('♞ '); end;
        WHITE_BISHOP: begin Write('♝ '); end;
        BLACK_BISHOP: begin TextColor(Blue); Write('♗ '); TextColor(COLOR_WHITE) end;
        WHITE_QUEEN: begin Write('♛ '); end;
        BLACK_QUEEN: begin TextColor(Blue); Write('♕ '); TextColor(COLOR_WHITE) end;
        WHITE_KING: begin Write('♚ '); end;
        BLACK_KING: begin TextColor(Blue); Write('♔ '); TextColor(COLOR_WHITE) end;
          else Write('?'); end;
    end;
    WriteLn;
  end;
end;

procedure ShowHelp;
begin
    WriteLn('Usage: ChessSolver --fen <fen-notation> -o <output-file-path> [--color <white|black>] [--moves <moves>] [--buffer-size <buffer size>] [--moves-group-size <group-moves-size>] [--show-enemy-moves]');
    WriteLn('Example:');
    WriteLn('  ChessSolver --fen r1b4k/b6p/2pp1r2/pp6/4P3/PBNP2R1/1PP3PP/7K --moves 1 --color white');
    WriteLn('Options:');
    WriteLn('  --fen              - Fen notation string describing the chess board. Read more: http://www.ee.unb.ca/cgi-bin/tervo/fen.pl');
    WriteLn('  -o                 - File into which the output will be written');
    WriteLn('  --color            - Color of the player that should win. Possible values: white | black. Default is white');
    WriteLn('  --moves            - Number of expected moves for checkmate to be found');
    WriteLn('  --buffer-size      - No one knows what is this parameter, TBD. Default to 10000');
    WriteLn('  --moves-group-size - How many moves should be grouped together. Defaults to 0 (means no grouping).');
    WriteLn('  --show-enemy-moves - Shows enemy moves in the output. Defaults to false.');
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
                WriteLn('ERROR: Expected --fen <fen-notation-string>, but ', argument, ' occurred');
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
                WriteLn('ERROR: Expected --moves <moves-number>, but ', argument, ' is passed');
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
              WriteLn('ERROR: Output file name should not be empty');
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
                WriteLn('ERROR: Expected --buffer-size <buffer-size>, but ', argument, ' is passed');
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
                WriteLn('ERROR: Expected --color <black|white>, but ', argument, ' is passed');
                Exit(false);
            end;
            expectsColor := false
        end
        else if argument = '--show-enemy-moves' then args.ShowEnemyMoves := true
        else if argument = '--moves-group-size' then expectsMovesGroupSize := true
        else if expectsMovesGroupSize then
        begin
            Val(argument, args.MovesGroupSize, code);
            if code <> 0 then
            begin
                ShowHelp;
                WriteLn('ERROR: Expected --moves-group-size <group size>, but ', argument, ' is passed');
                Exit(false);
            end;
            expectsMovesGroupSize := false;
        end;
    end;
    if expectsFenString or not fenArgumentProvided then
    begin
        ShowHelp;
        WriteLn('ERROR: Expected --fen <fen-notation-string>, but nothing is passed');
        Exit(false);
    end;
    if expectsOutputFileName or not outputFileNameProvided then
    begin
        ShowHelp;
        WriteLn('ERROR: Expected -o <output file path>, but nothing is passed');
        Exit(false);
    end;
    if expectsMoves then
    begin
        ShowHelp;
        WriteLn('ERROR: Expected --steps <steps-count>, but nothing is passed');
        Exit(false);
    end;
    if expectsColor then
    begin
        ShowHelp;
        WriteLn('ERROR: Expected --color <white|black>, but nothing is passed');
        Exit(false);
    end;
    if expectsBufferSize then
    begin
        ShowHelp;
        WriteLn('ERROR: Expected --buffer-size <buffer-size>, but nothing is passed');
        Exit(false);
    end;
    if expectsMovesGroupSize then
    begin
        ShowHelp;
        WriteLn('ERROR: Expected --moves-group-size <group size>, but nothing is passed');
        Exit(false);
    end;
    if not bufferSizeProvided then args.BufferSize := 10000;
    Exit(true);
end;
function GetFigureValue(figure: ChessFigure; color: PlayerColor): shortint;
var sign: shortint;
begin
  if color = PlayerColorWhite
    then sign := 1
    else sign := -1;
  case figure of
    Pawn: Exit(WHITE_PAWN * sign);
    Knight: Exit(WHITE_KNIGHT * sign);
    Bishop: Exit(WHITE_BISHOP * sign);
    Rook: Exit(WHITE_ROOK * sign);
    Queen: Exit(WHITE_QUEEN * sign);
    King: Exit(WHITE_KING * sign);
  end;
end;

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure FindKing(color: PlayerColor; var i0,j0: longint);
var i,j: longint;
begin
  for i:=1 to BOARD_SIZE do
  begin
    for j:=1 to BOARD_SIZE do
    begin
      if board[i,j] = GetFigureValue(King, color) then
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
procedure Next;
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
          Next;
        end;
      end else
      if (s[k] = 'K') then
      begin
        board[i,j]:=6;
        Next;
      end else
      if (s[k] = 'Q') then
      begin
        board[i,j]:=5;
        Next;
      end else
      if (s[k] = 'R') then
      begin
        board[i,j]:=4;
        Next;
      end else
      if (s[k] = 'B') then
      begin
        board[i,j]:=3;
        Next;
      end else
      if (s[k] = 'N') then
      begin
        board[i,j]:=2;
        Next;
      end else
      if (s[k] = 'P') then
      begin
        board[i,j]:=1;
        Next;
      end else
      if (s[k] = 'k') then
      begin
        board[i,j]:=-6;
        Next;
      end else
      if (s[k] = 'q') then
      begin
        board[i,j]:=-5;
        Next;
      end else
      if (s[k] = 'r') then
      begin
        board[i,j]:=-4;
        Next;
      end else
      if (s[k] = 'b') then
      begin
        board[i,j]:=-3;
        Next;
      end else
      if (s[k] = 'n') then
      begin
        board[i,j]:=-2;
        Next;
      end else
      if (s[k] = 'p') then
      begin
        board[i,j]:=-1;
        Next;
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
  for i:=1 to BOARD_SIZE do
  begin
    for j:=1 to BOARD_SIZE do
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
  WriteLn('Moves: ', cmdArgs.Moves);
  WriteLn('Color: ', cmdArgs.Color);
  MakeBoardWithFen(board, cmdArgs.fen);
  if cmdArgs.Color = PlayerColorBlack then ReverseColors(board);     
  Assign(outputFile, cmdArgs.OutputFileName);
  Rewrite(outputFile);
  Close(outputFile);
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function ColorOf(f: integer): PlayerColor;
begin
  assert(f <> 0, 'Cannot get color of the empty cell');
  if f > 0 then Exit(PlayerColorWhite)
  else if f < 0 then Exit(PlayerColorBlack)
end;
function GetFigureOn(i,j: longint): longint;
begin
  if (i>=1) and (i<=BOARD_SIZE) and (j>=1) and (j<=BOARD_SIZE) then
  begin
    GetFigureOn := board[i,j];
  end else
  begin
    GetFigureOn := 0;
  end;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function SearchTo(i0,j0,dn,dm: longint): longint;
var i,j: longint;
    current: longint;
begin
	i := i0 + dn;
	j := j0 + dm;

  while (i<=BOARD_SIZE) and (i>=1) and (j<=BOARD_SIZE) and (j>=1) do
  begin
	  current := GetFigureOn(i,j);
    if current <> 0 then Exit(current);
    i := i + dn;
    j := j + dm;
  end;
  Exit(0);
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function IsUnderAttackByFigure(attackerFigure: ChessFigure; attackerColor: PlayerColor; i0, j0: longint): boolean;
var res: boolean;
    figure: shortint;
begin
  res := false;
  figure := GetFigureValue(attackerFigure, attackerColor);
  // TODO: Rewrite this logic to not use abs(figure)
  if (abs(figure) = WHITE_PAWN) then
  begin
    if (figure*WHITE_PAWN_MOVE_DIRECTION > 0) then
    begin
    	if (GetFigureOn(i0+1,j0+1) = figure) or (GetFigureOn(i0+1,j0-1) = figure) then
    	begin
    		res := true;
    	end;
    end else
    begin
    	if (GetFigureOn(i0-1,j0+1) = figure) or (GetFigureOn(i0-1,j0-1) = figure) then
    	begin
    		res := true;
    	end;
    end;
  end else
  if (abs(figure) = WHITE_KNIGHT) then
  begin
  	if ((GetFigureOn(i0-2,j0-1) = figure) or
                (GetFigureOn(i0-2,j0+1) = figure) or
  		(GetFigureOn(i0+2,j0-1) = figure) or
  		(GetFigureOn(i0+2,j0+1) = figure) or
  		(GetFigureOn(i0-1,j0-2) = figure) or
  		(GetFigureOn(i0-1,j0+2) = figure) or
  		(GetFigureOn(i0+1,j0-2) = figure) or
  		(GetFigureOn(i0+1,j0+2) = figure)) then
  	begin
  		res := true;
  	end
  end else
  if (abs(figure) = WHITE_BISHOP) then
  begin
  	if (SearchTo(i0,j0,-1,-1) = figure) then
  	begin
  		//To The left top
  		res := true;
  	end
  	else if (SearchTo(i0,j0,-1,1) = figure) then
  	begin
  		//To The right Top
  		res := true;
  	end
	else if (SearchTo(i0,j0,1,-1) = figure) then
  	begin
  		//To the left bottom
  		res := true;
  	end
  	else if (SearchTo(i0,j0,1,1) = figure) then
  	begin
	  	//to the right bottom
  		res := true;
  	end;

  end else
  if (abs(figure) = WHITE_ROOK) then
  begin
  	//Search
  	if (SearchTo(i0,j0,-1,0) = figure) then
  	begin
  		res := true;
  	end else if (SearchTo(i0,j0,1,0) = figure) then
  	begin
  		res := true;
  	end else if (SearchTo(i0,j0,0,-1) = figure) then
  	begin
  		res := true;
  	end else if (SearchTo(i0,j0,0,1) = figure) then
  	begin
  		res := true;
  	end;

  end else
  if (abs(figure) = WHITE_QUEEN) then
  begin
  	//Search
  	if (SearchTo(i0,j0,-1,-1) = figure) then
  	begin
  		res := true;
  	end else if (SearchTo(i0,j0,-1,0) = figure) then
  	begin
  		res := true;
  	end else if (SearchTo(i0,j0,-1,1) = figure) then
  	begin
  		res := true;
  	end else if (SearchTo(i0,j0,0,1) = figure) then
  	begin
  		res := true;
  	end else if (SearchTo(i0,j0,1,1) = figure) then
  	begin
  		res := true;
  	end else if (SearchTo(i0,j0,1,0) = figure) then
  	begin
  		res := true;
  	end else if (SearchTo(i0,j0,1,-1) = figure) then
  	begin
  		res := true;
  	end else if (SearchTo(i0,j0,0,-1) = figure) then
  	begin
  		res := true;
  	end;
  end else
  if (abs(figure) = WHITE_KING) then
  begin
  	if ((GetFigureOn(i0-1,j0-1) = figure) or
  	    (GetFigureOn(i0-1,j0) = figure) or
  	    (GetFigureOn(i0-1,j0+1) = figure) or
  	    (GetFigureOn(i0,j0-1) = figure) or
  	    (GetFigureOn(i0,j0+1) = figure) or
  	    (GetFigureOn(i0+1,j0-1) = figure) or
  	    (GetFigureOn(i0+1,j0) = figure) or
  	    (GetFigureOn(i0+1,j0+1) = figure)) then
  	begin
  		res := true;
  	end
  end;
  IsUnderAttackByFigure := res;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function IsUnderAttackBy(colorOfAttacker: PlayerColor; i0, j0: longint): boolean;
begin
   if IsUnderAttackByFigure(Pawn, colorOfAttacker, i0, j0) then Exit(true);
   if IsUnderAttackByFigure(Knight, colorOfAttacker, i0, j0) then Exit(true);
   if IsUnderAttackByFigure(Bishop, colorOfAttacker, i0, j0) then Exit(true);
   if IsUnderAttackByFigure(Rook, colorOfAttacker, i0, j0) then Exit(true);
   if IsUnderAttackByFigure(Queen, colorOfAttacker, i0, j0) then Exit(true);
   if IsUnderAttackByFigure(King, colorOfAttacker, i0, j0) then Exit(true);
   
   Exit(false)
end;
procedure SaveBoard;
var f: text;
    i,j: longint;
begin
  Assign(f,'out.txt');
  Append(f);
  for i:=1 to BOARD_SIZE do
  begin
    for j:=1 to BOARD_SIZE do
    begin
      Write(f, board[i,j]:3);
    end;
    WriteLn(f);
  end;
  WriteLn(f);
  Close(f);
end;
function FigureToStr(f: longint): string;
var res: string;
begin
  res:= ' ';
  if (abs(f) = WHITE_PAWN) then res:= ' pawn';
  if (abs(f) = WHITE_KNIGHT) then res:= ' knight';
  if (abs(f) = WHITE_BISHOP) then res:= ' bishop';
  if (abs(f) = WHITE_ROOK) then res:= ' rook';
  if (abs(f) = WHITE_QUEEN) then res:= ' queen';
  if (abs(f) = WHITE_KING) then res:= ' king';
  if (f<0) then res[1] := 'b'
           else res[1] := 'w';
  FigureToStr:=res;
end;
function GetCoordStr(i,j: longint): string;
var res: string;
begin
  str(i, res);
  Exit(chr(ord('a') + j - 1) + res)
end;
function MoveToStr(m:Move): string;
begin
  Exit(
    FigureToStr(m.figureStart) + ' '
    + GetCoordStr(m.iStart, m.jStart) + ' '
    + GetCoordStr(m.iEnd, m.jEnd)
  )
end;
procedure SaveBuf(var buffer: TStrings; outputFileName: string);
var f: text;
    i: longint;
begin
    Assign(f, outputFileName);
    Append(f);
    for i:=0 to buffer.length-1 do
    begin
      WriteLn(f,buffer.items[i]);
    end;
    Close(f);
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
  for i:=0 to makedMoves.length-1 do
  begin
    if (i<=movesGroupSize) then
    begin
      if (lastSavedMoves.length > i) and (lastSavedMoves.items[i] <> makedMoves.items[i]) then TStringsPush('', buffer);
    end;
  end;
  for i:=0 to makedMoves.length-1 do
  begin
    if (i mod 2 = 0) or showEnemyMoves then
    begin
      s := s + MoveToSTr(makedmoves.items[i])+chr(9)
    end;
  end;
  TStringsPush(s, buffer);
  if (buffer.length >= buffermax) then
  begin
    SaveBuf(buffer, outputFileName);
  end;
  lastSavedMoves.length := 0;
  for i := 0 to makedMoves.length-1 do
  begin
    TMovesPush(makedMoves.items[i], lastSavedMoves);
  end;
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
    if (iEnd = 1) and (figureStart*WHITE_PAWN_MOVE_DIRECTION = WHITE_PAWN) then
    begin
      board[iEnd,jEnd] := GetFigureValue(Queen, ColorOf(figureStart));
    end else if (iEnd = 8) and (figureStart*WHITE_PAWN_MOVE_DIRECTION = BLACK_PAWN) then
    begin
      board[iEnd,jEnd] := GetFigureValue(Queen,ColorOf(figureStart));
    end else board[iEnd, jEnd] := figureStart;

    board[iStart, jStart] := 0;
    TMovesPush(m, makedMoves)
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
    TMovesPop(makedMoves);
  end;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
function IsCheckTo(color: PlayerColor):boolean; //TOWRITE
var res: boolean;
    i,j: longint;
begin
  FindKing(color,i,j);
  res := IsUnderAttackBy(OppositeColor(color), i,j);
  IsCheckTo := res;
end;
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure AddMove(m: Move);
var isCheckAfterMove: boolean;
    isMoveToEmptyCell: boolean;
    isOppositeColorAttacked: boolean;
begin
  if (m.iEnd>=1) and (m.iEnd<=8) and (m.jEnd>=1) and (m.jEnd<=8) then
  begin
    doMove(m);
    
    isCheckAfterMove := IsCheckTo(ColorOf(m.figureStart));
    isMoveToEmptyCell := m.figureEnd = EMPTY_CELL;
    isOppositeColorAttacked := (not isMoveToEmptyCell) and (ColorOf(m.figurestart)<>ColorOf(m.figureEnd)); 

    if (not isCheckAfterMove) and (isMoveToEmptyCell or isOppositeColorAttacked) then
    begin
      TMovesPush(m, moves);
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
  currentFigure := GetFigureOn(i0,j0);
  current := GetFigureOn(i,j);
  if (dn <> 0) or (dm <> 0) then
  begin
    while (current*currentFigure <= 0) and (i<=BOARD_SIZE) and (i>=1) and (j<=BOARD_SIZE) and (j>=1) do
    begin
      curmov := CreateMove(i0,j0,i,j, currentFigure);
      AddMove(curmov);
      if (current*currentFigure < 0) then break;
      i := i + dn;
      j := j + dm;
      current := GetFigureOn(i,j);

    end;
  end;
end;
function HasEnemy(
  myColor: PlayerColor;
  i, j: shortint;
  var board: TBoard
): boolean;
begin
 HasEnemy := (i >= 1)
   and (i <= BOARD_SIZE)
   and (j >= 1)
   and (j <= BOARD_SIZE)
   and (board[i,j] <> EMPTY_CELL)
   and (ColorOf(board[i,j]) <> myColor)
end;
function HasEnemyOrEmpty(
  myColor: PlayerColor;
  i, j: shortint;
  var board: TBoard
): boolean;
begin
 HasEnemyOrEmpty := (i >= 1)
   and (i <= BOARD_SIZE)
   and (j >= 1)
   and (j <= BOARD_SIZE)
   and ((board[i,j] = EMPTY_CELL) or (ColorOf(board[i,j]) <> myColor))
end;

function HasPieceOfColor(var board:TBoard; i, j: shortint; color: PlayerColor): boolean;
begin
  HasPieceOfColor := (board[i,j] <> EMPTY_CELL) and (ColorOf(board[i,j]) = color);
end;

procedure AddAllPossiblePawnMoves(var board: TBoard; i, j: shortint);
var color: PlayerColor;
    curfig: shortint;
    currentPawnMoveDirection: shortint;
begin
  curfig := board[i,j];

  assert(abs(curfig) = WHITE_PAWN, 'invariant broken');
  
  color := ColorOf(curfig);

  if ColorOf(curfig) = PlayerColorWhite then
  begin
    currentPawnMoveDirection := WHITE_PAWN_MOVE_DIRECTION;
  end else 
  begin
    currentPawnMoveDirection := -WHITE_PAWN_MOVE_DIRECTION;
  end;

  if HasEnemy(
      color,
      i + currentPawnMoveDirection, j - 1,
      board
  ) then
  begin
      AddMove(CreateMove(
        i,j,
        i + currentPawnMoveDirection, j - 1,
        curfig
      ));
  end;
  if HasEnemy(
      color,
      i + currentPawnMoveDirection, j + 1,
      board
  ) then
  begin
      AddMove(CreateMove(
        i,j,
        i + currentPawnMoveDirection, j + 1,
        curfig
      ));
  end;
  if board[i + currentPawnMoveDirection, j] = EMPTY_CELL then
  begin
    AddMove(CreateMove(i,j,i+currentPawnMoveDirection,j, curfig));
  end;
  if (color = PlayerColorWhite) and (i = BOARD_SIZE - 1) then
  begin
    if (GetFigureOn(i + WHITE_PAWN_MOVE_DIRECTION, j) = EMPTY_CELL)
      and (GetFigureOn(i + 2 * WHITE_PAWN_MOVE_DIRECTION, j) = EMPTY_CELL) then
    begin
        AddMove(CreateMove(i,j,i + 2 * WHITE_PAWN_MOVE_DIRECTION, j, curfig));
    end;
  end;
  if (color = PlayerColorBlack) and (i = 2) then
  begin
    if (GetFigureOn(i - WHITE_PAWN_MOVE_DIRECTION, j) = EMPTY_CELL)
      and (GetFigureOn(i - 2 * WHITE_PAWN_MOVE_DIRECTION, j) = EMPTY_CELL) then
    begin
        AddMove(CreateMove(i,j,i - 2 * WHITE_PAWN_MOVE_DIRECTION,j, curfig));
    end;
  end;
end;

procedure AddAllPossibleMoves(color: PlayerColor);
var i,j: longint;
    curfig: longint; // Curent Figure
    curmov: Move;
    currentPawnMoveDirection: shortint;
begin
  for i:=1 to BOARD_SIZE do
  begin
    for j:=1 to BOARD_SIZE do
    begin
      {TODO: Replace board[i,j]*color to function "HasPieceOfColor(i,j,color)"}
      {TODO: decrease nestedness}
      if not HasPieceOfColor(board, i, j, color) then continue;


      curfig := board[i,j];
      if (abs(curfig) = WHITE_PAWN) then
      begin
        AddAllPossiblePawnMoves(board, i, j);
      end else
      if (abs(curfig) = WHITE_KNIGHT) then //-----------------------------------------------------Loshad
      begin
        if HasEnemyOrEmpty(color, i-2,j-1, board) then
        begin
          curmov := CreateMove(i,j,i-2,j-1, curfig);
          AddMove(curMov);
        end;
        if HasEnemyOrEmpty(color, i-2,j+1, board) then
        begin
          curmov := CreateMove(i,j,i-2,j+1, curfig);
          AddMove(curMov);
        end;
        if HasEnemyOrEmpty(color, i+2,j-1, board) then
        begin
          curmov := CreateMove(i,j,i+2,j-1, curfig);
          AddMove(curMov);
        end;
        if HasEnemyOrEmpty(color,i+2,j+1,board) then
        begin
          curmov := CreateMove(i,j,i+2,j+1, curfig);
          AddMove(curMov);
        end;

        if (HasEnemyOrEmpty(color,i-1,j-2,board)) then
        begin
          curmov := CreateMove(i,j,i-1,j-2, curfig);
          AddMove(curMov);
        end;
        if HasEnemyOrEmpty(color, i-1, j+2, board) then
        begin
          curmov := CreateMove(i,j,i-1,j+2, curfig);
          AddMove(curMov);
        end;
        if HasEnemyOrEmpty(color, i+1,j-2, board) then
        begin
          curmov := CreateMove(i,j,i+1,j-2, curfig);
          AddMove(curMov);
        end;
        if HasEnemyOrEmpty(color, i+1,j+2, board) then
        begin
          curmov := CreateMove(i,j,i+1,j+2, curfig);
          AddMove(curMov);
        end;
      end else
      if (abs(curfig) = WHITE_BISHOP) then
      begin
        AddMovesDist(i,j,-1,-1);
        AddMovesDist(i,j,-1, 1);
        AddMovesDist(i,j, 1,-1);
        AddMovesDist(i,j, 1, 1);
      end else
      if (abs(curfig) = WHITE_ROOK) then
      begin
        AddMovesDist(i,j,-1, 0);
        AddMovesDist(i,j, 0, 1);
        AddMovesDist(i,j, 1, 0);
        AddMovesDist(i,j, 0,-1);
      end else
      if (abs(curfig) = WHITE_QUEEN) then
      begin
        AddMovesDist(i,j,-1,-1);
        AddMovesDist(i,j,-1, 1);
        AddMovesDist(i,j, 1,-1);
        AddMovesDist(i,j, 1, 1);
        AddMovesDist(i,j,-1, 0);
        AddMovesDist(i,j, 0, 1);
        AddMovesDist(i,j, 1, 0);
        AddMovesDist(i,j, 0,-1);
      end else
      if (abs(curfig) = WHITE_KING) then
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
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
procedure Solve(
  color: PlayerColor;
  countOfMoves: longint;
  var buffer: TStrings;
  buffermax: longint;
  movesGroupSize: longint;
  showEnemyMoves: boolean;
  outputFileName: string
);
var firstPossibleMoveIndex: longint;
    lastPossibleMoveIndex: longint;
    i: longint;
    checkWhite, checkBlack: boolean;
    isOk: boolean;
begin
  if (countOfMoves <= 0) then Exit();

  Inc(cVariants);
  firstPossibleMoveIndex := moves.length + 1;

  isOk:= true;

  checkWhite := IsCheckTo(PlayerColorWhite);
  checkBlack := IsCheckTo(PlayerColorBlack);

  {
  | If current state didn't fixed previously set check
  | then it is an invalid state and we do not need to continue solving.
  | Not sure if it is some kind of optimization or not.
  }
  {TODO: Add early return instead of setting isOK}
  if (checkWhite) and (previousMoveWasCheckToWhites) then isOk := false;
  if (checkBlack) and (previousMoveWasCheckToBlacks) then isOK := false;

  if (isOk) then
  begin
    previousMoveWasCheckToWhites := checkWhite;
    previousMoveWasCheckToBlacks := checkBlack;
    AddAllPossibleMoves(color);
    lastPossibleMoveIndex := moves.length-1;
    if (lastPossibleMoveIndex < firstPossibleMoveIndex) and (IsCheckTo(PlayerColorBlack)) then
    begin
        Inc(cSolving);
        if (maxcountOfPossiblemoves < moves.length) then maxcountofPossibleMoves := moves.length;
        WriteLn('solved: ', cSolving, ' Solve: ', cVariants, '   max: ', maxcountofpossibleMoves);
        SaveMoves(outputFileName, buffer, buffermax, showEnemyMoves, movesGroupSize);

    end else
    for i := lastPossibleMoveIndex downto firstPossibleMoveIndex do
    begin
      DoMove(moves.items[i]);
      {$IFDEF SHOULD_LOG}
      WriteLn;
      ShowChessBoard(board);
      {$ENDIF}
      Solve(
        OppositeColor(color),
        countOfMoves -1,
        buffer,
        buffermax,
        movesGroupSize,
        showEnemyMoves,
        outputFileName
      );
      UndoMove(moves.items[i]);
    end;
    moves.length := firstPossibleMoveIndex - 1;

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
    PlayerColorWhite,
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
  WriteLn('Solved: ',cSolving);
  WriteLn('Watched: ', cVariants);
  readkey;
end.
