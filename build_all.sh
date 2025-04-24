#!/bin/bash

for d in $(seq 1 25)
do
  echo "Building day$d"
  cd d$d
  odin build . $1
  cd ..
done
