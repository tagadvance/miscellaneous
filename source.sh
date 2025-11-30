#!/bin/bash

##
## Checks the "configuration tree" for the specified paths and prints the first readable path.
##

usage() {
  echo "Usage: $0 <path1> [additional paths ...]"
  echo "  path1: The path to source, e.g. '.config'"
  echo "  path2: An optional path to source, e.g. 'foo/.config'"
}

if [ "$#" -lt 1 ]; then
  echo "Error: Missing arguments." >&2
  usage
  exit 1
fi

paths=(
  "."
  "$HOME"
  '/etc'
  # the directory containing the script
  "$(dirname "$(readlink -f "$0")")"
)

for arg in "$@"; do
  for path in "${paths[@]}"; do
    if [[ -r "$path/$arg" ]]; then
      echo "$path/$arg";
      break 2
    fi
  done
done
