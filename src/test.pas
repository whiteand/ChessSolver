{$assertions on}
program DynamicArray;
type
  TPerson =
  record
    name: string;
  end;

{$MACRO ON}
{$define ELEM_T:=TPerson}
{$define VEC_T:=TPersons}
{$define VEC_POP:=TPersons_Pop}
{$define VEC_PUSH:=TPersons_Push}
{$i ./vector.pas}
var person: TPerson;
    persons: TPersons;
    i: longint;
    a, b: longint;
{$MACRO ON}
{$define inc_a_b:=a := a + b}

begin
  // person := TPersons_Pop(persons);
  // writeln('Popped.name = ', person.name);
  a := 1;
  b := 2;
  inc_a_b;
  writeln('a = ', a);
  person.name := 'Andrii';
  TPersons_Push(person, persons);
  person.name := 'Vasylyna';
  TPersons_Push(person, persons);
  person.name := 'Volodymyr';
  TPersons_Push(person, persons);
  person.name := 'Mykola';
  TPersons_Push(person, persons);
  
  person.name := 'Vasyl';
  TPersons_Push(person, persons);
  writeln('Capacity = ', Length(persons.items));
  writeln('Length = ', persons.length);
  
  for i := 0 to Length(persons.items)-1 do
  begin
    writeln('persons[',i,'].name = ', persons.items[i].name);
  end;
end.