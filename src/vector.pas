{$ifndef VECTOR_ELEM_TYPE}{$FATAL Define VECTOR_ELEM_TYPE when you include vector.pas}{$ENDIF}
{$ifndef VECTOR_TYPE}{$FATAL Define VECTOR_TYPE when you include vector.pas}{$ENDIF}
{$ifndef VECTOR_PUSH}{$FATAL Define VECTOR_PUSH when you include vector.pas}{$ENDIF}
{$ifndef VECTOR_POP}{$FATAL Define VECTOR_POP when you include vector.pas}{$ENDIF}
{$assertions on}
type
  VECTOR_TYPE =
  record
    items: array of VECTOR_ELEM_TYPE;
    length: longint
  end;
procedure VECTOR_PUSH(x: VECTOR_ELEM_TYPE; var xs: VECTOR_TYPE);
begin
  if Length(xs.items) <= xs.length then
  begin
    if xs.length = 0
      then SetLength(xs.items, 4)
      else SetLength(xs.items, xs.length * 2);
  end;
  xs.items[xs.length] := x;
  Inc(xs.length);
end;
function VECTOR_POP(var xs: VECTOR_TYPE): VECTOR_ELEM_TYPE;
begin
  assert(xs.length > 0, 'Cannot pop element from empty array');
  VECTOR_POP := xs.items[xs.length-1];
  Dec(xs.length);
end;
{$undef VECTOR_ELEM_TYPE}
{$undef VECTOR_TYPE}
{$undef VECTOR_PUSH}
{$undef VECTOR_POP}