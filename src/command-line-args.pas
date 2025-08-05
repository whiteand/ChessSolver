program CommandLineArgsProgram;
type TCmdArgs =
    record
        ShowHelp: Boolean;
        Fen: string;
        Steps: longint;
        BufferSize: longint;
        A1IsAtTheLeftBottomCorner: boolean;
        MovesGroupSize: integer;
        ShowEnemyMoves: boolean;
    end;
procedure ShowHelp;
begin
    writeln('Usage: ChessSolver --fen <fen-notation> [--color <color>] [--steps <steps>] [--buffer-size <buffer size>] [--a1-at-top-right] [--moves-group-size <group-moves-size>] [--show-enemy-moves]');
    writeln('Example:');
    writeln('  ChessSolver --fen r1b4k/b6p/2pp1r2/pp6/4P3/PBNP2R1/1PP3PP/7K --steps 1 --color white');
    writeln('Options:');
    writeln('  --fen              - Fen notation string describing the chess board. Read more: http://www.ee.unb.ca/cgi-bin/tervo/fen.pl');
    writeln('  --color            - Color of the player that should win. Possible values: white | black. Default is white');
    writeln('  --steps            - Number of expected steps for checkmate to be found');
    writeln('  --buffer-size      - No one knows what is this parameter, TBD. Default to 10000');
    writeln('  --a1-at-top-right  - Should show A1 at the top right corner. Defaults to false');
    writeln('  --moves-group-size - How many moves should be grouped together. Defaults to 0 (means no grouping).');
    writeln('  --show-enemy-moves - Shows enemy moves in the output. Defaults to false.');
end;
function ParseArguments(var args: TCmdArgs): boolean;
var i: integer;
    argument: string;
    expectsFenString: boolean = false;
    expectsSteps: boolean = false;
    expectsBufferSize: boolean = false;
    expectsMovesGroupSize: boolean = false;
    fenArgumentProvided: boolean = false;
    bufferSizeProvided: boolean = false;
    code: Shortint;
begin
    args.A1IsAtTheLeftBottomCorner := false;
    for i := 1 to ParamCount() do
    begin
        argument := ParamStr(i);
        if (argument = '--help') then args.ShowHelp := true
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
        end else if (argument = '--steps') then expectsSteps := true
        else if (expectsSteps) then
        begin
            Val(argument, args.Steps, code);
            if code <> 0 then
            begin
                ShowHelp;
                writeln('ERROR: Expected --steps <steps-number>, but ', argument, ' is passed');
                Exit(false);
            end;
            expectsSteps := false;
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
        else if argument = '--a1-at-top-right' then args.A1IsAtTheLeftBottomCorner := true
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
    if expectsSteps then
    begin
        ShowHelp;
        writeln('ERROR: Expected --steps <steps-count>, but nothing is passed');
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
var args: TCmdArgs;
BEGIN
    if (not ParseArguments(args)) then
        Halt(1);
    writeLn('ShowHelp = ', args.ShowHelp);
    writeLn('Fen = ', args.Fen);
    writeLn('Steps = ', args.Steps);
    writeLn('Buffer Size = ', args.BufferSize);
    writeLn('A1IsAtTheLeftBottomCorner = ', args.A1IsAtTheLeftBottomCorner);
    writeLn('MovesGroupSize = ', args.MovesGroupSize);
    writeLn('ShowEnemyMoves = ', args.ShowEnemyMoves);
END.