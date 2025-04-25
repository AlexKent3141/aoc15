#!/bin/bash

for d in $(seq 1 25)
do
  echo "Timing day$d"
  cd d$d
  hyperfine ./d$d
  cd ..
done
