Program ChessSolver;
uses crt;
const n        = 8;
      peshka   = 1;
      loshad   = 2;
      officer  = 3;
      ladya    = 4;
      ferz     = 5;
      korol    = 6;

var field: array [1..n, 1..n] of integer;


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
  clrscr;
  showField;
end;
//Reshenie
function isWhiteSafe:boolean;
var i,j, i0, j0: integer;
    res: boolean;
begin
  findKorol(1,i0,j0);
  //Peshki
  //loshad
  //officer
  //ladya
  //ferz

end; // End of isWhiteSafe

function isBlackSafe:boolean;
begin

end;

Begin
  initialize;

  readkey;
end.
