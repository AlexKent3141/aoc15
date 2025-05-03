#!/bin/bash

day_times=()
total=0
day_max=25
for d in $(seq 1 $day_max)
do
  echo "Timing day$d"
  pushd d$d
  hyperfine ./d$d --export-json ./tmp.json
  res=`cat ./tmp.json | jq ".results[0].mean"`
  rm ./tmp.json
  echo "Time taken for day$d: $res"
  total=`awk "BEGIN{ print $total + $res }"`
  popd

  day_times+=($res:d$d)
done

# Sort and print out the days in order of least costly to most costly.
sorted_day_times=($(printf '%s\n' "${day_times[@]}" | sort))

max_day_time=${sorted_day_times[$day_max - 1]}
tokens=(${max_day_time//:/ })
max_time=${tokens[0]}

max_width=50
time_per_token=`awk "BEGIN{ print $max_time / $max_width }"`

for day_time in "${sorted_day_times[@]}"
do
  tokens=(${day_time//:/ })
  len=`awk "BEGIN{ print ${tokens[0]} / $time_per_token }"`
  printf "%-3.3s" "${tokens[1]}"
  printf "%7.7s" " ${tokens[0]}"
  printf " |"
  for i in $(seq 1 $len)
  do
    printf "▓"
  done
  echo ""
done

echo "Total time taken: $total"
