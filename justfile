set fallback

build:
  rm -f ./target/chessSolver
  rm -f ./target/chessSolver.o
  fpc -FE./target -gw3 ./src/chessSolver.pas

run: build
  ./target/chessSolver
