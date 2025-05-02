#!/bin/bash

total=0
for d in $(seq 1 25)
do
  echo "Timing day$d"
  pushd d$d
  hyperfine ./d$d --export-json ./tmp.json
  res=`cat ./tmp.json | jq ".results[0].mean"`
  rm ./tmp.json
  echo "Time taken for day$d: $res"
  total=`awk "BEGIN{ print $total + $res }"`
  popd
done

echo "Total: $total"
