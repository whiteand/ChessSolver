{$assertions on}
program DynamicArray;
type
  TPerson =
  record
    name: string;
  end;
  
{$macro on}
{$define VECTOR_ELEM_TYPE := TPerson}
{$define VECTOR_TYPE := TPersons}
{$define VECTOR_PUSH := PushPerson}
{$define VECTOR_POP := PopPerson}
{$i ./vector.pas}

{$define VECTOR_ELEM_TYPE := longint}
{$define VECTOR_TYPE := TNumbers}
{$define VECTOR_PUSH := PushNumber}
{$define VECTOR_POP := PopNumber}
{$i ./vector.pas}
var person: TPerson;
    persons: TPersons;
    numbers: TNumbers;
    a: longint;
    i: longint;
begin
  PushNumber(1, numbers);
  PushNumber(2, numbers);
  PushNumber(3, numbers);
  for i := 0 to Length(numbers.items)-1 do
  begin
    writeln('numbers[',i,'] = ', numbers.items[i]);
  end;

  person.name := 'Andrii';
  PushPerson(person, persons);
  person := PopPerson(persons);
  writeln('Popped.name = ', person.name);
  person.name := 'Vasylyna';
  PushPerson(person, persons);
  person.name := 'Volodymyr';
  PushPerson(person, persons);
  person.name := 'Mykola';
  PushPerson(person, persons);
  person.name := 'Vasyl';
  PushPerson(person, persons);
  writeln('Capacity = ', Length(persons.items));
  writeln('Length = ', persons.length);
  
  for i := 0 to Length(persons.items)-1 do
  begin
    writeln('persons[',i,'].name = ', persons.items[i].name);
  end;
end.