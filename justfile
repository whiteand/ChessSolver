build:
  rm -f ./target/chessSolver
  rm -f ./target/chessSolver.o
  fpc -FE./target ./src/chessSolver.pas