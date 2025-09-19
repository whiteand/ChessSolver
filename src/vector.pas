{$IFNDEF ELEM_T}{$FATAL Define ELEM_T before including vector.inc}{$ENDIF}
{$IFNDEF VEC_T}{$FATAL Define VEC_T before including vector.inc}{$ENDIF}
{$IFNDEF VEC_POP}{$FATAL Define VEC_POP before including vector.inc}{$ENDIF}
{$IFNDEF VEC_PUSH}{$FATAL Define VEC_PUSH before including vector.inc}{$ENDIF}
{$MACRO ON}
{$assertions on}
type
  VEC_T =
    record
      items: array of ELEM_T;
      length: longint
    end;

procedure VEC_PUSH(x: ELEM_T; var xs: VEC_T);
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
function VEC_POP(var xs: VEC_T): TPerson;
begin
  assert(xs.length > 0, 'Cannot pop element from empty vector');
  VEC_POP := xs.items[xs.length-1];
  Dec(xs.length);
end;

{$undef ELEM_T}{$undef VEC_T}{$undef VEC_POP}{$undef VEC_PUSH}