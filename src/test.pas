{$assertions on}
program DynamicArray;
type
  TPerson =
  record
    name: string;
  end;
  
  TPersons =
  record
    items: array of TPerson;
    length: longint
  end;
procedure PushPerson(person: TPerson; var persons: TPersons);
begin
  if Length(persons.items) <= persons.length then
  begin
    if persons.length = 0
      then SetLength(persons.items, 4)
      else SetLength(persons.items, persons.length * 2);
  end;
  persons.items[persons.length] := person;
  Inc(persons.length);
end;
function PopPerson(var persons: TPersons): TPerson;
begin
  assert(persons.length > 0, 'Cannot pop element from empty array');
  PopPerson := persons.items[persons.length-1];
  Dec(persons.length);
end;

var person: TPerson;
    persons: TPersons;
    i: longint;
begin
  person := PopPerson(persons);
  writeln('Popped.name = ', person.name);

  person.name := 'Andrii';
  PushPerson(person, persons);
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