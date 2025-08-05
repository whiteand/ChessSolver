set fallback

build:
  rm -f ./target/chessSolver
  rm -f ./target/chessSolver.o
  fpc -FE./target -gw3 ./src/chessSolver.pas

run *params: build
  @clear
  @./target/chessSolver {{params}}

r:
  just run --fen r1b4k/b6p/2pp1r2/pp6/4P3/PBNP2R1/1PP3PP/7K --moves 1 --color white

help:
  just run --help

