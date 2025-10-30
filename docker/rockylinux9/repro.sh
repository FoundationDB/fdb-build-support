#!/bin/bash
# Generate reproduction commands for failed simulation tests

fields_to_extract=("TestFile" "RandomSeed" "BuggifyEnabled")

while read -r line; do
  for field in "${fields_to_extract[@]}"; do
    if [[ $line =~ $field=\"([^\"]*)\" ]]; then
      if [[ $field == "TestFile" ]]; then
        testfile="${BASH_REMATCH[1]}"
      elif [[ $field == "RandomSeed" ]]; then
        randomseed="${BASH_REMATCH[1]}"
      elif [[ $field == "BuggifyEnabled" ]]; then
        buggify_enabled="${BASH_REMATCH[1]}"
        if [[ $buggify_enabled == "1" ]]; then
          buggify="on"
        else
          buggify="off"
        fi
      fi
    fi
  done
  if [[ -n "$testfile" && -n "$randomseed" ]]; then
    echo "fdbserver -r simulation -f src/foundationdb/$testfile --buggify $buggify --seed $randomseed"
    testfile=""
    randomseed=""
  fi
done
